# ðŸ”„ ReestruturaÃ§Ã£o do Banco de Dados Magnus PBX

## ðŸ“‹ Problema Identificado

O projeto tinha **conflito de estruturas CDR**:

### âŒ Estrutura Antiga (sql/init.sql)
```sql
CREATE TABLE cdr (
    uniqueid VARCHAR(150) PRIMARY KEY,  -- PK no uniqueid
    accountcode VARCHAR(20),
    src VARCHAR(80),
    dst VARCHAR(80),
    start TIMESTAMP,
    answer TIMESTAMP,
    "end" TIMESTAMP,
    -- 18 campos (estrutura Asterisk antiga)
);
```

### âŒ Estrutura Nova Conflitante (sql/04_create_cdr_table.sql)
```sql
CREATE TABLE IF NOT EXISTS cdr (
    id SERIAL PRIMARY KEY,              -- PK diferente!
    calldate TIMESTAMP,                 -- Campo diferente
    uniqueid VARCHAR(150),              -- NÃ£o Ã© PK
    linkedid VARCHAR(150),              -- Novo campo
    -- 26 campos (estrutura Asterisk 22 moderna)
);
```

### âš ï¸ Resultado
- **Asterisk nÃ£o sabia qual estrutura usar**
- **Scripts SQL conflitantes na pasta `/docker-entrypoint-initdb.d`**
- **Banco ficava inconsistente**

## âœ… SoluÃ§Ã£o: Estrutura Unificada

### 1. Arquitetura Nova

```
sql/
â”œâ”€â”€ 01_init_schema.sql      â† Schema completo (tabela CDR moderna)
â”œâ”€â”€ 02_sample_data.sql      â† Dados de exemplo (3 tenants, 5 ramais)
â”œâ”€â”€ 03_fix_and_validate.sql â† Scripts utilitÃ¡rios (nÃ£o executa auto)
â””â”€â”€ 99_deprecated/          â† Arquivos antigos movidos aqui
```

### 2. Ordem de ExecuÃ§Ã£o

O PostgreSQL executa arquivos em **ordem alfabÃ©tica** no `/docker-entrypoint-initdb.d`:

1. âœ… `01_init_schema.sql` â†’ Cria todas as tabelas (incluindo CDR moderna)
2. âœ… `02_sample_data.sql` â†’ Insere 3 tenants, 5 ramais, 5 CDRs de teste
3. â­ï¸ `03_fix_and_validate.sql` â†’ **NÃƒO executa** (mantenha como utilitÃ¡rio)

### 3. Tabela CDR Final (Asterisk 22 Moderna)

```sql
CREATE TABLE cdr (
    id BIGSERIAL PRIMARY KEY,           -- âœ… Chave primÃ¡ria autoincremental
    calldate TIMESTAMP,                 -- âœ… Data/hora da chamada
    src VARCHAR(80),                    -- âœ… Origem
    dst VARCHAR(80),                    -- âœ… Destino
    duration INTEGER,                   -- âœ… DuraÃ§Ã£o total
    billsec INTEGER,                    -- âœ… DuraÃ§Ã£o tarifÃ¡vel
    disposition VARCHAR(45),            -- âœ… Status (ANSWERED, NO ANSWER, BUSY)
    uniqueid VARCHAR(150),              -- âœ… ID Ãºnico da chamada
    linkedid VARCHAR(150),              -- âœ… ID de chamadas relacionadas (NEW!)
    sequence INTEGER,                   -- âœ… SequÃªncia (NEW!)
    peeraccount VARCHAR(80),            -- âœ… Conta do ramal chamado (NEW!)
    tenant_id INT,                      -- âœ… Multi-tenant (Magnus custom)
    -- ... 20 campos totais
);
```

### 4. Compatibilidade

**MantÃ©m compatibilidade com:**
- âœ… Asterisk 22.8.2 (cdr_pgsql.so)
- âœ… Multi-tenant (tenant_id)
- âœ… Campos legados (src, dst, duration, billsec)
- âœ… Campos modernos (linkedid, sequence, peeraccount)

## ðŸš€ Como Resetar o Banco

### OpÃ§Ã£o 1: Script Automatizado (Recomendado)
```bash
cd /srv/magnus-pbx
git pull origin main
chmod +x scripts/reset-database.sh
./scripts/reset-database.sh
```

**O script faz:**
1. ðŸ›‘ Para containers
2. ðŸ—‘ï¸ Remove `postgres_data/`
3. ðŸš€ Recria container PostgreSQL
4. â³ Aguarda banco ficar pronto
5. âœ… Executa `01_init_schema.sql` e `02_sample_data.sql` automaticamente

### OpÃ§Ã£o 2: Manual
```bash
# 1. Parar tudo
docker compose down

# 2. Remover volume
sudo rm -rf postgres_data
mkdir postgres_data

# 3. Subir PostgreSQL (executa SQLs automaticamente)
docker compose up -d postgres-magnus

# 4. Aguardar ~10 segundos
sleep 10

# 5. Verificar tabelas criadas
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\dt"

# 6. Ver ramais de exemplo
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, context FROM ps_endpoints;"
```

## ðŸ“Š ApÃ³s o Reset

### 1. Verificar Estrutura
```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\d cdr"
```

