#!/bin/bash
# ============================================
# MAGNUS PBX - Docker Hub Push
# ============================================

set -e

# Configurações (ALTERAR PARA SEU USUÁRIO!)
DOCKER_USER="${DOCKER_USER:-wagnercne}"
IMAGE_NAME="magnus-pbx"
ASTERISK_VERSION="22"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════"
echo "  MAGNUS PBX - Docker Hub Deployment"
echo "════════════════════════════════════════"
echo ""
echo "Docker Hub User: $DOCKER_USER"
echo "Image Name: $IMAGE_NAME"
echo "Asterisk Version: $ASTERISK_VERSION (LTS current)"
echo ""

# 1. Verificar login
echo -e "${YELLOW}[1/6]${NC} Verificando login no Docker Hub..."
if ! docker info 2>/dev/null | grep -q "Username:"; then
    echo -e "${RED}❌ Não logado no Docker Hub${NC}"
    echo ""
    echo "Execute primeiro: ${GREEN}docker login${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Login OK${NC}"

# 2. Escolher Dockerfile
echo ""
echo -e "${YELLOW}[2/6]${NC} Escolher versão:"
echo "  1) Original (Dockerfile)"
echo "  2) Otimizada (Dockerfile.optimized)"
read -p "Opção [1-2]: " opcao

case $opcao in
    1)
        DOCKERFILE="Dockerfile"
        TAG_SUFFIX="latest"
        ;;
    2)
        DOCKERFILE="Dockerfile.optimized"
        TAG_SUFFIX="optimized"
        ;;
    *)
        echo -e "${RED}❌ Opção inválida${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}✅ Usando: $DOCKERFILE${NC}"

# 3. Build da imagem
echo ""
echo -e "${YELLOW}[3/6]${NC} Building imagem..."
echo "Tags que serão criadas:"
echo "  • $DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION-$TAG_SUFFIX"
echo "  • $DOCKER_USER/$IMAGE_NAME:$TAG_SUFFIX"
echo ""

docker build \
    -t "$DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION-$TAG_SUFFIX" \
    -t "$DOCKER_USER/$IMAGE_NAME:$TAG_SUFFIX" \
    -f "$DOCKERFILE" \
    .

echo -e "${GREEN}✅ Build concluído${NC}"

# 4. Verificar tamanho
echo ""
echo -e "${YELLOW}[4/6]${NC} Informações da imagem:"
docker images "$DOCKER_USER/$IMAGE_NAME" | head -4
echo ""

# 5. Confirmar push
echo -e "${YELLOW}[5/6]${NC} Pronto para fazer push para Docker Hub"
read -p "Continuar? [S/n]: " confirma

if [[ "$confirma" =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}ℹ️  Push cancelado. Imagem local criada.${NC}"
    exit 0
fi

# 6. Push para Docker Hub
echo ""
echo -e "${YELLOW}[6/6]${NC} Fazendo push para Docker Hub..."
echo "Isso pode levar 5-10 minutos..."
echo ""

docker push "$DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION-$TAG_SUFFIX"
docker push "$DOCKER_USER/$IMAGE_NAME:$TAG_SUFFIX"

echo -e "${GREEN}✅ Push concluído${NC}"

# Resumo
echo ""
echo "════════════════════════════════════════"
echo -e "${GREEN}✅ DEPLOY CONCLUÍDO!${NC}"
echo "════════════════════════════════════════"
echo ""
echo "📦 Imagens disponíveis:"
echo "  • docker pull $DOCKER_USER/$IMAGE_NAME:$ASTERISK_VERSION-$TAG_SUFFIX"
echo "  • docker pull $DOCKER_USER/$IMAGE_NAME:$TAG_SUFFIX"
echo ""
echo "🌐 Docker Hub:"
echo "  https://hub.docker.com/r/$DOCKER_USER/$IMAGE_NAME"
echo ""
echo "📝 Para usar em docker-compose.yml:"
echo "  asterisk-magnus:"
echo "    image: $DOCKER_USER/$IMAGE_NAME:$TAG_SUFFIX"
echo ""
echo "⚡ Deploy rápido:"
echo "  docker compose pull"
echo "  docker compose up -d"
echo ""
