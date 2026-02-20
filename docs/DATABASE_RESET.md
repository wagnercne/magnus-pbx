# 🔄 Reestruturação do Banco de Dados Magnus PBX

## 📋 Problema Identificado

O projeto tinha **conflito de estruturas CDR**:

### ❌ Estrutura Antiga (sql/init.sql)
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

### ❌ Estrutura Nova Conflitante (sql/04_create_cdr_table.sql)
```sql
CREATE TABLE IF NOT EXISTS cdr (
    id SERIAL PRIMARY KEY,              -- PK diferente!
    calldate TIMESTAMP,                 -- Campo diferente
    uniqueid VARCHAR(150),              -- Não é PK
    linkedid VARCHAR(150),              -- Novo campo
    -- 26 campos (estrutura Asterisk 22 moderna)
);
```

### ⚠️ Resultado
- **Asterisk não sabia qual estrutura usar**
- **Scripts SQL conflitantes na pasta `/docker-entrypoint-initdb.d`**
- **Banco ficava inconsistente**

## ✅ Solução: Estrutura Unificada

### 1. Arquitetura Nova

```
sql/
├── 01_init_schema.sql      ← Schema completo (tabela CDR moderna)
├── 02_sample_data.sql      ← Dados de exemplo (3 tenants, 5 ramais)
├── 03_fix_and_validate.sql ← Scripts utilitários (não executa auto)
└── 99_deprecated/          ← Arquivos antigos movidos aqui
```

### 2. Ordem de Execução

O PostgreSQL executa arquivos em **ordem alfabética** no `/docker-entrypoint-initdb.d`:

1. ✅ `01_init_schema.sql` → Cria todas as tabelas (incluindo CDR moderna)
2. ✅ `02_sample_data.sql` → Insere 3 tenants, 5 ramais, 5 CDRs de teste
3. ⏭️ `03_fix_and_validate.sql` → **NÃO executa** (mantenha como utilitário)

### 3. Tabela CDR Final (Asterisk 22 Moderna)

```sql
CREATE TABLE cdr (
    id BIGSERIAL PRIMARY KEY,           -- ✅ Chave primária autoincremental
    calldate TIMESTAMP,                 -- ✅ Data/hora da chamada
    src VARCHAR(80),                    -- ✅ Origem
    dst VARCHAR(80),                    -- ✅ Destino
    duration INTEGER,                   -- ✅ Duração total
    billsec INTEGER,                    -- ✅ Duração tarifável
    disposition VARCHAR(45),            -- ✅ Status (ANSWERED, NO ANSWER, BUSY)
    uniqueid VARCHAR(150),              -- ✅ ID único da chamada
    linkedid VARCHAR(150),              -- ✅ ID de chamadas relacionadas (NEW!)
    sequence INTEGER,                   -- ✅ Sequência (NEW!)
    peeraccount VARCHAR(80),            -- ✅ Conta do ramal chamado (NEW!)
    tenant_id INT,                      -- ✅ Multi-tenant (Magnus custom)
    -- ... 20 campos totais
);
```

### 4. Compatibilidade

**Mantém compatibilidade com:**
- ✅ Asterisk 22.8.2 (cdr_pgsql.so)
- ✅ Multi-tenant (tenant_id)
- ✅ Campos legados (src, dst, duration, billsec)
- ✅ Campos modernos (linkedid, sequence, peeraccount)

## 🚀 Como Resetar o Banco

### Opção 1: Script Automatizado (Recomendado)
```bash
cd /srv/magnus-pbx
git pull origin main
chmod +x scripts/reset-database.sh
./scripts/reset-database.sh
```

**O script faz:**
1. 🛑 Para containers
2. 🗑️ Remove `postgres_data/`
3. 🚀 Recria container PostgreSQL
4. ⏳ Aguarda banco ficar pronto
5. ✅ Executa `01_init_schema.sql` e `02_sample_data.sql` automaticamente

### Opção 2: Manual
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

## 📊 Após o Reset

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

## 🎯 Caminhos de CDR no Asterisk

### cdr_pgsql.conf (já configurado)
```ini
[global]
hostname=postgres-magnus
port=5432
dbname=magnus_pbx
user=admin_magnus
password=magnus123
table=cdr        ← ✅ Usa a tabela nova!
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
| **linkedid**  | linkedid         | VARCHAR(150) ✨ |
| **sequence**  | sequence         | INTEGER ✨ |

## 📝 Diferenças Principais

### Antes (Estrutura Antiga)
- ❌ `uniqueid` era PRIMARY KEY (não permitia registros duplicados)
- ❌ Campos `start`, `answer`, `end` separados
- ❌ Sem suporte a `linkedid` (chamadas relacionadas)
- ❌ Sem `sequence` (ordem de eventos)

### Depois (Estrutura Nova)
- ✅ `id BIGSERIAL` é PRIMARY KEY (permite múltiplos registros da mesma chamada)
- ✅ Campo único `calldate` ao invés de 3 campos
- ✅ Suporte a `linkedid` (rastreia transferências, conferências)
- ✅ Suporte a `sequence` (ordem cronológica de eventos CDR)
- ✅ Campo `peeraccount` (identifica conta do outro lado)
- ✅ Multi-tenant (`tenant_id`)

## 🔍 Troubleshooting

### Erro: "relation cdr already exists"
```bash
# Significa que o banco não foi resetado
sudo rm -rf postgres_data
docker compose up -d postgres-magnus
```

### Arquivos SQL não executam
```bash
# Verificar montagem do volume
docker compose exec postgres-magnus ls -la /docker-entrypoint-initdb.d

# Deve mostrar:
# 01_init_schema.sql
# 02_sample_data.sql
# 03_fix_and_validate.sql
```

### CDR não está gravando
```bash
# 1. Verificar módulo carregado
docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"

# 2. Verificar conexão
docker compose exec asterisk-magnus asterisk -rx "cdr status"

# 3. Ver logs
docker compose logs asterisk-magnus | grep -i cdr
```

## 📚 Arquivos Relacionados

- [scripts/reset-database.sh](../scripts/reset-database.sh) - Script de reset automatizado
- [sql/01_init_schema.sql](../sql/01_init_schema.sql) - Schema completo
- [sql/02_sample_data.sql](../sql/02_sample_data.sql) - Dados de exemplo
- [asterisk_etc/cdr_pgsql.conf](../asterisk_etc/cdr_pgsql.conf) - Configuração CDR PostgreSQL
- [doc/CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL úteis
- [doc/CDR_DEPLOY.md](./CDR_DEPLOY.md) - Guia de implantação

## ✅ Checklist Pós-Reset

- [ ] Banco de dados resetado com sucesso
- [ ] Tabela `cdr` com estrutura moderna verificada
- [ ] 5 ramais de teste visíveis no banco
- [ ] CDRs de exemplo consultáveis
- [ ] Asterisk conectado ao banco (sem erros no log)
- [ ] Módulo `cdr_pgsql.so` carregado
- [ ] Teste *43 gravando CDR corretamente
- [ ] View `cdr_readable` funcionando

Agora o banco está **limpo, organizado e com estrutura moderna**! 🎉
