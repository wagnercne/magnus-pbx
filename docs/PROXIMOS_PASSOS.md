# ðŸŽ¯ PrÃ³ximos Passos - Magnus PBX

Guia sequencial do que fazer apÃ³s ativar o dialplan modular.

---

## âœ… Status Atual

- âœ… Asterisk 22.8.2 rodando com PostgreSQL realtime
- âœ… Dialplan modular ativado (extensions-features + routing + tenants)
- âœ… Feature codes prontos (*43, *97, *500, etc)
- âœ… Scripts de deploy e manutenÃ§Ã£o
- âœ… RepositÃ³rio GitHub configurado
- âœ… DocumentaÃ§Ã£o completa

---

## ðŸ“‹ Roadmap de Desenvolvimento

### **Fase 1: ValidaÃ§Ã£o e Testes** (1-2 dias)
Configure softphones e valide que tudo funciona corretamente.

### **Fase 2: Backend C#** (3-5 dias)
Desenvolva a API REST que o Asterisk e frontend vÃ£o consumir.

### **Fase 3: Frontend Vue** (3-5 dias)
Interface web para gerenciar tenants, ramais e visualizar chamadas.

### **Fase 4: IntegraÃ§Ã£o** (2-3 dias)
Conectar Asterisk â†’ Backend â†’ Frontend.

### **Fase 5: Funcionalidades AvanÃ§adas** (ContÃ­nuo)
Adicionar features conforme necessidade.

---

## ðŸš€ FASE 1: ValidaÃ§Ã£o e Testes

### **1.1 Verificar Dialplan Modular Carregado**

```bash
# Na VM Linux
cd /srv/magnus-pbx

# Verificar contextos
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts" | grep -E "ctx-|features-base"

# Deve mostrar:
#   'ctx-belavista'    incluÃ­do por 'tenant-base'
#   'ctx-acme'         incluÃ­do por 'tenant-base'
#   'ctx-techno'       incluÃ­do por 'tenant-base'
#   'tenant-base'      incluÃ­do por 'features-base'
#   'features-base'    (nÃ£o incluÃ­do por ninguÃ©m)
#   'dial-internal'    (sub-rotina)
#   'dial-outbound'    (sub-rotina)
#   'open-gate'        (sub-rotina)
```

### **1.2 Verificar Feature Codes**

```bash
# Testar *43 (Echo Test)
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"

# Deve mostrar:
#   '*43' =>      1. NoOp(=== Echo Test: ${CALLERID(num)} ===)
#                 2. Answer()
#                 3. Playback(demo-echotest)
#                 4. Echo()
#                 5. Hangup()

# Testar *500 (PortÃ£o)
docker compose exec asterisk-magnus asterisk -rx "dialplan show *500@ctx-belavista"

# Testar *97 (VoiceMail)
docker compose exec asterisk-magnus asterisk -rx "dialplan show *97@ctx-belavista"
```

### **1.3 Configurar Softphones**

Escolha um softphone e configure 2 ramais para testar:

**Softphones recomendados:**
- **Zoiper** (Windows/Mac/Linux/Mobile) - Mais completo
- **MicroSIP** (Windows) - Leve e simples
- **Linphone** (Multiplataforma) - Open source

**ConfiguraÃ§Ã£o ramal 1001@belavista:**

```
UsuÃ¡rio: 1001@belavista
Senha: senha_1001
DomÃ­nio/Servidor: IP_DA_VM (ex: 192.168.1.100)
Porta: 5060
Transporte: UDP
```

**ConfiguraÃ§Ã£o ramal 1002@belavista:**

```
UsuÃ¡rio: 1002@belavista
Senha: senha_1002
DomÃ­nio/Servidor: IP_DA_VM
Porta: 5060
Transporte: UDP
```

**DocumentaÃ§Ã£o:** [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md)

### **1.4 Executar Testes**

**Teste 1: Registro**
```
âœ… Abrir os 2 softphones
âœ… Verificar status "Registrado" ou "Online"
```

**Teste 2: Echo Test (*43)**
```
âœ… Do ramal 1001, discar *43
âœ… Deve ouvir sua prÃ³pria voz (eco)
âœ… Desligar
```

**Teste 3: LigaÃ§Ã£o Interna**
```
âœ… Do ramal 1001, discar 1002
âœ… Ramal 1002 deve tocar
âœ… Atender e conversar
âœ… Desligar
```

**Teste 4: VoiceMail (*97)**
```
âœ… Do ramal 1001, discar *97
âœ… Deve tocar o menu do voicemail
```

