using Magnus.Core.Entities;
using Magnus.Infrastructure.Data;
using Magnus.Pbx.Hubs;
using Magnus.Pbx.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ============================================
// CONFIGURAÇÃO DE LOGGING (Serilog)
// ============================================
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/magnus-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// ============================================
// CONFIGURAÇÃO DE SERVIÇOS
// ============================================

// PostgreSQL + Entity Framework
builder.Services.AddDbContext<MagnusDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key não configurada");
var key = Encoding.ASCII.GetBytes(jwtKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false,
        ClockSkew = TimeSpan.Zero
    };
    
    // Permitir JWT em SignalR
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// Controllers
builder.Services.AddControllers();

// SignalR
builder.Services.AddSignalR();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Magnus PBX API", Version = "v1" });
    
    // JWT no Swagger
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "JWT Authorization header usando Bearer. Exemplo: 'Bearer {token}'",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowVueFrontend", policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
            ?? new[] { "http://localhost:5173", "http://localhost:8080" };

        policy.WithOrigins(origins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

// ============================================
// SERVIÇOS CUSTOMIZADOS
// ============================================

// AGI Service (para chamadas do Asterisk)
builder.Services.AddScoped<Magnus.Pbx.Services.AgiService>();

// Asterisk AMI Service (opcional)
var enableAmi = builder.Configuration.GetValue<bool>("Asterisk:EnableAmi");
if (enableAmi)
{
    builder.Services.AddHostedService<AsteriskAmiService>();
    builder.Services.AddSingleton<IAsteriskService, AsteriskAmiService>();
}

// AutoMapper (se usar)
// builder.Services.AddAutoMapper(typeof(Program));

// ============================================
// BUILD DA APLICAÇÃO
// ============================================
var app = builder.Build();

// ============================================
// MIDDLEWARE PIPELINE
// ============================================

// Swagger (apenas em desenvolvimento)
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Magnus PBX API v1");
        c.RoutePrefix = string.Empty; // Swagger na raiz
    });
}

app.UseExceptionHandler(handler =>
{
    handler.Run(async context =>
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync("{\"message\":\"Erro interno do servidor\"}");
    });
});

// CORS
app.UseCors("AllowVueFrontend");

// HTTPS Redirect (descomente em produção)
// app.UseHttpsRedirection();

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// Controllers
app.MapControllers();

// SignalR Hubs
app.MapHub<AsteriskEventsHub>("/hubs/asterisk");

// ============================================
// INICIALIZAÇÃO DO BANCO (migrations)
// ============================================
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<MagnusDbContext>();
    try
    {
        db.Database.Migrate();
        Log.Information("Database migrated successfully");
    }
    catch (Exception ex)
    {
        Log.Error(ex, "An error occurred while migrating the database");
    }
}

// ============================================
// START
// ============================================
Log.Information("Magnus PBX API starting...");
app.Run();

Log.Information("Magnus PBX API stopped");
