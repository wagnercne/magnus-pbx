# 🌐 Arquitetura Híbrida: Local + Internet

## 🎯 Cenário: Funcionamento Misto

**Requisitos:**
- ✅ Funciona **com** internet (usuários remotos)
- ✅ Funciona **sem** internet (contingência, rede local)
- ✅ Mesma configuração nos softphones
- ✅ Multi-tenant em ambos cenários

**Casos de Uso:**
- Escritório com ramais locais + funcionários home office
- Contingência quando internet cai
- Filiais com VPN + acesso local
- Clientes externos + ramais internos

---

## 🏗️ Arquitetura Recomendada: Split DNS

```
                    ┌─────────────────┐
                    │   INTERNET      │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         Cloudflare       Internet       Roteador
         (DNS público)     DOWN?        (DNS local)
              │              │              │
              ▼              ▼              ▼
      magnus.com.br    USA DNS LOCAL   192.168.15.0/24
      IP Público       dnsmasq         LAN privada
         │                  │              │
         ▼                  └──────┬───────┘
    WAN: 200.x.x.x                 │
    NAT: 5060→192.168.15.253       ▼
         │                  LAN: 192.168.15.253
         └──────────┬───────┘
                    ▼
            ┌──────────────┐
            │   Asterisk   │
            │ 192.168.15.253
            └──────────────┘
```

**Funcionamento:**
1. **Com Internet**: DNS público resolve domínio → IP público → NAT → Asterisk
2. **Sem Internet**: DNS local resolve domínio → IP local → Asterisk direto
3. **Softphone**: MESMA configuração em ambos casos

---

## 📋 Solução 1: Split DNS (Mais Simples) ⭐ RECOMENDADO

### **Conceito:**
- DNS externo (Cloudflare): `belavista.magnus.com.br` → IP público
- DNS interno (dnsmasq): `belavista.magnus.com.br` → IP local  
- Cliente pergunta primeiro ao DNS local (resposta mais rápida vence)

### **Configuração:**

#### **1. Cloudflare (DNS Público)**

```
# Registros DNS em Cloudflare
A    belavista.magnus.com.br   →   200.x.x.x (seu IP público)
A    acme.magnus.com.br         →   200.x.x.x
A    techno.magnus.com.br       →   200.x.x.x

SRV  _sip._udp.belavista.magnus.com.br  →  0 5 5060 belavista.magnus.com.br
SRV  _sip._tcp.belavista.magnus.com.br  →  0 5 5061 belavista.magnus.com.br
```

#### **2. dnsmasq (DNS Local no Roteador)**

```bash
# /etc/dnsmasq.conf no roteador ou VM

# DNS Interno: responder domínios Magnus com IP local
address=/belavista.magnus.com.br/192.168.15.253
address=/acme.magnus.com.br/192.168.15.253
address=/techno.magnus.com.br/192.168.15.253

# DNS Externo: encaminhar outras consultas para internet
server=8.8.8.8
server=1.1.1.1

# Priorizar respostas locais (mais rápido)
local=/magnus.com.br/
```

**Resultado:**
- **Rede local**: Cliente consulta roteador → resposta instantânea com IP local
- **Internet**: Cliente consulta Cloudflare → resposta com IP público

#### **3. NAT/Port Forward no Roteador**

```bash
# iptables ou interface web do roteador

# SIP UDP
WAN:5060/udp → 192.168.15.253:5060/udp

# SIP TCP/TLS
WAN:5060/tcp → 192.168.15.253:5060/tcp
WAN:5061/tcp → 192.168.15.253:5061/tcp

# RTP (Áudio/Vídeo)
WAN:10000-10200/udp → 192.168.15.253:10000-10200/udp

# WebRTC WSS (se usar)
WAN:443/tcp → 192.168.15.253:8089/tcp
```

#### **4. Asterisk: Configuração NAT**

```ini
; pjsip.conf

[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
; IP externo para clientes via internet
external_media_address=200.x.x.x
external_signaling_address=200.x.x.x
; Redes locais (não usa NAT)
local_net=192.168.15.0/24
local_net=10.0.0.0/8
local_net=172.16.0.0/12
```

#### **5. Configuração Cliente (Única!)**

```
Servidor: belavista.magnus.com.br
Usuário: 1002
Senha: magnus123
Porta: 5060
```

**Magia:** DNS resolve automaticamente para IP correto!

---

## 📋 Solução 2: VPN + DNS Local (Mais Seguro)

### **Para usuários remotos:**

```
Funcionário → VPN (WireGuard/OpenVPN) → Rede Local → DNS Local → Asterisk
```

**Vantagens:**
- ✅ Tráfego SIP criptografado pela VPN
- ✅ Cliente se comporta como se estivesse na LAN
- ✅ Não precisa expor porta 5060 na internet
- ✅ Mais seguro

