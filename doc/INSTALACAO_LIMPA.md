# 🧹 Guia de Instalação Limpa - Magnus PBX

## 📋 Visão Geral

Este guia orienta a **instalação limpa do zero** do Magnus PBX, removendo qualquer instalação anterior e garantindo que não haja resquícios de configurações antigas que possam causar problemas.

### ✅ Por que fazer instalação limpa?

- 🧹 Remove configurações herdadas problemáticas
- 🔒 Garante estrutura consistente com o GitHub
- 📦 Banco de dados criado do zero (schema moderno)
- 🎯 Apenas arquivos essenciais (sem "lixo")
- 🚀 Setup reproduzível e documentado

---

## 🎯 Pré-requisitos

### Na VM Linux

```bash
# 1. Docker e Docker Compose instalados
docker --version
docker compose version

# 2. Git instalado
git --version

# 3. Acesso root ou sudo
sudo -v

# 4. Portas livres: 5060, 8088, 8089, 80, 443, 9443, 10000-10100
sudo netstat -tulpn | grep -E "5060|8088|8089|80|443|9443"
```

---

## 🚀 Método 1: Script Automatizado (Recomendado)

### 1. Download do Script

```bash
# Baixar diretamente do GitHub
wget https://raw.githubusercontent.com/wagnercne/magnus-pbx/main/scripts/instalacao-limpa.sh -O /tmp/instalacao-limpa.sh
chmod +x /tmp/instalacao-limpa.sh
```

### 2. Executar Instalação Limpa

```bash
/tmp/instalacao-limpa.sh
```

**O script vai:**
1. ✅ Fazer backup da instalação antiga
2. ✅ Parar e remover containers
3. ✅ Apagar `/srv/magnus-pbx`
4. ✅ Clonar repositório do GitHub
5. ✅ Compilar imagem Asterisk (~15 min)
6. ✅ Criar banco de dados do zero
7. ✅ Validar instalação

### 3. Aguardar

```
⏳ Build da imagem: ~10-15 minutos (primeira vez)
⏳ Inicialização: ~30 segundos
```

---

## 🔧 Método 2: Manual (Passo a Passo)

### Passo 1: Backup e Limpeza

```bash
# 1.1 Fazer backup (segurança)
sudo cp -r /srv/magnus-pbx /tmp/magnus-pbx-backup-$(date +%Y%m%d)

# 1.2 Parar containers
cd /srv/magnus-pbx
docker compose down -v

# 1.3 Remover instalação antiga
sudo rm -rf /srv/magnus-pbx
```

### Passo 2: Clonar Repositório

```bash
# 2.1 Clonar do GitHub
git clone https://github.com/wagnercne/magnus-pbx.git /srv/magnus-pbx

# 2.2 Entrar na pasta
cd /srv/magnus-pbx

# 2.3 Verificar branch
git branch
# Deve mostrar: * main
```

### Passo 3: Criar Estrutura de Pastas

```bash
# 3.1 Criar pastas de dados (volumes)
mkdir -p postgres_data
mkdir -p portainer_data
mkdir -p redis_data
mkdir -p custom_sounds

# 3.2 Garantir que pastas de log estão vazias
rm -f asterisk_logs/*.log 2>/dev/null || true

# NOTA: Sons PT-BR já vêm embutidos no container (/var/lib/asterisk/sounds/pt_BR)
# Pasta custom_sounds/ é para sons customizados opcionais (voz masculina, outros idiomas, etc)

# 3.3 Verificar estrutura
ls -la
```

**Deve ver:**
```
asterisk_etc/          ← Configurações (versionado)
asterisk_logs/         ← Logs (vazio, não versionado)
asterisk_recordings/   ← Gravações (vazio)
custom_sounds/         ← Sons customizados opcionais (criado agora)
backend/               ← API .NET (futuro)
doc/                   ← Documentação
frontend/              ← Vue 3 (futuro)
postgres_data/         ← Dados PostgreSQL (criado agora)
portainer_data/        ← Dados Portainer (criado agora)
redis_data/            ← Dados Redis (criado agora)
sql/                   ← Scripts SQL iniciais
scripts/               ← Scripts de automação
docker-compose.yml     ← Orquestração
Dockerfile             ← Imagem Asterisk
README.md
.gitignore
```

