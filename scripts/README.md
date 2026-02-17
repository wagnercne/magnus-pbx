# 🛠️ Scripts do Magnus PBX

Esta pasta contém todos os scripts de automação e manutenção do sistema.

## 📋 Scripts Principais

### � Preparação e Sincronização

#### `copiar-para-vm.ps1`
**Preparar arquivos para copiar do Windows para VM Linux**

```powershell
# Verificar arquivos e gerar comandos
.\scripts\copiar-para-vm.ps1

# OU gerar script SCP automático
.\scripts\copiar-para-vm.ps1 -VMUser "user" -VMHost "192.168.1.100" -VMPath "/srv/magnus-pbx"
```

**Funcionalidades:**
- Verifica se os 5 arquivos modulares existem
- Mostra tamanho de cada arquivo
- Gera comandos Git, SCP, ou manual
- Cria script `copiar-scp.sh` automaticamente (se parâmetros fornecidos)

**Use quando:** Antes de ativar dialplan modular na VM.

**Saída:** Lista de comandos para sincronizar Windows → Linux

---

### �🚀 Deploy e Configuração

#### `deploy.sh` / `deploy.ps1`
**Deploy completo do sistema**

```bash
# Linux/WSL
./scripts/deploy.sh

# Windows PowerShell
.\scripts\deploy.ps1
```

**O que faz:**
1. Para o Asterisk
2. Corrige contextos no banco (`ctx-{slug}`)
3. Verifica estrutura do banco
4. Inicia o Asterisk
5. Verifica módulos carregados (pbx_config, res_config_pgsql)
6. Recarrega dialplan
7. Valida contextos e extensões

**Use quando:**
- Primeira instalação
- Após alterações no banco de dados
- Após alterações em arquivos de configuração

---

#### `ativar-dialplan-modular.sh`
**Migra para dialplan modular**

```bash
./scripts/ativar-dialplan-modular.sh
```

**O que faz:**
1. Verifica se arquivos modulares existem
2. Faz backup do `extensions.conf` atual
3. Copia `extensions-modular.conf` → `extensions.conf`
4. Reinicia Asterisk
5. Valida o novo dialplan

**Use quando:**
- Quiser organizar o dialplan em múltiplos arquivos
- [Ver documentação completa](../doc/DIALPLAN_QUAL_USAR.md)

---

### 🔄 Reload e Manutenção

#### `reload-dialplan.sh` / `reload-dialplan.ps1`
**Recarrega apenas o dialplan**

```bash
# Linux/WSL
./scripts/reload-dialplan.sh

# Windows PowerShell
.\scripts\reload-dialplan.ps1
```

**O que faz:**
1. Recarrega módulo `pbx_config.so`
2. Verifica se o módulo está carregado

**Use quando:**
- Alterou `extensions.conf`
- Adicionou novos feature codes
- Não quer reiniciar o Asterisk completamente

---

### 🔍 Diagnóstico

#### `diagnostico.sh`
**Diagnóstico completo do sistema**

```bash
./scripts/diagnostico.sh > diagnostico.log
cat diagnostico.log
```

**O que faz:**
1. Verifica arquivo `extensions.conf` no host
2. Verifica arquivo no container
3. Verifica conteúdo dos contextos
4. Verifica configuração de módulos
5. Lista todos os contextos do Asterisk
6. Verifica endpoints no PostgreSQL
7. Mostra logs do Asterisk

**Use quando:**
- Algo não está funcionando
- Precisa de informações completas para debug
- Quer validar toda a configuração

---

#### `fix-dialplan.sh`
**Força recarga completa do dialplan**

```bash
./scripts/fix-dialplan.sh
```

**O que faz:**
1. Reinicia container do Asterisk (força leitura de arquivos)
2. Verifica módulo `pbx_config.so`
3. Lista contextos disponíveis
4. Mostra contexto completo `ctx-belavista`
5. Verifica especificamente o `*43`

**Use quando:**
- `reload-dialplan.sh` não resolveu
- Contextos não estão aparecendo
- Precisa de diagnóstico + fix ao mesmo tempo

---

### 🚪 Hardware (Portaria Virtual)

#### `open_gate.sh`
**Aciona abertura de portões/portas**

```bash
# Chamado automaticamente pelo dialplan via System()
/usr/local/bin/open_gate.sh {gate_name} {extension} {uniqueid}

# Exemplo:
./scripts/open_gate.sh social 1001 1234567890.123
```

**O que faz:**
1. Tenta 4 métodos de abertura (GPIO, HTTP, MQTT, AMI)
2. Loga evento em `/var/log/asterisk/gate_openings.log`
3. Envia notificação via API backend

**Métodos suportados:**
- **GPIO** - Raspberry Pi (pinos 17, 27, 22)
- **HTTP** - Relés com API REST
- **MQTT** - Home Assistant / IoT
- **AMI** - Via Asterisk originate

**Use quando:**
- Testar abertura de portão manualmente
- Configurar novo hardware
- [Ver documentação completa](../doc/ARQUITETURA_HIBRIDA.md)

---

## 📊 Matriz de Uso

| Script | Frequência | Demora | Impacto |
|--------|-----------|--------|---------|
| `deploy.sh` | 1x por deploy | ~30s | Alto (reinicia Asterisk) |
| `reload-dialplan.sh` | N vezes durante dev | ~2s | Mínimo (só reload) |
| `diagnostico.sh` | Quando houver problema | ~10s | Nenhum (read-only) |
| `fix-dialplan.sh` | Quando reload falhar | ~15s | Médio (restart Asterisk) |
| `ativar-dialplan-modular.sh` | 1x (migração) | ~15s | Alto (muda dialplan) |
| `open_gate.sh` | Automático (dialplan) | <1s | Nenhum (hardware) |

---

## 🎯 Fluxo de Trabalho Típico

### Primeira Instalação
1. `deploy.sh` - Setup completo
2. Configurar softphone
3. Testar `*43`

### Desenvolvimento (adicionar features)
1. Editar `extensions.conf`
2. `reload-dialplan.sh` - Aplicar mudanças
3. Testar
4. Repetir

### Migrar para Modular
1. Sincronizar arquivos modulares
2. `ativar-dialplan-modular.sh` - Migrar
3. Testar `*43`

### Troubleshooting
1. `diagnostico.sh > log.txt` - Coletar info
2. Analisar saída
3. `fix-dialplan.sh` - Tentar corrigir
4. Se não resolver: `deploy.sh` (reset completo)

---

## 🔒 Permissões (Linux/WSL)

```bash
# Dar permissão de execução a todos os scripts
chmod +x scripts/*.sh
```

---

## 📖 Documentação Relacionada

- [COMO_INICIAR.md](../doc/COMO_INICIAR.md) - Guia completo de instalação
- [DIALPLAN_QUAL_USAR.md](../doc/DIALPLAN_QUAL_USAR.md) - Escolher dialplan
- [MIGRACAO_DIALPLAN.md](../doc/MIGRACAO_DIALPLAN.md) - Migrar para modular
- [ARQUITETURA_HIBRIDA.md](../doc/ARQUITETURA_HIBRIDA.md) - Portaria virtual
- [GUIA_DE_TESTES.md](../doc/GUIA_DE_TESTES.md) - Testes completos

---

**Total:** 8 scripts (6 Linux + 2 Windows)
