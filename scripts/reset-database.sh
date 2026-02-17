#!/bin/bash
# =================================================================
# MAGNUS PBX - Reset Completo do Banco de Dados
# =================================================================
# Este script APAGA todos os dados e reconstrói o banco do zero
# Use com CUIDADO! Apenas em desenvolvimento.
# =================================================================

set -e  # Parar em caso de erro

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  MAGNUS PBX - Reset Completo do Banco de Dados            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  ATENÇÃO: Este script vai APAGAR todos os dados do banco!"
echo ""
read -p "Tem certeza que deseja continuar? (digite 'sim' para confirmar): " confirmacao

if [ "$confirmacao" != "sim" ]; then
    echo "❌ Operação cancelada."
    exit 1
fi

echo ""
echo "[1/5] Parando containers..."
docker compose down

echo ""
echo "[2/5] Removendo volume do banco de dados..."
sudo rm -rf postgres_data
mkdir -p postgres_data

echo ""
echo "[3/5] Iniciando PostgreSQL..."
docker compose up -d postgres-magnus

echo ""
echo "[4/5] Aguardando PostgreSQL ficar pronto..."
sleep 5

# Aguardar até o PostgreSQL aceitar conexões
for i in {1..30}; do
    if docker compose exec -T postgres-magnus pg_isready -U admin_magnus &>/dev/null; then
        echo "✅ PostgreSQL pronto!"
        break
    fi
    echo "   Tentativa $i/30..."
    sleep 2
done

echo ""
echo "[5/5] Scripts SQL sendo executados automaticamente..."
echo "   📄 01_init_schema.sql - Estrutura completa"
echo "   📄 02_sample_data.sql - Dados de exemplo"
sleep 3

echo ""
echo "✅ Banco de dados resetado com sucesso!"
echo ""
echo "📊 Verificando estrutura criada..."
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx <<'EOSQL'
    SELECT 
        schemaname,
        tablename,
        CASE 
            WHEN tablename IN ('tenants', 'ps_endpoints', 'ps_auths', 'ps_aors') THEN '🔐 PJSIP'
            WHEN tablename IN ('cdr', 'queue_log', 'gate_logs') THEN '📊 Relatórios'
            WHEN tablename IN ('queues', 'queue_members') THEN '📞 Filas'
            WHEN tablename = 'extensions' THEN '📋 Dialplan'
            ELSE '📦 Outros'
        END AS categoria
    FROM pg_tables 
    WHERE schemaname = 'public'
    ORDER BY categoria, tablename;
EOSQL

echo ""
echo "📋 Testando dados de exemplo..."
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT id, name, domain FROM tenants;"

echo ""
echo "🚀 Agora execute: docker compose up -d"
echo ""