**Nota sobre sons:**
- 📁 `custom_sounds/` é para customizações opcionais (voz masculina, outros idiomas, sonsda empresa)
- 📖 Veja [custom_sounds/README.md](../custom_sounds/README.md) para detalhes
- ✅ Sons PT-BR já incluídos no container (`/var/lib/asterisk/sounds/pt_BR`)
- ✅ Instalados automaticamente durante build do Dockerfile
- ⏭️ `asterisk_sounds/` seria apenas para sons customizados extras (opcional)

### Passo 4: Build da Imagem Asterisk

```bash
# 4.1 Compilar imagem (primeira vez demora ~15 min)
docker compose build asterisk-magnus

# 4.2 Ver tamanho da imagem
docker images | grep asterisk-magnus
```

### Passo 5: Iniciar Serviços

```bash
# 5.1 Subir tudo
docker compose up -d

# 5.2 Ver status
docker compose ps

# 5.3 Deve mostrar todos 'healthy' ou 'running'
```

### Passo 6: Aguardar Inicialização

```bash
# 6.1 Aguardar PostgreSQL
echo "⏳ Aguardando PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres-magnus pg_isready -U admin_magnus &>/dev/null; then
        echo "✅ PostgreSQL pronto!"
        break
    fi
    sleep 2
done

# 6.2 Aguardar Asterisk
echo "⏳ Aguardando Asterisk..."
sleep 15

# 6.3 Verificar Asterisk
docker compose exec asterisk-magnus asterisk -rx "core show version"
```

### Passo 7: Validação

```bash
# 7.1 Ver banco de dados criado
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
"

# 7.2 Ver ramais de exemplo
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT id, context, allow FROM ps_endpoints;
"

# Deve mostrar:
#     id           |    context    |      allow
# -----------------+---------------+------------------
# 1001@belavista   | ctx-belavista | opus,g722,ulaw
# 1002@belavista   | ctx-belavista | ulaw,alaw,gsm
# 2001@acme        | ctx-acme      | ulaw,alaw
# 3001@techno      | ctx-techno    | opus,vp8

# 7.3 Ver módulos Asterisk carregados
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"
docker compose exec asterisk-magnus asterisk -rx "module show like cdr"

# 7.4 Ver logs em tempo real
docker compose logs -f asterisk-magnus
# Ctrl+C para sair
```

---

## ✅ Validação da Instalação

### 1. Containers Rodando

```bash
docker compose ps
```

**Deve mostrar:**
```
NAME                STATUS              PORTS
asterisk-magnus     healthy             5060/udp, 5060/tcp, 5061/tcp, 8088-8089/tcp, 10000-10100/udp
postgres-magnus     healthy             5432/tcp
redis-magnus        healthy             6379/tcp
traefik-magnus      running             80/tcp, 443/tcp
portainer-magnus    running             9000/tcp, 9443/tcp
```

### 2. Banco de Dados

```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT 
        (SELECT COUNT(*) FROM tenants) as tenants,
        (SELECT COUNT(*) FROM ps_endpoints) as ramais,
        (SELECT COUNT(*) FROM cdr) as cdrs_exemplo;
"
```

**Deve mostrar:**
```
 tenants | ramais | cdrs_exemplo
---------+--------+--------------
       3 |      5 |            5
```

### 3. Asterisk

```bash
# Ver versão
docker compose exec asterisk-magnus asterisk -rx "core show version"
# Asterisk 22.1.0

# Ver módulos críticos
docker compose exec asterisk-magnus asterisk -rx "module show like res_config_pgsql"
# res_config_pgsql.so        Running (Realtime Configuration Driver for PostgreSQL)

docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"
# cdr_pgsql.so              Running (PostgreSQL CDR Backend)
```

### 4. Conectividade Banco ↔ Asterisk

```bash
docker compose exec asterisk-magnus asterisk -rx "realtime load ps_endpoints 1001@belavista"
```

**Deve mostrar os dados do endpoint sem erros**

### 5. Portas Expostas

```bash
sudo netstat -tulpn | grep -E "5060|8088|8089|9443"
```

**Deve mostrar:**
```
udp   0.0.0.0:5060    LISTEN    docker-proxy
tcp   0.0.0.0:5060    LISTEN    docker-proxy
tcp   0.0.0.0:8088    LISTEN    docker-proxy
tcp   0.0.0.0:8089    LISTEN    docker-proxy
tcp   0.0.0.0:9443    LISTEN    docker-proxy
```

---

## 🧪 Teste Funcional

### 1. Configurar Softphone

**Exemplo: Zoiper, Linphone, ou MicroSIP**

```
Servidor:    <IP_DA_VM>:5060
Usuário:     1001
Senha:       magnus123
Domínio:     belavista
Transporte:  UDP
```

