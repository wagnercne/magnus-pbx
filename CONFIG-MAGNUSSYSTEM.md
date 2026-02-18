# 🚀 Configuração MAGNUS PBX - magnussystem.com.br

## 📋 Estrutura de Domínios Definida

```
Domínio Base: magnussystem.com.br
├─ pbx.magnussystem.com.br          → Dashboard Web (porta 443)
├─ pbx-api.magnussystem.com.br      → API REST (porta 443)
└─ Tenants (subdomínios para SIP):
   ├─ belavista.magnussystem.com.br → Tenant 1 (porta 5060)
   ├─ acme.magnussystem.com.br       → Tenant 2 (porta 5060)
   └─ techno.magnussystem.com.br     → Tenant 3 (porta 5060)
```

**Observação:** `api.magnussystem.com.br` já existe para outro sistema (preservado).

---

## 🌐 Passo 1: Configurar DNS no Cloudflare

### **Registros A (IPv4)**

```
Tipo: A
Nome: belavista
Conteúdo: SEU_IP_PUBLICO_AQUI
Proxy: ☁️ Off (cinza) ← IMPORTANTE para SIP!
TTL: Auto

Tipo: A
Nome: acme
Conteúdo: SEU_IP_PUBLICO_AQUI
Proxy: ☁️ Off
TTL: Auto

Tipo: A
Nome: techno
Conteúdo: SEU_IP_PUBLICO_AQUI
Proxy: ☁️ Off
TTL: Auto

Tipo: A
Nome: pbx
Conteúdo: SEU_IP_PUBLICO_AQUI
Proxy: 🟠 On (laranja) ← Pode ativar para dashboard
TTL: Auto

Tipo: A
Nome: pbx-api
Conteúdo: SEU_IP_PUBLICO_AQUI
Proxy: 🟠 On (pode ativar, mas desative se usar WebSocket)
TTL: Auto
```

**❗ CRÍTICO:** 
- Subdomínios SIP (belavista, acme, techno): **Proxy OFF**
- Dashboard/API (pbx, pbx-api): Proxy ON ou OFF (sua escolha)

**Por quê OFF para SIP?**
- SIP precisa ver IP real do servidor
- Cloudflare proxy só funciona para HTTP/HTTPS
- SIP UDP não passa por proxy HTTP

### **Registros SRV (Opcional - Auto-Discovery)**

```
Tipo: SRV
Nome: _sip._udp.belavista
Prioridade: 10
Peso: 5
Porta: 5060
Target: belavista.magnussystem.com.br

Tipo: SRV
Nome: _sip._tcp.belavista
Prioridade: 10
Peso: 5
Porta: 5061
Target: belavista.magnussystem.com.br

(Repetir para acme e techno)
```

**SRV permite softphones descobrirem automaticamente o servidor e porta.**

---

## 🏠 Passo 2: Configurar DNS Local (Split DNS)

### **Opção A: dnsmasq no Roteador** ⭐ RECOMENDADO

```bash
# SSH no roteador
ssh root@192.168.15.1

# Editar dnsmasq.conf
cat >> /etc/dnsmasq.conf <<'EOF'

# ==================================================
# MAGNUS PBX - Split DNS Local
# ==================================================
# Quando consultas vem da LAN, retornar IP local
# Economiza largura de banda e melhora latência

# Tenants SIP
address=/belavista.magnussystem.com.br/192.168.15.253
address=/acme.magnussystem.com.br/192.168.15.253
address=/techno.magnussystem.com.br/192.168.15.253

# Dashboard e API (também local)
address=/pbx.magnussystem.com.br/192.168.15.253
address=/pbx-api.magnussystem.com.br/192.168.15.253

# Wildcard: qualquer *.magnus.local resolve para o servidor
address=/magnus.local/192.168.15.253

# Domínios locais não vão para internet
local=/magnussystem.com.br/
domain=magnussystem.com.br

# DNS upstream para outros domínios
server=8.8.8.8
server=1.1.1.1

# Cache
cache-size=1000

EOF

# Reiniciar dnsmasq
/etc/init.d/dnsmasq restart

# Verificar
/etc/init.d/dnsmasq status
```

### **Opção B: dnsmasq na VM (se não tiver acesso ao roteador)**

```bash
# Na VM 192.168.15.253
apt update
apt install dnsmasq -y

# Editar configuração
nano /etc/dnsmasq.conf
```

