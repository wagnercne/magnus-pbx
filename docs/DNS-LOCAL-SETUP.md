# 🌐 Configuração DNS Local para Multi-Tenant

## 📋 Objetivo

Configurar DNS local para resolver domínios multi-tenant em rede privada:
- `belavista.magnus.local` → 192.168.15.253
- `acme.magnus.local` → 192.168.15.253
- `techno.magnus.local` → 192.168.15.253

Softphones usam domínios em vez de IP direto.

---

## ✅ Solução Recomendada: dnsmasq

### **Vantagens:**
- ✅ Simples e leve (10 linhas de config)
- ✅ DHCP + DNS integrado
- ✅ Já vem no OpenWrt, DD-WRT, pfSense
- ✅ Ideal para redes locais

---

## 🚀 Instalação no Ubuntu

### **Opção 1: dnsmasq no próprio host do Asterisk**

```bash
# Na VM 192.168.15.253
apt update
apt install dnsmasq -y

# Editar configuração
nano /etc/dnsmasq.conf
```

**Adicionar ao final:**

```conf
# Magnus PBX - Multi-tenant DNS
# =================================

# Porta DNS (padrão 53)
port=53

# Interface de rede
interface=eth0
bind-interfaces

# Domínios multi-tenant (todos apontam para este servidor)
address=/belavista.magnus.local/192.168.15.253
address=/acme.magnus.local/192.168.15.253
address=/techno.magnus.local/192.168.15.253

# Domínio wildcard (qualquer subdomínio .magnus.local)
address=/magnus.local/192.168.15.253

# DNS upstream (para resolver outros domínios)
server=8.8.8.8
server=8.8.4.4

# Cache
cache-size=1000
```

**Iniciar:**

```bash
systemctl restart dnsmasq
systemctl enable dnsmasq

# Verificar
systemctl status dnsmasq

# Testar resolução
dig belavista.magnus.local @192.168.15.253
nslookup belavista.magnus.local 192.168.15.253
```

---

### **Opção 2: dnsmasq no roteador** ⭐ MELHOR

Se seu roteador suporta (OpenWrt, DD-WRT, pfSense, UniFi):

**OpenWrt/DD-WRT:**
```bash
# SSH no roteador
ssh root@192.168.15.1

# Editar dnsmasq
echo "address=/magnus.local/192.168.15.253" >> /etc/dnsmasq.conf

# Restart
/etc/init.d/dnsmasq restart
```

**pfSense:**
- Services → DNS Resolver
- Host Overrides:
  - Host: belavista, Domain: magnus.local, IP: 192.168.15.253
  - Host: acme, Domain: magnus.local, IP: 192.168.15.253

**UniFi:**
- Settings → Networks → DNS
- Static DNS Entries

---

## 🔧 Configuração de Clientes

### **Windows:**
```powershell
# Configurar DNS para usar o servidor local
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("192.168.15.253","8.8.8.8")

# Testar
nslookup belavista.magnus.local
```

### **Linux/Mac:**
```bash
# Editar /etc/resolv.conf
nameserver 192.168.15.253
nameserver 8.8.8.8

# Testar
dig belavista.magnus.local
```

### **Android (Linphone):**
```
Configurações WiFi → Avançado
DNS 1: 192.168.15.253
DNS 2: 8.8.8.8
```

---

## 📱 Configuração Softphone

**Antes (com IP):**
```
Servidor: 192.168.15.253
Usuário: 1002@belavista
Senha: magnus123
```

**Depois (com DNS):**
```
Servidor: belavista.magnus.local
Usuário: 1002
Senha: magnus123
```

Asterisk identifica o tenant pelo domínio SIP no REGISTER.

---

## 🔍 Troubleshooting

### **Problema: DNS não resolve**

```bash
# Verificar se dnsmasq está escutando
netstat -tulpn | grep 53

# Ver logs
journalctl -u dnsmasq -f

# Testar diretamente
dig belavista.magnus.local @192.168.15.253
```

### **Problema: Firewall bloqueando**

```bash
# Liberar porta 53 UDP
ufw allow 53/udp
ufw allow 53/tcp
```

### **Problema: systemd-resolved conflitando**

```bash
# Desabilitar systemd-resolved
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Remover link simbólico
rm /etc/resolv.conf

# Criar novo resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Restart dnsmasq
systemctl restart dnsmasq
```

---

## ⚙️ Asterisk: Configurar ps_domain_aliases

No banco de dados:

```sql
-- Mapear domínios para tenants
INSERT INTO ps_domain_aliases (id, domain) VALUES
    ('belavista', 'belavista.magnus.local'),
    ('acme', 'acme.magnus.local'),
    ('techno', 'techno.magnus.local')
ON CONFLICT (id) DO NOTHING;
```

**Ativar no Asterisk:**

```bash
# extconfig.conf precisa ter:
ps_domain_aliases => pgsql,general

# sorcery.conf precisa ter:
[res_pjsip]
domain_alias=realtime,ps_domain_aliases
```

---

## 🎯 Vantagens desta Solução

✅ **Softphones usam domínio** (mais profissional)  
✅ **Multi-tenant transparente** (domínio identifica tenant)  
✅ **Sem mapeamento IP** (funciona com DHCP)  
✅ **Escalável** (adicione domínios sem reconfigurar clientes)  
✅ **Funciona offline** (DNS local, sem internet)

---

## 📊 Comparação: DNS vs Identificação por IP

| Critério | DNS | IP |
|----------|-----|-----|
| Setup | Médio | Simples |
| DHCP/IP dinâmico | ✅ Sim | ❌ Não |
| Profissional | ✅ Sim | ⚠️ Médio |
| Sem infraestrutura | ❌ Precisa DNS | ✅ Sim |
| Mobile/VPN | ✅ Funciona | ⚠️ Complexo |

---

## 🔮 Evolução para Produção

Para ambiente público (internet):

1. **Comprar domínio**: `magnus.com.br` no Registro.br
2. **DNS público**: Cloudflare (grátis) ou Route53
3. **Subdomínios**:
   - `belavista.magnus.com.br` → IP público
   - `acme.magnus.com.br` → IP público
4. **SSL/TLS**: Certificados Let's Encrypt
5. **Traefik**: Reverse proxy para WebRTC (WSS)
6. **Asterisk**: SIP UDP/TLS direto (sem proxy)

Ver: `docs/PRODUCTION-SETUP.md`

---

## 📚 Referências

- [dnsmasq man page](http://www.thekelleys.org.uk/dnsmasq/doc.html)
- [Asterisk Domain Aliases](https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/Configuring-res_pjsip/PJSIP-Configuration-Sections-and-Relationships/#domain_alias)
