# 🚀 Próximos Passos - Reset do Banco de Dados

## ✅ O que foi feito (no Windows)

1. ✅ Estrutura SQL reorganizada
   - `01_init_schema.sql` - Schema completo (CDR moderna)
   - `02_sample_data.sql` - Dados de exemplo
   - Arquivos antigos movidos para `99_deprecated/`

2. ✅ Script de reset criado
   - `scripts/reset-database.sh` - Automatiza todo o processo

3. ✅ Documentação atualizada
   - [DATABASE_RESET.md](./DATABASE_RESET.md) - Guia completo
   - [CDR_DEPLOY.md](./CDR_DEPLOY.md) - Deploy do CDR
   - [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL

4. ✅ Commitado e enviado para GitHub
   - Commit: `refactor: Reestruturar banco de dados com schema unificado`
   - Branch: `main`

## 🎯 Execute na VM

### 1. Atualizar código
```bash
cd /srv/magnus-pbx
git pull origin main
```

### 2. Resetar banco de dados
```bash
chmod +x scripts/reset-database.sh
./scripts/reset-database.sh
```

**O script vai:**
- 🛑 Parar containers
- 🗑️ Remover `postgres_data/` (APAGA DADOS!)
- 🚀 Recriar PostgreSQL
- ✅ Executar `01_init_schema.sql` e `02_sample_data.sql` automaticamente
- 📊 Mostrar estatísticas das tabelas criadas

### 3. Subir tudo
```bash
docker compose up -d
```

### 4. Verificar
```bash
# Ver ramais criados
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT id, context, allow FROM ps_endpoints;
"

# Ver estrutura CDR
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    \d cdr
"

# Ver CDRs de exemplo
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT * FROM cdr_readable ORDER BY \"Data/Hora\" DESC LIMIT 5;
"
```

### 5. Testar CDR
```bash
# 1. Configurar softphone:
#    - Servidor: IP_DA_VM:5060
#    - Usuário: 1001
#    - Senha: magnus123
#    - Contexto: belavista

# 2. Ligar para *43 (echo test)

# 3. Verificar se gravou CDR
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT calldate, src, dst, duration, disposition 
    FROM cdr 
    WHERE src = '1001' 
    ORDER BY calldate DESC 
    LIMIT 5;
"
```

## 🎁 Ramais Pré-Configurados

| Ramal | Tenant | Senha | Tipo | Contexto |
|-------|--------|-------|------|----------|
| **1001** | belavista | magnus123 | WebRTC | ctx-belavista |
| **1002** | belavista | magnus123 | SIP | ctx-belavista |
| **2001** | acme | acme2001 | SIP | ctx-acme |
| **3001** | techno | techno3001 | WebRTC | ctx-techno |

### Teste Rápido

**Configure 2 softphones** (1001 e 1002) e teste:

```
1001 → *43       ✅ Echo test
1001 → *97       ✅ Voicemail
1001 → 1002      ✅ Chamada interna
1002 → 1001      ✅ Chamada reversa
```

Todos os CDRs devem aparecer em:
```sql
SELECT * FROM cdr_readable ORDER BY "Data/Hora" DESC;
```

## 📊 Estrutura Nova vs Antiga

### ❌ Antes (Conflito)
```
sql/
├── init.sql                  ← CDR antiga (uniqueid PK)
├── 04_create_cdr_table.sql   ← CDR nova (id SERIAL PK)
└── teste_inicial.sql         ← Dados desatualizados
```
**Resultado:** Conflito de schemas, banco inconsistente

### ✅ Depois (Unificado)
```
sql/
├── 01_init_schema.sql        ← Schema completo (CDR moderna)
├── 02_sample_data.sql        ← Dados atualizados (3 tenants, 5 ramais)
├── 03_fix_and_validate.sql   ← Utilitários (não executa automaticamente)
└── 99_deprecated/            ← Arquivos antigos (referência)
```
**Resultado:** Schema limpo, CDR moderna do Asterisk 22

## 🔍 Diferenças na Tabela CDR

| Campo | Antes | Depois |
|-------|-------|--------|
| **PK** | `uniqueid VARCHAR(150) PRIMARY KEY` | `id BIGSERIAL PRIMARY KEY` |
| **Data** | `start`, `answer`, `end` (3 campos) | `calldate` (1 campo) |
| **Linked Calls** | ❌ Não suportado | ✅ `linkedid VARCHAR(150)` |
| **Sequence** | ❌ Não suportado | ✅ `sequence INTEGER` |
| **Peer Account** | ❌ Não suportado | ✅ `peeraccount VARCHAR(80)` |
| **Multi-tenant** | ✅ `tenant_id` | ✅ `tenant_id` |

## ✅ Checklist Final

- [ ] Código atualizado (`git pull`)
- [ ] Banco resetado (`reset-database.sh`)
- [ ] Containers rodando (`docker compose ps`)
- [ ] Tabela `cdr` com estrutura moderna verificada
- [ ] 5 ramais visíveis no banco
- [ ] CDRs de exemplo consultáveis
- [ ] Asterisk sem erros de CDR nos logs
- [ ] Teste *43 gravando CDR

## 📚 Documentação

- [DATABASE_RESET.md](./DATABASE_RESET.md) - Guia completo da reestruturação
- [CDR_DEPLOY.md](./CDR_DEPLOY.md) - Como configurar CDR PostgreSQL
- [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL úteis
- [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md) - Roadmap do projeto

---
Agora o banco está **limpo, organizado e com estrutura profissional**! 🎉
