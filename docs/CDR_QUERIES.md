# 📊 Consultas CDR (Call Detail Records)

Guia de consultas SQL úteis para análise de chamadas.

---

## 🔍 Consultas Básicas

### Ver Últimas 10 Chamadas

```sql
SELECT * FROM cdr_readable LIMIT 10;
```

**OU formato completo:**

```sql
SELECT 
    id,
    calldate,
    src AS origem,
    dst AS destino,
    dcontext AS contexto,
    disposition AS status,
    duration AS duracao_total,
    billsec AS duracao_conversa
FROM cdr
ORDER BY calldate DESC
LIMIT 10;
```

### Ver Chamadas de Hoje

```sql
SELECT * FROM cdr_readable 
WHERE calldate::date = CURRENT_DATE;
```

### Ver Chamadas de um Ramal

```sql
SELECT * FROM cdr_readable 
WHERE src = '1001'
ORDER BY calldate DESC
LIMIT 20;
```

### Ver Chamadas Atendidas vs Não Atendidas

```sql
SELECT 
    disposition,
    COUNT(*) as total
FROM cdr
GROUP BY disposition;
```

---

## 📈 Relatórios

### Chamadas por Hora (Hoje)

```sql
SELECT 
    EXTRACT(HOUR FROM calldate) AS hora,
    COUNT(*) AS total_chamadas,
    COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) AS atendidas,
    COUNT(CASE WHEN disposition = 'NO ANSWER' THEN 1 END) AS nao_atendidas
FROM cdr
WHERE calldate::date = CURRENT_DATE
GROUP BY EXTRACT(HOUR FROM calldate)
ORDER BY hora;
```

### Top 10 Ramais Que Mais Ligam

```sql
SELECT 
    src AS ramal,
    COUNT(*) AS total_chamadas,
    SUM(duration) AS tempo_total_segundos,
    ROUND(AVG(duration), 2) AS media_duracao
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY src
ORDER BY total_chamadas DESC
LIMIT 10;
```

### Chamadas por Contexto (Tenant)

```sql
SELECT 
    dcontext AS contexto,
    COUNT(*) AS total_chamadas,
    COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) AS atendidas,
    COUNT(CASE WHEN disposition = 'NO ANSWER' THEN 1 END) AS perdidas,
    SUM(billsec) AS total_segundos_conversa
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY dcontext
ORDER BY total_chamadas DESC;
```

### Duração Média por Tipo de Chamada

```sql
SELECT 
    CASE 
        WHEN dst ~ '^[0-9]{3,4}$' THEN 'Interna'
        WHEN dst ~ '^\*' THEN 'Feature Code'
        ELSE 'Externa'
    END AS tipo_chamada,
    COUNT(*) AS total,
    ROUND(AVG(duration), 2) AS media_duracao,
    MAX(duration) AS max_duracao,
    MIN(duration) AS min_duracao
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY tipo_chamada;
```

---

## 🕐 Análise Temporal

### Chamadas por Dia da Semana

```sql
SELECT 
    TO_CHAR(calldate, 'Day') AS dia_semana,
    EXTRACT(DOW FROM calldate) AS dia_numero,
    COUNT(*) AS total_chamadas
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dia_semana, dia_numero
ORDER BY dia_numero;
```

### Horário de Pico

```sql
SELECT 
    EXTRACT(HOUR FROM calldate) AS hora,
    COUNT(*) AS total_chamadas
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY hora
ORDER BY total_chamadas DESC
LIMIT 5;
```

### Chamadas por Mês

```sql
SELECT 
    TO_CHAR(calldate, 'YYYY-MM') AS mes,
    COUNT(*) AS total_chamadas,
    SUM(billsec) AS total_segundos,
    ROUND(SUM(billsec)::numeric / 60, 2) AS total_minutos
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY mes
ORDER BY mes DESC;
```

---

## 🎯 Análise de Qualidade

### Taxa de Atendimento

```sql
SELECT 
    COUNT(*) AS total_chamadas,
    COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) AS atendidas,
    COUNT(CASE WHEN disposition = 'NO ANSWER' THEN 1 END) AS nao_atendidas,
    COUNT(CASE WHEN disposition = 'BUSY' THEN 1 END) AS ocupado,
    ROUND(
        100.0 * COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) / COUNT(*), 
        2
    ) AS taxa_atendimento_pct
FROM cdr
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days';
```

### Chamadas Curtas (< 10 segundos)

```sql
SELECT 
    calldate,
    src,
    dst,
    duration,
    disposition
FROM cdr
WHERE billsec < 10 
  AND disposition = 'ANSWERED'
  AND calldate >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY calldate DESC;
```

### Chamadas Longas (> 1 hora)