**Teste 5: PortÃ£o (*500)** (ainda nÃ£o funciona - precisa backend)
```
âš ï¸ Do ramal 1001, discar *500
âš ï¸ Por enquanto vai falhar (API backend nÃ£o existe ainda)
âš ï¸ Normal - vamos implementar na Fase 2
```

**DocumentaÃ§Ã£o:** [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md)

### **1.5 Troubleshooting**

Se algo nÃ£o funcionar:

```bash
# DiagnÃ³stico completo
./scripts/diagnostico.sh > diagnostico.log
cat diagnostico.log

# Ver logs em tempo real
docker compose logs -f asterisk-magnus

# Ver se ramais registraram
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"
```

**DocumentaÃ§Ã£o:** [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md)

---

## ðŸ’» FASE 2: Backend C# (.NET 10)

Desenvolver a API REST que gerencia tenants, ramais e integra com Asterisk.

### **2.1 Criar Estrutura do Projeto**

```powershell
# No Windows
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Criar projeto Web API
dotnet new webapi -n Magnus.Pbx.Api -o backend/Magnus.Pbx.Api
cd backend/Magnus.Pbx.Api

# Adicionar pacotes NuGet
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL --version 10.0.0
dotnet add package Microsoft.AspNetCore.SignalR --version 10.0.0
dotnet add package Swashbuckle.AspNetCore --version 7.2.0
```

### **2.2 Estrutura de Pastas**

```
backend/
â”œâ”€â”€ Magnus.Pbx.Api/
â”‚   â”œâ”€â”€ Controllers/
â”‚   â”‚   â”œâ”€â”€ TenantsController.cs      # CRUD de tenants
â”‚   â”‚   â”œâ”€â”€ EndpointsController.cs    # CRUD de ramais
â”‚   â”‚   â”œâ”€â”€ CallsController.cs        # CDR e chamadas ativas
â”‚   â”‚   â””â”€â”€ GateController.cs         # Controle de portÃµes
â”‚   â”‚
â”‚   â”œâ”€â”€ Models/
â”‚   â”‚   â”œâ”€â”€ Tenant.cs
â”‚   â”‚   â”œâ”€â”€ Endpoint.cs
â”‚   â”‚   â”œâ”€â”€ Call.cs
â”‚   â”‚   â””â”€â”€ GatePermission.cs
â”‚   â”‚
â”‚   â”œâ”€â”€ Data/
â”‚   â”‚   â”œâ”€â”€ MagnusDbContext.cs        # Entity Framework
â”‚   â”‚   â””â”€â”€ Migrations/
â”‚   â”‚
â”‚   â”œâ”€â”€ Services/
â”‚   â”‚   â”œâ”€â”€ AsteriskAmiService.cs     # IntegraÃ§Ã£o AMI
â”‚   â”‚   â”œâ”€â”€ GateControlService.cs     # LÃ³gica de portÃµes
â”‚   â”‚   â””â”€â”€ AuthService.cs            # AutenticaÃ§Ã£o JWT
â”‚   â”‚
â”‚   â””â”€â”€ Program.cs
â”‚
â””â”€â”€ Magnus.Pbx.Tests/
    â””â”€â”€ (Testes unitÃ¡rios)
```

### **2.3 Endpoints da API**

**Tenants:**
```
GET    /api/tenants              # Listar todos
GET    /api/tenants/{slug}       # Obter por slug
POST   /api/tenants              # Criar novo
PUT    /api/tenants/{slug}       # Atualizar
DELETE /api/tenants/{slug}       # Deletar
```

**Ramais:**
```
GET    /api/tenants/{slug}/endpoints           # Listar ramais do tenant
GET    /api/tenants/{slug}/endpoints/{id}      # Obter ramal
POST   /api/tenants/{slug}/endpoints           # Criar ramal
PUT    /api/tenants/{slug}/endpoints/{id}      # Atualizar ramal
DELETE /api/tenants/{slug}/endpoints/{id}      # Deletar ramal
```

**Chamadas:**
```
GET    /api/calls/active         # Chamadas ativas (via AMI)
GET    /api/calls/history        # HistÃ³rico (CDR)
POST   /api/calls/originate      # Originar chamada
POST   /api/calls/hangup/{id}    # Desligar chamada
```

**PortÃµes:**
```
POST   /api/gate/open            # Abrir portÃ£o (body: {tenant, extension, gate})
GET    /api/gate/permissions     # Listar permissÃµes
POST   /api/gate/permissions     # Criar permissÃ£o
```

