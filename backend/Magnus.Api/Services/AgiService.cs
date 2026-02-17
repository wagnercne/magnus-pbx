using Magnus.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

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
        try
        {
            // Busca rotas ativas do tenant ordenadas por prioridade
            var routes = await _context.OutboundRoutes
                .Where(r => r.TenantId == tenantId && r.IsActive)
                .OrderBy(r => r.Priority)
                .ToListAsync();

            foreach (var route in routes)
            {
                // Verifica se o número discado corresponde ao padrão
                // Pattern pode ser: _9XXXXXXXX, _0800XXXXXXX, etc
                if (MatchesPattern(dialedNumber, route.Pattern))
                {
                    _logger.LogInformation("Número {DialedNumber} corresponde à rota {RouteName}, usando trunk {TrunkName}",
                        dialedNumber, route.Name, route.TrunkName);
                    return route.TrunkName;
                }
            }

            _logger.LogWarning("Nenhuma rota encontrada para {TenantId}/{DialedNumber}", tenantId, dialedNumber);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao buscar rota de saída: {TenantId}/{DialedNumber}", tenantId, dialedNumber);
            return null;
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
}
