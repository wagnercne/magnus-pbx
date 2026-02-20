using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Magnus.Pbx.Hubs;

/// <summary>
/// Hub SignalR para eventos em tempo real do Asterisk
/// </summary>
[Authorize]
public class AsteriskEventsHub : Hub
{
    private readonly ILogger<AsteriskEventsHub> _logger;

    public AsteriskEventsHub(ILogger<AsteriskEventsHub> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Cliente conectou ao hub
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        var extension = Context.User?.FindFirst("Extension")?.Value;
        var tenantSlug = Context.User?.FindFirst("TenantSlug")?.Value;

        _logger.LogInformation(
            "Cliente conectado: {ConnectionId}, Ramal: {Extension}, Tenant: {TenantSlug}",
            Context.ConnectionId, extension, tenantSlug
        );

        // Adiciona cliente ao grupo do tenant (para broadcast por tenant)
        if (!string.IsNullOrEmpty(tenantSlug))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"tenant-{tenantSlug}");
        }

        await base.OnConnectedAsync();
    }

    /// <summary>
    /// Cliente desconectou do hub
    /// </summary>
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var extension = Context.User?.FindFirst("Extension")?.Value;
        var tenantSlug = Context.User?.FindFirst("TenantSlug")?.Value;

        _logger.LogInformation(
            "Cliente desconectado: {ConnectionId}, Ramal: {Extension}, Tenant: {TenantSlug}",
            Context.ConnectionId, extension, tenantSlug
        );

        if (!string.IsNullOrEmpty(tenantSlug))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"tenant-{tenantSlug}");
        }

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Broadcast de evento de portão aberto para todos os clientes do tenant
    /// </summary>
    public async Task NotifyGateOpened(string tenantSlug, string extension, string action, DateTime timestamp)
    {
        await Clients.Group($"tenant-{tenantSlug}").SendAsync("GateOpened", new
        {
            Extension = extension,
            TenantSlug = tenantSlug,
            Action = action,
            Timestamp = timestamp
        });
    }

    /// <summary>
    /// Broadcast de evento de portão negado
    /// </summary>
    public async Task NotifyGateDenied(string tenantSlug, string extension, string reason, DateTime timestamp)
    {
        await Clients.Group($"tenant-{tenantSlug}").SendAsync("GateDenied", new
        {
            Extension = extension,
            TenantSlug = tenantSlug,
            Reason = reason,
            Timestamp = timestamp
        });
    }

    /// <summary>
    /// Broadcast de nova chamada
    /// </summary>
    public async Task NotifyNewCall(string tenantSlug, string from, string to, DateTime timestamp)
    {
        await Clients.Group($"tenant-{tenantSlug}").SendAsync("NewCall", new
        {
            From = from,
            To = to,
            TenantSlug = tenantSlug,
            Timestamp = timestamp
        });
    }
}