**Desvantagens:**
- ⚠️ Precisa configurar VPN nos dispositivos
- ⚠️ Latência adicional (pode afetar qualidade)

### **Configuração WireGuard:**

```ini
# /etc/wireguard/wg0.conf (servidor na VM)

[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT

# Cliente 1 (Funcionário remoto)
[Peer]
PublicKey = CLIENT1_PUBLIC_KEY
AllowedIPs = 10.8.0.2/32

# Cliente 2
[Peer]
PublicKey = CLIENT2_PUBLIC_KEY
AllowedIPs = 10.8.0.3/32
```

**Cliente (Laptop/Mobile):**
```ini
[Interface]
Address = 10.8.0.2/24
PrivateKey = CLIENT_PRIVATE_KEY
DNS = 192.168.15.253  # DNS interno via VPN

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 200.x.x.x:51820
AllowedIPs = 192.168.15.0/24, 10.8.0.0/24
PersistentKeepalive = 25
```

**Softphone via VPN:**
```
Servidor: belavista.magnus.com.br  (resolve para 192.168.15.253 via VPN)
Usuário: 1002
Senha: magnus123
```

---

## 📋 Solução 3: Auto-Discovery (Mais Avançado)

Softphone tenta múltiplos servidores automaticamente.

### **Configuração SRV Records DNS:**

```
# Cloudflare (Prioridade 10 = Público)
_sip._udp.belavista.magnus.com.br  10 5 5060 wan.magnus.com.br
WAN: 200.x.x.x

# Local (Prioridade 1 = Preferido)
_sip._udp.belavista.magnus.com.br   1 5 5060 local.magnus.com.br
LAN: 192.168.15.253
```

**Softphone:**
1. Tenta servidor com menor prioridade (1 = local)
2. Se falhar, tenta próximo (10 = público)
3. Failover automático!

**Limitação:** Nem todos softphones suportam SRV records.

---

## 🔧 Configuração Prática: Passo a Passo

### **Passo 1: Configurar dnsmasq no Roteador**

```bash
# SSH no roteador (OpenWrt/DD-WRT)
ssh root@192.168.15.1

# Editar dnsmasq
cat >> /etc/dnsmasq.conf <<EOF
# Magnus PBX - Split DNS
address=/magnus.com.br/192.168.15.253
local=/magnus.com.br/
EOF

# Restart
/etc/init.d/dnsmasq restart
```

### **Passo 2: Port Forward no Roteador**

**Via Web UI:**
```
Port Forwarding:
  Nome: Asterisk SIP UDP
  Protocolo: UDP
  Porta Externa: 5060
  IP Interno: 192.168.15.253
  Porta Interna: 5060
  
  Nome: Asterisk RTP
  Protocolo: UDP
  Porta Externa: 10000-10200
  IP Interno: 192.168.15.253
  Porta Interna: 10000-10200
```

### **Passo 3: Atualizar pjsip.conf**

```bash
# Na VM
cd /srv/magnus-pbx/asterisk_etc

# Editar pjsip.conf
nano pjsip.conf
```

**Adicionar:**

```ini
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060
external_media_address=SEU_IP_PUBLICO_AQUI
external_signaling_address=SEU_IP_PUBLICO_AQUI
local_net=192.168.15.0/24
local_net=192.168.0.0/16
local_net=10.0.0.0/8
```

**Descobrir seu IP público:**
```bash
curl ifconfig.me
# ou
curl icanhazip.com
```

### **Passo 4: Reiniciar Asterisk**

```bash
docker restart asterisk-magnus
sleep 10
docker logs asterisk-magnus --tail 50
```

### **Passo 5: Configurar Cloudflare (DNS Público)**

1. Compre domínio: `magnus.com.br` no Registro.br
2. Aponte nameservers para Cloudflare
3. Adicione registros:

```
Tipo: A
Nome: belavista
Conteúdo: SEU_IP_PUBLICO
Proxy: Off (ícone nuvem cinza)
TTL: Auto

Tipo: A
Nome: acme
Conteúdo: SEU_IP_PUBLICO
Proxy: Off
TTL: Auto
```

### **Passo 6: Testar Ambos Cenários**

**Teste 1: Rede Local**
```bash
# Na rede 192.168.15.0/24
nslookup belavista.magnus.com.br
# Deve retornar: 192.168.15.253

# Testar SIP
docker exec asterisk-magnus asterisk -rx "pjsip show transports"
```

**Teste 2: Via Internet** (use 4G do celular)
```bash
# Desconectar WiFi, usar dados móveis
nslookup belavista.magnus.com.br
# Deve retornar: SEU_IP_PUBLICO

# Testar registro no softphone
```

---

## 🔍 Troubleshooting Híbrido

