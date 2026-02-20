# ðŸ§¹ Guia de InstalaÃ§Ã£o Limpa - Magnus PBX

## ðŸ“‹ VisÃ£o Geral

Este guia orienta a **instalaÃ§Ã£o limpa do zero** do Magnus PBX, removendo qualquer instalaÃ§Ã£o anterior e garantindo que nÃ£o haja resquÃ­cios de configuraÃ§Ãµes antigas que possam causar problemas.

### âœ… Por que fazer instalaÃ§Ã£o limpa?

- ðŸ§¹ Remove configuraÃ§Ãµes herdadas problemÃ¡ticas
- ðŸ”’ Garante estrutura consistente com o GitHub
- ðŸ“¦ Banco de dados criado do zero (schema moderno)
- ðŸŽ¯ Apenas arquivos essenciais (sem "lixo")
- ðŸš€ Setup reproduzÃ­vel e documentado

---

## ðŸŽ¯ PrÃ©-requisitos

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

## ðŸš€ MÃ©todo 1: Script Automatizado (Recomendado)

### 1. Download do Script

```bash
# Baixar diretamente do GitHub
wget https://raw.githubusercontent.com/wagnercne/magnus-pbx/main/scripts/instalacao-limpa.sh -O /tmp/instalacao-limpa.sh
chmod +x /tmp/instalacao-limpa.sh
```

### 2. Executar InstalaÃ§Ã£o Limpa

```bash
/tmp/instalacao-limpa.sh
```

**O script vai:**
1. âœ… Fazer backup da instalaÃ§Ã£o antiga
2. âœ… Parar e remover containers
3. âœ… Apagar `/srv/magnus-pbx`
4. âœ… Clonar repositÃ³rio do GitHub
5. âœ… Compilar imagem Asterisk (~15 min)
6. âœ… Criar banco de dados do zero
7. âœ… Validar instalaÃ§Ã£o

### 3. Aguardar

```
â³ Build da imagem: ~10-15 minutos (primeira vez)
â³ InicializaÃ§Ã£o: ~30 segundos
```

---

## ðŸ”§ MÃ©todo 2: Manual (Passo a Passo)

### Passo 1: Backup e Limpeza

```bash
# 1.1 Fazer backup (seguranÃ§a)
sudo cp -r /srv/magnus-pbx /tmp/magnus-pbx-backup-$(date +%Y%m%d)

# 1.2 Parar containers
cd /srv/magnus-pbx
docker compose down -v

# 1.3 Remover instalaÃ§Ã£o antiga
sudo rm -rf /srv/magnus-pbx
```

### Passo 2: Clonar RepositÃ³rio

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