**AGI Endpoints (para Asterisk chamar):**
```
GET    /api/agi/check-gate-permission?tenant=...&extension=...&gate=...
GET    /api/agi/get-outbound-route?tenantId=...&number=...
GET    /api/agi/get-did-route?did=...
```

### **2.4 Modelo de Dados (Entity Framework)**

```csharp
// Models/Tenant.cs
public class Tenant
{
    public int Id { get; set; }
    public string Slug { get; set; }        // belavista, acme
    public string Name { get; set; }        // Bela Vista CondomÃ­nio
    public bool Active { get; set; }
    public DateTime CreatedAt { get; set; }
    
    public List<Endpoint> Endpoints { get; set; }
    public List<GatePermission> GatePermissions { get; set; }
}

// Models/GatePermission.cs
public class GatePermission
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public string Extension { get; set; }   // 1001
    public string GateName { get; set; }    // social, garagem, fundos
    public bool Allowed { get; set; }
    public TimeOnly? StartTime { get; set; } // HorÃ¡rio permitido (opcional)
    public TimeOnly? EndTime { get; set; }
    
    public Tenant Tenant { get; set; }
}
```

### **2.5 IntegraÃ§Ã£o com Asterisk (AMI)**

```csharp
// Services/AsteriskAmiService.cs
public class AsteriskAmiService
{
    private TcpClient _amiClient;
    
    public async Task Connect()
    {
        _amiClient = new TcpClient("localhost", 5038);
        await Login("admin", "senha");
    }
    
    public async Task<List<ActiveCall>> GetActiveCalls()
    {
        // Action: CoreShowChannels
    }
    
    public async Task OriginateCall(string channel, string extension)
    {
        // Action: Originate
    }
    
    public async Task HangupCall(string channel)
    {
        // Action: Hangup
    }
}
```

**DocumentaÃ§Ã£o:** [SETUP_BACKEND.md](SETUP_BACKEND.md)

### **2.6 Testar Backend**

```powershell
# Rodar localmente
cd backend/Magnus.Pbx.Api
dotnet run

# Acessar Swagger
# http://localhost:5000/swagger
```

```bash
# Testar endpoint
curl http://localhost:5000/api/tenants
```

---

## ðŸŽ¨ FASE 3: Frontend Vue 3

Interface web para gerenciar o sistema.

### **3.1 Criar Projeto Vue**

```powershell
# No Windows
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Criar projeto Vue 3 + TypeScript + Vite
npm create vue@latest

# OpÃ§Ãµes:
# Project name: frontend
# TypeScript? Yes
# JSX? No
# Vue Router? Yes
# Pinia? Yes
# Vitest? Yes
# ESLint? Yes
# Prettier? Yes

cd frontend
npm install

# Adicionar bibliotecas
npm install axios
npm install @microsoft/signalr  # Para notificaÃ§Ãµes em tempo real
npm install chart.js vue-chartjs  # Para grÃ¡ficos
```

### **3.2 Estrutura de PÃ¡ginas**

```
frontend/src/
â”œâ”€â”€ views/
â”‚   â”œâ”€â”€ DashboardView.vue         # Dashboard principal
â”‚   â”œâ”€â”€ TenantsView.vue           # Lista de tenants
â”‚   â”œâ”€â”€ TenantDetailView.vue      # Detalhes + ramais do tenant
â”‚   â”œâ”€â”€ EndpointsView.vue         # Gerenciar ramais
â”‚   â”œâ”€â”€ CallsView.vue             # Chamadas ativas + histÃ³rico
â”‚   â”œâ”€â”€ GatePermissionsView.vue   # Gerenciar permissÃµes de portÃµes
â”‚   â””â”€â”€ SettingsView.vue          # ConfiguraÃ§Ãµes
â”‚
â”œâ”€â”€ components/
â”‚   â”œâ”€â”€ TenantCard.vue
â”‚   â”œâ”€â”€ EndpointList.vue
â”‚   â”œâ”€â”€ CallHistoryTable.vue
â”‚   â”œâ”€â”€ ActiveCallsWidget.vue
â”‚   â””â”€â”€ GateControlPanel.vue
â”‚
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ api.ts                    # Axios configurado
â”‚   â”œâ”€â”€ tenantsService.ts
â”‚   â”œâ”€â”€ endpointsService.ts
â”‚   â”œâ”€â”€ callsService.ts
â”‚   â””â”€â”€ websocket.ts              # SignalR
â”‚
â”œâ”€â”€ stores/
â”‚   â”œâ”€â”€ tenantsStore.ts           # Pinia store
â”‚   â”œâ”€â”€ callsStore.ts
â”‚   â””â”€â”€ authStore.ts
â”‚
â””â”€â”€ router/
    â””â”€â”€ index.ts
```

