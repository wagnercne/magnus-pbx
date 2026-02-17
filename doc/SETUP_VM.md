# 🖥️ Setup na VM Linux

Guia para configurar o Magnus PBX em uma VM Linux usando o repositório GitHub.

---

## 📋 Pré-requisitos

### Software Necessário:
- ✅ Git
- ✅ Docker
- ✅ Docker Compose
- ✅ Conexão com internet

### Verificar instalação:
```bash
git --version        # Git 2.x ou superior
docker --version     # Docker 20.x ou superior
docker compose version  # Docker Compose 2.x ou superior
```

---

## 🚀 Instalação Inicial (Primeira Vez)

### 1. Clonar o Repositório

```bash
# Ir para o diretório onde quer instalar
cd /srv

# Clonar o projeto
git clone https://github.com/wagnercne/magnus-pbx.git

# Entrar no diretório
cd magnus-pbx
```

### 2. Verificar Arquivos

```bash
# Listar estrutura
ls -lh

# Você deve ver:
#   README.md
#   Dockerfile
#   docker-compose.yml
#   asterisk_etc/
#   scripts/
#   doc/
#   sql/
```

### 3. Subir os Containers

```bash
# Iniciar PostgreSQL e Asterisk
docker compose up -d

# Verificar status
docker compose ps

# Ver logs
docker compose logs -f asterisk-magnus
```

### 4. Executar Deploy Inicial

```bash
# Dar permissão de execução nos scripts
chmod +x scripts/*.sh

# Executar deploy (corrige banco, etc)
./scripts/deploy.sh

# Aguardar ~30 segundos
```

### 5. Validar Instalação

```bash
# Verificar contextos carregados
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts"

# Deve mostrar: ctx-belavista, ctx-acme, ctx-techno

# Testar *43 (echo test)
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"
```

---

## 🔄 Atualizações (Quando Houver Mudanças no Windows)

### Cenário: Você editou arquivos no Windows e fez push

```bash
# Na VM Linux
cd /srv/magnus-pbx

# Puxar atualizações
git pull origin main

# Se houve mudanças no banco ou dialplan
./scripts/deploy.sh

# Se só mudou dialplan
./scripts/reload-dialplan.sh
```

---

## 🎯 Ativar Dialplan Modular (Opcional)

Se decidir migrar para a estrutura modular:

```bash
cd /srv/magnus-pbx

# Verificar se arquivos modulares existem
ls -lh asterisk_etc/extensions-modular.conf
ls -lh asterisk_etc/extensions-features.conf
ls -lh asterisk_etc/routing.conf
ls -lh asterisk_etc/tenants.conf

# Executar script de ativação
./scripts/ativar-dialplan-modular.sh

# O script irá:
#   1. Fazer backup do extensions.conf atual
#   2. Ativar o dialplan modular
#   3. Reiniciar Asterisk
#   4. Validar se carregou
```

---

## 📁 Estrutura do Projeto na VM

```
/srv/magnus-pbx/
├── asterisk_etc/           # Configurações do Asterisk
│   ├── extensions.conf         → Dialplan atual (monolítico ou modular)
│   ├── extensions-modular.conf → Master file (se modular)
│   ├── extensions-features.conf → Feature codes (*43, *500)
│   ├── routing.conf             → Lógica de roteamento
│   ├── tenants.conf             → Contextos dos tenants
│   ├── pjsip.conf              → Configuração SIP
│   ├── modules.conf            → Módulos do Asterisk
│   └── res_config_pgsql.conf   → Conexão com PostgreSQL
│
├── scripts/                # Scripts de automação
│   ├── deploy.sh               → Deploy completo
│   ├── reload-dialplan.sh      → Reload rápido
│   ├── ativar-dialplan-modular.sh → Migrar para modular
│   ├── diagnostico.sh          → Diagnóstico completo
│   └── fix-dialplan.sh         → Forçar reload
│
├── sql/                    # Scripts SQL
│   ├── init.sql                → Estrutura do banco
│   └── 03_fix_and_validate.sql → Correções
│
├── doc/                    # Documentação
│   ├── COMO_INICIAR.md
│   ├── GUIA_DE_TESTES.md
│   └── ...
│
├── docker-compose.yml      # Orquestração
└── Dockerfile              # Imagem Asterisk
```

---

## 🔧 Comandos Úteis

### Docker

```bash
# Ver containers rodando
docker compose ps

# Ver logs em tempo real
docker compose logs -f asterisk-magnus
docker compose logs -f postgres-magnus

# Reiniciar um serviço
docker compose restart asterisk-magnus

# Parar tudo
docker compose down

# Iniciar tudo
docker compose up -d

# Rebuild (após mudanças no Dockerfile)
docker compose up -d --build
```

### Asterisk CLI

```bash
# Entrar no console do Asterisk
docker compose exec asterisk-magnus asterisk -rvvv

# Ou executar comando direto
docker compose exec asterisk-magnus asterisk -rx "core show channels"

# Ver ramais registrados
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Ver contextos do dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts"

# Ver módulos carregados
docker compose exec asterisk-magnus asterisk -rx "module show like pbx"
docker compose exec asterisk-magnus asterisk -rx "module show like res_config"
```

