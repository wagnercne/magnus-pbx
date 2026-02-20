# 🔧 Configuração MikroTik - DNS Estático para MAGNUS PBX

## 🎯 Objetivo

Configurar **Static DNS** no MikroTik RouterOS para resolver domínios `*.magnussystem.com.br` para o servidor local `10.3.2.253`.

---

## 🚀 Método 1: Via WinBox (Interface Gráfica) ⭐ MAIS FÁCIL

### **Passo 1: Abrir WinBox**
1. Conectar no MikroTik (IP: geralmente `192.168.88.1` ou seu IP)
2. Login: admin / senha configurada

### **Passo 2: IP → DNS**
```
Menu: IP → DNS
```

**Verificar configuração DNS:**
- **Servers:** `8.8.8.8`, `1.1.1.1` (ou seus DNS preferidos)
- **Allow Remote Requests:** ✅ Marcado (importante!)
- **Cache Size:** 2048 KiB (padrão)

### **Passo 3: Adicionar Static DNS Records**

```
Menu: IP → DNS → Static Tab
Botão: + (Add New)
```

**Adicionar cada domínio:**

#### **Tenant Belavista**
```
Name: belavista.magnussystem.com.br
Address: 10.3.2.253
TTL: 00:05:00 (5 minutos)
Regexp: (deixar vazio)
Match Subdomain: ❌ (deixar desmarcado)
```
Clicar **OK**

#### **Tenant ACME**
```
Name: acme.magnussystem.com.br
Address: 10.3.2.253
TTL: 00:05:00
```
Clicar **OK**

#### **Tenant Techno**
```
Name: techno.magnussystem.com.br
Address: 10.3.2.253
TTL: 00:05:00
```
Clicar **OK**

#### **Dashboard Web**
```
Name: pbx.magnussystem.com.br
Address: 10.3.2.253
TTL: 00:05:00
```
Clicar **OK**

#### **API REST**
```
Name: pbx-api.magnussystem.com.br
Address: 10.3.2.253
TTL: 00:05:00
```
Clicar **OK**

### **Passo 4: Verificar Lista**

No tab **Static**, você deve ver:

```
Name                              Address           TTL
belavista.magnussystem.com.br     10.3.2.253        5m
acme.magnussystem.com.br          10.3.2.253        5m
techno.magnussystem.com.br        10.3.2.253        5m
pbx.magnussystem.com.br           10.3.2.253        5m
pbx-api.magnussystem.com.br       10.3.2.253        5m
```

---

## 🖥️ Método 2: Via Terminal/SSH (CLI)

### **Conectar via SSH:**

```bash
ssh admin@192.168.88.1
# ou pelo Telnet/Serial Console
```

### **Comandos para adicionar Static DNS:**

```bash
# Verificar DNS atual
/ip dns print

# Garantir que Allow Remote Requests está habilitado
/ip dns set allow-remote-requests=yes

# Adicionar registros estáticos
/ip dns static add name=belavista.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=acme.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=techno.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=pbx.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=pbx-api.magnussystem.com.br address=10.3.2.253 ttl=5m

# Verificar registros criados
/ip dns static print

# Limpar cache DNS (forçar uso imediato)
/ip dns cache flush
```

### **Saída esperada do `print`:**

```
Flags: D - dynamic, X - disabled, R - regexp
 #   NAME                              ADDRESS          TTL
 0   belavista.magnussystem.com.br     10.3.2.253       5m
 1   acme.magnussystem.com.br          10.3.2.253       5m
 2   techno.magnussystem.com.br        10.3.2.253       5m
 3   pbx.magnussystem.com.br           10.3.2.253       5m
 4   pbx-api.magnussystem.com.br       10.3.2.253       5m
```

---

## 🌐 Método 3: Wildcard DNS (Avançado - Opcional)

Se você quer que **QUALQUER** subdomínio de `magnussystem.com.br` resolva para o servidor:

### **Via Terminal:**

```bash
# Adicionar entrada wildcard usando Regexp
/ip dns static add name=".*\\.magnussystem\\.com\\.br" address=10.3.2.253 regexp=".*" ttl=5m
```

### **Via WinBox:**

```
Name: .*\.magnussystem\.com\.br
Address: 10.3.2.253
TTL: 00:05:00
Regexp: .*
Match Subdomain: ✅ Marcado
```

**Vantagem:** Qualquer novo tenant automaticamente resolve (ex: `novo.magnussystem.com.br`)

**Desvantagem:** Pode causar conflitos se você tiver outros subdomínios

---

## 🔍 Testes

### **Teste 1: Do próprio MikroTik**

```bash
# Terminal do MikroTik
/tool fetch url=http://belavista.magnussystem.com.br:5060 mode=http

# Ou usar resolve
/ping belavista.magnussystem.com.br count=4
```

### **Teste 2: De um PC na rede**

