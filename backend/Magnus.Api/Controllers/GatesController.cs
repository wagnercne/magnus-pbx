using Magnus.Core.Entities;
using Magnus.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Magnus.Pbx.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class GatesController : ControllerBase
{
    private readonly MagnusDbContext _db;
    private readonly ILogger<GatesController> _logger;
    
    public GatesController(MagnusDbContext db, ILogger<GatesController> logger)
    {
        _db = db;
        _logger = logger;
    }
    
    // POST api/gates/open
    [HttpPost("open")]
    public async Task<IActionResult> OpenGate([FromBody] OpenGateRequest request)
    {
        try
        {
            // 1. Obter tenant e extension do JWT
            var tenantSlug = User.Claims.FirstOrDefault(c => c.Type == "TenantSlug")?.Value;
            var extensionNumber = User.Claims.FirstOrDefault(c => c.Type == "Extension")?.Value;
            
            if (string.IsNullOrEmpty(tenantSlug) || string.IsNullOrEmpty(extensionNumber))
            {
                return Unauthorized(new { message = "Token inválido" });
            }
            
            // 2. Buscar tenant
            var tenant = await _db.Tenants
                .FirstOrDefaultAsync(t => t.Slug == tenantSlug && t.IsActive);
            
            if (tenant == null)
            {
                return NotFound(new { message = "Tenant não encontrado" });
            }
            
            // 3. Verificar permissão
            var now = DateTime.UtcNow;
            var hasPermission = await _db.Permissions
                .AnyAsync(p => 
                    p.TenantId == tenant.Id &&
                    p.Extension == extensionNumber &&
                    p.GateName == request.GateName &&
                    p.CanOpen &&
                    p.IsActive &&
                    (p.ValidFrom == null || p.ValidFrom <= now) &&
                    (p.ValidUntil == null || p.ValidUntil >= now)
                );
            
            if (!hasPermission)
            {
                // Log tentativa negada
                await LogGateEvent(tenant.Id, extensionNumber, request.GateName, "denied");
                
                return Forbid();
            }
            
            // 4. TODO: Enviar comando para Asterisk AMI
            // await _asteriskService.OriginateCall(...);
            
            // 5. TODO: Enviar comando para hardware (GPIO/HTTP/MQTT)
            // await SendHardwareCommand(request.GateName);
            
            // 6. Log da abertura
            await LogGateEvent(tenant.Id, extensionNumber, request.GateName, "opened");
            
            _logger.LogInformation(
                "Portão {GateName} aberto por {Extension}@{Tenant}",
                request.GateName, extensionNumber, tenantSlug
            );
            
            return Ok(new
            {
                success = true,
                message = $"Portão {request.GateName} aberto com sucesso",
                timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao abrir portão");
            return StatusCode(500, new { message = "Erro interno do servidor" });
        }
    }
    
    // GET api/gates/logs
    [HttpGet("logs")]
    public async Task<IActionResult> GetLogs([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        try
        {
            var tenantSlug = User.Claims.FirstOrDefault(c => c.Type == "TenantSlug")?.Value;
            
            if (string.IsNullOrEmpty(tenantSlug))
            {
                return Unauthorized();
            }
            
            var tenant = await _db.Tenants
                .FirstOrDefaultAsync(t => t.Slug == tenantSlug);
            
            if (tenant == null)
            {
                return NotFound();
            }
            
            var query = _db.GateLogs
                .Where(g => g.TenantId == tenant.Id)
                .OrderByDescending(g => g.EventTime);
            
            var total = await query.CountAsync();
            
            var logs = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(g => new
                {
                    g.Id,
                    g.Extension,
                    g.GateName,
                    g.Action,
                    g.EventTime,
                    g.IpAddress
                })
                .ToListAsync();
            
            return Ok(new
            {
                data = logs,
                pagination = new
                {
                    currentPage = page,
                    pageSize,
                    totalItems = total,
                    totalPages = (int)Math.Ceiling((double)total / pageSize)
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao buscar logs de portão");
            return StatusCode(500, new { message = "Erro interno do servidor" });
        }
    }
    
    // Helper: Log de eventos de portão
    private async Task LogGateEvent(int tenantId, string extension, string gateName, string action)
    {
        var log = new GateLog
        {
            TenantId = tenantId,
            Extension = extension,
            GateName = gateName,
            Action = action,
            EventTime = DateTime.UtcNow,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString()
        };
        
        _db.GateLogs.Add(log);
        await _db.SaveChangesAsync();
    }
}

// DTOs
public class OpenGateRequest
{
    public required string GateName { get; set; } // "social", "garagem", "fundos"
}
