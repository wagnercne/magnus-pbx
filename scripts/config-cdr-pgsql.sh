#!/bin/bash
# ============================================
# CONFIGURAR CDR POSTGRESQL
# Configura gravação de CDR no banco de dados
# ============================================

echo "=========================================="
echo " CONFIGURAR CDR POSTGRESQL"
echo "=========================================="
echo ""

echo "[1/5] Criando tabela CDR no banco..."

docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -f /docker-entrypoint-initdb.d/04_create_cdr_table.sql

if [ $? -eq 0 ]; then
    echo "  ✓ Tabela CDR criada com sucesso"
else
    echo "  ℹ️  Tabela já existe (normal se já foi criada antes)"
fi

echo ""
echo "[2/5] Verificando configuração do Asterisk..."

# Verificar se arquivo existe
if docker compose exec asterisk-magnus test -f /etc/asterisk/cdr_pgsql.conf; then
    echo "  ✓ Arquivo cdr_pgsql.conf existe"
else
    echo "  ✗ Arquivo cdr_pgsql.conf NÃO encontrado!"
    echo "  Sincronize o arquivo do repositório para a VM"
    exit 1
fi

echo ""
echo "[3/5] Recarregando módulos CDR..."

docker compose exec asterisk-magnus asterisk -rx "module unload cdr_pgsql.so"
sleep 1
docker compose exec asterisk-magnus asterisk -rx "module load cdr_pgsql.so"
sleep 1
docker compose exec asterisk-magnus asterisk -rx "cdr show status"

echo ""
echo "[4/5] Testando conexão com banco..."

docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"

echo ""
echo "[5/5] Fazendo chamada teste para validar CDR..."

echo "  Aguardando 5 segundos..."
sleep 5

# Ver últimos registros do CDR
echo ""
echo "Últimos CDRs gravados:"
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT calldate, src, dst, disposition, duration FROM cdr ORDER BY calldate DESC LIMIT 5;"

echo ""
echo "=========================================="
echo " CONFIGURAÇÃO CONCLUÍDA!"
echo "=========================================="
echo ""
echo "CDR agora grava em PostgreSQL!"
echo ""
echo "Comandos úteis:"
echo "  # Ver últimos CDRs"
echo "  docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c \"SELECT * FROM cdr_readable LIMIT 10;\""
echo ""
echo "  # Contar chamadas por origem"
echo "  docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c \"SELECT src, COUNT(*) FROM cdr GROUP BY src;\""
echo ""
echo "  # Ver chamadas de hoje"
echo "  docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c \"SELECT * FROM cdr WHERE calldate::date = CURRENT_DATE;\""
echo ""
