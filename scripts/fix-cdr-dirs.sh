#!/bin/bash
# ============================================
# CORRIGIR DIRETÓRIOS DO ASTERISK
# Cria diretórios faltantes para CDR e logs
# ============================================

echo "=========================================="
echo " CORRIGINDO DIRETÓRIOS DO ASTERISK"
echo "=========================================="
echo ""

echo "[1/3] Criando diretórios de logs..."

# Entrar no container e criar diretórios
docker compose exec asterisk-magnus bash -c "
    mkdir -p /var/log/asterisk/cdr-csv
    mkdir -p /var/log/asterisk/cdr
    mkdir -p /var/spool/asterisk/monitor
    mkdir -p /var/spool/asterisk/voicemail
    
    # Dar permissões corretas
    chown -R asterisk:asterisk /var/log/asterisk
    chown -R asterisk:asterisk /var/spool/asterisk
    chmod -R 755 /var/log/asterisk
    chmod -R 755 /var/spool/asterisk
"

echo "  ✓ Diretórios criados"

echo ""
echo "[2/3] Verificando diretórios..."

docker compose exec asterisk-magnus bash -c "
    ls -la /var/log/asterisk/
    echo ''
    ls -la /var/spool/asterisk/
"

echo ""
echo "[3/3] Recarregando módulo CDR..."

docker compose exec asterisk-magnus asterisk -rx "module reload cdr_csv.so"

echo ""
echo "=========================================="
echo " CORREÇÃO CONCLUÍDA!"
echo "=========================================="
echo ""
echo "Teste novamente o *43. Os erros devem sumir."
echo ""
