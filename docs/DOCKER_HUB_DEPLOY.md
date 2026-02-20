# 🐳 Publicar Imagem no Docker Hub

## 🎯 Por Que Publicar a Imagem?

**Vantagens:**
- ⚡ **Deploy rápido** - Não precisa rebuildar (economiza 10-15 minutos)
- 🔄 **Recuperação** - Se a VM quebrar, `docker pull` e pronto
- 📦 **Versionamento** - Tags para cada versão (22.0, 22.1, latest)
- 🌍 **Multi-servidor** - Usar mesma imagem em dev/staging/prod
- 💾 **Backup** - Imagem segura no Docker Hub

---

## 📋 Pré-requisitos

### 1. Criar Conta no Docker Hub

```bash
# Acessar: https://hub.docker.com/signup
# Criar conta gratuita (1 repositório privado + ilimitados públicos)
```

### 2. Login no Docker

```bash
# Na sua máquina local (Windows) ou na VM
docker login

# Digitar:
# Username: seu_usuario
# Password: sua_senha

# Ou usar token (mais seguro):
# 1. Docker Hub → Account Settings → Security → New Access Token
# 2. docker login -u seu_usuario
# 3. Colar o token como senha
```

---

## 🚀 Método 1: Build e Push Manual

### Passo 1: Build da Imagem

```bash
cd /srv/magnus-pbx  # Na VM
# ou
cd C:\DEV\PROJETOS\MAGNUS-PBX  # No Windows

# Build com tag para Docker Hub
docker build -t wagnercne/magnus-pbx:22-latest -f Dockerfile .

# Ou versão otimizada
docker build -t wagnercne/magnus-pbx:22-optimized -f Dockerfile.optimized .

# Ou com múltiplas tags
docker build -t wagnercne/magnus-pbx:22.1.0 \
             -t wagnercne/magnus-pbx:22-latest \
             -t wagnercne/magnus-pbx:latest \
             -f Dockerfile .
```

**⚠️ Nota:** Substitua `wagnercne` pelo seu usuário do Docker Hub!

### Passo 2: Verificar Imagem

```bash
# Ver imagens locais
docker images | grep magnus-pbx

# Deve mostrar:
# wagnercne/magnus-pbx   22-latest      abc123def456   2 minutes ago   1.2GB
```

### Passo 3: Push para Docker Hub

```bash
# Push de uma tag
docker push wagnercne/magnus-pbx:22-latest

# Ou push de todas as tags
docker push wagnercne/magnus-pbx:22.1.0
docker push wagnercne/magnus-pbx:22-latest
docker push wagnercne/magnus-pbx:latest
```

**⏳ Tempo:** ~5-10 minutos (primeira vez), ~1-2 minutos (updates)

### Passo 4: Verificar no Docker Hub

```bash
# Abrir navegador:
https://hub.docker.com/r/wagnercne/magnus-pbx

# Deve ver a imagem listada com tags
```

---

## 🤖 Método 2: Script Automatizado (Recomendado)

### Script: `scripts/docker-hub-push.sh`