# 3.2 Garantir que pastas de log estÃ£o vazias
rm -f asterisk_logs/*.log 2>/dev/null || true

# NOTA: Sons PT-BR jÃ¡ vÃªm embutidos no container (/var/lib/asterisk/sounds/pt_BR)
# Pasta custom_sounds/ Ã© para sons customizados opcionais (voz masculina, outros idiomas, etc)

# 3.3 Verificar estrutura
ls -la
```

**Deve ver:**
```
asterisk_etc/          â† ConfiguraÃ§Ãµes (versionado)
asterisk_logs/         â† Logs (vazio, nÃ£o versionado)
asterisk_recordings/   â† GravaÃ§Ãµes (vazio)
custom_sounds/         â† Sons customizados opcionais (criado agora)
backend/               â† API .NET (futuro)
docs/                   â† DocumentaÃ§Ã£o
frontend/              â† Vue 3 (futuro)
postgres_data/         â† Dados PostgreSQL (criado agora)
portainer_data/        â† Dados Portainer (criado agora)
redis_data/            â† Dados Redis (criado agora)
sql/                   â† Scripts SQL iniciais
scripts/               â† Scripts de automaÃ§Ã£o
docker-compose.yml     â† OrquestraÃ§Ã£o
Dockerfile             â† Imagem Asterisk
README.md
.gitignore
```

**Nota sobre sons:**
- ðŸ“ `custom_sounds/` Ã© para customizaÃ§Ãµes opcionais (voz masculina, outros idiomas, sonsda empresa)
- ðŸ“– Veja [custom_sounds/README.md](../custom_sounds/README.md) para detalhes
- âœ… Sons PT-BR jÃ¡ incluÃ­dos no container (`/var/lib/asterisk/sounds/pt_BR`)
- âœ… Instalados automaticamente durante build do Dockerfile
- â­ï¸ `asterisk_sounds/` seria apenas para sons customizados extras (opcional)

### Passo 4: Build da Imagem Asterisk

```bash
# 4.1 Compilar imagem (primeira vez demora ~15 min)
docker compose build asterisk-magnus

# 4.2 Ver tamanho da imagem
docker images | grep asterisk-magnus
```

### Passo 5: Iniciar ServiÃ§os

```bash
# 5.1 Subir tudo
docker compose up -d

# 5.2 Ver status
docker compose ps

# 5.3 Deve mostrar todos 'healthy' ou 'running'
```

### Passo 6: Aguardar InicializaÃ§Ã£o

```bash
# 6.1 Aguardar PostgreSQL
echo "â³ Aguardando PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres-magnus pg_isready -U admin_magnus &>/dev/null; then
        echo "âœ… PostgreSQL pronto!"
        break
    fi
    sleep 2
done

# 6.2 Aguardar Asterisk
echo "â³ Aguardando Asterisk..."
sleep 15

# 6.3 Verificar Asterisk
docker compose exec asterisk-magnus asterisk -rx "core show version"
```

### Passo 7: ValidaÃ§Ã£o

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

# 7.3 Ver mÃ³dulos Asterisk carregados
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"
docker compose exec asterisk-magnus asterisk -rx "module show like cdr"

# 7.4 Ver logs em tempo real
docker compose logs -f asterisk-magnus
# Ctrl+C para sair
```

---

## âœ… ValidaÃ§Ã£o da InstalaÃ§Ã£o

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
# Ver versÃ£o
docker compose exec asterisk-magnus asterisk -rx "core show version"
# Asterisk 22.1.0

# Ver mÃ³dulos crÃ­ticos
docker compose exec asterisk-magnus asterisk -rx "module show like res_config_pgsql"
# res_config_pgsql.so        Running (Realtime Configuration Driver for PostgreSQL)

docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"
# cdr_pgsql.so              Running (PostgreSQL CDR Backend)
```

### 4. Conectividade Banco â†” Asterisk

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

## ðŸ§ª Teste Funcional

### 1. Configurar Softphone

**Exemplo: Zoiper, Linphone, ou MicroSIP**

```
Servidor:    <IP_DA_VM>:5060
UsuÃ¡rio:     1001
Senha:       magnus123
DomÃ­nio:     belavista
Transporte:  UDP
```

### 2. Registrar

- Softphone deve mostrar **"Registrado"** ou **"Online"**
- Ver no Asterisk:

```bash
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"
```

Deve mostrar `1001@belavista` como **Avail** (disponÃ­vel)

### 3. Discar *43 (Echo Test)

- Discar: `*43`
- Deve tocar e vocÃª ouve sua prÃ³pria voz com delay
- Desligar

### 4. Verificar CDR

```bash
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
    SELECT 
        \"Data/Hora\",
        \"Origem\",
        \"Destino\",
        \"DuraÃ§Ã£o Total (s)\",
        \"Status\"
    FROM cdr_readable 
    ORDER BY \"Data/Hora\" DESC 
    LIMIT 5;
"
```

**Deve mostrar sua chamada para *43 com status ANSWERED**

---

## ðŸ“Š Acessar Interfaces Web

### Portainer (Gerenciamento Docker)

```
URL: https://<IP_DA_VM>:9443
Primeira vez: Criar usuÃ¡rio admin
```

### Traefik Dashboard

```
URL: http://<IP_DA_VM>:8080
Mostra roteamento e backends
```

---

## ðŸ” Troubleshooting

### Asterisk nÃ£o inicia

```bash
# Ver logs
docker compose logs asterisk-magnus

# Verificar configuraÃ§Ãµes
docker compose exec asterisk-magnus asterisk -rx "core show settings"

# Entrar no container
docker compose exec -it asterisk-magnus bash
```

### PostgreSQL nÃ£o aceita conexÃµes

```bash
# Ver logs
docker compose logs postgres-magnus

# Testar conexÃ£o manual
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT version();"
```

### Porta 5060 em uso

```bash
# Ver o que estÃ¡ usando
sudo lsof -i :5060

# Parar serviÃ§o conflitante (exemplo: Asterisk local)
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

## ðŸ“ Estrutura de Arquivos

### âœ… Versionados no Git (mantÃ©m)

```
asterisk_etc/          â† ConfiguraÃ§Ãµes Asterisk
backend/               â† API .NET (futuro)
docs/                   â† DocumentaÃ§Ã£o Markdown
frontend/              â† Vue 3 (futuro)
scripts/               â† Scripts Bash/PowerShell
sql/                   â† Scripts SQL
docker-compose.yml     â† OrquestraÃ§Ã£o Docker
Dockerfile             â† Imagem Asterisk
README.md
.gitignore
```

### âŒ NÃƒO versionados (gerados em runtime)

```
postgres_data/         â† Dados PostgreSQL
portainer_data/        â† Dados Portainer
redis_data/            â† Dados Redis
asterisk_logs/*.log    â† Logs Asterisk
asterisk_recordings/*  â† GravaÃ§Ãµes
```

---

## ðŸŽ¯ PrÃ³ximos Passos

ApÃ³s instalaÃ§Ã£o limpa e testes:

1. âœ… **Configurar 2 softphones** (1001 e 1002)
2. âœ… **Testar chamadas internas** (1001 â†’ 1002)
3. âœ… **Testar cÃ³digos de recursos** (*43, *97)
4. âœ… **Verificar CDRs no banco**
5. â­ï¸ **Desenvolver backend** .NET 10 API
6. â­ï¸ **Desenvolver frontend** Vue 3
7. â­ï¸ **Integrar** frontend â†” backend â†” Asterisk

---

## ðŸ“š DocumentaÃ§Ã£o Relacionada

- [DATABASE_RESET.md](./DATABASE_RESET.md) - Detalhes do schema do banco
- [CDR_DEPLOY.md](./CDR_DEPLOY.md) - ConfiguraÃ§Ã£o CDR PostgreSQL
- [CDR_QUERIES.md](./CDR_QUERIES.md) - 50+ consultas SQL Ãºteis
- [ASTERISK_CONFIG_INVENTORY.md](./ASTERISK_CONFIG_INVENTORY.md) - InventÃ¡rio de arquivos de config
- [PROXIMOS_PASSOS.md](./PROXIMOS_PASSOS.md) - Roadmap completo
- [SETUP_VM.md](./SETUP_VM.md) - Setup inicial da VM

---

## âœ… Checklist Final

- [ ] Backup da instalaÃ§Ã£o anterior feito
- [ ] RepositÃ³rio clonado do GitHub
- [ ] Imagem Asterisk compilada
- [ ] 5 containers rodando (asterisk, postgres, redis, traefik, portainer)
- [ ] Banco com 3 tenants, 5 ramais, 5 CDRs de exemplo
- [ ] MÃ³dulos `res_config_pgsql` e `cdr_pgsql` carregados
- [ ] Softphone registrado com sucesso
- [ ] *43 funciona e grava CDR
- [ ] Portainer acessÃ­vel em 9443
- [ ] Logs sem erros crÃ­ticos

---

**âœ¨ InstalaÃ§Ã£o limpa concluÃ­da! Agora vocÃª tem um ambiente consistente, reproduzÃ­vel e pronto para desenvolvimento.**

