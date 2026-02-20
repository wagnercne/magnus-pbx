# ðŸ› ï¸ Scripts do Magnus PBX

Esta pasta contÃ©m todos os scripts de automaÃ§Ã£o e manutenÃ§Ã£o do sistema.

## ðŸ“‹ Scripts Principais

### ï¿½ PreparaÃ§Ã£o e SincronizaÃ§Ã£o

#### `copiar-para-vm.ps1`
**Preparar arquivos para copiar do Windows para VM Linux**

```powershell
# Verificar arquivos e gerar comandos
.\scripts\copiar-para-vm.ps1

# OU gerar script SCP automÃ¡tico
.\scripts\copiar-para-vm.ps1 -VMUser "user" -VMHost "192.168.1.100" -VMPath "/srv/magnus-pbx"
```

**Funcionalidades:**
- Verifica se os 5 arquivos modulares existem
- Mostra tamanho de cada arquivo
- Gera comandos Git, SCP, ou manual
- Cria script `copiar-scp.sh` automaticamente (se parÃ¢metros fornecidos)

**Use quando:** Antes de ativar dialplan modular na VM.

**SaÃ­da:** Lista de comandos para sincronizar Windows â†’ Linux

---

### ï¿½ðŸš€ Deploy e ConfiguraÃ§Ã£o

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
5. Verifica mÃ³dulos carregados (pbx_config, res_config_pgsql)
6. Recarrega dialplan
7. Valida contextos e extensÃµes

**Use quando:**
- Primeira instalaÃ§Ã£o
- ApÃ³s alteraÃ§Ãµes no banco de dados
- ApÃ³s alteraÃ§Ãµes em arquivos de configuraÃ§Ã£o

---

#### `ativar-dialplan-modular.sh`
**Migra para dialplan modular**

```bash
./scripts/ativar-dialplan-modular.sh
```

**O que faz:**
1. Verifica se arquivos modulares existem
2. Faz backup do `extensions.conf` atual
3. Copia `extensions-modular.conf` â†’ `extensions.conf`
4. Reinicia Asterisk
5. Valida o novo dialplan

**Use quando:**
- Quiser organizar o dialplan em mÃºltiplos arquivos
- [Ver documentaÃ§Ã£o completa](./DIALPLAN_QUAL_USAR.md)

---

### ðŸ”„ Reload e ManutenÃ§Ã£o

#### `reload-dialplan.sh` / `reload-dialplan.ps1`
**Recarrega apenas o dialplan**

```bash
# Linux/WSL
./scripts/reload-dialplan.sh

# Windows PowerShell
.\scripts\reload-dialplan.ps1
```

**O que faz:**
1. Recarrega mÃ³dulo `pbx_config.so`
2. Verifica se o mÃ³dulo estÃ¡ carregado

**Use quando:**
- Alterou `extensions.conf`
- Adicionou novos feature codes
- NÃ£o quer reiniciar o Asterisk completamente

---

### ðŸ” DiagnÃ³stico

#### `diagnostico.sh`
**DiagnÃ³stico completo do sistema**

```bash
./scripts/diagnostico.sh > diagnostico.log
cat diagnostico.log
```

**O que faz:**
1. Verifica arquivo `extensions.conf` no host
2. Verifica arquivo no container
3. Verifica conteÃºdo dos contextos
4. Verifica configuraÃ§Ã£o de mÃ³dulos
5. Lista todos os contextos do Asterisk
6. Verifica endpoints no PostgreSQL
7. Mostra logs do Asterisk

**Use quando:**
- Algo nÃ£o estÃ¡ funcionando
- Precisa de informaÃ§Ãµes completas para debug
- Quer validar toda a configuraÃ§Ã£o

---

#### `fix-dialplan.sh`
**ForÃ§a recarga completa do dialplan**

```bash
./scripts/fix-dialplan.sh
```

**O que faz:**
1. Reinicia container do Asterisk (forÃ§a leitura de arquivos)
2. Verifica mÃ³dulo `pbx_config.so`
3. Lista contextos disponÃ­veis
4. Mostra contexto completo `ctx-belavista`
5. Verifica especificamente o `*43`

**Use quando:**
- `reload-dialplan.sh` nÃ£o resolveu
- Contextos nÃ£o estÃ£o aparecendo
- Precisa de diagnÃ³stico + fix ao mesmo tempo

---

#### `fix-cdr-dirs.sh`
**Corrige erros de CDR (Call Detail Records)**

```bash
./scripts/fix-cdr-dirs.sh
```

