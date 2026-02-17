#!/bin/bash
# =================================================================
# MAGNUS PBX - Instalação Limpa do Zero
# =================================================================
# Este script apaga TUDO e recria a partir do GitHub
# Use APENAS em ambiente de desenvolvimento/staging
# =================================================================

set -e  # Parar em caso de erro

REPO_URL="https://github.com/wagnercne/magnus-pbx.git"
INSTALL_PATH="/srv/magnus-pbx"
BACKUP_PATH="/tmp/magnus-pbx-backup-$(date +%Y%m%d-%H%M%S)"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  MAGNUS PBX - Instalação Limpa do Zero                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "⚠️  ATENÇÃO: Este script vai:"
echo "    1. Parar todos os containers Docker"
echo "    2. Remover volumes de dados (PostgreSQL, logs, etc)"
echo "    3. Apagar a pasta $INSTALL_PATH"
echo "    4. Clonar repositório do GitHub"
echo "    5. Criar banco de dados do zero"
echo ""
echo "📦 Backup será salvo em: $BACKUP_PATH"
echo ""
read -p "Tem certeza que deseja continuar? (digite 'LIMPAR' para confirmar): " confirmacao

if [ "$confirmacao" != "LIMPAR" ]; then
    echo "❌ Operação cancelada."
    exit 1
fi

# =================================================================
# PASSO 1: BACKUP (SEGURANÇA)
# =================================================================
echo ""
echo "[1/8] 💾 Fazendo backup de segurança..."
if [ -d "$INSTALL_PATH" ]; then
    cp -r "$INSTALL_PATH" "$BACKUP_PATH"
    echo "✅ Backup salvo em: $BACKUP_PATH"
else
    echo "⚠️  Pasta $INSTALL_PATH não existe. Pulando backup."
fi

# =================================================================
# PASSO 2: PARAR E REMOVER CONTAINERS
# =================================================================
echo ""
echo "[2/8] 🛑 Parando containers Docker..."
cd "$INSTALL_PATH" 2>/dev/null || true
docker compose down -v 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
echo "✅ Containers parados"

# =================================================================
# PASSO 3: LIMPAR INSTALAÇÃO ANTIGA
# =================================================================
echo ""
echo "[3/8] 🗑️  Removendo instalação antiga..."
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
    echo "✅ Pasta $INSTALL_PATH removida"
fi

# =================================================================
# PASSO 4: CLONAR REPOSITÓRIO DO GITHUB
# =================================================================
echo ""
echo "[4/8] 📥 Clonando repositório do GitHub..."
git clone "$REPO_URL" "$INSTALL_PATH"
cd "$INSTALL_PATH"
echo "✅ Repositório clonado"

# =================================================================
# PASSO 5: CRIAR ESTRUTURA DE PASTAS
# =================================================================
echo ""
echo "[5/8] 📁 Criando estrutura de pastas..."
mkdir -p postgres_data
mkdir -p portainer_data
mkdir -p redis_data
mkdir -p asterisk_logs
mkdir -p asterisk_recordings
mkdir -p custom_sounds

# Limpar logs antigos se existirem
rm -f asterisk_logs/*.log 2>/dev/null || true

# NOTA: Sons PT-BR já vêm no container. custom_sounds/ é para customizações opcionais
echo "✅ Estrutura criada"

# =================================================================
# PASSO 6: BUILD DA IMAGEM ASTERISK
# =================================================================
echo ""
echo "[6/8] 🔨 Compilando imagem Docker do Asterisk..."
echo "    ⏳ Isso pode levar 10-15 minutos na primeira vez..."
docker compose build asterisk-magnus
echo "✅ Imagem compilada"

# =================================================================
# PASSO 7: INICIAR SERVIÇOS
# =================================================================
echo ""
echo "[7/8] 🚀 Iniciando serviços..."
docker compose up -d

echo ""
echo "⏳ Aguardando PostgreSQL ficar pronto..."
sleep 5

# Aguardar PostgreSQL
for i in {1..30}; do
    if docker compose exec -T postgres-magnus pg_isready -U admin_magnus &>/dev/null; then
        echo "✅ PostgreSQL pronto!"
        break
    fi
    echo "   Tentativa $i/30..."
    sleep 2
done

echo ""
echo "⏳ Aguardando Asterisk iniciar..."
sleep 10

# Aguardar Asterisk
for i in {1..20}; do
    if docker compose exec asterisk-magnus asterisk -rx "core show version" &>/dev/null; then
        echo "✅ Asterisk pronto!"
        break
    fi
    echo "   Tentativa $i/20..."
    sleep 3
done

# =================================================================
# PASSO 8: VALIDAÇÃO
# =================================================================
echo ""
echo "[8/8] ✅ Validando instalação..."

echo ""
echo "📊 Status dos containers:"
docker compose ps

echo ""
echo "🔍 Verificando banco de dados..."
docker compose exec -T postgres-magnus psql -U admin_magnus -d magnus_pbx <<'EOSQL'
    SELECT 
        'Banco de Dados' as componente,
        COUNT(*) as tabelas,
        (SELECT COUNT(*) FROM tenants) as tenants,
        (SELECT COUNT(*) FROM ps_endpoints) as ramais,
        (SELECT COUNT(*) FROM cdr) as cdrs
    FROM pg_tables 
    WHERE schemaname = 'public';
EOSQL

echo ""
echo "🔍 Verificando módulos Asterisk..."
docker compose exec asterisk-magnus asterisk -rx "module show like res_config_pgsql"
docker compose exec asterisk-magnus asterisk -rx "module show like pbx_config"
docker compose exec asterisk-magnus asterisk -rx "module show like cdr_pgsql"

echo ""
echo "🔍 Verificando conectividade banco → asterisk..."
docker compose exec asterisk-magnus asterisk -rx "realtime load ps_endpoints all"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  ✅ INSTALAÇÃO LIMPA CONCLUÍDA COM SUCESSO!               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1️⃣  Acessar Portainer:"
echo "    https://$(hostname -I | awk '{print $1}'):9443"
echo ""
echo "2️⃣  Configurar softphone (exemplo):"
echo "    Servidor: $(hostname -I | awk '{print $1}'):5060"
echo "    Usuário: 1001"
echo "    Senha: magnus123"
echo "    Contexto: belavista"
echo ""
echo "3️⃣  Testar com *43 (echo test)"
echo ""
echo "4️⃣  Ver logs do Asterisk:"
echo "    docker compose logs -f asterisk-magnus"
echo ""
echo "5️⃣  Ver CDRs:"
echo "    docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c \"SELECT * FROM cdr_readable ORDER BY \\\"Data/Hora\\\" DESC LIMIT 5;\""
echo ""
echo "💾 Backup da instalação anterior em: $BACKUP_PATH"
echo "    (pode ser removido após testar: rm -rf $BACKUP_PATH)"
echo ""
echo "📚 Documentação completa em: doc/"
echo ""
