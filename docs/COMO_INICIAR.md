# 🚀 Magnus PBX - Como Iniciar o Projeto

## 📋 Pré-requisitos

- ✅ Docker e Docker Compose instalados
- ✅ .NET 10.0 SDK instalado
- ✅ Node.js 18+ e npm instalados
- ✅ PostgreSQL rodando (via docker-compose)
- ✅ Asterisk 22 rodando (via docker-compose)

---

## 🏗️ Arquitetura do Sistema

O Magnus PBX usa **arquitetura híbrida**:
- 📁 **extensions.conf** - Padrões fixos (performance máxima)
- 💾 **PostgreSQL** - Rotas dinâmicas (flexibilidade multi-tenant)
- 🔌 **AGI/API** - Lógica de negócio (validações + logging)

📖 **Leia:** [ARQUITETURA_HIBRIDA.md](ARQUITETURA_HIBRIDA.md) para entender o fluxo completo

---

## 1️⃣ Corrigir Database do Asterisk (CRITICAL - Fazer PRIMEIRO!)

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX
.\scripts\deploy.ps1
```

**O que o script faz:**
- Corrige ps_endpoints.context de NULL para 'ctx-{slug}'
- Define transport='transport-udp' para todos os endpoints
- Valida configuração do dialplan
- Reinicia container Asterisk

**Validação:**
```powershell
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"
```

**Deve aparecer:**
```
[ Context 'ctx-belavista' created by 'pbx_config' ]
  '*43' => 1. NoOp(=== Echo Test ===)
```

---

## 2️⃣ Criar Projeto Backend (C# ASP.NET Core)

### Criar estrutura de pastas e projetos

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Criar solution
dotnet new sln -n Magnus

# Criar projetos
dotnet new webapi -n Magnus.Pbx -o backend/Magnus.Pbx
dotnet new classlib -n Magnus.Core -o backend/Magnus.Core
dotnet new classlib -n Magnus.Infrastructure -o backend/Magnus.Infrastructure

# Adicionar projetos à solution
dotnet sln add backend/Magnus.Pbx/Magnus.Pbx.csproj
dotnet sln add backend/Magnus.Core/Magnus.Core.csproj
dotnet sln add backend/Magnus.Infrastructure/Magnus.Infrastructure.csproj

# Adicionar referências entre projetos
dotnet add backend/Magnus.Pbx/Magnus.Pbx.csproj reference backend/Magnus.Core/Magnus.Core.csproj
dotnet add backend/Magnus.Pbx/Magnus.Pbx.csproj reference backend/Magnus.Infrastructure/Magnus.Infrastructure.csproj
dotnet add backend/Magnus.Infrastructure/Magnus.Infrastructure.csproj reference backend/Magnus.Core/Magnus.Core.csproj
```

### Instalar NuGet packages

```powershell
# Magnus.Pbx
cd backend/Magnus.Pbx
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package AsterNET.AMI
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console

# Magnus.Infrastructure
cd ../Magnus.Infrastructure
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design

cd ../..
```

### ✅ Arquivos já criados

Os seguintes arquivos **já foram criados** pelo agente:

- ✅ `backend/Magnus.Pbx/Program.cs` - Configuração completa da API
- ✅ `backend/Magnus.Pbx/appsettings.json` - Configurações (DB, JWT, AMI)
- ✅ `backend/Magnus.Core/Entities/Entities.cs` - Modelos de domínio
- ✅ `backend/Magnus.Infrastructure/Data/MagnusDbContext.cs` - EF Core DbContext
- ✅ `backend/Magnus.Pbx/Controllers/GatesController.cs` - API de portões
- ✅ `backend/Magnus.Pbx/Hubs/AsteriskEventsHub.cs` - SignalR Hub
- ✅ `backend/Magnus.Pbx/Services/AsteriskAmiService.cs` - Integração AMI

### Rodar backend

```powershell
cd backend/Magnus.Pbx
dotnet restore
dotnet build
dotnet run
```