**Deve mostrar:**
```
Column      | Type                     | Collation | Nullable | Default
----------------+--------------------------+-----------+----------+---------------------------
id              | bigint                   |           | not null | nextval('cdr_id_seq'::regclass)
calldate        | timestamp without time zone |           |          | now()
src             | character varying(80)    |           |          |
dst             | character varying(80)    |           |          |
...
linkedid        | character varying(150)   |           |          |
sequence        | integer                  |           |          |
tenant_id       | integer                  |           |          |
```

### 2. Ver Ramais de Teste
```sql
SELECT 
    id,
    context,
    transport,
    allow
FROM ps_endpoints;
```

**Deve retornar:**
```
     id           |    context    |  transport    |      allow
------------------+---------------+---------------+------------------
1001@belavista    | ctx-belavista | transport-wss | opus,g722,ulaw
1002@belavista    | ctx-belavista | transport-udp | ulaw,alaw,gsm
2001@acme         | ctx-acme      | transport-udp | ulaw,alaw
3001@techno       | ctx-techno    | transport-wss | opus,vp8
```

### 3. Ver CDRs de Exemplo
```sql
SELECT * FROM cdr_readable ORDER BY "Data/Hora" DESC LIMIT 5;
```

## ðŸŽ¯ Caminhos de CDR no Asterisk

### cdr_pgsql.conf (jÃ¡ configurado)
```ini
[global]
hostname=postgres-magnus
port=5432
dbname=magnus_pbx
user=admin_magnus
password=magnus123
table=cdr        â† âœ… Usa a tabela nova!
encoding=utf8
```

### Mapeamento de Campos

| Asterisk      | Banco PostgreSQL | Tipo    |
|---------------|------------------|---------|
| calldate      | calldate         | TIMESTAMP |
| src           | src              | VARCHAR(80) |
| dst           | dst              | VARCHAR(80) |
| duration      | duration         | INTEGER |
| billsec       | billsec          | INTEGER |
| disposition   | disposition      | VARCHAR(45) |
| uniqueid      | uniqueid         | VARCHAR(150) |
| **linkedid**  | linkedid         | VARCHAR(150) âœ¨ |
| **sequence**  | sequence         | INTEGER âœ¨ |

## ðŸ“ DiferenÃ§as Principais

### Antes (Estrutura Antiga)
- âŒ `uniqueid` era PRIMARY KEY (nÃ£o permitia registros duplicados)
- âŒ Campos `start`, `answer`, `end` separados
- âŒ Sem suporte a `linkedid` (chamadas relacionadas)
- âŒ Sem `sequence` (ordem de eventos)

### Depois (Estrutura Nova)
- âœ… `id BIGSERIAL` Ã© PRIMARY KEY (permite mÃºltiplos registros da mesma chamada)
- âœ… Campo Ãºnico `calldate` ao invÃ©s de 3 campos
- âœ… Suporte a `linkedid` (rastreia transferÃªncias, conferÃªncias)
- âœ… Suporte a `sequence` (ordem cronolÃ³gica de eventos CDR)
- âœ… Campo `peeraccount` (identifica conta do outro lado)
- âœ… Multi-tenant (`tenant_id`)

## ðŸ” Troubleshooting

### Erro: "relation cdr already exists"
```bash
# Significa que o banco nÃ£o foi resetado
sudo rm -rf postgres_data
docker compose up -d postgres-magnus
```

### Arquivos SQL nÃ£o executam
```bash
# Verificar montagem do volume
docker compose exec postgres-magnus ls -la /docker-entrypoint-initdb.d

# Deve mostrar:
# 01_init_schema.sql
# 02_sample_data.sql
# 03_fix_and_validate.sql
```

### CDR nÃ£o estÃ¡ gravando
```bash
# 1. Verificar mÃ³dulo carregado
docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"

# 2. Verificar conexÃ£o
docker compose exec asterisk-magnus asterisk -rx "cdr status"

# 3. Ver logs
docker compose logs asterisk-magnus | grep -i cdr
```

## ðŸ“š Arquivos Relacionados

- [scripts/reset-database.sh](../scripts/reset-database.sh) - Script de reset automatizado
- [sql/01_init_schema.sql](../sql/01_init_schema.sql) - Schema completo
- [sql/02_sample_data.sql](../sql/02_sample_data.sql) - Dados de exemplo
- [asterisk_etc/cdr_pgsql.conf](../asterisk_etc/cdr_pgsql.conf) - ConfiguraÃ§Ã£o CDR PostgreSQL
- [docs/CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL Ãºteis
- [docs/CDR_DEPLOY.md](./CDR_DEPLOY.md) - Guia de implantaÃ§Ã£o

## âœ… Checklist PÃ³s-Reset

- [ ] Banco de dados resetado com sucesso
- [ ] Tabela `cdr` com estrutura moderna verificada
- [ ] 5 ramais de teste visÃ­veis no banco
- [ ] CDRs de exemplo consultÃ¡veis
- [ ] Asterisk conectado ao banco (sem erros no log)
- [ ] MÃ³dulo `cdr_pgsql.so` carregado
- [ ] Teste *43 gravando CDR corretamente
- [ ] View `cdr_readable` funcionando

Agora o banco estÃ¡ **limpo, organizado e com estrutura moderna**! ðŸŽ‰

