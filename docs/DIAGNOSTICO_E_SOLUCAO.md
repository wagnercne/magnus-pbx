# MAGNUS PBX - Análise e Solução do Problema de Dialplan Realtime

## 🔴 PROBLEMA IDENTIFICADO

### Comportamento Observado
Quando o ramal `1001@belavista` disca `*43` (Echo Test), o Asterisk retorna:
```
extension not found
```

### Causa Raiz

#### 1️⃣ **Limitação Crítica do Realtime (Pattern Matching)**

No arquivo `extconfig.conf` você tem:
```ini
extensions => pgsql,general,extensions
```

Isso instrui o Asterisk a buscar extensões no banco de dados. **PORÉM**:

- ✅ Realtime funciona para buscas **EXATAS**: `WHERE exten = '1001'`
- ❌ Realtime **NÃO funciona** para **PATTERNS**: `_*X.` ou `_XXXX`

**O que acontece quando você disca *43:**

```sql
-- O que o Asterisk faz:
SELECT app, appdata FROM extensions 
WHERE context='ctx-belavista' AND exten='*43' AND priority=1;

-- Resultado: 0 rows (não encontra!)
-- A tabela tem: exten='_*X.' (padrão) ≠ '*43' (valor exato)
```

#### 2️⃣ **Problema no extensions.conf**

Seu `extensions.conf` atual:
```ini
[tenant-router]
exten => _X.,1,Set(T_SLUG=${CUT(CHANNEL(endpoint),@,2)})
same => n,Goto(ctx-dynamic,${EXTEN},1)
```

**Problemas:**
- O contexto `ctx-dynamic` **não existe** no arquivo
- Se o endpoint está configurado com `context=ctx-belavista`, ele nunca passa por `tenant-router`
- Você está fazendo `Goto` para um contexto inexistente

#### 3️⃣ **Falta de Switch Realtime**

Para que o Asterisk consulte o banco, você precisa de:
```ini
[ctx-belavista]
switch => Realtime/extensions@general
```

Mas isso só funciona para **valores exatos**, não patterns!

---

## ✅ SOLUÇÃO IMPLEMENTADA

### Arquitetura Híbrida (Pattern no Arquivo + Dados no Banco)

```
┌─────────────────────────────────────────────────────────────┐
│  Ramal 1001@belavista disca *43                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  PJSIP Endpoint: context=ctx-belavista                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  extensions.conf [ctx-belavista]                            │
│  ├─ Herda [tenant-base](!)                                  │
│  │                                                           │
│  └─ Pattern Matching (ARQUIVO FÍSICO):                      │
│     • exten => *43  ──────► Echo()                          │
│     • exten => _XXXX ─────► Dial ramal interno              │
│     • exten => _9XXXXXXXX ► AGI busca trunk no banco        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  Quando precisa de dados do banco:                          │
│  • AGI Script (magnus-outbound-router.php)                  │
│  • func_odbc (MAGNUS_GET_TRUNK)                             │
│  • Consultas SQL dinâmicas                                  │
└─────────────────────────────────────────────────────────────┘
```

### Mudanças Necessárias

#### 1. **REMOVER extensions do extconfig.conf**
```diff
[settings]
ps_endpoints => pgsql,general
ps_auths => pgsql,general
ps_aors => pgsql,general
- extensions => pgsql,general,extensions  ❌ REMOVER!
```

#### 2. **Reescrever extensions.conf**
- Todos os **patterns** (`_*X.`, `_XXXX`, `_9XXXXXXXX`) ficam no arquivo físico
- Features globais (*43, *97, *98) hardcoded no arquivo
- Para dados dinâmicos, usa AGI/func_odbc

#### 3. **O que fica no banco de dados?**
- ✅ **Ramais (ps_endpoints, ps_auths, ps_aors)**: Realtime funciona perfeitamente
- ✅ **Dados de roteamento** (trunks, rotas, DIDs): Consultados via AGI/func_odbc
- ❌ **Extensions com patterns**: NUNCA no Realtime!

---

## 🔧 STACK RECOMENDADA

### Opção 1: res_config_pgsql (Seu Setup Atual)
**Prós:**
- ✅ Mais leve (sem ODBC)
- ✅ Conexão direta PostgreSQL
- ✅ Menos camadas de abstração

**Contras:**
- ❌ Menos flexível
- ❌ Não funciona com func_odbc (precisa de AGI ou AMI)

### Opção 2: ODBC + func_odbc
**Prós:**
- ✅ func_odbc permite consultas SQL inline no dialplan
- ✅ Mais flexível para queries complexas
- ✅ Melhor para lógica condicional no dialplan

**Contras:**
- ❌ Uma camada extra (unixODBC)
- ❌ Mais configuração inicial

### **RECOMENDAÇÃO FINAL: MANTENHA res_config_pgsql**

Para 1.000+ tenants:
- Use **res_config_pgsql** para Realtime (endpoints, auths, aors)
- Use **AGI scripts PHP** para lógica de negócio (roteamento, DIDs)
- Patterns ficam no **extensions.conf** (estático)

**Por quê?**
- AGI é mais escalável que func_odbc para lógica complexa
- Você pode cachear queries no Redis
- Fácil de debugar e manter
- Performance melhor para 1.000+ tenants

---

## 📊 COMPARAÇÃO TÉCNICA

| Recurso | res_config_pgsql | ODBC + func_odbc |
|---------|------------------|------------------|
| Realtime PJSIP | ✅ Excelente | ✅ Excelente |
| Queries no dialplan | ❌ Não tem func | ✅ func_odbc |
| Performance | ⚡ Muito boa | ⚡ Boa |
| Escalabilidade | ✅ 1.000+ tenants | ✅ 1.000+ tenants |
| Complexidade | 🟢 Baixa | 🟡 Média |
| Debugging | 🟢 Simples | 🟡 Médio |

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ Remover `extensions` do extconfig.conf
2. ✅ Aplicar novo extensions.conf com patterns
3. ✅ Adicionar sorcery.conf para transports realtime (opcional)
4. ✅ Criar scripts AGI para roteamento
5. ✅ Testar discagem de *43, ramais internos e externos

---

## 🚀 RESULTADO ESPERADO

Após aplicar as correções:

```bash
# Do ramal 1001@belavista:
*43          → Echo() funciona ✅
1002         → Disca ramal interno ✅
*97          → VoiceMailMain() ✅
48999887766  → Busca trunk no banco e disca ✅
```

**Data:** 16 de fevereiro de 2026
**Asterisk:** 22.8.2
**PostgreSQL:** 17
**Método:** res_config_pgsql + AGI
