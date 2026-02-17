# ============================================
# RECARREGAR DIALPLAN NO ASTERISK
# ============================================

Write-Host "Recarregando módulo pbx_config.so..." -ForegroundColor Yellow
docker compose exec asterisk-magnus asterisk -rx "module reload pbx_config.so"

Write-Host ""
Write-Host "Verificando se o módulo está carregado:" -ForegroundColor Cyan
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

Write-Host ""
Write-Host "Verificando extensão *43:" -ForegroundColor Cyan
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

Write-Host ""
Write-Host "✓ Dialplan recarregado!" -ForegroundColor Green
Write-Host ""
Write-Host "Agora teste discar *43 do ramal 1001@belavista" -ForegroundColor Yellow