### 2. Registrar

- Softphone deve mostrar **"Registrado"** ou **"Online"**
- Ver no Asterisk:

```bash
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"
```

Deve mostrar `1001@belavista` como **Avail** (disponível)

### 3. Discar *43 (Echo Test)

- Discar: `*43`
- Deve tocar e você ouve sua própria voz com delay
- Desligar

### 4. Verificar CDR

```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT 
        \"Data/Hora\",
        \"Origem\",
        \"Destino\",
        \"Duração Total (s)\",
        \"Status\"
    FROM cdr_readable 
    ORDER BY \"Data/Hora\" DESC 
    LIMIT 5;
"
```

**Deve mostrar sua chamada para *43 com status ANSWERED**

---

## 📊 Acessar Interfaces Web

### Portainer (Gerenciamento Docker)

```
URL: https://<IP_DA_VM>:9443
Primeira vez: Criar usuário admin
```

### Traefik Dashboard

```
URL: http://<IP_DA_VM>:8080
Mostra roteamento e backends
```

---

## 🔍 Troubleshooting

### Asterisk não inicia

```bash
# Ver logs
docker compose logs asterisk-magnus

# Verificar configurações
docker compose exec asterisk-magnus asterisk -rx "core show settings"

# Entrar no container
docker compose exec -it asterisk-magnus bash
```

### PostgreSQL não aceita conexões

```bash
# Ver logs
docker compose logs postgres-magnus

# Testar conexão manual
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT version();"
```

### Porta 5060 em uso

```bash
# Ver o que está usando
sudo lsof -i :5060

# Parar serviço conflitante (exemplo: Asterisk local)
sudo systemctl stop asterisk
sudo systemctl disable asterisk
```

### Build falha

```bash
# Limpar cache Docker
docker system prune -a

# Build com verbose
docker compose build --no-cache --progress=plain asterisk-magnus
```

---

## 📁 Estrutura de Arquivos

### ✅ Versionados no Git (mantém)

```
asterisk_etc/          ← Configurações Asterisk
backend/               ← API .NET (futuro)
doc/                   ← Documentação Markdown
frontend/              ← Vue 3 (futuro)
scripts/               ← Scripts Bash/PowerShell
sql/                   ← Scripts SQL
docker-compose.yml     ← Orquestração Docker
Dockerfile             ← Imagem Asterisk
README.md
.gitignore
```

### ❌ NÃO versionados (gerados em runtime)

```
postgres_data/         ← Dados PostgreSQL
portainer_data/        ← Dados Portainer
redis_data/            ← Dados Redis
asterisk_logs/*.log    ← Logs Asterisk
asterisk_recordings/*  ← Gravações
```

---

## 🎯 Próximos Passos

Após instalação limpa e testes:

1. ✅ **Configurar 2 softphones** (1001 e 1002)
2. ✅ **Testar chamadas internas** (1001 → 1002)
3. ✅ **Testar códigos de recursos** (*43, *97)
4. ✅ **Verificar CDRs no banco**
5. ⏭️ **Desenvolver backend** .NET 10 API
6. ⏭️ **Desenvolver frontend** Vue 3
7. ⏭️ **Integrar** frontend ↔ backend ↔ Asterisk

---

## 📚 Documentação Relacionada

- [DATABASE_RESET.md](./DATABASE_RESET.md) - Detalhes do schema do banco
- [CDR_DEPLOY.md](./CDR_DEPLOY.md) - Configuração CDR PostgreSQL
- [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL úteis
- [ASTERISK_CONFIG_INVENTORY.md](./ASTERISK_CONFIG_INVENTORY.md) - Inventário de arquivos de config
- [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md) - Roadmap completo
- [SETUP_VM.md](./SETUP_VM.md) - Setup inicial da VM

---

## ✅ Checklist Final

- [ ] Backup da instalação anterior feito
- [ ] Repositório clonado do GitHub
- [ ] Imagem Asterisk compilada
- [ ] 5 containers rodando (asterisk, postgres, redis, traefik, portainer)
- [ ] Banco com 3 tenants, 5 ramais, 5 CDRs de exemplo
- [ ] Módulos `res_config_pgsql` e `cdr_pgsql` carregados
- [ ] Softphone registrado com sucesso
- [ ] *43 funciona e grava CDR
- [ ] Portainer acessível em 9443
- [ ] Logs sem erros críticos

---

**✨ Instalação limpa concluída! Agora você tem um ambiente consistente, reproduzível e pronto para desenvolvimento.**
