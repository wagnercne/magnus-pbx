# 🚀 Como Usar Docker Compose Otimizado

## 🎯 3 Formas de Usar os Arquivos Otimizados

---

## Opção 1: Flag `-f` (Mantém Originais Intactos) ✅

**Recomendado para testar sem alterar config atual.**

```bash
# Build da imagem otimizada
docker compose -f docker-compose.optimized.yml build asterisk-magnus

# Subir serviços
docker compose -f docker-compose.optimized.yml up -d

# Ver logs
docker compose -f docker-compose.optimized.yml logs -f asterisk-magnus

# Ver status
docker compose -f docker-compose.optimized.yml ps

# Parar
docker compose -f docker-compose.optimized.yml down

# Parar e remover volumes (cuidado!)
docker compose -f docker-compose.optimized.yml down -v
```

**Vantagem:** Não altera arquivos originais, pode testar lado a lado.  
**Desvantagem:** Precisa usar `-f` em todos os comandos.

---

## Opção 2: Substituir Arquivos (Mais Simples) ⭐

**Recomendado para ambiente de produção após testar.**

```bash
# 1. Backup dos originais
cp Dockerfile Dockerfile.original
cp docker-compose.yml docker-compose.original

# 2. Substituir pelos otimizados
cp Dockerfile.optimized Dockerfile
cp docker-compose.optimized.yml docker-compose.yml

# 3. Parar serviços antigos
docker compose down

# 4. Build da nova imagem
docker compose build --no-cache asterisk-magnus

# 5. Subir novos serviços
docker compose up -d

# 6. Verificar saúde
docker compose ps
```

**Comandos normais funcionam:**
```bash
docker compose logs -f asterisk-magnus   # ✅ Sem -f
docker compose ps                        # ✅ Sem -f
docker compose restart asterisk-magnus   # ✅ Sem -f
```

**Para reverter:**
```bash
docker compose down
cp Dockerfile.original Dockerfile
cp docker-compose.original docker-compose.yml
docker compose up -d
```

---

## Opção 3: Alias Bash (Conveniência)

**Recomendado para desenvolvimento com múltiplas versões.**

```bash
# Adicionar no ~/.bashrc ou ~/.zshrc
alias dco='docker compose -f docker-compose.optimized.yml'

# Recarregar shell
source ~/.bashrc

# Usar com comandos curtos
dco build asterisk-magnus
dco up -d
dco ps
dco logs -f asterisk-magnus
dco down
```

---

## 📊 Diferenças entre Original vs Otimizado

| Característica | Original | Otimizado |
|----------------|----------|-----------|
| **Dockerfile** | Single-stage | Multi-stage (builder + runtime) |
| **Tamanho imagem** | ~1.2 GB | ~800 MB (-30%) |
| **Usuário** | root | asterisk (UID 1000) |
| **Healthcheck** | Via compose | Nativo no Dockerfile |
| **Volumes** | Bind mounts | Named volumes |
| **IPs** | Dinâmicos | Fixos (172.20.0.x) |
| **Resource limits** | ❌ Não | ✅ CPU/RAM configurados |
| **Logging** | Ilimitado | Rotação automática |
| **Dependencies** | Simples | `service_healthy` conditions |

---

## 🔄 Migração: Original → Otimizado

### Passo 1: Testar Lado a Lado

```bash
# 1. Manter serviços originais rodando
docker compose ps

# 2. Build da versão otimizada (sem subir)
docker compose -f docker-compose.optimized.yml build asterisk-magnus

# 3. Ver tamanho das imagens
docker images | grep asterisk-magnus
```

### Passo 2: Parar Original e Subir Otimizado

```bash
# 1. Backup do banco (importante!)
docker compose exec postgres-magnus pg_dump -U admin_magnus magnus_pbx > backup_pre_migration.sql

# 2. Parar original (mantém volumes)
docker compose down

# 3. Subir otimizado
docker compose -f docker-compose.optimized.yml up -d

# 4. Aguardar inicialização
sleep 30

# 5. Validar
docker compose -f docker-compose.optimized.yml exec asterisk-magnus asterisk -rx "core show version"
docker compose -f docker-compose.optimized.yml exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT COUNT(*) FROM ps_endpoints;"
```

### Passo 3: Migrar Dados dos Volumes

**⚠️ IMPORTANTE:** O otimizado usa **named volumes**, não bind mounts!

```bash
# Se precisar migrar dados existentes:

# PostgreSQL (de ./postgres_data para named volume)
docker run --rm \
  -v $(pwd)/postgres_data:/source:ro \
  -v magnus-pbx_postgres_data:/target \
  alpine sh -c "cp -av /source/. /target/"

# Portainer (de ./portainer_data para named volume)
docker run --rm \
  -v $(pwd)/portainer_data:/source:ro \
  -v magnus-pbx_portainer_data:/target \
  alpine sh -c "cp -av /source/. /target/"
```

---

## ✅ Validação Pós-Migração

