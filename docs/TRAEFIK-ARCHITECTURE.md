# 🌐 Traefik + Asterisk: Arquitetura SaaS

## ⚠️ Importante: Traefik NÃO Serve para SIP UDP

**Traefik:**
- ✅ Reverse proxy HTTP/HTTPS (porta 80/443)
- ✅ Certificados SSL automáticos
- ✅ Load balancing HTTP
- ❌ **NÃO suporta SIP UDP/TCP** (porta 5060)
- ❌ Não é servidor DNS

**Asterisk SIP:**
- Protocolo: UDP/TCP (porta 5060/5061)
- **NÃO passa por reverse proxy**
- Comunicação direta com clientes

---

## 🏗️ Arquitetura Híbrida Recomendada

```
                           INTERNET
                              │
               ┌──────────────┼──────────────┐
               │              │              │
               │              │              │
            DNS (53)      HTTPS (443)    SIP (5060)
       Cloudflare/Route53   Traefik      Porta aberta
               │              │              │
               ▼              ▼              ▼
        Resolve domínios   WebRTC/WSS   SIP Hardphones
        multi-tenant      Web Dashboard  UDP direto
                              │              │
                              └──────┬───────┘
                                     ▼
                              ┌──────────────┐
                              │   Asterisk   │
                              │   Container  │
                              └──────────────┘
                                     │
                              ┌──────▼───────┐
                              │  PostgreSQL  │
                              └──────────────┘
```

---

## 🎯 Quando Usar Traefik com Asterisk

### **Use Case 1: WebRTC (WSS)** ⭐

WebRTC precisa **HTTPS/WSS** (porta 443). Traefik gerencia SSL:

```yaml
# docker-compose.yml
services:
  traefik:
    image: traefik:v2.10
    command:
      - --providers.docker=true
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.email=admin@magnus.com.br
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
    ports:
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt
    networks:
      - magnus

  asterisk:
    image: wagnercne/magnus-pbx:optimized
    labels:
      # WebRTC via Traefik (WSS)
      - "traefik.enable=true"
      - "traefik.http.routers.asterisk-wss.rule=Host(`belavista.magnus.com.br`) && PathPrefix(`/ws`)"
      - "traefik.http.routers.asterisk-wss.entrypoints=websecure"
      - "traefik.http.routers.asterisk-wss.tls.certresolver=letsencrypt"
      - "traefik.http.services.asterisk-wss.loadbalancer.server.port=8089"
      
      # Multi-tenant: outros domínios
      - "traefik.http.routers.asterisk-wss-acme.rule=Host(`acme.magnus.com.br`) && PathPrefix(`/ws`)"
      - "traefik.http.routers.asterisk-wss-techno.rule=Host(`techno.magnus.com.br`) && PathPrefix(`/ws`)"
    ports:
      # SIP UDP - DIRETO (não passa por Traefik)
      - "5060:5060/udp"
      - "5060:5060/tcp"
      # SIP TLS - DIRETO
      - "5061:5061/tcp"
      # RTP - DIRETO
      - "10000-10200:10000-10200/udp"
    networks:
      - magnus
```

**Fluxo WebRTC:**
```
Browser/App → HTTPS (443) → Traefik → WSS (8089) → Asterisk
              └─ SSL/TLS ─┘          └─ Interno ─┘
              Domínio multi-tenant
```

**Fluxo SIP Tradicional:**
```
Softphone → UDP (5060) → Asterisk
            └─ Direto ─┘
            Sem Traefik
```

---

### **Use Case 2: Web Dashboard Multi-Tenant**

```yaml
services:
  dashboard:
    image: magnus-web-dashboard:latest
    labels:
      - "traefik.enable=true"
      # Dashboard Belavista
      - "traefik.http.routers.dash-bv.rule=Host(`belavista.magnus.com.br`)"
      - "traefik.http.routers.dash-bv.tls.certresolver=letsencrypt"
      # Dashboard ACME
      - "traefik.http.routers.dash-acme.rule=Host(`acme.magnus.com.br`)"
      # Middleware: identificar tenant pelo domínio
      - "traefik.http.middlewares.tenant-header.headers.customrequestheaders.X-Tenant-Domain=belavista"
```

---

### **Use Case 3: API Multi-Tenant**

```yaml
services:
  api:
    image: magnus-api:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.magnus.com.br`)"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      # Rate limiting por tenant
      - "traefik.http.middlewares.rate-limit.ratelimit.average=100"
```

---

## 🚫 Quando NÃO Usar Traefik

### **❌ SIP UDP/TCP (porta 5060/5061)**

```yaml
# ERRADO: SIP não funciona com Traefik
services:
  asterisk:
    labels:
      - "traefik.tcp.routers.sip.rule=HostSNI(`*`)"  # ❌ NÃO FUNCIONA
      - "traefik.tcp.routers.sip.entrypoints=sip"
```

**Por quê não funciona?**
- SIP usa UDP (Traefik é TCP/HTTP)
- SIP tem lógica complexa (SDP, NAT traversal)
- Asterisk precisa ver IP real do cliente
- Latência adicional quebra RTP (áudio/vídeo)

**Solução: Expor porta SIP diretamente**

```yaml
services:
  asterisk:
    ports:
      - "5060:5060/udp"  # ✅ Exposição direta
      - "5060:5060/tcp"
      # Traefik NÃO envolvidoCódigo
