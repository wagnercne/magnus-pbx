# 🏢 Configuração Multi-Tenant MAGNUS PBX

## 📋 Problema

Softphones padrão (Linphone, Zoiper, Microsip, etc.) interpretam `1002@belavista` como:
- **Username**: `1002`
- **Domain**: `belavista`

Quando registram, enviam apenas `username=1002` na autenticação SIP, ignorando o `@belavista`.

O Asterisk procura por endpoint `1002` mas só encontra `1002@belavista` ❌

---

## ✅ Soluções Disponíveis

### **Opção 1: Identificação por IP/Subnet** ⭐ RECOMENDADA

**Como funciona:**
1. Endpoint ID interno: `1002@belavista`
2. Auth username: `1002` (sem @tenant)
3. Tabela `ps_identify` mapeia IP de origem → endpoint
4. Asterisk identifica tenant automaticamente pelo IP

**Configuração:**

```sql
-- Mapear subnet inteira para tenant
INSERT INTO ps_identify (id, endpoint, match) VALUES
    ('id_belavista', '1001@belavista', '192.168.15.0/26');
    
-- OU mapear IP individual por ramal
INSERT INTO ps_identify (id, endpoint, match) VALUES
    ('id_1001', '1001@belavista', '192.168.15.100'),
    ('id_1002', '1002@belavista', '192.168.15.101');
```

**No softphone:**
```
Servidor: 192.168.15.253
Usuário: 1002
Senha: magnus123
```

**Vantagens:**
- ✅ Funciona com **qualquer softphone**
- ✅ Não precisa DNS
- ✅ Controle granular por IP/subnet
- ✅ Ideal para redes segregadas por tenant

**Desvantagens:**
- ⚠️ Requer IP fixo ou DHCP reservado por ramal
- ⚠️ Mais complexo para usuários móveis (IP dinâmico)

---

### **Opção 2: Domínios SIP Reais**

**Como funciona:**
1. Cada tenant tem subdomínio DNS: `belavista.magnus.com.br`
2. Endpoint ID: `1002` (sem @tenant)
3. Auth username: `1002`
4. Asterisk usa domínio SIP para identificar tenant

**Configuração DNS:**
```
belavista.magnus.com.br → 192.168.15.253
acme.magnus.com.br → 192.168.15.253
techno.magnus.com.br → 192.168.15.253
```

**No banco:**
```sql
-- ps_domain_aliases mapeia domínio → tenant
INSERT INTO ps_domain_aliases (id, domain) VALUES
    ('belavista', 'belavista.magnus.com.br');
    
-- Endpoint sem @tenant
INSERT INTO ps_endpoints (id, tenant_id, ...) VALUES
    ('1002', 1, ...);
```

**No softphone:**
```
Servidor: belavista.magnus.com.br
Usuário: 1002
Senha: magnus123
```

**Vantagens:**
- ✅ Funciona com IP dinâmico
- ✅ Mais elegante e profissional
- ✅ Fácil para usuários móveis
- ✅ Padrão da indústria (Vonage, Twilio, etc.)

**Desvantagens:**
- ⚠️ Requer DNS configurado
- ⚠️ Certificado SSL por domínio (para WSS)
- ⚠️ Endpoints precisam IDs únicos globalmente

---

### **Opção 3: Prefixo no Username** 

**Como funciona:**
1. Username codifica o tenant: `bv1002` (bv=belavista)
2. Endpoint ID: `bv1002`
3. Sem @, sem DNS, apenas prefixo

**No banco:**
```sql
INSERT INTO ps_auths (id, username, ...) VALUES
    ('bv1002', 'bv1002', ...);
    
INSERT INTO ps_endpoints (id, ...) VALUES
    ('bv1002', ...);
```

**No softphone:**
```
Servidor: 192.168.15.253
Usuário: bv1002
Senha: magnus123
```

**Vantagens:**
- ✅ Simples de implementar
- ✅ Sem DNS, sem mapeamento IP
- ✅ Funciona em qualquer rede

**Desvantagens:**
- ⚠️ Menos elegante (usuários decoram prefixos)
- ⚠️ Dificulta portabilidade entre tenants
- ⚠️ Limitado a poucos tenants (prefixos curtos)

---

## 🎯 Recomendação por Cenário

| Cenário | Solução Recomendada |
|---------|---------------------|
| **PBX para condomínios/empresas locais** | Opção 1 (IP) |
| **SaaS multi-tenant nacional** | Opção 2 (DNS) |
| **Deploy rápido/protótipo** | Opção 3 (Prefixo) |
| **Rede corporativa segregada** | Opção 1 (IP por VLAN) |
| **App mobile/trabalho remoto** | Opção 2 (DNS) |

---

## 📝 Configuração Atual do MAGNUS

O schema já está preparado para **Opção 1 (Identificação por IP)**:

- ✅ Tabela `ps_identify` criada
- ✅ `sorcery.conf` configurado para usar realtime identify
- ✅ `extconfig.conf` mapeia ps_identify → PostgreSQL
- ✅ Usernames em `ps_auths` são apenas número (`1002`)
- ✅ Endpoint IDs internos mantêm formato `1002@belavista`

**Para ativar:**

1. Insira registros em `ps_identify` mapeando seus IPs
2. Reinicie Asterisk: `docker restart asterisk-magnus`
3. Configure softphones com username sem @tenant

**Exemplo de ativação:**

```bash
# Na VM
docker exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
INSERT INTO ps_identify (id, endpoint, match) VALUES
    ('id_1001', '1001@belavista', '192.168.15.100'),
    ('id_1002', '1002@belavista', '192.168.15.101')
ON CONFLICT (id) DO NOTHING;
"

# Reload PJSIP
docker exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"

# Verificar
docker exec asterisk-magnus asterisk -rx "pjsip show identifies"
```

---

## 🔄 Migração para Opção 2 (DNS)

Se preferir usar domínios reais, consulte: `docs/DNS-SETUP.md`

---

## 📚 Referências

- [Asterisk PJSIP Identify](https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/Configuring-res_pjsip/PJSIP-Configuration-Sections-and-Relationships/#identify)
- [Multi-Tenant SIP Best Practices](https://www.voip-info.org/asterisk-multi-tenant/)
