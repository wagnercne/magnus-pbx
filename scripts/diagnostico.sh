#!/bin/bash
# ============================================
# DIAGNÓSTICO COMPLETO DO ASTERISK
# ============================================

echo "=========================================="
echo " DIAGNÓSTICO - MAGNUS PBX"
echo "=========================================="
echo ""

# 1. Verificar se o arquivo extensions.conf existe no HOST
echo "[1/8] Arquivo extensions.conf no HOST:"
if [ -f "asterisk_etc/extensions.conf" ]; then
    echo "  ✓ Existe: $(ls -lh asterisk_etc/extensions.conf)"
    echo "  Linhas com ctx-belavista:"
    grep -n "ctx-belavista" asterisk_etc/extensions.conf
else
    echo "  ✗ NÃO EXISTE!"
fi

# 2. Verificar se o arquivo existe no CONTAINER
echo ""
echo "[2/8] Arquivo extensions.conf no CONTAINER:"
docker compose exec asterisk-magnus ls -lh /etc/asterisk/extensions.conf

# 3. Verificar conteúdo do arquivo no container
echo ""
echo "[3/8] Linhas com ctx-belavista no CONTAINER:"
docker compose exec asterisk-magnus grep -n "ctx-belavista" /etc/asterisk/extensions.conf

# 4. Verificar se modules.conf carrega pbx_config
echo ""
echo "[4/8] Configuração de módulos no CONTAINER:"
docker compose exec asterisk-magnus grep "pbx_config" /etc/asterisk/modules.conf

# 5. Verificar se o módulo está carregado
echo ""
echo "[5/8] Módulo pbx_config.so carregado:"
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

# 6. Listar TODOS os contextos
echo ""
echo "[6/8] Todos os contextos disponíveis:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts"

# 7. Verificar configuração do endpoint no banco
echo ""
echo "[7/8] Configuração do endpoint 1001@belavista no PostgreSQL:"
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, context, transport FROM ps_endpoints WHERE id LIKE '1001@%';"

# 8. Ver logs do Asterisk durante inicialização
echo ""
echo "[8/8] Últimas 30 linhas do log do Asterisk:"
docker compose logs --tail=30 asterisk-magnus | grep -E "pbx_config|extensions.conf|dialplan|ctx-"

echo ""
echo "=========================================="
echo " FIM DO DIAGNÓSTICO"
echo "=========================================="
