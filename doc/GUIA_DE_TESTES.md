# 🚀 MAGNUS PBX - Guia de Implantação e Teste

## 📋 Checklist de Implantação

### 1️⃣ Aplicar Configurações

```bash
# No host (Windows PowerShell ou terminal)
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Parar o container Asterisk
docker compose stop asterisk-magnus

# Aplicar correções no banco de dados
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -f /docker-entrypoint-initdb.d/03_fix_and_validate.sql

# Ou conectar manualmente:
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx
```

### 2️⃣ Executar SQL de Correção

```sql
-- Dentro do psql:

-- Corrigir contextos de todos os endpoints
UPDATE ps_endpoints e
SET context = 'ctx-' || split_part(e.id, '@', 2),
    transport = 'transport-udp'
WHERE e.id LIKE '%@%';

-- Verificar resultado
SELECT id, context, transport FROM ps_endpoints;

-- Deve retornar algo como:
-- id               | context        | transport
-- 1001@belavista   | ctx-belavista  | transport-udp
-- 1002@belavista   | ctx-belavista  | transport-udp

\q
```

### 3️⃣ Reiniciar Asterisk

```bash
# Iniciar o container
docker compose start asterisk-magnus

# Acompanhar os logs
docker compose logs -f asterisk-magnus

# Verificar se iniciou sem erros:
# - "res_pjsip.so" carregado
# - "pbx_config.so" carregado
# - PostgreSQL conectado
```

### 4️⃣ Validar Configuração do Asterisk

```bash
# Entrar no container
docker compose exec asterisk-magnus asterisk -rx "core show version"

# Verificar módulo PostgreSQL
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"

# Deve mostrar:
# res_config_pgsql.so    Running

# Verificar dialplan carregado
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# Deve mostrar os patterns:
# '*43' : 1. NoOp(=== Echo Test ===)
# '_XXXX' : 1. Goto(dial-internal,${EXTEN},1)
# etc.

# Verificar endpoints registrados
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Verificar se endpoint está registrado
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoint 1001@belavista"
```

---

## 🧪 Testes de Funcionalidade

### Teste 1: Echo Test (*43) ⭐ PRINCIPAL

**Cenário:** Ramal 1001@belavista disca *43

**Configuração do Softphone:**
- **Username:** 1001
- **Password:** (senha do banco)
- **Domain/Realm:** belavista
- **SIP Server:** IP_DO_SERVIDOR:5060
- **Transport:** UDP

**Passos:**
1. Registrar o softphone (Zoiper, Linphone, etc)
2. Discar: `*43`
3. Aguardar a chamada ser atendida
4. Falar algo e ouvir o eco

**Resultado Esperado:**
✅ A chamada é atendida
✅ Toca um beep
✅ Tudo que você fala volta como eco
✅ Não aparece "extension not found"

**Logs no Asterisk:**
```bash
docker compose exec asterisk-magnus asterisk -rx "core set verbose 5"
docker compose exec asterisk-magnus asterisk -rx "core set debug 3"

# Discar *43 e observar:
# -- Executing [*43@ctx-belavista:1] NoOp("PJSIP/1001@belavista-...", "=== Echo Test ===")
# -- Executing [*43@ctx-belavista:2] Answer(...)
# -- Executing [*43@ctx-belavista:3] Echo(...)
```

---

### Teste 2: Discagem Interna (Ramal para Ramal)

**Cenário:** 1001@belavista liga para 1002@belavista

**Passos:**
1. Registrar dois softphones (1001 e 1002)
2. Do ramal 1001, discar: `1002`
3. O ramal 1002 deve tocar

**Resultado Esperado:**
✅ Chamada estabelecida entre ramais
✅ Áudio bidirecional funciona
✅ CallerID correto (1001)

**Logs:**
```
-- Executing [1002@ctx-belavista:1] Goto("PJSIP/1001@belavista-...", "dial-internal,1002,1")
-- Executing [1002@dial-internal:1] NoOp(...)
-- Executing [...] Dial("PJSIP/1001@belavista-...", "PJSIP/1002@belavista,30,tTr")
-- Called PJSIP/1002@belavista
-- PJSIP/1002@belavista-... is ringing
-- PJSIP/1002@belavista-... answered
```

---

### Teste 3: VoiceMail (*97)

**Cenário:** Verificar caixa postal

**Passos:**
1. Discar: `*97`
2. Sistema deve solicitar senha

**Resultado Esperado:**
✅ VoiceMailMain() executado
✅ Solicita senha da caixa postal