```sql
SELECT 
    calldate,
    src,
    dst,
    duration,
    ROUND(duration::numeric / 60, 2) AS minutos
FROM cdr
WHERE duration > 3600
ORDER BY duration DESC;
```

---

## 🔍 Busca Específica

### Buscar por ID Único

```sql
SELECT * FROM cdr 
WHERE uniqueid = '1234567890.123';
```

### Buscar Chamadas entre Dois Ramais

```sql
SELECT * FROM cdr_readable
WHERE (src = '1001' AND dst = '1002')
   OR (src = '1002' AND dst = '1001')
ORDER BY calldate DESC;
```

### Buscar por Período

```sql
SELECT * FROM cdr_readable
WHERE calldate BETWEEN '2026-02-01' AND '2026-02-28'
ORDER BY calldate DESC;
```

---

## 🗑️ Limpeza e Manutenção

### Deletar Chamadas Antigas (> 1 ano)

```sql
-- CUIDADO: Isso deleta permanentemente!
DELETE FROM cdr 
WHERE calldate < CURRENT_DATE - INTERVAL '1 year';
```

### Arquivar Chamadas Antigas

```sql
-- Criar tabela de arquivo
CREATE TABLE cdr_archive (LIKE cdr INCLUDING ALL);

-- Mover registros antigos
INSERT INTO cdr_archive
SELECT * FROM cdr 
WHERE calldate < CURRENT_DATE - INTERVAL '1 year';

-- Deletar da tabela principal
DELETE FROM cdr 
WHERE calldate < CURRENT_DATE - INTERVAL '1 year';
```

### Ver Tamanho da Tabela

```sql
SELECT 
    pg_size_pretty(pg_total_relation_size('cdr')) AS tamanho_total,
    pg_size_pretty(pg_relation_size('cdr')) AS tamanho_dados,
    pg_size_pretty(pg_indexes_size('cdr')) AS tamanho_indices;
```

---

## 💡 Dicas de Performance

### Criar Índice para Consultas Frequentes

```sql
-- Se você consulta muito por período + contexto
CREATE INDEX idx_cdr_period_context 
ON cdr(calldate, dcontext);

-- Se você consulta muito chamadas atendidas
CREATE INDEX idx_cdr_answered 
ON cdr(disposition) 
WHERE disposition = 'ANSWERED';
```

### Ver Índices Existentes

```sql
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'cdr';
```

---

## 🚀 Exportar Dados

### Exportar para CSV

```sql
COPY (
    SELECT * FROM cdr_readable 
    WHERE calldate >= CURRENT_DATE - INTERVAL '30 days'
) TO '/tmp/cdr_export.csv' WITH CSV HEADER;
```

**No Docker:**

```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
COPY (SELECT * FROM cdr_readable WHERE calldate >= CURRENT_DATE - INTERVAL '30 days') 
TO STDOUT WITH CSV HEADER
" > cdr_export.csv
```

---

## 📊 Dashboard Queries (Para Backend)

### Estatísticas do Dashboard

```sql
-- Total chamadas hoje
SELECT COUNT(*) FROM cdr WHERE calldate::date = CURRENT_DATE;

-- Chamadas ativas (via AMI, não CDR)
-- Ver documentação do backend

-- Top 5 ramais mais ativos (última semana)
SELECT src, COUNT(*) 
FROM cdr 
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY src 
ORDER BY COUNT(*) DESC 
LIMIT 5;

-- Taxa de atendimento (última semana)
SELECT 
    ROUND(100.0 * COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) / COUNT(*), 2) 
FROM cdr 
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days';
```

---

## 🔗 Comandos Úteis no Terminal

```bash
# Ver últimos 10 CDRs
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT * FROM cdr_readable LIMIT 10;"

# Contar chamadas de hoje
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT COUNT(*) FROM cdr WHERE calldate::date = CURRENT_DATE;"

# Ver chamadas do ramal 1001
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT * FROM cdr_readable WHERE src = '1001' LIMIT 20;"

# Taxa de atendimento
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) as atendidas,
    ROUND(100.0 * COUNT(CASE WHEN disposition = 'ANSWERED' THEN 1 END) / COUNT(*), 2) as taxa_pct
FROM cdr 
WHERE calldate >= CURRENT_DATE - INTERVAL '7 days';
"
```

---

## 📚 Referências

- **Tabela CDR:** `sql/04_create_cdr_table.sql`
- **View Legível:** `cdr_readable` (português)
- **Configuração:** `asterisk_etc/cdr_pgsql.conf`
- **Setup:** `scripts/config-cdr-pgsql.sh`

---

**Dica:** Use sempre `cdr_readable` para consultas mais legíveis com labels em português! 🇧🇷