```

---

## 🔧 Configuração Completa: Produção SaaS

### **1. DNS (Cloudflare/Route53)**

```
# Registros A
belavista.magnus.com.br  → 203.0.113.10 (IP público)
acme.magnus.com.br       → 203.0.113.10
techno.magnus.com.br     → 203.0.113.10
*.magnus.com.br          → 203.0.113.10 (wildcard)

# SRV Records (opcional, para auto-discovery)
_sip._udp.belavista.magnus.com.br → belavista.magnus.com.br:5060
_sip._tcp.belavista.magnus.com.br → belavista.magnus.com.br:5061
```

### **2. Docker Compose Completo**

```yaml
version: '3.8'

networks:
  magnus:
    driver: bridge

services:
  # Traefik: Apenas HTTP/HTTPS
  traefik:
    image: traefik:v2.10
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.email=admin@magnus.com.br
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - magnus
    restart: unless-stopped

  # Asterisk: SIP direto + WSS via Traefik
  asterisk:
    image: wagnercne/magnus-pbx:optimized
    hostname: asterisk-magnus
    labels:
      # WebRTC WSS via Traefik
      - "traefik.enable=true"
      - "traefik.http.routers.wss.rule=(Host(`belavista.magnus.com.br`) || Host(`acme.magnus.com.br`) || Host(`techno.magnus.com.br`)) && PathPrefix(`/ws`)"
      - "traefik.http.routers.wss.entrypoints=websecure"
      - "traefik.http.routers.wss.tls.certresolver=letsencrypt"
      - "traefik.http.services.wss.loadbalancer.server.port=8089"
    ports:
      # SIP - Direto (SEM Traefik)
      - "5060:5060/udp"
      - "5060:5060/tcp"
      - "5061:5061/tcp"
      # RTP - Direto
      - "10000-10200:10000-10200/udp"
    environment:
      - POSTGRES_HOST=postgres-magnus
      - POSTGRES_DB=magnus_pbx
      - POSTGRES_USER=admin_magnus
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./asterisk_etc:/etc/asterisk
      - asterisk_logs:/var/log/asterisk
    networks:
      - magnus
    depends_on:
      - postgres
    restart: unless-stopped

  # PostgreSQL
  postgres:
    image: postgres:17-alpine
    hostname: postgres-magnus
    environment:
      - POSTGRES_DB=magnus_pbx
      - POSTGRES_USER=admin_magnus
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./sql:/docker-entrypoint-initdb.d
      - postgres_data:/var/lib/postgresql/data
    networks:
      - magnus
    restart: unless-stopped

volumes:
  postgres_data:
  asterisk_logs:
  letsencrypt:
```

### **3. Firewall (UFW/iptables)**

```bash
# HTTP/HTTPS (Traefik)
ufw allow 80/tcp
ufw allow 443/tcp

# SIP UDP/TCP (Asterisk direto)
ufw allow 5060/udp
ufw allow 5060/tcp
ufw allow 5061/tcp

# RTP (Áudio/Vídeo)
ufw allow 10000:10200/udp

# Não abrir: 8089 (WSS interno, via Traefik apenas)
```

---

## 📊 Comparação: Com vs Sem Traefik

### **Rede Local (Sem Internet)**

| Componente | Com Traefik | Sem Traefik |
|------------|-------------|-------------|
| DNS | dnsmasq/Bind | - |
| SIP | Direto | Direto |
| WebRTC | Via Traefik WSS | HTTP simples |
| SSL | Let's Encrypt | Auto-assinado |
| **Recomendação** | ❌ Desnecessário | ✅ **Mais simples** |

**Para rede local: NÃO use Traefik**

### **SaaS Público (Internet)**

| Componente | Com Traefik | Sem Traefik |
|------------|-------------|-------------|
| DNS | Cloudflare | Cloudflare |
| SIP | Direto | Direto |
| WebRTC | Via Traefik WSS | Nginx manual |
| SSL | Automático | Manual |
| Multi-tenant | SNI routing | Config manual |
| **Recomendação** | ✅ **Profissional** | ⚠️ Mais trabalho |

**Para SaaS: USE Traefik (apenas para WSS/HTTPS)**

---

## 🎯 Resumo: Quando Usar Cada Ferramenta

| Ferramenta | Função | Usado Para |
|------------|--------|------------|
| **DNS** (dnsmasq/Bind/Cloudflare) | Resolver nomes | Todos os cenários |
| **Traefik** | Reverse proxy HTTPS | WebRTC (WSS), Dashboard, API |
| **Asterisk Direto** | SIP UDP/TCP | Softphones SIP |
| **Firewall** | Controle de acesso | Segurança |

---

## ✅ Recomendação para Seu Caso

**Ambiente Atual: Rede Local**

```
NÃO use Traefik ainda. Use:
1. dnsmasq no roteador/VM (DNS local)
2. Asterisk expondo portas direto
3. Certificados auto-assinados (ou sem SSL)
```

**Futuro: SaaS Público**

```
Evolua para:
1. Cloudflare (DNS público)
2. Traefik (WebRTC + Dashboard)
3. Asterisk (SIP direto)
4. Let's Encrypt (SSL automático)
```

---

## 📚 Referências

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [WebRTC + Asterisk](https://wiki.asterisk.org/wiki/display/AST/WebRTC+tutorial+using+SIPML5)
- [SIP NAT Traversal](https://www.voip-info.org/asterisk-sip-nat-solutions/)