**Backend estará em:** `http://localhost:5000`

**Testar API:**
```powershell
curl http://localhost:5000/api/health
```

---

## 3️⃣ Criar Projeto Frontend (Vue 3 + TypeScript)

### Instalar dependências

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX\frontend
npm install
```

### ✅ Arquivos já criados

Os seguintes arquivos **já foram criados** pelo agente:

**Configuração:**
- ✅ `frontend/package.json` - Dependências do projeto
- ✅ `frontend/vite.config.ts` - Configuração do Vite com proxy
- ✅ `frontend/tsconfig.json` - Configuração TypeScript
- ✅ `frontend/index.html` - HTML de entrada
- ✅ `frontend/src/main.ts` - Bootstrap da aplicação
- ✅ `frontend/src/App.vue` - Componente raiz

**Services:**
- ✅ `frontend/src/services/api.ts` - Axios configurado com JWT
- ✅ `frontend/src/services/gateService.ts` - API de portões

**Stores (Pinia):**
- ✅ `frontend/src/stores/auth.ts` - Gerenciamento de autenticação

**Composables:**
- ✅ `frontend/src/composables/useSignalR.ts` - Hook para SignalR

**Components:**
- ✅ `frontend/src/components/OpenGateButton.vue` - Botão abrir portão
- ✅ `frontend/src/components/GateLogList.vue` - Lista de logs

**Views:**
- ✅ `frontend/src/views/Login.vue` - Tela de login
- ✅ `frontend/src/views/Dashboard.vue` - Dashboard principal

### Rodar frontend

```powershell
cd frontend
npm run dev
```

**Frontend estará em:** `http://localhost:5173`

---

## 4️⃣ Testar Integração Completa

### 1. Testar Backend

```powershell
# Health check
curl http://localhost:5000/api/health

# Abrir portão (requer JWT - vai retornar 401)
curl -X POST http://localhost:5000/api/gates/open
```

### 2. Testar Endpoints AGI

```powershell
# Verificar permissão de portão
curl "http://localhost:5000/api/agi/check-gate-permission?tenant=belavista&extension=1001&gate=social"

# Buscar rota de saída
curl "http://localhost:5000/api/agi/get-outbound-route?tenantId=1&number=91199887766"

# Registrar log de portão
curl -X POST http://localhost:5000/api/agi/log-gate-event `
  -H "Content-Type: application/json" `
  -d '{"tenantId":1,"extension":"1001","gateName":"social","action":"opened"}'
```

### 3. Testar Frontend

1. Acesse: `http://localhost:5173`
2. Faça login (mock temporário):
   - Usuário: `1001`
   - Senha: `senha123`
3. Clique em "Abrir Portão"
4. Veja logs em tempo real

### 4. Testar Asterisk + *43

1. Configure softphone (Zoiper/Linphone):
   - **Servidor:** localhost:5060
   - **Ramal:** 1001
   - **Senha:** senha1001
   - **Username:** 1001@belavista

2. Disque `*43` no softphone
3. Deve ouvir o echo test

### 5. Testar Abertura de Portão via Asterisk

1. No softphone, disque `*500` (portão social)
2. Asterisk vai:
   - Verificar permissão via AGI
   - Executar script open_gate.sh
   - Registrar log no banco
   - Broadcast evento via SignalR
3. Veja log aparecer no dashboard frontend

---

## 📁 Estrutura Final do Projeto

