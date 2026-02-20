# 📱 Configurações de Softphones - MAGNUS PBX

Este guia mostra como configurar softphones populares para conectar ao Magnus PBX.

---

## 🔐 Informações Necessárias

Antes de configurar qualquer softphone, você precisa destas informações:

```bash
# Consultar no banco de dados:
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
SELECT 
    e.id as endpoint_id,
    split_part(e.id, '@', 1) as ramal,
    split_part(e.id, '@', 2) as dominio,
    a.username,
    a.password
FROM ps_endpoints e
INNER JOIN ps_auths a ON e.auth = a.id
WHERE e.id = '1001@belavista';  -- Substitua pelo seu endpoint
"
```

**Exemplo de resultado:**
```
endpoint_id    | ramal | dominio    | username | password
1001@belavista | 1001  | belavista  | 1001     | senha1001
```

**Informações do servidor:**
- **IP/Host:** O IP da sua VM (ex: 192.168.1.100)
- **Porta:** 5060 (UDP)
- **Transporte:** UDP

---

## 📱 Softphones Testados

1. [Zoiper (Windows/Mac/Mobile)](#zoiper)
2. [Linphone (Desktop/Mobile)](#linphone)
3. [MicroSIP (Windows)](#microsip)
4. [Bria (Desktop/Mobile)](#bria)
5. [Groundwire (Mobile)](#groundwire)
6. [Browser (WebRTC - JsSIP)](#webrtc)

---

## 1️⃣ Zoiper

### Windows / macOS

1. Baixar: https://www.zoiper.com/
2. Abrir Zoiper → **Settings** → **Accounts** → **Add Account**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Account type** | SIP |
| **Username** | `1001` |
| **Password** | `senha1001` |
| **Domain** | `belavista` |
| **Authentication username** | `1001` |
| **Outbound Proxy** | `192.168.1.100:5060` |
| **Transport** | UDP |
| **Caller ID** | `João Silva <1001>` |

3. Clicar em **Register**

**Teste:**
- Status deve aparecer como **✓ Registered**
- Discar `*43` para testar eco

---

## 2️⃣ Linphone

### Desktop (Windows/Linux/Mac)

1. Baixar: https://www.linphone.org/
2. **Assistant** → **Use SIP Account**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Username** | `1001` |
| **Password** | `senha1001` |
| **Domain** | `192.168.1.100` |
| **Transport** | UDP |
| **Display name** | `João Silva` |

3. **Advanced** → **Outbound proxy:**
   - Ativar: `sip:192.168.1.100:5060;transport=udp`

4. Clicar em **Use** / **Login**

**Teste:**
- Status: **Connected**
- Discar `*43`

---

### Mobile (Android/iOS)

1. Baixar da Play Store / App Store
2. **Menu** → **Settings** → **SIP Accounts** → **Add**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Username** | `1001` |
| **Password** | `senha1001` |
| **Domain** | `192.168.1.100` |
| **Transport** | UDP |

---

## 3️⃣ MicroSIP (Windows)

**Leve e simples - Recomendado para testes rápidos**

1. Baixar: https://www.microsip.org/
2. **Menu** → **Add Account**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Account name** | Bela Vista - 1001 |
| **SIP Server** | `192.168.1.100:5060` |
| **Username** | `1001` |
| **Domain** | `belavista` |
| **Login** | `1001` |
| **Password** | `senha1001` |
| **Proxy** | `192.168.1.100:5060` |

3. Salvar → Deve aparecer **✓** verde

---

## 4️⃣ Bria (Desktop/Mobile)

### Desktop

1. Baixar: https://www.counterpath.com/bria/
2. **Accounts** → **Add Account** → **Manual Setup**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Display Name** | João Silva |
| **Phone Number** | 1001 |
| **Username** | `1001` |
| **Password** | `senha1001` |
| **Authorization Name** | `1001` |
| **Domain** | `192.168.1.100` |

**Advanced:**
- **Outbound Proxy:** `192.168.1.100:5060`
- **Transport:** UDP

---

## 5️⃣ Groundwire (iOS/Android)

**Excelente para mobile - compatível com WebRTC**

1. Comprar na App Store / Google Play
2. **Accounts** → **Add Account** → **Generic SIP Account**

**Configuração:**

| Campo | Valor |
|-------|-------|
| **Title** | Bela Vista 1001 |
| **Name** | João Silva |
| **Username** | `1001` |
| **Password** | `senha1001` |
| **Server** | `192.168.1.100` |
| **Port** | 5060 |

**Advanced:**
- **Domain:** `belavista`
- **Transport:** UDP

---

## 6️⃣ WebRTC (Browser)

### Usando JsSIP

O Magnus PBX já tem WebRTC configurado na porta **8089** (WSS).

**Exemplo HTML:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Magnus PBX WebRTC</title>
    <script src="https://cdn.jsdelivr.net/npm/jssip@3.9.1/dist/jssip.min.js"></script>
</head>
<body>
    <h1>Magnus PBX Client</h1>
    <button onclick="dial('*43')">Testar Echo (*43)</button>
    
    <script>
        // Configuração
        const socket = new JsSIP.WebSocketInterface('wss://192.168.1.100:8089/ws');
        
        const configuration = {
            sockets: [socket],
            uri: 'sip:1001@belavista',
            password: 'senha1001',
            display_name: 'João Silva'
        };
        
        const ua = new JsSIP.UA(configuration);
        ua.start();
        
        // Discar
        function dial(number) {
            const options = {
                'mediaConstraints': {
                    'audio': true,
                    'video': false
                }
            };
            ua.call(number, options);
        }
    </script>
</body>
</html>
```

---

## 🧪 Testes Após Registro

### 1. Verificar Status no Asterisk

```bash
# Ver endpoints registrados
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Deve mostrar:
# 1001@belavista  ...  Avail  1  15.43
```

### 2. Ver Detalhes do Endpoint

```bash
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoint 1001@belavista"

# Deve mostrar:
# Endpoint: 1001@belavista/Transport: transport-udp
# context: ctx-belavista
# Contacts: 1001@belavista/sip:1001@192.168.1.50:5060 (Avail)
```

### 3. Testes de Discagem

| Código | O que testa | Resultado Esperado |
|--------|-------------|-------------------|
| **\*43** | Echo Test | Ouve sua própria voz de volta |
| **\*97** | VoiceMail | Pede senha da caixa postal |
| **1002** | Ramal interno | Toca no ramal 1002 (se existir) |
| **\*60100** | Sala de conferência | Entra na sala 100 |

---

## 🔧 Troubleshooting

### ❌ Não registra (401 Unauthorized)

**Causa:** Senha incorreta

**Solução:**
```bash
# Verificar senha no banco
docker compose exec postgres-magnus psql -U admin_magnus -d magnus_pbx -c "
SELECT id, username, password FROM ps_auths WHERE id='1001@belavista';
"
```

---

### ❌ Não registra (408 Request Timeout)

**Causa:** Firewall bloqueando porta 5060

**Solução:**
```bash
# Windows: Abrir porta 5060 UDP
netsh advfirewall firewall add rule name="Asterisk SIP" dir=in action=allow protocol=UDP localport=5060

# Linux: Permitir porta
sudo ufw allow 5060/udp
```

---

### ❌ Registra mas não disca

**Causa:** Contexto errado no endpoint

**Solução:**
```sql
-- Verificar e corrigir contexto
UPDATE ps_endpoints 
SET context = 'ctx-belavista' 
WHERE id = '1001@belavista';
```

```bash
# Recarregar
docker compose exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"
```

---

### ❌ *43 diz "extension not found"

**Causa:** Dialplan não foi carregado ou contexto incorreto

**Solução:**
```bash
# Verificar dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# Se não mostrar o *43, recarregar:
docker compose exec asterisk-magnus asterisk -rx "dialplan reload"

# Se persistir, reiniciar:
docker compose restart asterisk-magnus
```

---

## 📊 Logs em Tempo Real

### Monitorar Registro de Ramal

```bash
# Terminal 1: Logs do Asterisk
docker compose exec asterisk-magnus asterisk -r

# No CLI do Asterisk:
CLI> core set verbose 5
CLI> core set debug 3
CLI> pjsip set logger on
```

**O que você deve ver ao registrar:**
```
PJSIP contact '1001@belavista/sip:1001@192.168.1.50:5060' created for endpoint '1001@belavista'
Endpoint '1001@belavista' registered contact 'sip:1001@192.168.1.50:5060'
```

### Monitorar Chamada

```bash
# Ao discar *43:
-- Executing [*43@ctx-belavista:1] NoOp("PJSIP/1001@belavista-...", "=== Echo Test ===") 
-- Executing [*43@ctx-belavista:2] Answer("PJSIP/1001@belavista-...")
-- Executing [*43@ctx-belavista:3] Wait("PJSIP/1001@belavista-...", "1")
-- Executing [*43@ctx-belavista:4] Playback("PJSIP/1001@belavista-...", "beep")
-- Executing [*43@ctx-belavista:5] Echo("PJSIP/1001@belavista-...")
```

---

## 🎯 Configuração Recomendada de Codecs

Para melhor qualidade de áudio:

| Codec | Bitrate | Qualidade | Uso de Banda |
|-------|---------|-----------|--------------|
| **opus** | 48 kbps | ⭐⭐⭐⭐⭐ | Baixo |
| **g722** | 64 kbps | ⭐⭐⭐⭐ | Médio |
| **ulaw** | 64 kbps | ⭐⭐⭐ | Médio |
| **alaw** | 64 kbps | ⭐⭐⭐ | Médio |
| **gsm** | 13 kbps | ⭐⭐ | Muito Baixo |

**Configurar no softphone:**
1. **Preferência:** opus > g722 > ulaw > alaw > gsm
2. **Desabilitar:** G.729 (se não licenciado), video codecs (se não usar)

---

## 📱 Apps Mobile Recomendados

### Android

1. **Linphone** - Gratuito, open source ⭐⭐⭐⭐⭐
2. **Zoiper** - Versão free funcional ⭐⭐⭐⭐
3. **Groundwire** - Pago, muito estável ⭐⭐⭐⭐⭐
4. **Bria Mobile** - Pago, recursos avançados ⭐⭐⭐⭐

### iOS

1. **Linphone** - Gratuito, open source ⭐⭐⭐⭐⭐
2. **Groundwire** - Pago, melhor para iOS ⭐⭐⭐⭐⭐
3. **Bria Mobile** - Pago, integração PBX ⭐⭐⭐⭐
4. **Zoiper** - Versão free limitada ⭐⭐⭐

---

## 🔐 Dicas de Segurança

1. **Não use senhas fracas:**
   ```sql
   -- Gerar senhas fortes:
   UPDATE ps_auths 
   SET password = md5(random()::text || random()::text)
   WHERE id = '1001@belavista';
   ```

2. **Desabilitar guest calls (sem autenticação)**

3. **Usar TLS/SRTP quando possível**

4. **Configurar fail2ban para bloquear ataques de força bruta**

---

## ✅ Checklist de Sucesso

- [ ] Softphone configurado
- [ ] Status: **Registered** / **Connected**
- [ ] Discar `*43` - Eco funciona
- [ ] Discar outro ramal - Chamada estabelecida
- [ ] Áudio bidirecional OK
- [ ] CallerID aparece corretamente

---

**Última atualização:** 16 de fevereiro de 2026  
**Compatibilidade:** Asterisk 22.8.2 + PJSIP
