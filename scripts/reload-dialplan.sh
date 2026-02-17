#!/bin/bash
# ============================================
# RECARREGAR DIALPLAN NO ASTERISK
# ============================================

echo "Recarregando módulo pbx_config.so..."
docker compose exec asterisk-magnus asterisk -rx "module reload pbx_config.so"

echo ""
echo "Verificando se o módulo está carregado:"
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

echo ""
echo "Verificando extensão *43:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

echo ""
echo "✓ Dialplan recarregado!"
echo ""
echo "Agora teste discar *43 do ramal 1001@belavista"
