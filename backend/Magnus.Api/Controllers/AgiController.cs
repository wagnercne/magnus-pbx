using Magnus.Pbx.Services;
using Microsoft.AspNetCore.Mvc;

namespace Magnus.Pbx.Controllers;

/// <summary>
/// Endpoints AGI para Asterisk chamar durante processamento de chamadas
/// Estes endpoints são chamados por scripts AGI/FastAGI ou dialplan via CURL
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AgiController : ControllerBase
{
    private readonly AgiService _agiService;
    private readonly ILogger<AgiController> _logger;

    public AgiController(AgiService agiService, ILogger<AgiController> logger)
    {
        _agiService = agiService;
        _logger = logger;
    }

    /// <summary>
    /// Verifica se ramal tem permissão para abrir portão
    /// Chamado pelo Asterisk via: CURL(http://backend:5000/api/agi/check-gate-permission?tenant=belavista&extension=1001&gate=social)
    /// </summary>
    [HttpGet("check-gate-permission")]
    public async Task<IActionResult> CheckGatePermission(
        [FromQuery] string tenant,
        [FromQuery] string extension,
        [FromQuery] string gate)
    {
        if (string.IsNullOrEmpty(tenant) || string.IsNullOrEmpty(extension) || string.IsNullOrEmpty(gate))
        {
            return BadRequest(new { allowed = false, reason = "Parâmetros obrigatórios faltando" });
        }

        _logger.LogInformation("AGI: Verificando permissão de portão - {Tenant}/{Extension}/{Gate}",
            tenant, extension, gate);

        var (allowed, reason) = await _agiService.CheckGatePermissionAsync(tenant, extension, gate);

        return Ok(new
        {
            allowed,
            reason,
            tenant,
            extension,
            gate
        });
    }

    /// <summary>
    /// Busca rota de saída para número discado
    /// Retorna trunk e número normalizado
    /// </summary>
    [HttpGet("get-outbound-route")]
    public async Task<IActionResult> GetOutboundRoute(
        [FromQuery] int? tenantId,
        [FromQuery] string? tenant,
        [FromQuery] string number,
        [FromQuery] string? format)
    {
        if (string.IsNullOrEmpty(number))
        {
            return BadRequest(new { trunk = (string?)null, error = "Parâmetros inválidos" });
        }

        var tenantRef = tenantId.HasValue && tenantId.Value > 0
            ? tenantId.Value.ToString()
            : tenant;

        if (string.IsNullOrWhiteSpace(tenantRef))
        {
            return BadRequest(new { trunk = (string?)null, error = "TenantId ou tenant é obrigatório" });
        }

        _logger.LogInformation("AGI: Buscando rota de saída - TenantRef={TenantRef}, Number={Number}",
            tenantRef, number);

        var decision = await _agiService.GetOutboundRouteDecisionAsync(tenantRef, number);

        if (string.Equals(format, "text", StringComparison.OrdinalIgnoreCase))
        {
            if (string.IsNullOrWhiteSpace(decision.TrunkName))
            {
                return Content(string.Empty, "text/plain");
            }

            return Content($"{decision.TrunkName}|{decision.DialNumber}", "text/plain");
        }

        return Ok(new
        {
            trunk = decision.TrunkName,
            dialNumber = decision.DialNumber,
            route = decision.RouteName,
            tenant = tenantRef,
            number,
            found = decision.TrunkName != null
        });
    }

    /// <summary>
    /// Registra evento de portão (aberto, negado, tentativa)
    /// </summary>
    [HttpPost("log-gate-event")]
    public async Task<IActionResult> LogGateEvent([FromBody] GateEventRequest request)
    {
        if (request == null || request.TenantId <= 0 || string.IsNullOrEmpty(request.Extension))
        {
            return BadRequest(new { success = false, error = "Parâmetros inválidos" });
        }

        _logger.LogInformation("AGI: Registrando evento de portão - {TenantId}/{Extension}/{Gate}/{Action}",
            request.TenantId, request.Extension, request.GateName, request.Action);

        var logId = await _agiService.LogGateEventAsync(
            request.TenantId,
            request.Extension,
            request.GateName,
            request.Action,
            request.UniqueId,
            request.IpAddress
        );

        return Ok(new
        {
            success = logId > 0,
            logId,
            message = logId > 0 ? "Evento registrado com sucesso" : "Erro ao registrar evento"
        });
    }

    /// <summary>
    /// Obtém configuração de feature do PBX (IVR, filas, etc)
    /// </summary>
    [HttpGet("get-feature")]
    public async Task<IActionResult> GetFeature(
        [FromQuery] int tenantId,
        [FromQuery] string type,
        [FromQuery] string context)
    {
        if (tenantId <= 0 || string.IsNullOrEmpty(type) || string.IsNullOrEmpty(context))
        {
            return BadRequest(new { feature = (object?)null, error = "Parâmetros inválidos" });
        }

        _logger.LogInformation("AGI: Buscando feature - TenantId={TenantId}, Type={Type}, Context={Context}",
            tenantId, type, context);

        var feature = await _agiService.GetFeatureAsync(tenantId, type, context);

        return Ok(new
        {
            feature,
            found = feature != null
        });
    }
}

public class GateEventRequest
{
    public int TenantId { get; set; }
    public string Extension { get; set; } = string.Empty;
    public string GateName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string? UniqueId { get; set; }
    public string? IpAddress { get; set; }
}