```bash
# 1. Todos serviços healthy?
docker compose -f docker-compose.optimized.yml ps
# Deve mostrar "(healthy)" para todos

# 2. Asterisk carregado?
docker compose -f docker-compose.optimized.yml exec asterisk-magnus asterisk -rx "core show version"
docker compose -f docker-compose.optimized.yml exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# 3. Banco de dados OK?
docker compose -f docker-compose.optimized.yml exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "\dt"
docker compose -f docker-compose.optimized.yml exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT * FROM ps_endpoints;"

# 4. Teste de ligação
# Registrar softphone (1001@belavista/magnus123)
# Discar *43 (echo test)

# 5. CDR gravando?
docker compose -f docker-compose.optimized.yml exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT COUNT(*) FROM cdr;"
```

---

## 🎯 Comandos Úteis

### Rebuild Completo

```bash
# Parar tudo
docker compose -f docker-compose.optimized.yml down -v

# Rebuild sem cache
docker compose -f docker-compose.optimized.yml build --no-cache

# Subir
docker compose -f docker-compose.optimized.yml up -d
```

### Ver Recursos Usados

```bash
# CPU e memória em tempo real
docker stats

# Resource limits configurados
docker compose -f docker-compose.optimized.yml config | grep -A5 "resources:"
```

### Ver Logs com Rotação

```bash
# Tamanho dos logs
du -sh /var/lib/docker/containers/*/

# Ver configuração de logging
docker inspect asterisk-magnus | jq '.[0].HostConfig.LogConfig'
```

### Healthchecks

```bash
# Ver status de saúde
docker compose -f docker-compose.optimized.yml ps

# Inspecionar healthcheck
docker inspect asterisk-magnus | jq '.[0].State.Health'

# Logs do healthcheck
docker inspect asterisk-magnus | jq '.[0].State.Health.Log'
```

---

## 🔧 Troubleshooting

### Build falha com "permission denied"

```bash
# Dar permissões corretas
chmod +x Dockerfile.optimized
sudo chown -R $USER:$USER .
```

### Named volumes não encontrados

```bash
# Criar volumes manualmente
docker volume create magnus-pbx_postgres_data
docker volume create magnus-pbx_portainer_data

# Listar volumes
docker volume ls | grep magnus
```

### IP fixo conflita

```bash
# Ver redes existentes
docker network ls
docker network inspect magnus-pbx_magnus-net

# Remover rede antiga
docker compose down
docker network rm magnus-pbx_magnus-net

# Recriar
docker compose -f docker-compose.optimized.yml up -d
```

### Container não fica healthy

```bash
# Ver logs do healthcheck
docker inspect asterisk-magnus | jq '.[0].State.Health.Log[-5:]'

# Testar comando manualmente
docker compose -f docker-compose.optimized.yml exec asterisk-magnus asterisk -rx "core show version"

# Aumentar start_period (editar docker-compose.optimized.yml)
healthcheck:
  start_period: 120s  # Era 60s
```

---

## 📝 Exemplo Completo: Migração em Produção

```bash
#!/bin/bash
set -e

echo "=== Migração para Docker Otimizado ==="

# 1. Backup
echo "[1/8] Backup do banco..."
docker compose exec -T postgres-magnus pg_dump -U admin_magnus magnus_pbx > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Backup configs
echo "[2/8] Backup de configs..."
tar -czf backup_configs_$(date +%Y%m%d_%H%M%S).tar.gz asterisk_etc/

# 3. Parar original
echo "[3/8] Parando serviços..."
docker compose down

# 4. Backup dos arquivos principais
echo "[4/8] Backup de Dockerfile e compose..."
cp Dockerfile Dockerfile.original
cp docker-compose.yml docker-compose.original

# 5. Substituir pelos otimizados
echo "[5/8] Ativando versões otimizadas..."
cp Dockerfile.optimized Dockerfile
cp docker-compose.optimized.yml docker-compose.yml

# 6. Build
echo "[6/8] Build da imagem otimizada (pode levar 10-15min)..."
docker compose build --no-cache asterisk-magnus

# 7. Subir
echo "[7/8] Iniciando serviços..."
docker compose up -d

# 8. Aguardar e validar
echo "[8/8] Aguardando inicialização..."
sleep 60

echo ""
echo "=== Validação ==="
docker compose ps
docker compose exec asterisk-magnus asterisk -rx "core show version"
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "SELECT COUNT(*) FROM ps_endpoints;"

echo ""
echo "✅ Migração concluída!"
echo "📊 Verifique tamanho: docker images | grep asterisk-magnus"
echo "📝 Teste: Registrar 1001 e discar *43"
```

---

## 🎁 Conclusão

**Para desenvolvimento local (Windows):**
- Use **Opção 1** (flag `-f`) para testar

**Para VM de staging/produção:**
- Use **Opção 2** (substituir arquivos) após testar

**Dica:** Sempre faça **backup do banco** antes de migrar!

```bash
# Backup rápido
docker compose exec postgres-magnus pg_dump -U admin_magnus magnus_pbx > backup.sql
```