**O que faz:**
1. Cria diretÃ³rio `/var/log/asterisk/cdr-csv/`
2. Cria diretÃ³rio `/var/log/asterisk/cdr/`
3. Cria diretÃ³rio `/var/spool/asterisk/monitor/`
4. Cria diretÃ³rio `/var/spool/asterisk/voicemail/`
5. Ajusta permissÃµes (asterisk:asterisk)
6. Recarrega mÃ³dulo `cdr_csv.so`

**Use quando:**
- Ver erro "Unable to open file .../Master.csv"
- Ver erro "Unable to write CSV record to master"
- Logs mostram problema com CDR

**Problema tÃ­pico:**
```
ERROR: Unable to open file /var/log/asterisk/cdr-csv//Master.csv : No such file or directory
```

**SoluÃ§Ã£o:** Execute o script uma vez, os erros vÃ£o sumir.

---

### ðŸšª Hardware (Portaria Virtual)

#### `open_gate.sh`
**Aciona abertura de portÃµes/portas**

```bash
# Chamado automaticamente pelo dialplan via System()
/usr/local/bin/open_gate.sh {gate_name} {extension} {uniqueid}

# Exemplo:
./scripts/open_gate.sh social 1001 1234567890.123
```

**O que faz:**
1. Tenta 4 mÃ©todos de abertura (GPIO, HTTP, MQTT, AMI)
2. Loga evento em `/var/log/asterisk/gate_openings.log`
3. Envia notificaÃ§Ã£o via API backend

**MÃ©todos suportados:**
- **GPIO** - Raspberry Pi (pinos 17, 27, 22)
- **HTTP** - RelÃ©s com API REST
- **MQTT** - Home Assistant / IoT
- **AMI** - Via Asterisk originate

**Use quando:**
- Testar abertura de portÃ£o manualmente
- Configurar novo hardware
- [Ver documentaÃ§Ã£o completa](./ARQUITETURA_HIBRIDA.md)

---

## ðŸ“Š Matriz de Uso

| Script | FrequÃªncia | Demora | Impacto |
|--------|-----------|--------|---------|
| `deploy.sh` | 1x por deploy | ~30s | Alto (reinicia Asterisk) |
| `reload-dialplan.sh` | N vezes durante dev | ~2s | MÃ­nimo (sÃ³ reload) |
| `diagnostico.sh` | Quando houver problema | ~10s | Nenhum (read-only) |
| `fix-dialplan.sh` | Quando reload falhar | ~15s | MÃ©dio (restart Asterisk) |
| `ativar-dialplan-modular.sh` | 1x (migraÃ§Ã£o) | ~15s | Alto (muda dialplan) |
| `open_gate.sh` | AutomÃ¡tico (dialplan) | <1s | Nenhum (hardware) |

---

## ðŸŽ¯ Fluxo de Trabalho TÃ­pico

### Primeira InstalaÃ§Ã£o
1. `deploy.sh` - Setup completo
2. Configurar softphone
3. Testar `*43`

### Desenvolvimento (adicionar features)
1. Editar `extensions.conf`
2. `reload-dialplan.sh` - Aplicar mudanÃ§as
3. Testar
4. Repetir

### Migrar para Modular
1. Sincronizar arquivos modulares
2. `ativar-dialplan-modular.sh` - Migrar
3. Testar `*43`

### Troubleshooting
1. `diagnostico.sh > log.txt` - Coletar info
2. Analisar saÃ­da
3. `fix-dialplan.sh` - Tentar corrigir
4. Se nÃ£o resolver: `deploy.sh` (reset completo)

---

## ðŸ”’ PermissÃµes (Linux/WSL)

```bash
# Dar permissÃ£o de execuÃ§Ã£o a todos os scripts
chmod +x scripts/*.sh
```

---

## ðŸ“– DocumentaÃ§Ã£o Relacionada

- [COMO_INICIAR.md](./COMO_INICIAR.md) - Guia completo de instalaÃ§Ã£o
- [DIALPLAN_QUAL_USAR.md](./DIALPLAN_QUAL_USAR.md) - Escolher dialplan
- [MIGRACAO_DIALPLAN.md](./MIGRACAO_DIALPLAN.md) - Migrar para modular
- [ARQUITETURA_HIBRIDA.md](./ARQUITETURA_HIBRIDA.md) - Portaria virtual
- [GUIA_DE_TESTES.md](./GUIA_DE_TESTES.md) - Testes completos

---

**Total:** 8 scripts (6 Linux + 2 Windows)