### **3.3 Funcionalidades do Dashboard**

**Dashboard Principal:**
- ðŸ“Š VisÃ£o geral: Total de tenants, ramais, chamadas ativas
- ðŸ“ž Lista de chamadas ativas (tempo real via SignalR)
- ðŸ“ˆ GrÃ¡fico de chamadas por hora/dia
- âš ï¸ Alertas de sistema

**Gerenciar Tenants:**
- âž• Criar novo tenant
- âœï¸ Editar tenant existente
- ðŸ—‘ï¸ Deletar tenant
- ðŸ‘ï¸ Ver ramais do tenant

**Gerenciar Ramais:**
- âž• Criar novo ramal
- âœï¸ Editar ramal (senha, contexto, permissÃµes)
- ðŸ—‘ï¸ Deletar ramal
- ðŸ“ž Originar chamada teste

**Chamadas:**
- ðŸ“ž Lista de chamadas ativas (refresh automÃ¡tico)
- â¹ï¸ Desligar chamada ativa
- ðŸ“Š HistÃ³rico de chamadas (CDR)
- ðŸ” Filtros por tenant, ramal, data

**PortÃµes:**
- ðŸšª Painel de controle de portÃµes
- âž• Configurar permissÃµes (quem pode abrir qual portÃ£o)
- â° HorÃ¡rios permitidos
- ðŸ“œ Log de aberturas

**DocumentaÃ§Ã£o:** [SETUP_FRONTEND.md](SETUP_FRONTEND.md)

### **3.4 Rodar Frontend**

```powershell
cd frontend
npm run dev

# Acessar http://localhost:5173
```

---

## ðŸ”— FASE 4: IntegraÃ§Ã£o

Conectar todas as partes.

### **4.1 Asterisk â†’ Backend (AGI/AMI)**

**Atualizar dialplan para chamar API:**

Editar `asterisk_etc/extensions-features.conf`:

```ini
; Sub-rotina: Abrir PortÃ£o (jÃ¡ existe, sÃ³ garantir que estÃ¡ correto)
[open-gate]
exten => s,1,NoOp(=== Open Gate: ${GATE_NAME} ===)
 same => n,Set(TENANT_SLUG=${CUT(CHANNEL(endpoint),@,2)})
 same => n,Set(CALLER=${CALLERID(num)})
 
 ; Chamar API backend
 same => n,Set(API_URL=http://backend:5000/api/agi/check-gate-permission)
 same => n,Set(QUERY=?tenant=${TENANT_SLUG}&extension=${CALLER}&gate=${GATE_NAME})
 same => n,Set(RESPONSE=${CURL(${API_URL}${QUERY})})
 
 ; Verificar resposta
 same => n,GotoIf($["${RESPONSE}" = "allowed"]?open:denied)
 
 same => n(open),Answer()
 same => n,Playback(beep)
 same => n,System(/usr/local/bin/open_gate.sh ${GATE_NAME} ${CALLER} ${UNIQUEID})
 same => n,Playback(auth-thankyou)
 same => n,Hangup()
 
 same => n(denied),Answer()
 same => n,Playback(access-denied)
 same => n,Hangup()
```

**Adicionar backend ao docker-compose.yml:**

```yaml
services:
  backend:
    build: ./backend/Magnus.Pbx.Api
    ports:
      - "5000:8080"
    environment:
      - ConnectionStrings__DefaultConnection=Host=postgres-magnus;Database=magnus_pbx;Username=admin_magnus;Password=senha_forte_123
    depends_on:
      - postgres-magnus
    networks:
      - magnus-network

  asterisk-magnus:
    # ... configuraÃ§Ã£o existente ...
    depends_on:
      - postgres-magnus
      - backend  # Adicionar dependÃªncia
```

### **4.2 Backend â†’ Asterisk (AMI)**

Configurar AMI no Asterisk:

```ini
# asterisk_etc/manager.conf
[general]
enabled = yes
port = 5038
bindaddr = 0.0.0.0

[backend_api]
secret = senha_ami_segura
read = all
write = all
```

### **4.3 Frontend â†’ Backend (REST API)**

```typescript
// services/api.ts
import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json'
  }
})

export default api
```

### **4.4 Backend â†’ Frontend (SignalR)**

NotificaÃ§Ãµes em tempo real:

