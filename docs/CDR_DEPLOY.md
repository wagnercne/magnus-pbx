# 📞 Guia de Implantação do CDR PostgreSQL

## ✅ Configurações Concluídas

### 1. Estrutura de Banco de Dados
- ✅ **sql/04_create_cdr_table.sql** - Tabela CDR completa com:
  - 20+ colunas (calldate, src, dst, duration, billsec, disposition, etc)
  - 7 índices (calldate, src, dst, uniqueid, linkedid, dcontext, disposition)
  - View `cdr_readable` com labels em português
  - Permissões para `admin_magnus`

### 2. Configuração do Asterisk
- ✅ **asterisk_etc/cdr_pgsql.conf** - Conexão com banco
  - hostname: postgres-magnus
  - database: magnus_pbx
  - table: cdr
  - user: admin_magnus
  
- ✅ **asterisk_etc/modules.conf** - Módulos CDR carregados
  - `load => app_cdr.so`
  - `load => cdr_custom.so`
  - `load => cdr_pgsql.so`
  
- ✅ **asterisk_etc/cdr.conf** - Log habilitado
  - `unanswered = yes` - Log de chamadas não atendidas
  - `congestion = yes` - Log de chamadas congestionadas
  - `[csv]` mantido como backup

### 3. Scripts e Documentação
- ✅ **scripts/config-cdr-pgsql.sh** - Automação da configuração
- ✅ **scripts/deploy.sh** - Verificação de módulo CDR
- ✅ **doc/CDR_QUERIES.md** - 50+ consultas SQL de exemplo

### 4. Docker Compose
- ✅ Volume montado: `./sql:/docker-entrypoint-initdb.d`
  - SQL será executado automaticamente na primeira criação do container

## 🚀 Próximos Passos na VM

### Passo 1: Atualizar o Código
```bash
cd /srv/magnus-pbx
git pull origin main
```

### Passo 2: Executar Script de Configuração
```bash
chmod +x scripts/config-cdr-pgsql.sh
./scripts/config-cdr-pgsql.sh
```

**O que o script faz:**
1. ✅ Cria a tabela CDR no PostgreSQL
2. ✅ Verifica se cdr_pgsql.conf existe
3. ✅ Recarrega módulo cdr_pgsql.so no Asterisk
4. ✅ Testa conexão com banco
5. ✅ Mostra últimos 5 CDRs

### Passo 3: Testar Gravação de CDR
```bash
# 1. Ligue para *43 (echo test) de um softphone
# 2. Verifique se apareceu no banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT * FROM cdr_readable ORDER BY calldate DESC LIMIT 5;"
```

### Passo 4: Verificar Logs do Asterisk
```bash
docker compose logs -f asterisk-magnus | grep -i cdr
```

**Você deve ver:**
- ✅ `cdr_pgsql.so` carregado
- ✅ `Connected to postgres-magnus@magnus_pbx`
- ✅ Sem erros de "No such file or directory"

## 📊 Consultando CDRs

### Ver Últimas 10 Chamadas
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

**Mais consultas:** Veja [doc/CDR_QUERIES.md](./CDR_QUERIES.md)

## 🔍 Troubleshooting

### Erro: "module cdr_pgsql.so not found"
```bash
# Verificar se módulo está disponível
docker compose exec asterisk-magnus ls -la /usr/lib/asterisk/modules/cdr_pgsql.so

# Recarregar módulos
docker compose exec asterisk-magnus asterisk -rx "module load cdr_pgsql.so"
```

### Erro: "could not connect to database"
```bash
# Testar conexão com PostgreSQL
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT version();"

# Verificar configuração
cat asterisk_etc/cdr_pgsql.conf
```

### Nenhum CDR está sendo gravado
```bash
# Verificar se CDR está habilitado
docker compose exec asterisk-magnus asterisk -rx "cdr status"

# Verificar módulos CDR carregados
docker compose exec asterisk-magnus asterisk -rx "module show like cdr"

# Verificar tabela CDR existe
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\d cdr"
```

### Chamadas não atendidas não aparecem
- ✅ Verifique `cdr.conf`: `unanswered = yes`
- ✅ Já está configurado no arquivo atual

## 📋 Arquitetura CDR Dual

O sistema está configurado para usar **dois backends simultaneamente**:

### 1. PostgreSQL (Principal)
- ✅ Armazenamento em banco relacional
- ✅ Consultas SQL avançadas
- ✅ Integração com dashboards
- ✅ Backup automático do banco
- ✅ Relatórios e análises

### 2. CSV (Backup)
- ✅ Arquivos em `/var/log/asterisk/cdr-csv/Master.csv`
- ✅ Backup redundante
- ✅ Exportação rápida
- ✅ Compatibilidade legada

## 🎯 Próximas Fases

Após CDR configurado, seguir [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md):

1. **Fase 1 - Validação**: Testar softphones e códigos de recurso
2. **Fase 2 - Backend**: API .NET 10 para integração
3. **Fase 3 - Frontend**: Dashboard Vue 3 com relatórios CDR
4. **Fase 4 - Integração**: Conectar frontend ↔ backend ↔ Asterisk
5. **Fase 5 - Recursos Avançados**: Gravação de chamadas, IVR, etc

## 📝 Referências

- [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL de exemplo
- [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md) - Roadmap completo do projeto
- [SETUP_VM.md](./SETUP_VM.md) - Configuração inicial da VM
- [ESTRUTURA_MODULAR.md](./ESTRUTURA_MODULAR.md) - Documentação do dialplan modular