**Conteúdo:**

```conf
# Magnus PBX - DNS Local
port=53
interface=eth0
bind-interfaces

# Tenants
address=/belavista.magnussystem.com.br/192.168.15.253
address=/acme.magnussystem.com.br/192.168.15.253
address=/techno.magnussystem.com.br/192.168.15.253
address=/pbx.magnussystem.com.br/192.168.15.253
address=/pbx-api.magnussystem.com.br/192.168.15.253

# Upstream
server=8.8.8.8
server=1.1.1.1

# Cache
cache-size=1000
```

**Ativar:**

```bash
systemctl restart dnsmasq
systemctl enable dnsmasq
systemctl status dnsmasq

# Testar resolução local
dig belavista.magnussystem.com.br @192.168.15.253
```

**Configurar clientes para usar este DNS:**
- Windows: Configurações de Rede → DNS → 192.168.15.253
- DHCP do roteador: DNS Server → 192.168.15.253

---

## 🔥 Passo 3: Port Forwarding no Roteador

### **Regras NAT/Firewall:**

```
Nome: Asterisk SIP UDP
Protocolo: UDP
Porta Externa: 5060
IP Interno: 192.168.15.253
Porta Interna: 5060
Interface: WAN

Nome: Asterisk SIP TLS
Protocolo: TCP
Porta Externa: 5061
IP Interno: 192.168.15.253
Porta Interna: 5061
Interface: WAN

Nome: Asterisk RTP (Áudio/Vídeo)
Protocolo: UDP
Porta Externa: 10000-10200
IP Interno: 192.168.15.253
Porta Interna: 10000-10200
Interface: WAN

Nome: Dashboard HTTPS (Opcional)
Protocolo: TCP
Porta Externa: 443
IP Interno: 192.168.15.253
Porta Interna: 443
Interface: WAN

Nome: WebRTC WSS (Se usar WebRTC)
Protocolo: TCP
Porta Externa: 8089
IP Interno: 192.168.15.253
Porta Interna: 8089
Interface: WAN
```

**Via iptables (se usar Linux como roteador):**

```bash
# SIP UDP
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 5060 -j DNAT --to-destination 192.168.15.253:5060
iptables -A FORWARD -p udp -d 192.168.15.253 --dport 5060 -j ACCEPT

# SIP TLS
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 5061 -j DNAT --to-destination 192.168.15.253:5061
iptables -A FORWARD -p tcp -d 192.168.15.253 --dport 5061 -j ACCEPT

# RTP Range
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10000:10200 -j DNAT --to-destination 192.168.15.253:10000-10200
iptables -A FORWARD -p udp -d 192.168.15.253 --dport 10000:10200 -j ACCEPT

# HTTPS
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 192.168.15.253:443
iptables -A FORWARD -p tcp -d 192.168.15.253 --dport 443 -j ACCEPT

# Salvar regras
iptables-save > /etc/iptables/rules.v4
```

---

## ⚙️ Passo 4: Configurar Asterisk (pjsip.conf)

```bash
# Na VM
cd /srv/magnus-pbx/asterisk_etc

# Backup
cp pjsip.conf pjsip.conf.backup

# Editar
nano pjsip.conf
```

**Adicionar/Atualizar seção transport:**

```ini
[transport-udp]
type=transport
protocol=udp
bind=0.0.0.0:5060

; ===================================
; NAT Configuration
; ===================================
; Descobrir IP público: curl ifconfig.me
external_media_address=SEU_IP_PUBLICO_AQUI
external_signaling_address=SEU_IP_PUBLICO_AQUI

; Redes locais (não aplica NAT para estas subnets)
local_net=192.168.0.0/16
local_net=10.0.0.0/8
local_net=172.16.0.0/12

[transport-tcp]
type=transport
protocol=tcp
bind=0.0.0.0:5060

[transport-tls]
type=transport
protocol=tls
bind=0.0.0.0:5061
; cert_file=/etc/asterisk/keys/asterisk.pem
; priv_key_file=/etc/asterisk/keys/asterisk.key
; ca_list_file=/etc/asterisk/keys/ca.crt

[transport-wss]
type=transport
protocol=wss
bind=0.0.0.0:8089
; WebRTC (precisa de certificado SSL)
```

**Verificar RTP config:**

```bash
nano /etc/asterisk/rtp.conf
```

