# 📚 Documentação do Magnus PBX

Esta pasta contém toda a documentação técnica do projeto Magnus PBX.

## 🚀 Começando

**Novo no projeto?** Comece aqui:
1. [SETUP_VM.md](SETUP_VM.md) - **Setup completo na VM Linux** (clone do GitHub)
2. [COMO_INICIAR.md](COMO_INICIAR.md) - Guia de instalação e configuração inicial

## 📖 Índice por Categoria

### 🏗️ Arquitetura

- [ARQUITETURA_STACK.md](ARQUITETURA_STACK.md) - **Stack completo** (Asterisk + PostgreSQL + C# + Vue)
- [ARQUITETURA_HIBRIDA.md](ARQUITETURA_HIBRIDA.md) - **Dialplan híbrido** (patterns + AGI + banco)
- [PGSQL_VS_ODBC.md](PGSQL_VS_ODBC.md) - Comparação entre drivers PostgreSQL

### 🔧 Configuração

- [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md) - Configurar **Zoiper, Linphone, MicroSIP** etc
- [DIALPLAN_QUAL_USAR.md](DIALPLAN_QUAL_USAR.md) - Escolher entre **dialplan modular vs monolítico**
- [MIGRACAO_DIALPLAN.md](MIGRACAO_DIALPLAN.md) - Migrar para dialplan modular
- [SYNC_WINDOWS_LINUX.md](SYNC_WINDOWS_LINUX.md) - **Sincronizar arquivos Windows → Linux VM**
- [SETUP_BACKEND.md](SETUP_BACKEND.md) - Setup do **backend C# (.NET 10)**
- [SETUP_FRONTEND.md](SETUP_FRONTEND.md) - Setup do **frontend Vue 3 + TypeScript**

### 🧪 Testes e Validação

- [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md) - **Passo a passo** de todos os testes
- [QUICK_FIX.md](QUICK_FIX.md) - Correções rápidas para problemas comuns

### 🐛 Troubleshooting

- [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md) - **Análise detalhada** do problema original (*43 não funcionava)

### 📋 Referência

- [IMPLEMENTACOES_COMPLETAS.md](IMPLEMENTACOES_COMPLETAS.md) - Lista de **todas as implementações** realizadas

---

## 🎯 Fluxo de Leitura Recomendado

### Para Iniciantes
1. [COMO_INICIAR.md](COMO_INICIAR.md) → Instalar e rodar
2. [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md) → Configurar telefone
3. [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md) → Testar funcionalidades

### Para Desenvolvedores
1. [ARQUITETURA_STACK.md](ARQUITETURA_STACK.md) → Entender o sistema completo
2. [ARQUITETURA_HIBRIDA.md](ARQUITETURA_HIBRIDA.md) → Entender a abordagem híbrida
3. [SETUP_BACKEND.md](SETUP_BACKEND.md) → Configurar backend
4. [SETUP_FRONTEND.md](SETUP_FRONTEND.md) → Configurar frontend

### Para Administradores
1. [PGSQL_VS_ODBC.md](PGSQL_VS_ODBC.md) → Entender escolhas técnicas
2. [DIALPLAN_QUAL_USAR.md](DIALPLAN_QUAL_USAR.md) → Escolher abordagem
3. [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md) → Troubleshooting avançado

---

## 📂 Outros Documentos

- `asterisk_etc/README-DIALPLAN.md` - **Documentação específica** do dialplan modular

---

**Voltar:** [README.md principal](../README.md)
