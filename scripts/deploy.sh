#!/bin/bash
# ============================================
# MAGNUS PBX - Script de Implantação
# Bash para Linux/WSL
# ============================================

set -e

echo "========================================"
echo " MAGNUS PBX - Aplicar Correções"
echo "========================================"
echo ""

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "ERRO: Execute este script na pasta MAGNUS-PBX"
    exit 1
fi

# Passo 1: Parar Asterisk
echo "[1/7] Parando Asterisk..."
docker compose stop asterisk-magnus
sleep 2

# Passo 2: Corrigir contextos no banco
echo "[2/7] Corrigindo contextos no banco de dados..."

SQL=$(cat <<'EOF'
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
EOF
)

echo "Executando SQL..."
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c "$SQL"

# Passo 3: Verificar tabelas
echo ""
echo "[3/7] Verificando estrutura do banco..."

CHECK_SQL=$(cat <<'EOF'
SELECT 
    (SELECT COUNT(*) FROM tenants WHERE is_active = true) as tenants_ativos,
    (SELECT COUNT(*) FROM ps_endpoints) as total_endpoints,
    (SELECT COUNT(*) FROM ps_auths) as total_auths,
    (SELECT COUNT(*) FROM ps_aors) as total_aors;
EOF
)

docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c "$CHECK_SQL"

# Passo 4: Iniciar Asterisk
echo ""
echo "[4/7] Iniciando Asterisk..."
docker compose start asterisk-magnus
sleep 5

# Passo 5: Verificar módulos carregados
echo ""
echo "[5/7] Verificando módulos do Asterisk..."
echo "  - res_config_pgsql.so"
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"

echo "  - pbx_config.so"
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"

echo "  - cdr_pgsql.so"
docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"

# Passo 6: Recarregar dialplan
echo ""
echo "[6/7] Recarregando dialplan..."
docker compose exec asterisk-magnus asterisk -rx "module reload pbx_config.so"
sleep 2

# Passo 7: Verificar dialplan
echo ""
echo "[7/7] Verificando dialplan..."
echo "  Listando contextos disponíveis:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep -E "ctx-|tenant-base" || echo "  ⚠️  Nenhum contexto encontrado!"

echo ""
echo "  Conteúdo completo do ctx-belavista:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista" || echo "  ⚠️  Contexto ctx-belavista NÃO encontrado!"

echo ""
echo "  Verificando extensão *43:"
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista" || echo "  ⚠️  Extensão *43 NÃO encontrada!"

# Resumo
echo ""
echo "========================================"
echo " Implantação Concluída!"
echo "========================================"
echo ""

echo "Próximos passos:"
echo "1. Configure um softphone (ver CONFIGURACAO_SOFTPHONES.md)"
echo "2. Registre o ramal 1001@belavista"
echo "3. Disque *43 para testar o Echo"
echo ""

echo "Comandos úteis:"
echo "  docker compose logs -f asterisk-magnus    # Ver logs"
echo "  docker compose exec asterisk-magnus asterisk -r  # CLI do Asterisk"
echo ""

echo "Documentação:"
echo "  README.md - Visão geral"
echo "  GUIA_DE_TESTES.md - Testes passo a passo"
echo "  DIAGNOSTICO_E_SOLUCAO.md - Detalhes técnicos"
echo ""