```bash
#!/bin/bash
# ============================================
# MAGNUS PBX - Docker Hub Push
# ============================================

set -e

# Configurações
DOCKER_USER="wagnercne"
IMAGE_NAME="magnus-pbx"
ASTERISK_VERSION="22.1.0"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "════════════════════════════════════════"
echo "  MAGNUS PBX - Docker Hub Deployment"
echo "════════════════════════════════════════"
echo ""

# 1. Verificar login
echo -e "${YELLOW}[1/5]${NC} Verificando login no Docker Hub..."
if ! docker info | grep -q "Username: $DOCKER_USER"; then
    echo -e "${RED}❌ Não logado no Docker Hub${NC}"
    echo "Execute: docker login"
    exit 1
fi
echo -e "${GREEN}✅ Login OK${NC}"

# 2. Build da imagem
echo ""
echo -e "${YELLOW}[2/5]${NC} Building imagem..."
echo "Tag: $DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION"
docker build \
    -t "$DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION" \
    -t "$DOCKER_USER/$IMAGE_NAME:22-latest" \
    -t "$DOCKER_USER/$IMAGE_NAME:latest" \
    -f Dockerfile \
    .

echo -e "${GREEN}✅ Build concluído${NC}"

# 3. Verificar tamanho
echo ""
echo -e "${YELLOW}[3/5]${NC} Verificando tamanho da imagem..."
docker images | grep "$DOCKER_USER/$IMAGE_NAME"

# 4. Push para Docker Hub
echo ""
echo -e "${YELLOW}[4/5]${NC} Fazendo push para Docker Hub..."
docker push "$DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION"
docker push "$DOCKER_USER/$IMAGE_NAME:22-latest"
docker push "$DOCKER_USER/$IMAGE_NAME:latest"

echo -e "${GREEN}✅ Push concluído${NC}"

# 5. Resumo
echo ""
echo "════════════════════════════════════════"
echo -e "${GREEN}✅ DEPLOY CONCLUÍDO!${NC}"
echo "════════════════════════════════════════"
echo ""
echo "📦 Imagens disponíveis:"
echo "  • docker pull $DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION"
echo "  • docker pull $DOCKER_USER/$IMAGE_NAME:22-latest"
echo "  • docker pull $DOCKER_USER/$IMAGE_NAME:latest"
echo ""
echo "🌐 Docker Hub:"
echo "  https://hub.docker.com/r/$DOCKER_USER/$IMAGE_NAME"
echo ""
```

### Usar o Script

```bash
# Dar permissão
chmod +x scripts/docker-hub-push.sh

# Executar
./scripts/docker-hub-push.sh
```

---

## 📥 Usar Imagem Publicada

### Opção 1: Alterar docker-compose.yml

```yaml
services:
  asterisk-magnus:
    # ANTES: Build local
    # build: .
    
    # DEPOIS: Pull do Docker Hub
    image: wagnercne/magnus-pbx:22-latest
    
    container_name: asterisk-magnus
    # ... resto da configuração
```

### Opção 2: Pull Manual e Deploy

```bash
# 1. Pull da imagem
docker pull wagnercne/magnus-pbx:22-latest

# 2. Tag local (se quiser usar nome diferente)
docker tag wagnercne/magnus-pbx:22-latest magnus-pbx/asterisk:22-latest

# 3. Subir serviços
docker compose up -d
```

### Opção 3: Deploy Rápido em Nova VM

```bash
# 1. Clonar repo (apenas para configs e compose)
git clone https://github.com/wagnercne/magnus-pbx.git /srv/magnus-pbx
cd /srv/magnus-pbx

# 2. Alterar docker-compose.yml para usar imagem publicada
sed -i 's/build: ./image: wagnercne\/magnus-pbx:22-latest/' docker-compose.yml
sed -i '/dockerfile:/d' docker-compose.yml

# 3. Criar pastas
mkdir -p postgres_data portainer_data redis_data asterisk_logs asterisk_recordings custom_sounds

# 4. Deploy (SEM BUILD!)
docker compose up -d

# ⚡ Tempo: ~2 minutos (vs 15 minutos com build)
```

---

## 🏷️ Estratégia de Tags

### Tags Recomendadas

```bash
# 1. Versão específica (ex: 22.1.0)
docker tag local/asterisk wagnercne/magnus-pbx:22.1.0

# 2. Versão major.minor (ex: 22-latest)
docker tag local/asterisk wagnercne/magnus-pbx:22-latest

# 3. Latest (sempre aponta para última stable)
docker tag local/asterisk wagnercne/magnus-pbx:latest

# 4. Ambientes diferentes
docker tag local/asterisk wagnercne/magnus-pbx:dev
docker tag local/asterisk wagnercne/magnus-pbx:staging
docker tag local/asterisk wagnercne/magnus-pbx:prod

# 5. Data (para backups)
docker tag local/asterisk wagnercne/magnus-pbx:20260217
```

