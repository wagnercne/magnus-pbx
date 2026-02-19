#!/bin/bash
# ============================================================================
# SETUP AUTENTICAÇÃO DNS - MAGNUS PBX
# ============================================================================
# Este script configura o método de autenticação por DNS no MAGNUS PBX
# 
# Pré-requisitos:
#   - Docker e Docker Compose rodando
#   - Containers asterisk-magnus e postgres-magnus ativos
#   - MikroTik configurado com Static DNS (ver docs/MIKROTIK-CONFIG.md)
#
# Execução:
#   chmod +x scripts/setup-dns-auth.sh
#   ./scripts/setup-dns-auth.sh
# ============================================================================

set -e  # Parar em caso de erro

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     MAGNUS PBX - Configuração Autenticação DNS                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# 1. VERIFICAR CONTAINERS
# ============================================================================
echo -e "${BLUE}[1/5] Verificando containers...${NC}"
if ! docker ps | grep -q postgres-magnus; then
    echo -e "${RED}❌ Container postgres-magnus não está rodando!${NC}"
    exit 1
fi
if ! docker ps | grep -q asterisk-magnus; then
    echo -e "${RED}❌ Container asterisk-magnus não está rodando!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Containers ativos${NC}"
echo ""

# ============================================================================
# 2. BACKUP DO BANCO DE DADOS
# ============================================================================
echo -e "${BLUE}[2/5] Criando backup do banco de dados...${NC}"
BACKUP_FILE="backup-$(date +%Y%m%d-%H%M%S).sql"
docker exec postgres-magnus pg_dump -U admin_magnus magnus_pbx > "/tmp/$BACKUP_FILE" 2>/dev/null || true
if [ -f "/tmp/$BACKUP_FILE" ]; then
    echo -e "${GREEN}✅ Backup salvo: /tmp/$BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  Backup não criado (não crítico)${NC}"
fi
echo ""

# ============================================================================
# 3. EXECUTAR SCRIPT SQL
# ============================================================================
echo -e "${BLUE}[3/5] Atualizando banco de dados PostgreSQL...${NC}"
docker exec -i postgres-magnus psql -U admin_magnus -d magnus_pbx < scripts/configure-dns-auth.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Banco de dados atualizado com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao atualizar banco de dados${NC}"
    exit 1
fi
echo ""

# ============================================================================
# 4. RECARREGAR ASTERISK PJSIP
# ============================================================================
echo -e "${BLUE}[4/5] Recarregando configuração PJSIP do Asterisk...${NC}"
docker exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"
sleep 2
docker exec asterisk-magnus asterisk -rx "pjsip reload"
echo -e "${GREEN}✅ PJSIP recarregado${NC}"
echo ""

# ============================================================================
# 5. VERIFICAÇÕES
# ============================================================================
echo -e "${BLUE}[5/5] Verificando configuração...${NC}"
echo ""

echo -e "${YELLOW}═══ Domínios Configurados ═══${NC}"
docker exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, domain FROM ps_domain_aliases ORDER BY id;"
echo ""

echo -e "${YELLOW}═══ Endpoints e Autenticação ═══${NC}"
docker exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT e.id, a.username, e.context FROM ps_endpoints e LEFT JOIN ps_auths a ON e.id = a.id ORDER BY e.id;"
echo ""

echo -e "${YELLOW}═══ Status Endpoints PJSIP ═══${NC}"
docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"
echo ""

# ============================================================================
# RESUMO E PRÓXIMOS PASSOS
# ============================================================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   CONFIGURAÇÃO CONCLUÍDA! ✅                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 PRÓXIMOS PASSOS:${NC}"
echo ""
echo "1️⃣  Configurar MikroTik Static DNS:"
echo "   Copie e cole no terminal do MikroTik:"
echo ""
echo "   /ip dns set allow-remote-requests=yes"
echo "   /ip dns static add name=belavista.magnussystem.com.br address=10.3.2.253 ttl=5m"
echo "   /ip dns static add name=acme.magnussystem.com.br address=10.3.2.253 ttl=5m"
echo "   /ip dns static add name=techno.magnussystem.com.br address=10.3.2.253 ttl=5m"
echo "   /ip dns cache flush"
echo ""
echo "2️⃣  Testar resolução DNS (no seu PC/notebook):"
echo "   nslookup belavista.magnussystem.com.br"
echo "   Deve retornar: 10.3.2.253"
echo ""
echo "3️⃣  Configurar softphone (Linphone/Zoiper):"
echo ""
echo "   Servidor: belavista.magnussystem.com.br"
echo "   Usuário: 1002"
echo "   Senha: magnus123"
echo "   Porta: 5060"
echo "   Transporte: UDP"
echo ""
echo "4️⃣  Verificar registro:"
echo "   docker exec asterisk-magnus asterisk -rx \"pjsip show endpoints\""
echo ""
echo -e "${BLUE}📚 Documentação completa em:${NC}"
echo "   - docs/MIKROTIK-CONFIG.md (configuração MikroTik)"
echo "   - docs/MULTI-TENANT-CONFIG.md (entendimento da arquitetura)"
echo "   - CONFIG-MAGNUSSYSTEM.md (configuração específica)"
echo ""
echo -e "${GREEN}🎉 Sistema pronto para testes!${NC}"
echo ""
