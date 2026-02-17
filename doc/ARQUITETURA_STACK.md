# 🏗️ MAGNUS PBX - Arquitetura Completa

## Stack Tecnológica

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Cliente)                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Vue 3 + TypeScript + Vite                           │  │
│  │  • Pinia (store)                                     │  │
│  │  • Vue Router                                        │  │
│  │  • TailwindCSS + HeadlessUI                          │  │
│  │  • Axios (HTTP client)                               │  │
│  │  • Socket.IO Client (realtime)                       │  │
│  │  • JsSIP (WebRTC)                                    │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API + SignalR
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Servidor)                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ASP.NET Core 10.0 Web API                           │  │
│  │  • Entity Framework Core (PostgreSQL)                │  │
│  │  • SignalR (WebSocket/realtime)                      │  │
│  │  • JWT Authentication                                │  │
│  │  • AsterNET.AMI (Asterisk integration)              │  │
│  │  • Serilog (logging)                                 │  │
│  │  • AutoMapper                                        │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ AMI Protocol (5038)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                  ASTERISK 22.8.2 (Telefonia)                │
│  • PJSIP Realtime                                           │
│  • AGI Scripts (C# via FastAGI - opcional)                  │
│  • WebRTC (porta 8089)                                      │
└────────────────────────┬────────────────────────────────────┘
                         │ libpq
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                   PostgreSQL 17                             │
│  • Dados de tenants, ramais, permissões                     │
│  • CDR, logs de portaria                                    │
│  • Configurações PJSIP Realtime                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 Estrutura de Diretórios

```
MAGNUS-PBX/
│
├── backend/                          # ASP.NET Core Web API
│   ├── Magnus.Pbx/                   # Projeto principal da API
│   │   ├── Controllers/
│   │   ├── Hubs/                     # SignalR hubs
│   │   ├── Middleware/
│   │   └── Program.cs
│   │
│   ├── Magnus.Core/                  # Camada de domínio
│   │   ├── Entities/
│   │   ├── Interfaces/
│   │   └── Services/
│   │
│   ├── Magnus.Infrastructure/        # Acesso a dados
│   │   ├── Data/
│   │   ├── Repositories/
│   │   └── Asterisk/                 # Integração AMI
│   │
│   └── Magnus.sln                    # Solution
│
├── frontend/                         # Vue 3 + TypeScript
│   ├── src/
│   │   ├── assets/
│   │   ├── components/
│   │   │   ├── admin/               # Dashboard admin
│   │   │   ├── portaria/            # Interface portaria
│   │   │   ├── morador/             # App morador
│   │   │   └── common/              # Componentes compartilhados
│   │   ├── composables/             # Vue composition API
│   │   ├── stores/                  # Pinia stores
│   │   ├── router/
│   │   ├── services/                # API clients
│   │   ├── types/                   # TypeScript types
│   │   ├── views/
│   │   ├── App.vue
│   │   └── main.ts
│   │
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   └── tailwind.config.js
│
├── asterisk/                         # Configurações Asterisk
│   ├── etc/asterisk/
│   ├── agi-bin/
│   └── sounds/
│
├── sql/                              # Scripts SQL
│   ├── init.sql
│   └── migrations/
│
├── docker-compose.yml                # Orquestração completa
├── docker-compose.dev.yml            # Desenvolvimento
└── README.md
```

---

## 🎯 Fluxo de Dados - Exemplo: Abrir Portão

```
┌────────────────────────────────────────────────────────────┐
│  1. Morador clica "Abrir Portão" no app Vue               │
└────────────────────┬───────────────────────────────────────┘
                     │ POST /api/gates/open
                     ↓
┌────────────────────────────────────────────────────────────┐
│  2. C# API valida JWT, verifica permissões                │
│     GatesController.OpenGate()                             │
└────────────────────┬───────────────────────────────────────┘
                     │ Query PostgreSQL
                     ↓
┌────────────────────────────────────────────────────────────┐
│  3. Verifica na tabela "permissions"                       │
│     SELECT * FROM permissions WHERE extension=1001...      │
└────────────────────┬───────────────────────────────────────┘
                     │ Se autorizado
                     ↓
┌────────────────────────────────────────────────────────────┐
│  4. Envia comando via AMI para Asterisk                    │
│     Originate channel para acionar relé                    │
└────────────────────┬───────────────────────────────────────┘
                     │ AGI executa
                     ↓
┌────────────────────────────────────────────────────────────┐
│  5. Asterisk aciona hardware (GPIO/HTTP/MQTT)              │
│     Portão abre!                                           │
└────────────────────┬───────────────────────────────────────┘
                     │ Log no banco
                     ↓
┌────────────────────────────────────────────────────────────┐
│  6. INSERT INTO gate_logs (extension, gate_name, ...)      │
└────────────────────┬───────────────────────────────────────┘
                     │ SignalR broadcast
                     ↓
┌────────────────────────────────────────────────────────────┐
│  7. Notifica dashboard admin em tempo real                 │
│     SignalR: gateOpened event                              │
└────────────────────────────────────────────────────────────┘
```

---

## 🔐 Autenticação & Autorização

### Backend (ASP.NET Core)

```csharp
// JWT Authentication
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidIssuer = "magnus-pbx",
            ValidAudience = "magnus-api",
            IssuerSigningKey = new SymmetricSecurityKey(key)
        };
    });

// Claims-based authorization
[Authorize(Policy = "CanOpenGate")]
public async Task<IActionResult> OpenGate()
{
    var tenantId = User.Claims.FirstOrDefault(c => c.Type == "TenantId")?.Value;
    // ...
}
```

### Frontend (Vue 3)

```typescript
// Axios interceptor para JWT
axios.interceptors.request.use((config) => {
  const token = useAuthStore().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Router guard
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore();
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login');
  } else {
    next();
  }
});
```

---

## 📡 Comunicação em Tempo Real

### Backend (SignalR Hub)

```csharp
public class AsteriskEventsHub : Hub
{
    public async Task SubscribeToTenant(string tenantSlug)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, tenantSlug);
    }
    
    // Chamado pelo serviço AMI
    public async Task NotifyGateOpened(string tenantSlug, GateEvent evt)
    {
        await Clients.Group(tenantSlug).SendAsync("GateOpened", evt);
    }
    
    public async Task NotifyCallStatus(string tenantSlug, CallEvent evt)
    {
        await Clients.Group(tenantSlug).SendAsync("CallStatusChanged", evt);
    }
}
```

### Frontend (Vue 3 Composable)

```typescript
// composables/useSignalR.ts
import * as signalR from "@microsoft/signalr";

export function useSignalR() {
  const connection = ref<signalR.HubConnection | null>(null);
  
  const connect = async () => {
    connection.value = new signalR.HubConnectionBuilder()
      .withUrl("http://localhost:5000/hubs/asterisk")
      .withAutomaticReconnect()
      .build();
    
    await connection.value.start();
    
    // Subscribe aos eventos
    connection.value.on("GateOpened", (event) => {
      console.log("Portão aberto:", event);
      // Atualizar UI
    });
  };
  
  return { connect, connection };
}
```

---

## 🔌 Integração Asterisk (AMI)

### Backend (AsterNET.AMI)

```csharp
// Services/AsteriskService.cs
public class AsteriskService : IHostedService
{
    private readonly ManagerConnection _amiConnection;
    private readonly ILogger<AsteriskService> _logger;
    
    public AsteriskService(IConfiguration config, ILogger<AsteriskService> logger)
    {
        _logger = logger;
        _amiConnection = new ManagerConnection(
            config["Asterisk:Host"],
            int.Parse(config["Asterisk:Port"]),
            config["Asterisk:Username"],
            config["Asterisk:Password"]
        );
        
        // Event handlers
        _amiConnection.PeerStatus += OnPeerStatus;
        _amiConnection.NewChannel += OnNewChannel;
    }
    
    public async Task<bool> OriginateCall(string channel, string extension)
    {
        var action = new OriginateAction
        {
            Channel = channel,
            Context = "ctx-belavista",
            Exten = extension,
            Priority = "1",
            Timeout = 30000
        };
        
        var response = await _amiConnection.SendActionAsync(action);
        return response.IsSuccess();
    }
    
    private void OnPeerStatus(object sender, PeerStatusEvent e)
    {
        _logger.LogInformation($"Peer {e.Peer}: {e.PeerStatus}");
        // Notificar via SignalR
    }
}
```

---

## 📦 NuGet Packages (Backend)

```xml
<!-- Magnus.Pbx.csproj -->
<PackageReference Include="Microsoft.AspNetCore.SignalR" Version="10.0.0" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="10.0.0" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
<PackageReference Include="AsterNET.AMI" Version="1.4.0" />
<PackageReference Include="Serilog.AspNetCore" Version="10.0.0" />
<PackageReference Include="AutoMapper.Extensions.Microsoft.DependencyInjection" Version="12.0.1" />
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
```

---

## 📦 NPM Packages (Frontend)

```json
{
  "dependencies": {
    "vue": "^3.4.0",
    "vue-router": "^4.2.0",
    "pinia": "^2.1.0",
    "axios": "^1.6.0",
    "@microsoft/signalr": "^10.0.0",
    "jssip": "^3.10.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "@types/node": "^20.10.0"
  }
}
```

---

## 🚀 Próximos Passos

1. **Validar Base Asterisk** (5 min)
   ```powershell
   .\scripts\deploy.ps1
   ```

2. **Criar Backend C#** (30 min)
   ```powershell
   cd backend
   dotnet new webapi -n Magnus.Pbx
   ```

3. **Criar Frontend Vue** (30 min)
   ```powershell
   cd frontend
   npm create vite@latest . -- --template vue-ts
   ```

4. **Conectar tudo** (1-2 horas)

Quer que eu crie os arquivos iniciais do backend e frontend agora?
