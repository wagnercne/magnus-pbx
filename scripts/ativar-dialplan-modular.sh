#!/bin/bash
# ============================================
# ATIVAR DIALPLAN MODULAR
# Execute este script MANUALMENTE quando quiser migrar
# ============================================

echo "=========================================="
echo " ATIVANDO DIALPLAN MODULAR"
echo "=========================================="
echo ""

# 1. Verificar se os arquivos existem
echo "[1/5] Verificando arquivos..."
MISSING=0

if [ ! -f "asterisk_etc/extensions-modular.conf" ]; then
    echo "  ✗ extensions-modular.conf NÃO encontrado!"
    MISSING=1
fi

if [ ! -f "asterisk_etc/extensions-features.conf" ]; then
    echo "  ✗ extensions-features.conf NÃO encontrado!"
    MISSING=1
fi

if [ ! -f "asterisk_etc/routing.conf" ]; then
    echo "  ✗ routing.conf NÃO encontrado!"
    MISSING=1
fi

if [ ! -f "asterisk_etc/tenants.conf" ]; then
    echo "  ✗ tenants.conf NÃO encontrado!"
    MISSING=1
fi

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "ERRO: Arquivos modulares não encontrados na VM!"
    echo "Sincronize do Windows primeiro."
    exit 1
fi

echo "  ✓ Todos os arquivos encontrados!"

# 2. Backup do atual
echo ""
echo "[2/5] Fazendo backup do dialplan atual..."
if [ -f "asterisk_etc/extensions.conf" ]; then
    cp asterisk_etc/extensions.conf asterisk_etc/extensions.conf.backup.$(date +%Y%m%d_%H%M%S)
    echo "  ✓ Backup criado: extensions.conf.backup.$(date +%Y%m%d_%H%M%S)"
else
    echo "  ⚠️  extensions.conf não existe, nenhum backup necessário"
fi

# 3. Ativar o modular
echo ""
echo "[3/5] Ativando dialplan modular..."
cp asterisk_etc/extensions-modular.conf asterisk_etc/extensions.conf
echo "  ✓ extensions-modular.conf → extensions.conf"

# 4. Reiniciar Asterisk
echo ""
echo "[4/5] Reiniciando Asterisk..."
docker compose restart asterisk-magnus
sleep 8

# 5. Verificar se carregou
echo ""
echo "[5/5] Verificando dialplan..."
echo ""
echo "Contextos carregados:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep -E "ctx-|features-base|tenant-base|dial-"

echo ""
echo "Extensão *43:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

echo ""
echo "=========================================="
echo " MIGRAÇÃO CONCLUÍDA!"
echo "=========================================="
echo ""
echo "Para voltar ao anterior:"
echo "  cp asterisk_etc/extensions.conf.backup.* asterisk_etc/extensions.conf"
echo "  docker compose restart asterisk-magnus"
echo ""
