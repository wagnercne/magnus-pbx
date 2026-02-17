# ============================================
# MAGNUS PBX - Script de Implantação
# PowerShell para Windows
# ============================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " MAGNUS PBX - Aplicar Correções" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está no diretório correto
if (-Not (Test-Path "docker-compose.yml")) {
    Write-Host "ERRO: Execute este script na pasta MAGNUS-PBX" -ForegroundColor Red
    exit 1
}

# Passo 1: Parar Asterisk
Write-Host "[1/7] Parando Asterisk..." -ForegroundColor Yellow
docker compose stop asterisk-magnus
Start-Sleep -Seconds 2

# Passo 2: Corrigir contextos no banco
Write-Host "[2/7] Corrigindo contextos no banco de dados..." -ForegroundColor Yellow

$sql = @"
-- Corrigir contextos dos endpoints
UPDATE ps_endpoints e
SET context = 'ctx-' || split_part(e.id, '@', 2),
    transport = 'transport-udp'
WHERE e.id LIKE '%@%';

-- Verificar resultado
SELECT 
    id as endpoint, 
    context, 
    transport,
    CASE 
        WHEN context LIKE 'ctx-%' THEN '✓ OK'
        ELSE '✗ ERRO'
    END as status
FROM ps_endpoints
ORDER BY id;
"@

Write-Host "Executando SQL..." -ForegroundColor Gray
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c $sql

# Passo 3: Verificar tabelas
Write-Host ""
Write-Host "[3/7] Verificando estrutura do banco..." -ForegroundColor Yellow

$checkSql = @"
SELECT 
    (SELECT COUNT(*) FROM tenants WHERE is_active = true) as tenants_ativos,
    (SELECT COUNT(*) FROM ps_endpoints) as total_endpoints,
    (SELECT COUNT(*) FROM ps_auths) as total_auths,
    (SELECT COUNT(*) FROM ps_aors) as total_aors;
"@

docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c $checkSql

# Passo 4: Iniciar Asterisk
Write-Host ""
Write-Host "[4/7] Iniciando Asterisk..." -ForegroundColor Yellow
docker compose start asterisk-magnus
Start-Sleep -Seconds 5

# Passo 5: Verificar módulos carregados
Write-Host ""
Write-Host "[5/7] Verificando módulos do Asterisk..." -ForegroundColor Yellow
Write-Host "  - res_config_pgsql.so" -ForegroundColor Gray
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"

Write-Host "  - pbx_config.so" -ForegroundColor Gray
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

# Passo 6: Recarregar dialplan
Write-Host ""
Write-Host "[6/7] Recarregando dialplan..." -ForegroundColor Yellow
docker compose exec asterisk-magnus asterisk -rx "module reload pbx_config.so"
Start-Sleep -Seconds 2

# Passo 7: Verificar dialplan
Write-Host ""
Write-Host "[7/7] Verificando dialplan..." -ForegroundColor Yellow
Write-Host "  Contexto: ctx-belavista" -ForegroundColor Gray
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista" | Select-String -Pattern "\*43"

# Resumo
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Implantação Concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Configure um softphone (ver CONFIGURACAO_SOFTPHONES.md)" -ForegroundColor White
Write-Host "2. Registre o ramal 1001@belavista" -ForegroundColor White
Write-Host "3. Disque *43 para testar o Echo" -ForegroundColor White
Write-Host ""

Write-Host "Comandos úteis:" -ForegroundColor Cyan
Write-Host "  docker compose logs -f asterisk-magnus    # Ver logs" -ForegroundColor White
Write-Host "  docker compose exec asterisk-magnus asterisk -r  # CLI do Asterisk" -ForegroundColor White
Write-Host ""

Write-Host "Documentação:" -ForegroundColor Cyan
Write-Host "  README.md - Visão geral" -ForegroundColor White
Write-Host "  GUIA_DE_TESTES.md - Testes passo a passo" -ForegroundColor White
Write-Host "  DIAGNOSTICO_E_SOLUCAO.md - Detalhes técnicos" -ForegroundColor White
Write-Host ""
