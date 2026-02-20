using Magnus.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Data.Common;

namespace Magnus.Pbx.Services;

/// <summary>
/// Serviço AGI (Asterisk Gateway Interface) para lógica de negócio durante chamadas
/// Usado via FastAGI ou AGI scripts que chamam esta API
/// </summary>
public class AgiService
{
    private readonly MagnusDbContext _context;
    private readonly ILogger<AgiService> _logger;

    public AgiService(MagnusDbContext context, ILogger<AgiService> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Verifica se um ramal tem permissão para abrir um portão específico
    /// </summary>
    /// <param name="tenantSlug">Slug do tenant (ex: belavista)</param>
    /// <param name="extension">Número do ramal (ex: 1001)</param>
    /// <param name="gateName">Nome do portão (ex: social, garagem)</param>
    /// <returns>Permissão concedida ou negada com motivo</returns>
    public async Task<(bool Allowed, string Reason)> CheckGatePermissionAsync(
        string tenantSlug, 
        string extension, 
        string gateName)
    {
        try
        {
            // Busca tenant
            var tenant = await _context.Tenants
                .FirstOrDefaultAsync(t => t.Slug == tenantSlug && t.IsActive);

            if (tenant == null)
            {
                return (false, "Tenant não encontrado ou inativo");
            }

            // Busca permissão
            var now = DateTime.UtcNow;
            var permission = await _context.Permissions
                .FirstOrDefaultAsync(p =>
                    p.TenantId == tenant.Id &&
                    p.Extension == extension &&
                    p.GateName == gateName &&
                    p.IsActive &&
                    p.CanOpen &&
                    (p.ValidFrom == null || p.ValidFrom <= now) &&
                    (p.ValidUntil == null || p.ValidUntil >= now)
                );

            if (permission == null)
            {
                return (false, "Sem permissão para este portão");
            }

            return (true, "Permissão concedida");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao verificar permissão: {TenantSlug}/{Extension}/{GateName}", 
                tenantSlug, extension, gateName);
            return (false, "Erro interno ao verificar permissão");
        }
    }

    /// <summary>
    /// Busca rota de saída (outbound route) para um número discado
    /// </summary>
    /// <param name="tenantId">ID do tenant</param>
    /// <param name="dialedNumber">Número discado (ex: 91199887766)</param>
    /// <returns>Nome do trunk a usar ou null</returns>
    public async Task<string?> GetOutboundRouteAsync(int tenantId, string dialedNumber)
    {
        var decision = await GetOutboundRouteDecisionAsync(tenantId.ToString(), dialedNumber);
        return decision.TrunkName;
    }

    public async Task<OutboundRouteDecision> GetOutboundRouteDecisionAsync(string tenantRef, string dialedNumber)
    {
        try
        {
            var tenantId = await ResolveTenantIdAsync(tenantRef);
            if (tenantId == null)
            {
                _logger.LogWarning("Tenant nao encontrado para referencia {TenantRef}", tenantRef);
                return new OutboundRouteDecision(null, dialedNumber, null);
            }

            var v2Decisions = await LoadV2CandidatesAsync(tenantId.Value);
            if (v2Decisions.Count > 0)
            {
                foreach (var candidate in v2Decisions)
                {
                    if (!MatchesPattern(dialedNumber, candidate.Pattern))
                    {
                        continue;
                    }

                    var normalized = ApplyRule(dialedNumber, candidate.StripDigits, candidate.PrependDigits);
                    _logger.LogInformation(
                        "Outbound V2 match tenant={TenantId} route={RouteName} rule={RuleName} trunk={TrunkName} dial={Dialed}->{Normalized}",
                        tenantId.Value,
                        candidate.RouteName,
                        candidate.RuleName,
                        candidate.TrunkName,
                        dialedNumber,
                        normalized
                    );

                    return new OutboundRouteDecision(candidate.TrunkName, normalized, candidate.RouteName);
                }
            }

            // Fallback legado para compatibilidade
            var routes = await _context.OutboundRoutes
                .Where(r => r.TenantId == tenantId.Value && r.IsActive)
                .OrderBy(r => r.Priority)
                .ToListAsync();

            foreach (var route in routes)
            {
                if (MatchesPattern(dialedNumber, route.Pattern))
                {
                    _logger.LogInformation("Outbound legacy match tenant={TenantId} route={RouteName} trunk={TrunkName} dial={Dialed}",
                        tenantId.Value,
                        route.Name,
                        route.TrunkName,
                        dialedNumber);
                    return new OutboundRouteDecision(route.TrunkName, dialedNumber, route.Name);
                }
            }

            _logger.LogWarning("Nenhuma rota outbound encontrada para tenant={TenantId} numero={DialedNumber}", tenantId.Value, dialedNumber);
            return new OutboundRouteDecision(null, dialedNumber, null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao buscar rota outbound: {TenantRef}/{DialedNumber}", tenantRef, dialedNumber);
            return new OutboundRouteDecision(null, dialedNumber, null);
        }
    }

    /// <summary>
    /// Registra log de abertura de portão
    /// </summary>
    public async Task<long> LogGateEventAsync(
        int tenantId,
        string extension,
        string gateName,
        string action,
        string? uniqueId = null,
        string? ipAddress = null)
    {
        try
        {
            var log = new Magnus.Core.Entities.GateLog
            {
                TenantId = tenantId,
                Extension = extension,
                GateName = gateName,
                Action = action,
                EventTime = DateTime.UtcNow,
                UniqueId = uniqueId,
                IpAddress = ipAddress
            };

            _context.GateLogs.Add(log);
            await _context.SaveChangesAsync();

            return log.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao registrar log de portão: {TenantId}/{Extension}/{GateName}",
                tenantId, extension, gateName);
            return -1;
        }
    }

