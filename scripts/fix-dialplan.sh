#!/bin/bash
# ============================================
# FIX DIALPLAN - Força recarga completa
# ============================================

echo "=========================================="
echo " CORRIGINDO DIALPLAN DO ASTERISK"
echo "=========================================="
echo ""

# 1. Reiniciar container (força leitura dos arquivos)
echo "[1/5] Reiniciando Asterisk..."
docker compose restart asterisk-magnus
sleep 8

# 2. Verificar se pbx_config carregou
echo ""
echo "[2/5] Verificando módulo pbx_config.so..."
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

# 3. Listar todos os contextos carregados
echo ""
echo "[3/5] Listando contextos disponíveis..."
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep -E "ctx-|tenant-base"

# 4. Mostrar o contexto ctx-belavista completo
echo ""
echo "[4/5] Conteúdo do contexto ctx-belavista:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# 5. Verificar especificamente o *43
echo ""
echo "[5/5] Verificando extensão *43:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

echo ""
echo "=========================================="
echo " DIAGNÓSTICO COMPLETO"
echo "=========================================="
echo ""
echo "Se o *43 não aparecer acima:"
echo "1. Verifique se asterisk_etc/extensions.conf existe"
echo "2. Execute: docker compose exec asterisk-magnus ls -la /etc/asterisk/extensions.conf"
echo "3. Execute: docker compose exec asterisk-magnus cat /etc/asterisk/extensions.conf | grep -A5 ctx-belavista"
echo ""
