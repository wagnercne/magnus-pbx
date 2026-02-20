# ðŸ“ž Guia de ImplantaÃ§Ã£o do CDR PostgreSQL

## âœ… ConfiguraÃ§Ãµes ConcluÃ­das

### 1. Estrutura de Banco de Dados
- âœ… **sql/04_create_cdr_table.sql** - Tabela CDR completa com:
  - 20+ colunas (calldate, src, dst, duration, billsec, disposition, etc)
  - 7 Ã­ndices (calldate, src, dst, uniqueid, linkedid, dcontext, disposition)
  - View `cdr_readable` com labels em portuguÃªs
  - PermissÃµes para `admin_magnus`

### 2. ConfiguraÃ§Ã£o do Asterisk
- âœ… **asterisk_etc/cdr_pgsql.conf** - ConexÃ£o com banco
  - hostname: postgres-magnus
  - database: magnus_pbx
  - table: cdr
  - user: admin_magnus
  
- âœ… **asterisk_etc/modules.conf** - MÃ³dulos CDR carregados
  - `load => app_cdr.so`
  - `load => cdr_custom.so`
  - `load => cdr_pgsql.so`
  
- âœ… **asterisk_etc/cdr.conf** - Log habilitado
  - `unanswered = yes` - Log de chamadas nÃ£o atendidas
  - `congestion = yes` - Log de chamadas congestionadas
  - `[csv]` mantido como backup

### 3. Scripts e DocumentaÃ§Ã£o
- âœ… **scripts/config-cdr-pgsql.sh** - AutomaÃ§Ã£o da configuraÃ§Ã£o
- âœ… **scripts/deploy.sh** - VerificaÃ§Ã£o de mÃ³dulo CDR
- âœ… **docs/CDR_QUERIES.md** - 50+ consultas SQL de exemplo

### 4. Docker Compose
- âœ… Volume montado: `./sql:/docker-entrypoint-initdb.d`
  - SQL serÃ¡ executado automaticamente na primeira criaÃ§Ã£o do container

## ðŸš€ PrÃ³ximos Passos na VM

### Passo 1: Atualizar o CÃ³digo
```bash
cd /srv/magnus-pbx
git pull origin main
```

### Passo 2: Executar Script de ConfiguraÃ§Ã£o
```bash
chmod +x scripts/config-cdr-pgsql.sh
./scripts/config-cdr-pgsql.sh
```

**O que o script faz:**
1. âœ… Cria a tabela CDR no PostgreSQL
2. âœ… Verifica se cdr_pgsql.conf existe
3. âœ… Recarrega mÃ³dulo cdr_pgsql.so no Asterisk
4. âœ… Testa conexÃ£o com banco
5. âœ… Mostra Ãºltimos 5 CDRs

### Passo 3: Testar GravaÃ§Ã£o de CDR
```bash
# 1. Ligue para *43 (echo test) de um softphone
# 2. Verifique se apareceu no banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT * FROM cdr_readable ORDER BY calldate DESC LIMIT 5;"
```

### Passo 4: Verificar Logs do Asterisk
```bash
docker compose logs -f asterisk-magnus | grep -i cdr
```

**VocÃª deve ver:**
- âœ… `cdr_pgsql.so` carregado
- âœ… `Connected to postgres-magnus@magnus_pbx`
- âœ… Sem erros de "No such file or directory"

## ðŸ“Š Consultando CDRs

### Ver Ãšltimas 10 Chamadas
```sql
SELECT * FROM cdr_readable 
ORDER BY calldate DESC 
LIMIT 10;
```

### Chamadas de Hoje
```sql
SELECT * FROM cdr_readable 
WHERE calldate::date = CURRENT_DATE 
ORDER BY calldate DESC;
```

### Taxa de Atendimento (hoje)
```sql
SELECT 
    COUNT(*) as total_chamadas,
    COUNT(*) FILTER (WHERE disposition = 'ANSWERED') as atendidas,
    COUNT(*) FILTER (WHERE disposition = 'NO ANSWER') as nao_atendidas,
    COUNT(*) FILTER (WHERE disposition = 'BUSY') as ocupado,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE disposition = 'ANSWERED') / COUNT(*),
        2
    ) as taxa_atendimento
FROM cdr
WHERE calldate::date = CURRENT_DATE;
```

**Mais consultas:** Veja [docs/CDR_QUERIES.md](./CDR_QUERIES.md)

## ðŸ” Troubleshooting

### Erro: "module cdr_pgsql.so not found"
```bash
# Verificar se mÃ³dulo estÃ¡ disponÃ­vel
docker compose exec asterisk-magnus ls -la /usr/lib/asterisk/modules/cdr_pgsql.so

# Recarregar mÃ³dulos
docker compose exec asterisk-magnus asterisk -rx "module load cdr_pgsql.so"
```

### Erro: "could not connect to database"
```bash
# Testar conexÃ£o com PostgreSQL
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT version();"

# Verificar configuraÃ§Ã£o
cat asterisk_etc/cdr_pgsql.conf
```

### Nenhum CDR estÃ¡ sendo gravado
```bash
# Verificar se CDR estÃ¡ habilitado
docker compose exec asterisk-magnus asterisk -rx "cdr status"

# Verificar mÃ³dulos CDR carregados
docker compose exec asterisk-magnus asterisk -rx "module show like cdr"

# Verificar tabela CDR existe
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\d cdr"
```

### Chamadas nÃ£o atendidas nÃ£o aparecem
- âœ… Verifique `cdr.conf`: `unanswered = yes`
- âœ… JÃ¡ estÃ¡ configurado no arquivo atual

## ðŸ“‹ Arquitetura CDR Dual

O sistema estÃ¡ configurado para usar **dois backends simultaneamente**:

### 1. PostgreSQL (Principal)
- âœ… Armazenamento em banco relacional
- âœ… Consultas SQL avanÃ§adas
- âœ… IntegraÃ§Ã£o com dashboards
- âœ… Backup automÃ¡tico do banco
- âœ… RelatÃ³rios e anÃ¡lises

### 2. CSV (Backup)
- âœ… Arquivos em `/var/log/asterisk/cdr-csv/Master.csv`
- âœ… Backup redundante
- âœ… ExportaÃ§Ã£o rÃ¡pida
- âœ… Compatibilidade legada

## ðŸŽ¯ PrÃ³ximas Fases

ApÃ³s CDR configurado, seguir [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md):

1. **Fase 1 - ValidaÃ§Ã£o**: Testar softphones e cÃ³digos de recurso
2. **Fase 2 - Backend**: API .NET 10 para integraÃ§Ã£o
3. **Fase 3 - Frontend**: Dashboard Vue 3 com relatÃ³rios CDR
4. **Fase 4 - IntegraÃ§Ã£o**: Conectar frontend â†” backend â†” Asterisk
5. **Fase 5 - Recursos AvanÃ§ados**: GravaÃ§Ã£o de chamadas, IVR, etc

## ðŸ“ ReferÃªncias

- [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL de exemplo
- [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md) - Roadmap completo do projeto
- [SETUP_VM.md](./SETUP_VM.md) - ConfiguraÃ§Ã£o inicial da VM
- [ESTRUTURA_MODULAR.md](./ESTRUTURA_MODULAR.md) - DocumentaÃ§Ã£o do dialplan modular

