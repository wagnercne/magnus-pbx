using AsterNET.Manager;
using AsterNET.Manager.Event;
using AsterNET.Manager.Action;
using Microsoft.AspNetCore.SignalR;
using Magnus.Pbx.Hubs;

namespace Magnus.Pbx.Services;

/// <summary>
/// Serviço de integração com Asterisk Manager Interface (AMI)
/// </summary>
public class AsteriskAmiService : BackgroundService
{
    private readonly ILogger<AsteriskAmiService> _logger;
    private readonly IConfiguration _configuration;
    private readonly IServiceProvider _serviceProvider;
    private ManagerConnection? _manager;

    public AsteriskAmiService(
        ILogger<AsteriskAmiService> logger,
        IConfiguration configuration,
        IServiceProvider serviceProvider)
    {
        _logger = logger;
        _configuration = configuration;
        _serviceProvider = serviceProvider;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(5000, stoppingToken); // Aguarda 5 segundos para garantir que outros serviços iniciaram

        var host = _configuration["Asterisk:AmiHost"] ?? "localhost";
        var port = int.Parse(_configuration["Asterisk:AmiPort"] ?? "5038");
        var username = _configuration["Asterisk:AmiUsername"] ?? "admin";
        var password = _configuration["Asterisk:AmiPassword"] ?? "admin123";

        _logger.LogInformation("Conectando ao Asterisk AMI em {Host}:{Port}...", host, port);

        _manager = new ManagerConnection(host, port, username, password);

        // Event handlers
        _manager.NewChannel += OnNewChannel;
        _manager.Hangup += OnHangup;
        _manager.PeerStatus += OnPeerStatus;
        _manager.ConnectionState += OnConnectionState;

        try
        {
            _manager.Login();
            _logger.LogInformation("✅ Conectado ao Asterisk AMI com sucesso!");

            // Mantém a conexão viva
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(10000, stoppingToken);

                // Ping para manter conexão viva
                if (_manager.IsConnected())
                {
                    _manager.SendAction(new PingAction());
                }
                else
                {
                    _logger.LogWarning("Conexão AMI perdida, tentando reconectar...");
                    _manager.Login();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Erro ao conectar ao Asterisk AMI");
        }
    }

    /// <summary>
    /// Evento disparado quando há mudança no status de conexão
    /// </summary>
    private void OnConnectionState(object? sender, ConnectionStateEvent e)
    {
        _logger.LogInformation("AMI Connection State: {State}", e.State);
    }

    /// <summary>
    /// Evento disparado quando um novo canal é criado (nova chamada)
    /// </summary>
    private async void OnNewChannel(object? sender, NewChannelEvent e)
    {
        _logger.LogInformation(
            "Nova chamada: From={CallerIdNum}, Channel={Channel}, Context={Context}",
            e.CallerIdNum, e.Channel, e.Context
        );

        // Extrai tenant do contexto (ctx-belavista -> belavista)
        if (e.Context?.StartsWith("ctx-") == true)
        {
            var tenantSlug = e.Context.Substring(4);

            using var scope = _serviceProvider.CreateScope();
            var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<AsteriskEventsHub>>();

            await hubContext.Clients.Group($"tenant-{tenantSlug}").SendAsync("NewCall", new
            {
                From = e.CallerIdNum,
                To = e.Exten,
                TenantSlug = tenantSlug,
                Timestamp = DateTime.UtcNow
            });
        }
    }

    /// <summary>
    /// Evento disparado quando uma chamada é desligada
    /// </summary>
    private void OnHangup(object? sender, HangupEvent e)
    {
        _logger.LogInformation(
            "Chamada finalizada: Channel={Channel}, Cause={Cause}",
            e.Channel, e.Cause
        );
    }

    /// <summary>
    /// Evento disparado quando o status de um peer muda (registro/desregistro)
    /// </summary>
    private void OnPeerStatus(object? sender, PeerStatusEvent e)
    {
        _logger.LogInformation(
            "Peer Status: Peer={Peer}, PeerStatus={PeerStatus}",
            e.Peer, e.PeerStatus
        );
    }

    /// <summary>
    /// Origina uma chamada do Asterisk (usado para abrir portão via canal Local)
    /// </summary>
    public async Task<bool> OriginateCallAsync(string extension, string context, string application, string data)
    {
        if (_manager == null || !_manager.IsConnected())
        {
            _logger.LogError("AMI não está conectado");
            return false;
        }

        try
        {
            var originateAction = new OriginateAction
            {
                Channel = $"Local/{extension}@{context}",
                Application = application,
                Data = data,
                Timeout = 30000,
                CallerIdNumber = "GATE",
                CallerIdName = "Portão",
                Async = true
            };

            var response = _manager.SendAction(originateAction, 5000);

            _logger.LogInformation(
                "Originate enviado: Channel={Channel}, Response={Response}",
                originateAction.Channel, response?.Response
            );

            return response?.Response == "Success";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao originar chamada via AMI");
            return false;
        }
    }

    /// <summary>
    /// Executa um comando CLI do Asterisk
    /// </summary>
    public async Task<string?> ExecuteCommandAsync(string command)
    {
        if (_manager == null || !_manager.IsConnected())
        {
            _logger.LogError("AMI não está conectado");
            return null;
        }

        try
        {
            var commandAction = new CommandAction { Command = command };
            var response = _manager.SendAction(commandAction, 5000);

            return response?.Response == "Success" ? response.Message : null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao executar comando AMI: {Command}", command);
            return null;
        }
    }

    public override void Dispose()
    {
        if (_manager != null)
        {
            _logger.LogInformation("Desconectando do Asterisk AMI...");
            _manager.Logoff();
            _manager = null;
        }

        base.Dispose();
    }
}
