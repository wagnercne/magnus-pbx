# 🚨 CORREÇÃO RÁPIDA - Magnus PBX

## ❌ Problema
```
Ramal 1001@belavista disca *43 → "extension not found"
```

## ✅ Causa
**Realtime NÃO faz pattern matching!**
- Asterisk busca `WHERE exten='*43'` (exato)
- Tabela tem `_*X.` (padrão) → NÃO combina!

## 🔧 Solução em 3 Passos

### 1️⃣ Corrigir Banco de Dados (2min)

```bash
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Executar
.\scripts\deploy.ps1   # Windows PowerShell
# ou
bash scripts/deploy.sh  # Linux/WSL
```

**OU manualmente:**
```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
UPDATE ps_endpoints 
SET context = 'ctx-' || split_part(id, '@', 2),
    transport = 'transport-udp'
WHERE id LIKE '%@%';
"
```

### 2️⃣ Reiniciar Asterisk (1min)

```bash
docker compose restart asterisk-magnus
```

### 3️⃣ Testar (1min)

```bash
# Verificar dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# Deve mostrar: '*43' => 1. NoOp(...)
```

---

## 📱 Softphone - Configuração Rápida

**Zoiper / Linphone / MicroSIP:**

| Campo | Valor |
|-------|-------|
| Username | `1001` |
| Password | *(ver banco)* |
| Domain | `belavista` |
| Server | `IP_DO_SERVIDOR:5060` |
| Transport | UDP |

**Consultar senha:**
```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
SELECT id, password FROM ps_auths WHERE id='1001@belavista';
"
```

---

## ✅ Teste de Validação

1. Registrar softphone
2. Discar: `*43`
3. Deve ouvir: **Beep + Eco**

**Se não funcionar:**
```bash
# Ver contexto do endpoint
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoint 1001@belavista"

# Deve mostrar: context: ctx-belavista
```

---

## 📊 O Que Foi Mudado

### ✅ extconfig.conf
```diff
[settings]
ps_endpoints => pgsql,general
ps_auths => pgsql,general
ps_aors => pgsql,general
- extensions => pgsql,general,extensions  ❌ REMOVIDO
```

### ✅ extensions.conf
```diff
- [tenant-router]
- exten => _X.,1,Goto(ctx-dynamic,${EXTEN},1)  ❌ ctx-dynamic não existe

+ [tenant-base](!)
+ exten => *43,1,Echo()  ✅ Pattern no arquivo
+ 
+ [ctx-belavista](tenant-base)  ✅ Contexto existe
```

### ✅ pjsip.conf
```diff
+ [transport-udp]  ✅ Transport compartilhado
+ type=transport
+ protocol=udp
+ bind=0.0.0.0:5060
```

---

## 🔍 Troubleshooting

| Problema | Solução |
|----------|---------|
| **401 Unauthorized** | Verificar senha no banco |
| **408 Timeout** | Firewall bloqueando porta 5060 |
| **extension not found** | Verificar contexto do endpoint → deve ser `ctx-{slug}` |
| **Endpoint Unavailable** | Verificar credenciais do softphone |

---

## 📚 Documentação Completa

| Arquivo | Descrição |
|---------|-----------|
| [README.md](README.md) | Visão geral do projeto |
| [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md) | Análise técnica profunda |
| [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md) | Testes passo a passo |
| [PGSQL_VS_ODBC.md](PGSQL_VS_ODBC.md) | Por que usar res_config_pgsql |
| [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md) | Setup de softphones |

---

## 🎯 Feature Codes Disponíveis

| Código | Função |
|--------|--------|
| **\*43** | Echo Test ✅ |
| **\*97** | VoiceMail Check ✅ |
| **\*98** | VoiceMail Any ✅ |
| **\*65** | Call Recording ✅ |
| **\*72XXXX** | Call Forward Enable ✅ |
| **\*73** | Call Forward Disable ✅ |
| **\*60XXX** | Conference Room ✅ |

---

## 🚀 Status

✅ **PRONTO PARA TESTES**

**Arquitetura:**
- Asterisk 22.8.2 + PostgreSQL 17
- res_config_pgsql (sem ODBC)
- Patterns estáticos no extensions.conf
- Dados dinâmicos no banco via AGI (futuro)

**Capacidade:**
- 1.000+ tenants
- Realtime PJSIP
- Isolamento completo por tenant

---

## 📞 Quick Commands

```bash
# Ver logs
docker compose logs -f asterisk-magnus

# CLI do Asterisk
docker compose exec asterisk-magnus asterisk -r

# Ver endpoints
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Ver dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# Recarregar dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan reload"

# Conectar no banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx
```

---

**Data:** 16/02/2026 | **Versão:** 1.0 | **Status:** ✅ Resolvido