---

### Teste 4: Call Forward (*72 e *73)

**Cenário:** Desviar chamadas

**Passos:**
1. Do ramal 1001, discar: `*721002` (desviar para 1002)
2. Sistema confirma ativação
3. Desativar: `*73`

**Resultado Esperado:**
✅ Call forward configurado no banco (AstDB)
✅ Playback de confirmação

---

### Teste 5: Discagem Externa (Outbound)

**Cenário:** Ligar para número externo

**Passos:**
1. Discar: `48999887766`
2. Sistema executa [dial-outbound]

**Resultado Esperado (temporário):**
✅ Playback "cannot-complete-as-dialed"
(Até configurar trunk ou AGI)

---

## 🔍 Diagnóstico de Problemas

### Problema: "extension not found" ao discar *43

**Causa:** Contexto do endpoint está errado

**Solução:**
```sql
-- Verificar contexto
SELECT id, context FROM ps_endpoints WHERE id = '1001@belavista';

-- Se context não for 'ctx-belavista', corrigir:
UPDATE ps_endpoints SET context = 'ctx-belavista' WHERE id = '1001@belavista';
```

```bash
# Recarregar endpoints
docker compose exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"

# Ou reiniciar
docker compose restart asterisk-magnus
```

---

### Problema: Endpoint não registra

**Diagnóstico:**
```bash
# Ver status
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Se aparecer "Unavailable":
# 1. Verificar credenciais do softphone
# 2. Verificar firewall/NAT
# 3. Verificar se transport UDP está ativo
```

**Solução:**
```bash
# Verificar transport
docker compose exec asterisk-magnus asterisk -rx "pjsip show transports"

# Deve mostrar:
# transport-udp   udp      0.0.0.0:5060
```

---

### Problema: Dialplan não carrega

**Causa:** Erro de sintaxe no extensions.conf

**Diagnóstico:**
```bash
docker compose exec asterisk-magnus asterisk -rx "dialplan reload"

# Se aparecer erro:
# [date time] ERROR[xxx]: pbx_config.c: ...
```

**Solução:**
1. Verificar sintaxe do extensions.conf
2. Testar no container:
```bash
docker compose exec asterisk-magnus cat /etc/asterisk/extensions.conf | grep -A5 "tenant-base"
```

---

### Problema: PostgreSQL não conecta

**Diagnóstico:**
```bash
# Verificar conexão
docker compose exec asterisk-magnus asterisk -rx "module show like pgsql"

# Testar conexão manual
docker compose exec asterisk-magnus psql -h postgres-magnus -U admin_magnus -d magnus_pbx -c "SELECT 1;"
```

**Solução:**
1. Verificar res_config_pgsql.conf
2. Verificar se postgres está rodando:
```bash
docker compose ps postgres-magnus
```

---

## 📊 Monitoramento

### Logs em Tempo Real

```bash
# Asterisk verbose
docker compose exec asterisk-magnus asterisk -r
CLI> core set verbose 5
CLI> core set debug 3

# PostgreSQL queries
docker compose exec postgres-magnus tail -f /var/lib/postgresql/data/log/postgresql-*.log

# Docker logs
docker compose logs -f asterisk-magnus
```

### Performance

```bash
# Status do sistema
docker compose exec asterisk-magnus asterisk -rx "core show uptime"
docker compose exec asterisk-magnus asterisk -rx "core show channels"
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Uso de memória
docker stats asterisk-magnus
```

---

## ✅ Checklist de Sucesso

- [ ] Container Asterisk iniciado sem erros
- [ ] res_config_pgsql.so carregado
- [ ] pbx_config.so carregado
- [ ] Dialplan ctx-belavista existe
- [ ] Endpoint 1001@belavista registrado
- [ ] Discagem *43 funciona (Echo)
- [ ] Discagem entre ramais funciona
- [ ] VoiceMail (*97) responde
- [ ] PostgreSQL conectado

---

## 🎓 Próximos Passos

1. ✅ **Sistema básico funcionando**
2. 🔄 Configurar trunks SIP (saída externa)
3. 🔄 Implementar AGI scripts para roteamento dinâmico
4. 🔄 Configurar DIDs (entrada)
5. 🔄 Implementar filas de atendimento
6. 🔄 Dashboard web para administração
7. 🔄 Monitoramento com Prometheus/Grafana
8. 🔄 Backup automatizado do PostgreSQL

---

**Data:** 16 de fevereiro de 2026  
**Versão:** 1.0  
**Status:** Pronto para testes ✅