### Exemplo Completo

```bash
# Build com múltiplas tags
docker build \
  -t wagnercne/magnus-pbx:22.1.0 \
  -t wagnercne/magnus-pbx:22-latest \
  -t wagnercne/magnus-pbx:latest \
  -t wagnercne/magnus-pbx:prod-20260217 \
  -f Dockerfile .

# Push todas
docker push wagnercne/magnus-pbx:22.1.0
docker push wagnercne/magnus-pbx:22-latest
docker push wagnercne/magnus-pbx:latest
docker push wagnercne/magnus-pbx:prod-20260217
```

---

## 🔒 Repositório Privado vs Público

### Público (Gratuito)

```bash
# ✅ Vantagens:
# - Ilimitados repositórios
# - Pull ilimitado
# - Grátis

# ❌ Desvantagens:
# - Qualquer um pode ver/baixar
# - Configs ficam expostas (se tiver no Dockerfile)

# Uso: Projetos open-source, demos
```

### Privado (1 grátis, depois pago)

```bash
# ✅ Vantagens:
# - Restrito a sua conta
# - Seguro para produção
# - 1 repositório privado grátis

# ❌ Desvantagens:
# - Precisa login para pull
# - Apenas 1 grátis (depois $5/mês)

# Uso: Produção, staging
```

**Como tornar privado:**
```
1. Docker Hub → Repositories → magnus-pbx → Settings
2. Visibility → Make Private
```

---

## 🔄 Atualizar Imagem Publicada

### Quando Atualizar?

- ✅ Correção de bugs no Dockerfile
- ✅ Nova versão do Asterisk
- ✅ Novos módulos/codecs
- ✅ Otimizações de tamanho
- ❌ Mudanças apenas em configs (use volumes)

### Processo de Atualização

```bash
# 1. Fazer mudanças no Dockerfile
vim Dockerfile

# 2. Rebuild com nova tag
docker build -t wagnercne/magnus-pbx:22.1.1 -f Dockerfile .

# 3. Tag como latest também
docker tag wagnercne/magnus-pbx:22.1.1 wagnercne/magnus-pbx:latest

# 4. Push ambas
docker push wagnercne/magnus-pbx:22.1.1
docker push wagnercne/magnus-pbx:latest

# 5. Atualizar VMs
# VM 1:
docker pull wagnercne/magnus-pbx:latest
docker compose up -d

# VM 2, 3, 4...
# Mesmos comandos
```

---

## 📊 Comparação: Build Local vs Docker Hub

| Aspecto | Build Local | Pull Docker Hub |
|---------|-------------|-----------------|
| **Tempo primeira vez** | 15-20 min | 2-3 min |
| **Tempo updates** | 15-20 min | 30 seg - 2 min |
| **CPU/RAM usado** | Alto | Baixo |
| **Espaço disco** | 3GB (cache) | 1.2GB (imagem) |
| **Dependências** | gcc, libs, internet | Apenas internet |
| **Reprodutibilidade** | ⚠️ Depende da VM | ✅ Idêntica sempre |
| **Rollback** | ❌ Difícil | ✅ Fácil (tags) |

---

## 💡 Dicas e Best Practices

### 1. Multi-Stage Build no Hub

```bash
# Push apenas a imagem final (stage 2), não o builder
docker build -t wagnercne/magnus-pbx:22-optimized -f Dockerfile.optimized .
docker push wagnercne/magnus-pbx:22-optimized

# Stage 1 (builder) fica local, não vai para o hub
```

### 2. Labels e Metadata

```dockerfile
# Adicionar no Dockerfile
LABEL maintainer="wagner@exemplo.com"
LABEL version="22.1.0"
LABEL description="Magnus PBX - Asterisk 22 + PostgreSQL + WebRTC"
LABEL org.opencontainers.image.source="https://github.com/wagnercne/magnus-pbx"
```

### 3. README no Docker Hub