**Windows:**
```powershell
# Verificar qual DNS está configurado
ipconfig /all

# Limpar cache
ipconfig /flushdns

# Testar resolução
nslookup belavista.magnussystem.com.br

# Deve retornar: 10.3.2.253
```

**Linux/Mac:**
```bash
# Testar
dig belavista.magnussystem.com.br

# Ou
nslookup belavista.magnussystem.com.br
```

### **Teste 3: Verificar Cache DNS do MikroTik**

```bash
# Ver cache DNS
/ip dns cache print where name~"magnussystem"

# Resultado esperado:
# NAME                              DATA         TTL
# belavista.magnussystem.com.br     10.3.2.253      4m59s
```

---

## 🛡️ Configuração DHCP (Importante!)

Para que os clientes usem o DNS do MikroTik automaticamente:

### **Via WinBox:**

```
Menu: IP → DHCP Server → Networks
Selecione sua rede (ex: 192.168.15.0/24)
```

**Verificar/Configurar:**
```
Address: 10.3.2.0/24
Gateway: 10.3.2.1 (IP do MikroTik)
DNS Servers: 10.3.2.1 (IP do MikroTik)
```

### **Via Terminal:**

```bash
# Ver configuração atual
/ip dhcp-server network print

# Atualizar se necessário
/ip dhcp-server network set [find address="10.3.2.0/24"] dns-server=10.3.2.1
```

**Resultado:** Clientes que pegarem IP por DHCP automaticamente usarão o DNS do MikroTik (que resolve os domínios locais).

---

## 🔄 Configuração Híbrida (Local + Internet)

### **Funcionamento:**

1. **Cliente na LAN:**
   - Pergunta ao MikroTik (10.3.2.1): "Qual IP de belavista.magnussystem.com.br?"
   - MikroTik responde: "10.3.2.253" (Static DNS)
   - Cliente conecta direto via LAN

2. **Cliente via Internet (4G, outra rede):**
   - Pergunta ao Cloudflare/Google DNS: "Qual IP de belavista.magnussystem.com.br?"
   - Cloudflare responde: "SEU_IP_PUBLICO"
   - Cliente conecta via internet → Port forward → Asterisk

**Ambos usam MESMA configuração no softphone!**

---

## 🔧 Port Forwarding no MikroTik

### **Via Terminal:**

```bash
# SIP UDP (porta 5060)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5060 protocol=udp dst-port=5060 in-interface=ether1

# SIP TCP (porta 5060)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5060 protocol=tcp dst-port=5060 in-interface=ether1

# SIP TLS (porta 5061)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5061 protocol=tcp dst-port=5061 in-interface=ether1

# RTP (áudio/vídeo - portas 10000-10200)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=10000-10200 protocol=udp dst-port=10000-10200 in-interface=ether1

# Verificar regras
/ip firewall nat print where chain=dstnat
```

**Nota:** Substitua `ether1` pela sua interface WAN (pode ser `pppoe-out1`, `bridge1`, etc.)

### **Via WinBox:**

```
Menu: IP → Firewall → NAT Tab
Botão: + (Add New)

General:
  Chain: dstnat
  Protocol: udp (17)
  Dst. Port: 5060
  In. Interface: ether1 (sua WAN)

Action:
  Action: dst-nat
  To Addresses: 10.3.2.253
  To Ports: 5060

Clicar OK
```

**Repetir para:**
- UDP 5060 (SIP)
- TCP 5060 (SIP)
- TCP 5061 (SIP TLS)
- UDP 10000-10200 (RTP - pode usar range)

---

## 🔥 Firewall (Liberar Tráfego)

### **Permitir tráfego para Asterisk:**

```bash
# Permitir SIP e RTP de qualquer origem para o servidor
/ip firewall filter add chain=forward action=accept protocol=udp dst-address=10.3.2.253 dst-port=5060 comment="Asterisk SIP UDP"
/ip firewall filter add chain=forward action=accept protocol=tcp dst-address=10.3.2.253 dst-port=5060,5061 comment="Asterisk SIP TCP/TLS"
/ip firewall filter add chain=forward action=accept protocol=udp dst-address=10.3.2.253 dst-port=10000-10200 comment="Asterisk RTP"

# Verificar
/ip firewall filter print where chain=forward
```

**Via WinBox:**

```
Menu: IP → Firewall → Filter Rules Tab
Inserir ANTES de qualquer regra "drop"

Chain: forward
Protocol: udp
Dst. Address: 10.3.2.253
Dst. Port: 5060
Action: accept
Comment: Asterisk SIP UDP
```

---

## 📊 Monitoramento

### **Ver queries DNS em tempo real:**

```bash
# Ativar logging de DNS
/system logging add topics=dns,!debug action=memory

# Ver logs
/log print where topics~"dns"
```

### **Ver estatísticas:**

```bash
# Pacotes DNS
/ip dns cache print stats

# Tráfego NAT
/ip firewall nat print stats
```

---

## ✅ Checklist de Configuração MikroTik

