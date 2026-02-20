# ðŸ“¦ Arquivos Deprecados

Esta pasta contÃ©m arquivos SQL antigos que foram substituÃ­dos pela reestruturaÃ§Ã£o do banco de dados em **17/02/2026**.

## âŒ Arquivos Antigos (NÃƒO USAR)

### init.sql
- **Status**: SubstituÃ­do por `01_init_schema.sql`
- **Problema**: Estrutura CDR antiga (Asterisk < 20)
- **Motivo**: `uniqueid` como PRIMARY KEY causava conflitos

### teste_inicial.sql
- **Status**: SubstituÃ­do por `02_sample_data.sql`
- **Problema**: Dados de teste desatualizados
- **Motivo**: Faltava multi-tenant completo

### 04_create_cdr_table.sql
- **Status**: Removido (duplicado)
- **Problema**: Criava tabela CDR que jÃ¡ existia em `init.sql`
- **Motivo**: Causava conflito de schemas

## âœ… Arquivos Novos (USAR ESTES)

Use os arquivos na pasta `sql/` principal:

1. **01_init_schema.sql** - Schema completo com CDR moderna
2. **02_sample_data.sql** - Dados de exemplo atualizados
3. **03_fix_and_validate.sql** - Scripts utilitÃ¡rios

## ðŸ”„ ReferÃªncia

Veja a documentaÃ§Ã£o completa da reestruturaÃ§Ã£o em:
- [docs/DATABASE_RESET.md](./DATABASE_RESET.md)

