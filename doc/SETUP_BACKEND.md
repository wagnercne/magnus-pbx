# Backend C# - ASP.NET Core Web API

## Criar Projeto

```powershell
cd C:\DEV\PROJETOS\MAGNUS-PBX

# Criar solution
dotnet new sln -n Magnus

# Criar projetos
dotnet new webapi -n Magnus.Pbx -o backend/Magnus.Pbx
dotnet new classlib -n Magnus.Core -o backend/Magnus.Core
dotnet new classlib -n Magnus.Infrastructure -o backend/Magnus.Infrastructure

# Adicionar à solution
dotnet sln add backend/Magnus.Pbx/Magnus.Pbx.csproj
dotnet sln add backend/Magnus.Core/Magnus.Core.csproj
dotnet sln add backend/Magnus.Infrastructure/Magnus.Infrastructure.csproj

# Adicionar referências
cd backend/Magnus.Pbx
dotnet add reference ../Magnus.Core/Magnus.Core.csproj
dotnet add reference ../Magnus.Infrastructure/Magnus.Infrastructure.csproj

cd ../Magnus.Infrastructure
dotnet add reference ../Magnus.Core/Magnus.Core.csproj

cd ../../
```

## Instalar Pacotes

```powershell
cd backend/Magnus.Pbx

# EF Core + PostgreSQL
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design

# JWT Authentication
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer

# SignalR (já incluído no template)

# Asterisk AMI
dotnet add package AsterNET.AMI

# Logging
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console
dotnet add package Serilog.Sinks.File

# AutoMapper
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection

# Swagger (já incluído)

cd ../../
```

## Estrutura Criada

```
backend/
├── Magnus.Pbx/              # API REST
│   ├── Controllers/
│   │   ├── AuthController.cs
│   │   ├── TenantsController.cs
│   │   ├── ExtensionsController.cs
│   │   └── GatesController.cs
│   ├── Hubs/
│   │   └── AsteriskEventsHub.cs
│   ├── Middleware/
│   │   └── ErrorHandlerMiddleware.cs
│   ├── Program.cs
│   └── appsettings.json
│
├── Magnus.Core/             # Domínio
│   ├── Entities/
│   │   ├── Tenant.cs
│   │   ├── Extension.cs
│   │   ├── GateLog.cs
│   │   └── Permission.cs
│   ├── Interfaces/
│   │   ├── IRepository.cs
│   │   ├── IAsteriskService.cs
│   │   └── IGateService.cs
│   └── DTOs/
│       └── GateOpenRequest.cs
│
└── Magnus.Infrastructure/   # Infraestrutura
    ├── Data/
    │   ├── MagnusDbContext.cs
    │   └── Configurations/
    ├── Repositories/
    │   └── Repository.cs
    └── Services/
        ├── AsteriskAmiService.cs
        └── GateService.cs
```

## Próximo Passo

Executar:
```powershell
# Testar compilação
dotnet build

# Rodar API
cd backend/Magnus.Pbx
dotnet run
```

API estará disponível em: http://localhost:5000