```
MAGNUS-PBX/
├── backend/
│   ├── Magnus.Pbx/
│   │   ├── Program.cs ✅
│   │   ├── appsettings.json ✅
│   │   ├── Controllers/
│   │   │   └── GatesController.cs ✅
│   │   ├── Hubs/
│   │   │   └── AsteriskEventsHub.cs ✅
│   │   └── Services/
│   │       └── AsteriskAmiService.cs ✅
│   ├── Magnus.Core/
│   │   └── Entities/
│   │       └── Entities.cs ✅
│   └── Magnus.Infrastructure/
│       └── Data/
│           └── MagnusDbContext.cs ✅
│
├── frontend/
│   ├── src/
│   │   ├── main.ts ✅
│   │   ├── App.vue ✅
│   │   ├── services/
│   │   │   ├── api.ts ✅
│   │   │   └── gateService.ts ✅
│   │   ├── stores/
│   │   │   └── auth.ts ✅
│   │   ├── composables/
│   │   │   └── useSignalR.ts ✅
│   │   ├── components/
│   │   │   ├── OpenGateButton.vue ✅
│   │   │   └── GateLogList.vue ✅
│   │   └── views/
│   │       ├── Login.vue ✅
│   │       └── Dashboard.vue ✅
│   ├── package.json ✅
│   ├── vite.config.ts ✅
│   └── tsconfig.json ✅
│
├── asterisk_etc/
│   ├── extensions.conf ✅ (CORRIGIDO)
│   ├── extconfig.conf ✅ (CORRIGIDO)
│   ├── pjsip.conf ✅
│   └── res_config_pgsql.conf ✅
│
├── sql/
│   ├── init.sql ✅
│   └── 03_fix_and_validate.sql ✅
│
├── docker-compose.yml ✅
├── Dockerfile ✅
└── scripts/
    └── deploy.ps1 ✅
```

---

## 🔧 Próximos Passos (TODO)

### Backend:
- [ ] Implementar `AuthController.cs` com endpoint de login real
- [ ] Criar middleware de tratamento de erros
- [ ] Implementar lógica de abertura de portão via GPIO/HTTP/MQTT
- [ ] Adicionar validação de horários permitidos
- [ ] Implementar notificações por e-mail/SMS quando portão abrir

### Frontend:
- [ ] Implementar integração WebRTC com JsSIP para videoporteiro
- [ ] Criar componente de chamada de vídeo
- [ ] Adicionar dashboard com estatísticas
- [ ] Implementar gerenciamento de permissões
- [ ] Criar tela de administração de usuários

### Integração:
- [ ] Testar abertura de portão real via relay
- [ ] Configurar SSL/TLS para produção
- [ ] Criar scripts de deploy automático
- [ ] Configurar CI/CD pipeline

---

## 🐛 Troubleshooting

### Backend não inicia:
```powershell
# Verificar se PostgreSQL está rodando
docker compose ps

# Ver logs
cd backend/Magnus.Pbx
dotnet run --verbosity detailed
```

### Frontend não conecta ao backend:
```powershell
# Verificar proxy no vite.config.ts
# Backend DEVE estar em http://localhost:5000
# Frontend DEVE estar em http://localhost:5173
```

### Asterisk não responde *43:
```powershell
# Verificar dialplan
docker compose exec asterisk-magnus asterisk -rx "dialplan show ctx-belavista"

# Verificar endpoints
docker compose exec asterisk-magnus asterisk -rx "pjsip show endpoints"

# Ver logs em tempo real
docker compose logs -f asterisk-magnus
```

---

## 📞 Contatos para Teste

**Tenant: belavista (slug)**

| Ramal | Senha | Username | Context |
|-------|-------|----------|---------|
| 1001 | senha1001 | 1001@belavista | ctx-belavista |
| 1002 | senha1002 | 1002@belavista | ctx-belavista |

**Códigos de Teste:**
- `*43` - Echo Test
- `*97` - VoiceMail
- `1002` - Ligar para ramal 1002

---

## ✅ Status do Projeto

- ✅ **Asterisk:** Configurado e rodando
- ✅ **PostgreSQL:** Schema criado
- ✅ **Backend (C#):** Estrutura criada
- ✅ **Frontend (Vue):** Estrutura criada
- ✅ **SignalR:** Hub configurado
- ✅ **AMI Integration:** AsteriskAmiService implementado
- 🔄 **Authentication:** Mock implementado, falta API real
- 🔄 **Gate Control:** Lógica implementada, falta hardware
- ⏳ **WebRTC:** Pendente

**Pronto para começar o desenvolvimento! 🚀**
