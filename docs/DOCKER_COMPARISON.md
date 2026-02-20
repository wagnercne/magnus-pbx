# 🔄 Dockerfile e Docker Compose: Original vs Otimizado

## 📊 Comparação

| Aspecto | Original | Otimizado |
|---------|----------|-----------|
| **Tamanho da imagem** | ~1.2 GB | ~800 MB |
| **Build time** | ~15 min | ~15 min |
| **Layers** | Single-stage | Multi-stage |
| **Cache** | Limitado | Otimizado |
| **Segurança** | root user | asterisk user |
| **Healthchecks** | Não | Sim |
| **Resource limits** | Não | Sim |
| **IPs fixos** | Não | Sim |
| **Volumes** | Bind mounts | Named volumes |

---

## 📁 Dockerfile.optimized

### ✅ Melhorias

1. **Multi-stage build**
   - Stage 1 (builder): Compilação
   - Stage 2 (runtime): Executável final
   - Resultado: Imagem ~30% menor

2. **Usuário não-root**
   - Executa como `USER asterisk`
   - Mais seguro

3. **Healthcheck nativo**
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=10s \
       CMD asterisk -rx "core show version" || exit 1
   ```

4. **Versão específica**
   ```dockerfile
   ENV ASTERISK_VERSION=22.1.0
   ```

5. **Melhor cache de layers**
   - Dependências separadas de código
   - Rebuild mais rápido

### 🔄 Como Migrar

```bash
# Opção 1: Renomear (recomendado para testes)
mv Dockerfile Dockerfile.old
mv Dockerfile.optimized Dockerfile

# Opção 2: Editar docker-compose.yml
# Alterar: dockerfile: Dockerfile.optimized

# Build
docker compose build --no-cache asterisk-magnus
```

---

## 🐳 docker-compose.optimized.yml

### ✅ Melhorias

1. **Named volumes ao invés de bind mounts**
   ```yaml
   volumes:
     postgres_data:
       driver: local
   
   services:
     postgres-magnus:
       volumes:
         - postgres_data:/var/lib/postgresql/data  # ← Named volume
   ```

   **Vantagens:**
   - Gerenciamento pelo Docker
   - Backup/restore mais fácil
   - Melhor performance

2. **IPs fixos**
   ```yaml
   networks:
     magnus-net:
       ipam:
         config:
           - subnet: 172.20.0.0/16
   
   postgres-magnus:
     networks:
       magnus-net:
         ipv4_address: 172.20.0.2  # ← IP fixo
   ```

   **Vantagens:**
   - Firewall rules consistentes
   - Troubleshooting mais fácil
   - DNS interno previsível

3. **Healthchecks para todos os serviços**
   ```yaml
   postgres-magnus:
     healthcheck:
       test: ["CMD-SHELL", "pg_isready -U admin_magnus"]
       interval: 10s
       timeout: 5s
       retries: 5
   ```

4. **Resource limits**
   ```yaml
   asterisk-magnus:
     deploy:
       resources:
         limits:
           cpus: '2'
           memory: 2G
         reservations:
           cpus: '0.5'
           memory: 512M
   ```

5. **Logging configurado**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "50m"
       max-file: "5"
   ```

   **Previne logs enchendo o disco**

6. **Dependency conditions**
   ```yaml
   asterisk-magnus:
     depends_on:
       postgres-magnus:
         condition: service_healthy  # ← Aguarda ficar healthy
   ```

7. **Restart policies**
   ```yaml
   restart: unless-stopped  # ← Mais seguro que 'always'
   ```

8. **Environment variables**
   ```yaml
   environment:
     POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-magnus123}
   ```

   Suporta `.env` file

### 🔄 Como Migrar

```bash
# Opção 1: Substituir (backup primeiro)
cp docker-compose.yml docker-compose.yml.old
mv docker-compose.optimized.yml docker-compose.yml

# Opção 2: Usar arquivo específico
docker compose -f docker-compose.optimized.yml up -d

# IMPORTANTE: Volumes named precisam migração
docker compose down
docker volume create postgres_data
docker volume create portainer_data
# Copiar dados dos bind mounts para volumes
sudo cp -r ./postgres_data/* /var/lib/docker/volumes/postgres_data/_data/
```

---

## ⚖️ Qual Usar?

### Use **Original** se:
- ✅ Desenvolvimento local rápido
- ✅ Precisa editar configs e ver mudanças imediatas
- ✅ Backup manual dos dados
- ✅ Single-machine setup

### Use **Otimizado** se:
- ✅ Produção ou Staging
- ✅ Performance é crítica
- ✅ Segurança é prioridade
- ✅ Gerenciamento Docker nativo
- ✅ Cluster/swarm no futuro

---

## 🔄 Migração Gradual (Recomendado)

### Etapa 1: Testar Dockerfile.optimized

```bash
# Build com nome diferente
docker build -f Dockerfile.optimized -t magnus-pbx/asterisk:22-optimized .

# Testar
docker run -it --rm magnus-pbx/asterisk:22-optimized asterisk -rx "core show version"
```

### Etapa 2: Testar docker-compose.optimized.yml

```bash
# Subir em paralelo (portas diferentes)
docker compose -f docker-compose.optimized.yml up -d

# Testar funcionalidades
# ...

# Se OK, parar e migrar definitivo
docker compose -f docker-compose.optimized.yml down
cp docker-compose.yml docker-compose.yml.old
mv docker-compose.optimized.yml docker-compose.yml
```

### Etapa 3: Migrar Dados

```bash
# Se usar Named Volumes, migrar dados:
./scripts/migrate-to-named-volumes.sh  # (criar este script)
```

---

## 📋 Checklist de Decisão

| Critério | Original | Otimizado |
|----------|----------|-----------|
| Ambiente dev local | ✅ | ⚠️ |
| CI/CD | ⚠️ | ✅ |
| Produção | ❌ | ✅ |
| Staging | ⚠️ | ✅ |
| Segurança | ⚠️ | ✅ |
| Performance | ⚠️ | ✅ |
| Facilidade debug | ✅ | ⚠️ |
| Resource control | ❌ | ✅ |
| Observability | ❌ | ✅ |

---

## 💡 Recomendação

Para sua instalação limpa na VM:

```bash
# 1. Use o otimizado desde o início
cd /srv/magnus-pbx
cp docker-compose.optimized.yml docker-compose.yml
cp Dockerfile.optimized Dockerfile

# 2. Build limpo
docker compose build --no-cache

# 3. Deploy
docker compose up -d

# 4. Monitorar
docker compose logs -f
docker stats
```

**Depois de validar tudo funcionando por 1 semana, pode deletar os `.old` files**

---

## 🔧 Customizações Comuns

### Ajustar Resource Limits

```yaml
# docker-compose.yml
asterisk-magnus:
  deploy:
    resources:
      limits:
        cpus: '4'      # ← Se tiver CPU potente
        memory: 4G     # ← Se tiver RAM sobrando
```

### Adicionar Serviço Prometheus

```yaml
# docker-compose.optimized.yml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    ports:
      - "9090:9090"
    networks:
      magnus-net:
        ipv4_address: 172.20.0.7
```

### Habilitar TLS no Asterisk

```yaml
# docker-compose.yml
asterisk-magnus:
  volumes:
    - ./certs:/etc/asterisk/keys:ro  # ← Certificados SSL
```

---

Escolha o que faz mais sentido para seu cenário! 🚀