    /// <summary>
    /// Busca feature do PBX por tipo e contexto
    /// </summary>
    public async Task<Magnus.Core.Entities.PbxFeature?> GetFeatureAsync(
        int tenantId, 
        string featureType, 
        string context)
    {
        try
        {
            return await _context.PbxFeatures
                .FirstOrDefaultAsync(f =>
                    f.TenantId == tenantId &&
                    f.FeatureType == featureType &&
                    f.Context == context &&
                    f.IsActive
                );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao buscar feature: {TenantId}/{FeatureType}/{Context}",
                tenantId, featureType, context);
            return null;
        }
    }

    /// <summary>
    /// Verifica se número corresponde a um padrão Asterisk
    /// Implementação simplificada - para produção usar regex mais robusto
    /// </summary>
    private bool MatchesPattern(string number, string pattern)
    {
        // Remove underscore inicial se houver (_9XXXXXXXX -> 9XXXXXXXX)
        if (pattern.StartsWith('_'))
        {
            pattern = pattern.Substring(1);
        }

        // Se tamanhos diferentes, não corresponde
        if (number.Length != pattern.Length)
        {
            return false;
        }

        // Verifica caractere por caractere
        for (int i = 0; i < pattern.Length; i++)
        {
            char p = pattern[i];
            char n = number[i];

            if (p == 'X') // X = qualquer dígito
            {
                if (!char.IsDigit(n)) return false;
            }
            else if (p == 'Z') // Z = 1-9
            {
                if (!char.IsDigit(n) || n == '0') return false;
            }
            else if (p == 'N') // N = 2-9
            {
                if (!char.IsDigit(n) || n == '0' || n == '1') return false;
            }
            else if (p == '.') // . = wildcard (qualquer coisa)
            {
                // Aceita qualquer coisa daqui pra frente
                break;
            }
            else if (p != n) // Caractere literal deve ser exatamente igual
            {
                return false;
            }
        }

        return true;
    }

    private static string ApplyRule(string dialedNumber, int stripDigits, string? prependDigits)
    {
        var result = dialedNumber;

        if (stripDigits > 0)
        {
            if (stripDigits >= result.Length)
            {
                result = string.Empty;
            }
            else
            {
                result = result.Substring(stripDigits);
            }
        }

        if (!string.IsNullOrWhiteSpace(prependDigits))
        {
            result = prependDigits + result;
        }

        return result;
    }

    private async Task<int?> ResolveTenantIdAsync(string tenantRef)
    {
        if (int.TryParse(tenantRef, out var numericTenantId))
        {
            var exists = await _context.Tenants.AnyAsync(t => t.Id == numericTenantId && t.IsActive);
            return exists ? numericTenantId : null;
        }

        var tenant = await _context.Tenants
            .Where(t => t.Slug == tenantRef && t.IsActive)
            .Select(t => new { t.Id })
            .FirstOrDefaultAsync();

        return tenant?.Id;
    }

    private async Task<List<OutboundV2Candidate>> LoadV2CandidatesAsync(int tenantId)
    {
        var candidates = new List<OutboundV2Candidate>();

        if (!await TableExistsAsync("outbound_route_rules") || !await TableExistsAsync("outbound_route_trunks"))
        {
            return candidates;
        }

        await using var connection = _context.Database.GetDbConnection();
        if (connection.State != System.Data.ConnectionState.Open)
        {
            await connection.OpenAsync();
        }

        await using var command = connection.CreateCommand();
        command.CommandText = @"
            SELECT
                r.route_name,
                rr.rule_name,
                rr.pattern,
                rr.strip_digits,
                rr.prepend_digits,
                rt.trunk_name,
                r.priority AS route_priority,
                rr.priority AS rule_priority,
                rt.priority AS trunk_priority
            FROM outbound_routes r
            INNER JOIN outbound_route_rules rr ON rr.route_id = r.id
            INNER JOIN outbound_route_trunks rt ON rt.route_id = r.id
            WHERE r.tenant_id = @tenant_id
              AND r.is_active = TRUE
              AND rr.is_active = TRUE
              AND rt.is_active = TRUE
            ORDER BY r.priority, rr.priority, rt.priority";

        var tenantParameter = command.CreateParameter();
        tenantParameter.ParameterName = "@tenant_id";
        tenantParameter.Value = tenantId;
        command.Parameters.Add(tenantParameter);

        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            candidates.Add(new OutboundV2Candidate(
                RouteName: reader.GetString(0),
                RuleName: reader.GetString(1),
                Pattern: reader.GetString(2),
                StripDigits: reader.IsDBNull(3) ? 0 : reader.GetInt32(3),
                PrependDigits: reader.IsDBNull(4) ? null : reader.GetString(4),
                TrunkName: reader.GetString(5)
            ));
        }

        return candidates;
    }

    private async Task<bool> TableExistsAsync(string tableName)
    {
        await using var connection = _context.Database.GetDbConnection();
        if (connection.State != System.Data.ConnectionState.Open)
        {
            await connection.OpenAsync();
        }

        await using var command = connection.CreateCommand();
        command.CommandText = @"
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = @table_name
            LIMIT 1";

        var parameter = command.CreateParameter();
        parameter.ParameterName = "@table_name";
        parameter.Value = tableName;
        command.Parameters.Add(parameter);

        var result = await command.ExecuteScalarAsync();
        return result != null;
    }
}

public record OutboundRouteDecision(string? TrunkName, string DialNumber, string? RouteName);

internal record OutboundV2Candidate(
    string RouteName,
    string RuleName,
    string Pattern,
    int StripDigits,
    string? PrependDigits,
    string TrunkName
);
