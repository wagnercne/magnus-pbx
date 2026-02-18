# 📚 Índice de Documentação MAGNUS PBX

## 🚀 Início Rápido

1. **[README.md](../README.md)** - Visão geral do projeto
2. **Build e Deploy** - Como construir e rodar o sistema

---

## 🏢 Arquitetura Multi-Tenant

### **Problemas e Soluções**

**Problema:** Softphones enviam apenas `1002` (sem `@belavista`)

**Soluções disponíveis:**

- **[MULTI-TENANT-CONFIG.md](MULTI-TENANT-CONFIG.md)** 📘
  - Opção 1: Identificação por IP ⭐ Implementada
  - Opção 2: DNS com domínios reais
  - Opção 3: Prefixo no username
  - Comparação detalhada das 3 abordagens

---

## 🌐 Configuração de DNS

### **Cenário 1: Rede Local**
- **[DNS-LOCAL-SETUP.md](DNS-LOCAL-SETUP.md)** 📗
  - dnsmasq no roteador
  - Domínios `.local` (belavista.magnus.local)
  - Sem necessidade de internet
  - Ideal para: PBX privado, condomínios

### **Cenário 2: Internet Pública**
- Cloudflare / Route53
- Domínios reais (belavista.magnus.com.br)
- SSL/TLS com Let's Encrypt

### **Cenário 3: Híbrido (Local + Internet)** ⭐ RECOMENDADO
- **[HYBRID-ARCHITECTURE.md](HYBRID-ARCHITECTURE.md)** 📙
  - Split DNS (funciona com e sem internet)
  - Port forwarding / NAT
  - VPN para usuários remotos
  - Contingência quando internet cai
  - Ideal para: Empresas com funcionários remotos

---

## 🌍 Traefik e Reverse Proxy

- **[TRAEFIK-ARCHITECTURE.md](TRAEFIK-ARCHITECTURE.md)** 📕
  - ⚠️ Traefik **NÃO serve para SIP UDP**
  - ✅ Use Traefik para: WebRTC (WSS), Dashboard, API
  - ❌ NÃO use para: SIP UDP/TCP (porta 5060)
  - Arquitetura SaaS completa
  - Docker Compose com Traefik + Asterisk

---

## 🎯 Escolha Rápida: Qual Documentação Ler?

### **"Estou começando, rede local, sem internet"**
```
1. README.md
2. DNS-LOCAL-SETUP.md (dnsmasq)
3. MULTI-TENANT-CONFIG.md (Opção 1: IP)
```

### **"Tenho internet, quero funcionários remotos"**
```
1. README.md
2. HYBRID-ARCHITECTURE.md (Split DNS)
3. MULTI-TENANT-CONFIG.md (Opção 2: DNS)
```

### **"Quero fazer SaaS público na nuvem"**
```
1. README.md
2. TRAEFIK-ARCHITECTURE.md (WebRTC + SSL)
3. MULTI-TENANT-CONFIG.md (Opção 2: DNS)
4. HYBRID-ARCHITECTURE.md (VPN para admin)
```

### **"Estou com problemas de softphone não registrando"**
```
1. MULTI-TENANT-CONFIG.md (entender as opções)
2. Troubleshooting no final de cada doc
```

---

## 📊 Comparação Rápida

| Cenário | DNS | Multi-Tenant | Traefik | Docs |
|---------|-----|--------------|---------|------|
| **Rede Local Simples** | dnsmasq | IP | ❌ Não | DNS-LOCAL + MULTI-TENANT |
| **Escritório + Remotos** | Split DNS | DNS | ⚠️ WebRTC | HYBRID + MULTI-TENANT |
| **SaaS Público** | Cloudflare | DNS | ✅ Sim | TRAEFIK + MULTI-TENANT |
| **Matriz + Filiais** | VPN | IP/DNS | ❌ Não | HYBRID (VPN) |

---

## 🔧 Snippets Úteis

### **Descobrir IP Público**
```bash
curl ifconfig.me
curl icanhazip.com
```

### **Testar DNS**
```bash
# DNS local
nslookup belavista.magnus.local 192.168.15.1

# DNS público
nslookup belavista.magnus.com.br 8.8.8.8

# Ver qual DNS responde primeiro
dig belavista.magnus.com.br
```

### **Testar Porta Aberta (SIP)**
```bash
# De fora da rede
nmap -sU -p 5060 SEU_IP_PUBLICO

# Ver conexões SIP
docker exec asterisk-magnus asterisk -rx "pjsip show transports"
```

### **Ver Registros Ativos**
```bash
docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"
docker exec asterisk-magnus asterisk -rx "pjsip show contacts"
```

---

## 🆘 Troubleshooting Rápido

| Problema | Solução | Doc |
|----------|---------|-----|
| DNS não resolve | Verificar dnsmasq, limpar cache | DNS-LOCAL, HYBRID |
| Ramal não registra | Verificar username, identificação | MULTI-TENANT |
| Áudio não funciona | RTP ports, NAT config | HYBRID, TRAEFIK |
| Funciona local, não via internet | Port forward, firewall | HYBRID |
| Softphone envia só "1002" | Usar ps_identify ou DNS | MULTI-TENANT |

---

## 📖 Estrutura dos Documentos

Cada documento segue este padrão:

1. **📋 Problema/Objetivo** - O que resolve
2. **✅ Solução** - Como implementar
3. **🚀 Configuração Prática** - Passo a passo
4. **🔍 Troubleshooting** - Resolução de problemas
5. **📊 Comparação** - Quando usar cada opção
6. **📚 Referências** - Links externos

---

## 🎓 Ordem de Leitura Recomendada

### **Nível 1: Iniciante**
1. README.md (visão geral)
2. MULTI-TENANT-CONFIG.md (conceitos)
3. DNS-LOCAL-SETUP.md (setup básico)

### **Nível 2: Intermediário**
1. HYBRID-ARCHITECTURE.md (expansão)
2. Implementar Split DNS
3. Testar acesso remoto

### **Nível 3: Avançado**
1. TRAEFIK-ARCHITECTURE.md (SaaS)
2. WebRTC com SSL
3. Alta disponibilidade

---

## 🗺️ Roadmap de Implementação

```
Fase 1: Local          Fase 2: Híbrido        Fase 3: SaaS
  │                         │                       │
  ├─ dnsmasq               ├─ Split DNS            ├─ Cloudflare
  ├─ ps_identify           ├─ Port forward         ├─ Traefik
  └─ Teste local           ├─ NAT config           ├─ Let's Encrypt
                           └─ Teste internet       └─ Load balancer
```

---

## 📝 Como Contribuir

Encontrou erro ou quer melhorar a documentação?

1. Abra issue no GitHub
2. Descreva o problema/sugestão
3. PR com correções bem-vindos!

---

## 🔗 Links Externos Úteis

- [Asterisk Official Docs](https://docs.asterisk.org/)
- [PJSIP Configuration](https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/Configuring-res_pjsip/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [dnsmasq Manual](http://www.thekelleys.org.uk/dnsmasq/doc.html)

---

**Última atualização:** 18/02/2026  
**Versão dos docs:** 2.0  
**Asterisk:** 22.8.2  
**PostgreSQL:** 17-alpine