- [ ] **DNS Settings:**
  - [ ] Allow Remote Requests: ✅ Habilitado
  - [ ] Servers: 8.8.8.8, 1.1.1.1 configurados
  
- [ ] **Static DNS Records:**
  - [ ] belavista.magnussystem.com.br → 10.3.2.253
  - [ ] acme.magnussystem.com.br → 10.3.2.253
  - [ ] techno.magnussystem.com.br → 10.3.2.253
  - [ ] pbx.magnussystem.com.br → 10.3.2.253
  - [ ] pbx-api.magnussystem.com.br → 10.3.2.253
  
- [ ] **DHCP Network:**
  - [ ] DNS Server: 10.3.2.1 (IP do MikroTik)
  
- [ ] **NAT (Port Forward):**
  - [ ] UDP 5060 → 10.3.2.253:5060
  - [ ] TCP 5060 → 10.3.2.253:5060
  - [ ] TCP 5061 → 10.3.2.253:5061
  - [ ] UDP 10000-10200 → 10.3.2.253
  
- [ ] **Firewall:**
  - [ ] Allow forward to 10.3.2.253:5060 (UDP/TCP)
  - [ ] Allow forward to 10.3.2.253:5061 (TCP)
  - [ ] Allow forward to 10.3.2.253:10000-10200 (UDP)
  
- [ ] **Testes:**
  - [ ] nslookup belavista.magnussystem.com.br → 10.3.2.253
  - [ ] Ping 10.3.2.253 funciona
  - [ ] Porta 5060 aberta (nmap de fora da rede)

---

## 🎓 Scripts Prontos

### **Script Completo - Copiar e Colar no Terminal:**

```bash
# MAGNUS PBX - Configuração MikroTik
# Executar via SSH ou Terminal do RouterOS

# 1. Habilitar DNS remoto
/ip dns set allow-remote-requests=yes

# 2. Adicionar registros estáticos
/ip dns static add name=belavista.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=acme.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=techno.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=pbx.magnussystem.com.br address=10.3.2.253 ttl=5m
/ip dns static add name=pbx-api.magnussystem.com.br address=10.3.2.253 ttl=5m

# 3. Limpar cache
/ip dns cache flush

# 4. Port Forwarding (ajuste ether1 para sua interface WAN)
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5060 protocol=udp dst-port=5060 in-interface=ether1 comment="Asterisk SIP UDP"
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5060 protocol=tcp dst-port=5060 in-interface=ether1 comment="Asterisk SIP TCP"
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=5061 protocol=tcp dst-port=5061 in-interface=ether1 comment="Asterisk SIP TLS"
/ip firewall nat add chain=dstnat action=dst-nat to-addresses=10.3.2.253 \
    to-ports=10000-10200 protocol=udp dst-port=10000-10200 in-interface=ether1 comment="Asterisk RTP"

# 5. Firewall rules (adicionar ANTES de regras drop)
/ip firewall filter add chain=forward action=accept protocol=udp dst-address=10.3.2.253 \
    dst-port=5060 place-before=0 comment="Asterisk SIP UDP"
/ip firewall filter add chain=forward action=accept protocol=tcp dst-address=10.3.2.253 \
    dst-port=5060,5061 place-before=1 comment="Asterisk SIP TCP/TLS"
/ip firewall filter add chain=forward action=accept protocol=udp dst-address=10.3.2.253 \
    dst-port=10000-10200 place-before=2 comment="Asterisk RTP"

# 6. Verificar
/ip dns static print
/ip firewall nat print where chain=dstnat
/ip firewall filter print where chain=forward

# PRONTO! Testar:
# /ping belavista.magnussystem.com.br
```

---

## 🔍 Troubleshooting MikroTik

### **Problema: DNS não resolve**

```bash
# Verificar se allow remote requests está habilitado
/ip dns print

# Ver se registro existe
/ip dns static print

# Limpar cache
/ip dns cache flush

# Testar do próprio MikroTik
/tool resolve name=belavista.magnussystem.com.br
```

### **Problema: Clientes não usam DNS do MikroTik**

```bash
# Verificar DHCP network
/ip dhcp-server network print

# Forçar renovação de IP nos clientes
# Windows: ipconfig /renew
# Linux: dhclient -r && dhclient
```

### **Problema: Port forward não funciona**

```bash
# Ver hits nas regras NAT
/ip firewall nat print stats

# Ver conexões ativas
/ip firewall connection print where dst-address~"10.3.2.253"

# Testar de fora (usar 4G)
# nmap -p 5060 SEU_IP_PUBLICO
```

---

## 📚 Documentação Oficial

- [MikroTik DNS Static](https://help.mikrotik.com/docs/display/ROS/DNS)
- [MikroTik NAT](https://help.mikrotik.com/docs/display/ROS/NAT)
- [MikroTik Firewall](https://help.mikrotik.com/docs/display/ROS/Firewall)

---

**Configuração MikroTik → Muito mais simples que dnsmasq!** ✅