```ini
[general]
rtpstart=10000
rtpend=10200
strictrtp=yes
icesupport=yes
```

---

## 🗄️ Passo 5: Atualizar Banco de Dados

```bash
# Conectar no PostgreSQL
docker exec postgres-magnus psql -U admin_magnus -d magnus_pbx
```

**Atualizar ps_domain_aliases:**

```sql
-- Limpar aliases antigos (se existirem)
DELETE FROM ps_domain_aliases;

-- Adicionar domínios reais
INSERT INTO ps_domain_aliases (id, domain) VALUES
    ('belavista', 'belavista.magnussystem.com.br'),
    ('acme', 'acme.magnussystem.com.br'),
    ('techno', 'techno.magnussystem.com.br')
ON CONFLICT (id) DO NOTHING;

-- Verificar
SELECT * FROM ps_domain_aliases;

-- Sair
\q
```

---

## 🔄 Passo 6: Reiniciar Asterisk

```bash
# Restart completo
docker restart asterisk-magnus

# Aguardar inicialização
sleep 15

# Verificar logs
docker logs asterisk-magnus --tail 100

# Verificar transports
docker exec asterisk-magnus asterisk -rx "pjsip show transports"

# Verificar endpoints
docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"
```

---

## 📱 Passo 7: Configurar Softphones

### **Cenário 1: Ramal na Rede Local (Escritório)**

**Configurações Linphone/Zoiper:**

```
Conta: Tenant Belavista
────────────────────────
Nome de usuário: 1002
Senha: magnus123
Domínio: belavista.magnussystem.com.br
Proxy/Servidor: belavista.magnussystem.com.br
Porta: 5060
Transporte: UDP
```

**O que acontece:**
1. Softphone consulta DNS → dnsmasq responde `192.168.15.253`
2. Registra via LAN (rede local, sem NAT)
3. Latência baixíssima, sem consumir internet

### **Cenário 2: Ramal Remoto (Home Office, 4G)**

**Mesma configuração:**

```
Nome de usuário: 1002
Senha: magnus123
Domínio: belavista.magnussystem.com.br
Servidor: belavista.magnussystem.com.br
Porta: 5060
```

**O que acontece:**
1. Softphone consulta DNS → Cloudflare responde `SEU_IP_PUBLICO`
2. Registra via internet → Port forward → Asterisk
3. Asterisk detecta que vem de IP externo e aplica NAT config

### **Cenário 3: Multi-Tenant**

**Tenant ACME:**

```
Nome de usuário: 2001
Senha: acme2001
Domínio: acme.magnussystem.com.br
Servidor: acme.magnussystem.com.br
```

**Tenant Techno:**

```
Nome de usuário: 3001
Senha: techno3001
Domínio: techno.magnussystem.com.br
Servidor: techno.magnussystem.com.br
```

---

## 🧪 Passo 8: Testes

### **Teste 1: DNS Local**

```bash
# Na rede local (192.168.15.0/24)
nslookup belavista.magnussystem.com.br

# Deve retornar: 192.168.15.253
```

### **Teste 2: DNS Externo**

```bash
# Use 4G no celular, ou SSH de fora da rede
nslookup belavista.magnussystem.com.br 8.8.8.8

# Deve retornar: SEU_IP_PUBLICO
```

### **Teste 3: Porta Aberta**

```bash
# De fora da rede (4G, outro servidor)
nmap -sU -p 5060 SEU_IP_PUBLICO

# Resultado esperado:
# 5060/udp open  sip
```

### **Teste 4: Registro Local**

```bash
# Configurar softphone na LAN
# Verificar no Asterisk:
docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Deve mostrar: endpoint Not in use ou Available
```

### **Teste 5: Registro Remoto**

```bash
# Configurar softphone via 4G/outra rede
# Verificar:
docker exec asterisk-magnus asterisk -rx "pjsip show contacts"

# Deve mostrar contact com IP externo
```

### **Teste 6: Chamada Local → Local**

```bash
# Ramal 1001 disca 1002 (ambos na LAN)
# Verificar:
docker exec asterisk-magnus asterisk -rx "core show channels"

# Deve mostrar canal ativo
```

### **Teste 7: Chamada Remoto → Local**

```bash
# Ramal remoto (4G) disca ramal local (LAN)
# Áudio deve funcionar em ambas direções
# Verificar latência e qualidade
```

