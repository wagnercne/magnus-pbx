# 🐛 Erros Comuns no Build - Ubuntu 24.04

## ❌ Erro: `E: Unable to locate package libncurses5`

### Problema
```
E: Unable to locate package libncurses5
```

### Causa
Ubuntu 24.04 substituiu `libncurses5` por `libncurses6`.

### Solução

**No Dockerfile (stage 1 - compilação):**
```dockerfile
# ERRADO ❌
libncurses5-dev

# CERTO ✅
libncurses-dev  # Aponta automaticamente para versão 6
```

**No Dockerfile.optimized (stage 2 - runtime):**
```dockerfile
# ERRADO ❌
libncurses5

# CERTO ✅
libncurses6  # Versão explícita para runtime
```

---

## ❌ Erro: `E: Package 'libasound2' has no installation candidate`

### Problema
```
E: Package 'libasound2' has no installation candidate
```

### Causa
Ubuntu 24.04 mudou para `libasound2t64` (transição para time64_t).

### Solução

**No Dockerfile.optimized (stage 2 - runtime):**
```dockerfile
# ERRADO ❌
libasound2

# CERTO ✅
libasound2t64  # Nova versão com suporte time64
```

---

## ❌ Erro: `E: Unable to locate package libasound2-dev`

### Problema
No stage de compilação, `libasound2-dev` não existe.

### Solução

**No Dockerfile (stage 1 - compilação):**
```dockerfile
# ERRADO ❌
libasound2-dev

# CERTO ✅
libasound2-dev  # Este ainda existe, mas...
# OU
libasound2t64-dev  # Se der erro, use esta
```

**Dica:** No stage 1 (builder), normalmente `libasound2-dev` ainda funciona. O problema é no stage 2 (runtime).

---

## 📋 Pacotes Corrigidos para Ubuntu 24.04

### Stage 1: Builder (compilação)

| Pacote Antigo | Pacote Novo | Notas |
|---------------|-------------|-------|
| `libncurses5-dev` | `libncurses-dev` | Aponta automaticamente para v6 |
| `libasound2-dev` | `libasound2-dev` | Ainda funciona (ou usar t64 version) |

### Stage 2: Runtime

| Pacote Antigo | Pacote Novo | Notas |
|---------------|-------------|-------|
| `libncurses5` | `libncurses6` | Versão explícita |
| `libasound2` | `libasound2t64` | Time64 transition |
| `libssl1.1` | `libssl3` | Ubuntu 24.04 usa OpenSSL 3 |

---

## 📝 Dockerfile Corrigido - Stage 1 (Builder)

```dockerfile
FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    ca-certificates \
    uuid-dev \
    libxml2-dev \
    libncurses-dev \        # ✅ Corrigido (não mais libncurses5-dev)
    libsqlite3-dev \
    libssl-dev \
    libjansson-dev \
    libedit-dev \
    libpq-dev \
    python3-dev \
    pkg-config \
    subversion \
    libbcg729-dev \
    libopus-dev \
    autoconf \
    automake \
    libtool \
    recode \
    libasound2-dev \        # ✅ OK ou use libasound2t64-dev
    libnewt-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# ... resto do build
```

---

## 📝 Dockerfile Corrigido - Stage 2 (Runtime)

```dockerfile
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2 \
    libncurses6 \           # ✅ Corrigido (não mais libncurses5)
    libsqlite3-0 \
    libssl3 \               # ✅ OpenSSL 3 no Ubuntu 24.04
    libjansson4 \
    libedit2 \
    libpq5 \
    libbcg729-0 \
    libopus0 \
    libasound2t64 \         # ✅ Corrigido (não mais libasound2)
    libnewt0.52 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ... resto da configuração
```

---

## 🔍 Como Descobrir Nome Correto do Pacote

### Método 1: apt-cache search

```bash
# Procurar pacote ncurses
apt-cache search libncurses | grep -i dev

# Saída:
# libncurses-dev - developer's libraries for ncurses
# libncurses6 - shared libraries for terminal handling

# Procurar libasound
apt-cache search libasound | grep -E "^libasound"

# Saída:
# libasound2t64 - shared library for ALSA applications
# libasound2-dev - shared library for ALSA applications -- development files
```