```markdown
# Criar arquivo README-DOCKERHUB.md

# Magnus PBX - Asterisk 22

Multi-tenant PBX com Asterisk 22, PostgreSQL, WebRTC e G.729

## Quick Start

\`\`\`bash
docker run -d \\
  --name asterisk \\
  -p 5060:5060/udp \\
  -p 8089:8089 \\
  wagnercne/magnus-pbx:latest
\`\`\`

## With docker-compose

\`\`\`yaml
services:
  asterisk:
    image: wagnercne/magnus-pbx:latest
    ports:
      - "5060:5060/udp"
      - "8089:8089"
\`\`\`

📖 Full docs: https://github.com/wagnercne/magnus-pbx
```

Depois no Docker Hub → Edit Repository → Description → Copiar conteúdo

### 4. CI/CD Automático (GitHub Actions)

```yaml
# .github/workflows/docker-publish.yml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: wagnercne/magnus-pbx:latest
```

---

## 🐛 Troubleshooting

### Erro: "denied: requested access to the resource is denied"

```bash
# Causa: Não está logado ou não tem permissão
# Solução:
docker logout
docker login
# Digite username e password corretos
```

### Erro: "no basic auth credentials"

```bash
# Causa: Repositório é privado mas não está logado
# Solução:
docker login
docker pull wagnercne/magnus-pbx:latest
```

### Push muito lento

```bash
# Causa: Imagem muito grande ou internet lenta
# Solução 1: Usar imagem otimizada (800MB vs 1.2GB)
docker push wagnercne/magnus-pbx:22-optimized

# Solução 2: Comprimir layers
docker build --squash -t wagnercne/magnus-pbx:22-compact .
```

### Imagem não aparece no Docker Hub

```bash
# Causa: Nome errado (tem que ser username/repo:tag)
# ERRADO:
docker push magnus-pbx:latest  # ❌

# CERTO:
docker push wagnercne/magnus-pbx:latest  # ✅
```

---

## ✅ Checklist Completo

- [ ] Conta criada no Docker Hub
- [ ] Login feito (`docker login`)
- [ ] Dockerfile corrigido (libncurses-dev)
- [ ] Build local testado e funcionando
- [ ] Imagem taggeada corretamente (username/repo:tag)
- [ ] Push para Docker Hub realizado
- [ ] Verificado no hub.docker.com
- [ ] docker-compose.yml atualizado (image: wagnercne/...)
- [ ] Testado pull e deploy em máquina limpa
- [ ] README.md atualizado com instruções de uso

---

## 🎯 Exemplo Completo: Do Zero ao Hub

```bash
# 1. Login
docker login

# 2. Build (Windows ou VM)
cd /srv/magnus-pbx  # Ou C:\DEV\PROJETOS\MAGNUS-PBX
docker build -t wagnercne/magnus-pbx:22.1.0 \
             -t wagnercne/magnus-pbx:22-latest \
             -t wagnercne/magnus-pbx:latest \
             -f Dockerfile .

# 3. Verificar
docker images | grep magnus-pbx

# 4. Push
docker push wagnercne/magnus-pbx:22.1.0
docker push wagnercne/magnus-pbx:22-latest
docker push wagnercne/magnus-pbx:latest

# 5. Limpar imagens locais (opcional)
docker rmi wagnercne/magnus-pbx:22.1.0
docker rmi wagnercne/magnus-pbx:22-latest  
docker rmi wagnercne/magnus-pbx:latest

# 6. Testar pull
docker pull wagnercne/magnus-pbx:latest

# 7. Deploy com imagem do hub
cd /srv/magnus-pbx
# Editar docker-compose.yml:
#   asterisk-magnus:
#     image: wagnercne/magnus-pbx:latest
docker compose up -d

# ✅ Pronto! Deploy em 2 minutos
```

---

**🎉 Benefício:** VM quebrou? `docker compose up -d` e o sistema volta em **2 minutos** (vs 15-20 min de build).