---

## 🔍 Troubleshooting Específico

### **Problema: DNS resolve para IP errado**

```bash
# Limpar cache DNS
# Windows:
ipconfig /flushdns

# Linux:
sudo systemd-resolve --flush-caches

# Testar direto:
dig belavista.magnussystem.com.br @192.168.15.1  # Router
dig belavista.magnussystem.com.br @8.8.8.8       # Google
```

### **Problema: SIP registra mas sem áudio**

```bash
# Verificar configuração NAT
docker exec asterisk-magnus asterisk -rx "pjsip show transport transport-udp"

# Deve mostrar:
# external_media_address = SEU_IP_PUBLICO
# external_signaling_address = SEU_IP_PUBLICO

# Verificar portas RTP abertas
nmap -sU -p 10000-10200 SEU_IP_PUBLICO
```

### **Problema: Cloudflare bloqueando SIP**

```bash
# SIP não funciona com Cloudflare Proxy ON
# Solução: Desativar proxy (☁️ → cinza)

# No Cloudflare:
belavista.magnussystem.com.br → Proxy Status: DNS only
```

---

## ✅ Checklist Final

- [ ] IP público descoberto: `curl ifconfig.me`
- [ ] Cloudflare configurado (A records, Proxy OFF)
- [ ] dnsmasq configurado no roteador/VM
- [ ] Port forward: 5060, 5061, 10000-10200
- [ ] pjsip.conf: external_*_address configurado
- [ ] Asterisk reiniciado
- [ ] Teste DNS local: resolve para 192.168.15.253
- [ ] Teste DNS externo: resolve para IP público
- [ ] Teste porta: nmap mostra 5060/udp open
- [ ] Softphone local: registra via LAN
- [ ] Softphone remoto: registra via internet
- [ ] Chamada local → local: áudio OK
- [ ] Chamada remoto → local: áudio OK
- [ ] CDR gravando no PostgreSQL

---

## 📊 Resumo da Arquitetura

```
┌─────────────────────────────────────────────────────┐
│  INTERNET                                           │
│  ├─ DNS: Cloudflare                                 │
│  │  └─ *.magnussystem.com.br → IP_PUBLICO          │
│  │                                                  │
│  └─ Cliente Remoto (4G/Home)                       │
│     └─ belavista.magnussystem.com.br → IP_PUBLICO  │
└──────────────────┬──────────────────────────────────┘
                   │
            ┌──────▼──────┐
            │  Roteador   │
            │ Port Forward│
            │ NAT + Split │
            │    DNS      │
            └──────┬──────┘
                   │
   ┌───────────────┼────────────────┐
   │               │                │
   ▼               ▼                ▼
Rede Local   Servidor PBX      Internet
192.168.15/24  .253            IP Público
   │               │
   │    ┌──────────▼──────────┐
   └───►│   Asterisk 22       │
        │   PostgreSQL 17     │
        │   192.168.15.253    │
        └─────────────────────┘
```

---

## 🚀 Próximos Passos

1. **SSL/TLS para Dashboard:**
   - Let's Encrypt com Traefik
   - Acesso: https://pbx.magnussystem.com.br

2. **API REST:**
   - https://pbx-api.magnussystem.com.br
   - Autenticação JWT

3. **WebRTC:**
   - WSS com certificado SSL
   - Cliente web sem instalação

4. **Monitoramento:**
   - Grafana + Prometheus
   - Alertas Telegram/Email

---

## 🌟 Comandos Úteis

```bash
# Descobrir IP público
curl ifconfig.me

# Ver logs tempo real
docker logs asterisk-magnus --tail 50 --follow

# Ver registros ativos
docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"
docker exec asterisk-magnus asterisk -rx "pjsip show contacts"

# Ver chamadas ativas
docker exec asterisk-magnus asterisk -rx "core show channels"

# Reload PJSIP (sem reiniciar)
docker exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"

# Ver transport NAT config
docker exec asterisk-magnus asterisk -rx "pjsip show transport transport-udp"

# Consultar CDR
docker exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT src, dst, duration FROM cdr ORDER BY calldate DESC LIMIT 10;"
```

---

**Domínio:** magnussystem.com.br  
**Dashboard:** pbx.magnussystem.com.br  
**API:** pbx-api.magnussystem.com.br  
**Tenants:** belavista/acme/techno.magnussystem.com.br