### Método 2: apt-file (mais preciso)

```bash
# Instalar apt-file
apt-get install apt-file
apt-file update

# Procurar arquivo específico
apt-file search libncurses.so

# Ver conteúdo de um pacote
apt-file list libncurses6
```

### Método 3: packages.ubuntu.com

```
1. Acessar: https://packages.ubuntu.com/
2. Selecionar: Ubuntu 24.04 (Noble)
3. Buscar: libncurses
4. Ver pacotes disponíveis
```

---

## ⚙️ Testar Localmente

### Docker Build com Output Detalhado

```bash
# Build com todos os erros visíveis
docker build \
    --no-cache \
    --progress=plain \
    -f Dockerfile.optimized \
    -t test:debug \
    . 2>&1 | tee build.log

# Procurar erros
grep -i "unable to locate" build.log
grep -i "no installation candidate" build.log
```

### Testar Pacote Dentro de Container

```bash
# Entrar em container Ubuntu 24.04
docker run -it --rm ubuntu:24.04 bash

# Atualizar e testar
apt-get update
apt-cache search libncurses
apt-cache search libasound
apt-get install -y libncurses6 libasound2t64

# Se funcionar, está correto!
```

---

## 🚀 Script de Verificação

```bash
#!/bin/bash
# verify-packages.sh - Verificar se pacotes existem no Ubuntu 24.04

PACKAGES=(
    "libncurses6"
    "libncurses-dev"
    "libasound2t64"
    "libasound2-dev"
    "libssl3"
    "libjansson4"
    "libpq5"
)

echo "Verificando pacotes no Ubuntu 24.04..."
docker run --rm ubuntu:24.04 bash -c "
    apt-get update -qq
    for pkg in ${PACKAGES[@]}; do
        if apt-cache show \$pkg &>/dev/null; then
            echo \"✅ \$pkg - OK\"
        else
            echo \"❌ \$pkg - NOT FOUND\"
        fi
    done
"
```

---

## 📊 Migração Ubuntu 22.04 → 24.04

| Pacote 22.04 | Pacote 24.04 | Mudança |
|--------------|--------------|---------|
| `libncurses5` | `libncurses6` | Versão major |
| `libncurses5-dev` | `libncurses-dev` | Nome genérico |
| `libasound2` | `libasound2t64` | Time64 transition |
| `libssl1.1` | `libssl3` | OpenSSL 3 |
| `python3.10` | `python3.12` | Python default |

---

## ✅ Validação Final

```bash
# 1. Pull correções
cd /srv/magnus-pbx
git pull origin main

# 2. Build limpo
docker compose build --no-cache asterisk-magnus

# Deve funcionar sem erros de pacotes!

# 3. Verificar imagem
docker images | grep magnus-pbx

# 4. Testar container
docker compose up -d
docker compose exec asterisk-magnus asterisk -rx "core show version"
```

---

## 🔗 Referências

- [Ubuntu 24.04 Release Notes](https://discourse.ubuntu.com/t/noble-numbat-release-notes/39890)
- [Time64 Transition](https://wiki.ubuntu.com/Time64)
- [NCurses 6 Migration](https://invisible-island.net/ncurses/announce.html)
- [OpenSSL 3 in Ubuntu](https://ubuntu.com/blog/openssl-3-0-in-ubuntu-22-04-lts)

---

## 💡 Dica Final

**Sempre que trocar versão do Ubuntu base, verificar:**

```bash
# Listar pacotes -dev instalados
docker run --rm ubuntu:24.04 bash -c "
    apt-get update -qq
    apt-cache search -- -dev | grep -E '^lib(ncurses|asound|ssl)' | sort
"
```

**Resultado esperado para 24.04:**
```
libasound2-dev - shared library for ALSA applications -- development files
libncurses-dev - developer's libraries for ncurses
libssl-dev - Secure Sockets Layer toolkit - development files
```

Se aparecer algo diferente, ajustar Dockerfile!
