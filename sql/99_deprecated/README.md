# 📦 Arquivos Deprecados

Esta pasta contém arquivos SQL antigos que foram substituídos pela reestruturação do banco de dados em **17/02/2026**.

## ❌ Arquivos Antigos (NÃO USAR)

### init.sql
- **Status**: Substituído por `01_init_schema.sql`
- **Problema**: Estrutura CDR antiga (Asterisk < 20)
- **Motivo**: `uniqueid` como PRIMARY KEY causava conflitos

### teste_inicial.sql
- **Status**: Substituído por `02_sample_data.sql`
- **Problema**: Dados de teste desatualizados
- **Motivo**: Faltava multi-tenant completo

### 04_create_cdr_table.sql
- **Status**: Removido (duplicado)
- **Problema**: Criava tabela CDR que já existia em `init.sql`
- **Motivo**: Causava conflito de schemas

## ✅ Arquivos Novos (USAR ESTES)

Use os arquivos na pasta `sql/` principal:

1. **01_init_schema.sql** - Schema completo com CDR moderna
2. **02_sample_data.sql** - Dados de exemplo atualizados
3. **03_fix_and_validate.sql** - Scripts utilitários

## 🔄 Referência

Veja a documentação completa da reestruturação em:
- [doc/DATABASE_RESET.md](../../doc/DATABASE_RESET.md)