```typescript
// services/websocket.ts
import * as signalR from '@microsoft/signalr'

const connection = new signalR.HubConnectionBuilder()
  .withUrl('http://localhost:5000/hubs/calls')
  .build()

connection.on('CallStarted', (call) => {
  // Atualizar lista de chamadas ativas
})

connection.on('CallEnded', (call) => {
  // Remover da lista
})

await connection.start()
```

---

## ðŸš€ FASE 5: Funcionalidades AvanÃ§adas

### **5.1 AutenticaÃ§Ã£o e AutorizaÃ§Ã£o**

- JWT tokens
- Login de administradores
- PermissÃµes por tenant

### **5.2 CDR AvanÃ§ado**

- AnÃ¡lise de chamadas
- RelatÃ³rios por tenant
- Exportar CSV/PDF

### **5.3 IVR (URA)**

- Menu interativo para chamadas externas
- "Disque 1 para vendas, 2 para suporte..."

### **5.4 Filas de Atendimento**

- Queue para atendentes
- MÃºsica de espera
- PriorizaÃ§Ã£o

### **5.5 GravaÃ§Ã£o de Chamadas**

- Armazenar gravaÃ§Ãµes
- Player no frontend
- Download de arquivos

### **5.6 ConferÃªncias**

- Salas de conferÃªncia
- Moderador
- Convites

### **5.7 NotificaÃ§Ãµes**

- E-mail quando portÃ£o abrir
- SMS para chamadas perdidas
- Webhook para integraÃ§Ãµes

### **5.8 API REST PÃºblica**

- DocumentaÃ§Ã£o OpenAPI
- Rate limiting
- API keys para clientes

---

## ðŸ“š DocumentaÃ§Ã£o de ReferÃªncia

- [ARQUITETURA_STACK.md](ARQUITETURA_STACK.md) - VisÃ£o geral da arquitetura
- [SETUP_BACKEND.md](SETUP_BACKEND.md) - Setup do backend C#
- [SETUP_FRONTEND.md](SETUP_FRONTEND.md) - Setup do frontend Vue
- [CONFIGURACAO_SOFTPHONES.md](CONFIGURACAO_SOFTPHONES.md) - Configurar softphones
- [GUIA_DE_TESTES.md](GUIA_DE_TESTES.md) - Testes completos
- [DIAGNOSTICO_E_SOLUCAO.md](DIAGNOSTICO_E_SOLUCAO.md) - Troubleshooting

---

## ðŸŽ¯ Checklist Resumido

### **Agora (Fase 1):**
- [ ] Verificar dialplan modular carregado
- [ ] Testar feature codes (*43, *97, *500)
- [ ] Configurar 2 softphones
- [ ] Testar ligaÃ§Ã£o entre ramais
- [ ] Testar echo (*43)
- [ ] Documentar tudo que funciona

### **PrÃ³xima Semana (Fase 2):**
- [ ] Criar projeto backend .NET 10
- [ ] Implementar controllers bÃ¡sicos
- [ ] Conectar com PostgreSQL via EF Core
- [ ] Implementar endpoint de portÃ£o
- [ ] Testar integraÃ§Ã£o Asterisk â†’ Backend

### **Semana Seguinte (Fase 3):**
- [ ] Criar projeto Vue 3
- [ ] Implementar dashboard
- [ ] Implementar CRUD de tenants
- [ ] Implementar CRUD de ramais
- [ ] Testar integraÃ§Ã£o Frontend â†’ Backend

### **Depois (Fase 4+):**
- [ ] IntegraÃ§Ã£o completa
- [ ] Testes end-to-end
- [ ] Deploy em produÃ§Ã£o
- [ ] Funcionalidades avanÃ§adas

---

## ðŸ’¡ Dicas

1. **Comece simples:** Valide cada fase antes de ir para a prÃ³xima
2. **Use Git:** Commit frequente com mensagens claras
3. **Documente:** Anote problemas e soluÃ§Ãµes
4. **Teste sempre:** NÃ£o avance sem testar
5. **Backend primeiro:** Ã‰ mais fÃ¡cil criar o frontend depois

---

## ðŸ†˜ Precisa de Ajuda?

1. Consulte a documentaÃ§Ã£o em `docs/`
2. Execute `./scripts/diagnostico.sh`
3. Verifique logs: `docker compose logs -f`
4. Pesquise issues semelhantes no GitHub
5. Abra uma issue: https://github.com/wagnercne/magnus-pbx/issues

---

**Boa sorte no desenvolvimento! ðŸš€**