### PostgreSQL

```bash
# Conectar ao banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx

# Ver tabelas
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\dt"

# Ver endpoints
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, context, transport FROM ps_endpoints;"
```

### Scripts de Manutenção

```bash
# Deploy completo (use após mudanças no banco)
./scripts/deploy.sh

# Reload rápido (use após editar dialplan)
./scripts/reload-dialplan.sh

# Diagnóstico (quando algo não funcionar)
./scripts/diagnostico.sh

# Forçar reload completo (quando reload simples não resolver)
./scripts/fix-dialplan.sh
```

---

## 🧪 Testar Instalação

### 1. Verificar se está tudo rodando

```bash
docker compose ps
# Deve mostrar:
#   asterisk-magnus  ... Up
#   postgres-magnus  ... Up
```

### 2. Verificar módulos carregados

```bash
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"
docker compose exec asterisk-magnus asterisk -rx "module show like res_config_pgsql"
# Ambos devem mostrar "1 modules loaded"
```

### 3. Verificar contextos

```bash
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep ctx-
# Deve mostrar: ctx-belavista, ctx-acme, ctx-techno
```

### 4. Verificar feature codes

```bash
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"
# Deve mostrar o dialplan do Echo Test
```

### 5. Verificar banco de dados

```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT COUNT(*) FROM ps_endpoints;"
# Deve retornar um número (ex: 6 endpoints)
```

---

## 🐛 Troubleshooting

### Problema: Containers não sobem

```bash
# Ver erros
docker compose logs

# Verificar portas em uso
netstat -tulpn | grep -E '5432|5060'

# Remover tudo e começar de novo
docker compose down -v
docker compose up -d
```

### Problema: Dialplan não carrega

```bash
# Verificar se pbx_config está carregado
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

# Se não estiver, carregar
docker compose exec asterisk-magnus asterisk -rx "module load pbx_config.so"

# Recarregar dialplan
./scripts/reload-dialplan.sh
```

### Problema: Ramais não registram

```bash
# Verificar endpoints no banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, context, transport FROM ps_endpoints;"

# Verificar se contextos estão corretos (deve ser ctx-{slug})
# Se estiverem NULL, executar:
./scripts/deploy.sh
```

### Problema: Git pull dá conflito

```bash
# Descartar mudanças locais
git reset --hard origin/main

# Ou fazer backup das mudanças
git stash
git pull origin main
git stash pop
```

---

## 📊 Monitoramento

### Ver uso de recursos

```bash
# CPU e Memória dos containers
docker stats

# Espaço em disco
df -h

# Logs do Asterisk (últimas 100 linhas)
docker compose logs --tail=100 asterisk-magnus
```

### Ver chamadas ativas

```bash
# Console com verbose
docker compose exec asterisk-magnus asterisk -rvvv

# Ou comando direto
docker compose exec asterisk-magnus asterisk -rx "core show channels"
```

---

## 🔐 Segurança

### Alterar senhas padrão

```bash
# PostgreSQL (editar docker-compose.yml)
# Mudar POSTGRES_PASSWORD

# Ramais (editar no banco)
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx
UPDATE ps_auths SET password = 'nova_senha_segura' WHERE id = '1001@belavista';
```

### Firewall

```bash
# Permitir apenas portas necessárias
sudo ufw allow 5060/udp  # SIP
sudo ufw allow 10000:20000/udp  # RTP (voz)
sudo ufw allow 22/tcp  # SSH
sudo ufw enable
```

---

## 🔄 Workflow Desenvolvimento → Produção

### 1. No Windows (Desenvolvimento)

```powershell
# Editar arquivos
# Testar localmente

# Commit
git add .
git commit -m "feat: Adicionar novo tenant"
git push origin main
```

### 2. Na VM (Produção)

```bash
# Puxar mudanças
cd /srv/magnus-pbx
git pull origin main

# Aplicar mudanças
./scripts/deploy.sh

# Verificar
docker compose logs -f asterisk-magnus
```

---

## 📚 Próximos Passos

1. **Configurar Softphones** → [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md)
2. **Testar Funcionalidades** → [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md)
3. **Adicionar Novos Tenants** → Editar `sql/init.sql` + `asterisk_etc/tenants.conf`
4. **Configurar Trunks SIP** → Editar `asterisk_etc/pjsip.conf`
5. **Setup Backend C#** → [SETUP_BACKEND.md](SETUP_BACKEND.md)
6. **Setup Frontend Vue** → [SETUP_FRONTEND.md](SETUP_FRONTEND.md)

---

## 🔗 Links Úteis

- **Repositório GitHub:** https://github.com/wagnercne/magnus-pbx
- **Documentação Asterisk:** https://docs.asterisk.org/
- **Docker Compose:** https://docs.docker.com/compose/
- **PostgreSQL:** https://www.postgresql.org/docs/

---

## 🆘 Suporte

Se encontrar problemas:

1. Consultar [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md)
2. Executar `./scripts/diagnostico.sh`
3. Consultar [QUICK_FIX.md](QUICK_FIX.md)
4. Ver issues no GitHub: https://github.com/wagnercne/magnus-pbx/issues