### **Problema: Funciona local mas não via internet**

```bash
# Verificar port forward
# No roteador, ver logs de firewall

# Testar abertura de porta
# De fora da rede:
nmap -sU -p 5060 SEU_IP_PUBLICO
# Deve mostrar: 5060/udp open

# Verificar NAT no Asterisk
docker exec asterisk-magnus asterisk -rx "pjsip show transport transport-udp"
# Ver: external_media_address e external_signaling_address
```

### **Problema: Áudio cortado em chamadas externas**

```bash
# RTP precisa passar pelo NAT
# Verificar se portas 10000-10200 estão abertas

# rtp.conf
[general]
rtpstart=10000
rtpend=10200
```

### **Problema: DNS resolve IP errado**

```bash
# Limpar cache DNS no cliente
# Windows:
ipconfig /flushdns

# Linux/Mac:
sudo systemd-resolve --flush-caches
# ou
sudo killall -HUP mDNSResponder

# Testar qual DNS está respondendo
dig belavista.magnus.com.br @8.8.8.8  # Público
dig belavista.magnus.com.br @192.168.15.1  # Local
```

---

## ⚡ Contingência: Internet Caiu

**Que funções continuam funcionando:**
- ✅ Ramais locais ligam entre si
- ✅ Filas locais continuam
- ✅ Transferência entre ramais
- ✅ Correio de voz (Voicemail local)
- ✅ Gravações (CDR no PostgreSQL local)

**O que para de funcionar:**
- ❌ Ramais remotos (fora da LAN)
- ❌ Troncos SIP externos (operadora)
- ❌ Provisionamento cloud
- ❌ Dashboard web (se hospedado fora)

**Para melhorar contingência:**
- Use UPS (no-break) no servidor
- PostgreSQL local (já configurado ✅)
- Backup local de configurações

---

## 📊 Comparação: 3 Soluções Híbridas

| Critério | Split DNS | VPN | Auto-Discovery |
|----------|-----------|-----|----------------|
| Setup | ⭐⭐⭐ Médio | ⭐⭐ Complexo | ⭐⭐⭐⭐ Simples |
| Segurança | ⭐⭐ Média | ⭐⭐⭐⭐⭐ Alta | ⭐⭐ Média |
| Performance | ⭐⭐⭐⭐ Alta | ⭐⭐⭐ Boa | ⭐⭐⭐⭐ Alta |
| Facilidade | ⭐⭐⭐⭐ Fácil | ⭐⭐ Difícil | ⭐⭐⭐ Média |
| NAT traversal | ⚠️ Precisa config | ✅ VPN resolve | ⚠️ Precisa config |
| Failover | ❌ Manual | ✅ Automático | ✅ Automático |
| **Recomendado** | ✅ **Maioria** | Segurança crítica | Recursos limitados |

---

## 🎯 Recomendação por Perfil

### **Pequena Empresa (até 50 ramais)**
```
✅ Split DNS (Solução 1)
- dnsmasq no roteador
- Port forward básico
- Cloudflare grátis
```

### **Empresa Média (50-200 ramais)**
```
✅ Split DNS + VPN para remotos
- Rede local: DNS interno
- Remotos críticos: VPN
- Clientes externos: Port forward
```

### **Empresa Grande (200+ ramais, multi-site)**
```
✅ VPN mesh + DNS centralizado
- Site-to-Site VPN (WireGuard)
- Todos acessam via VPN
- Sem exposição pública
```

---

## 📚 Arquivos para Configurar

### **No Roteador:**
```
/etc/dnsmasq.conf         - Split DNS
/etc/config/firewall      - Port forwarding (OpenWrt)
```

### **Na VM (Asterisk):**
```
asterisk_etc/pjsip.conf   - external_*_address
asterisk_etc/rtp.conf     - Portas RTP
```

### **No Cloudflare:**
```
A records    - belavista.magnus.com.br
SRV records  - _sip._udp (opcional)
```

---

## ✅ Checklist de Implementação

- [ ] Registrar domínio (magnus.com.br)
- [ ] Configurar Cloudflare com IP público
- [ ] Descobrir IP público atual (`curl ifconfig.me`)
- [ ] Configurar dnsmasq no roteador
- [ ] Port forward: 5060, 5061, 10000-10200
- [ ] Atualizar pjsip.conf com external_*_address
- [ ] Reiniciar Asterisk
- [ ] Testar: nslookup interno vs externo
- [ ] Testar: registro local
- [ ] Testar: registro via internet (4G)
- [ ] Testar: chamada local → local
- [ ] Testar: chamada internet → local
- [ ] Testar: contingência (desligar internet)

---

Quer que eu te ajude a implementar o Split DNS agora? Posso gerar os comandos específicos para seu cenário.
