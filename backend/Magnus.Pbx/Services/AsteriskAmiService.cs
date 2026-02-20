namespace Magnus.Pbx.Services;

/// <summary>
/// Implementacao baseline de integracao AMI para ambiente Docker.
/// Nesta fase, atua como no-op service para manter API compilavel.
/// </summary>
public class AsteriskAmiService : BackgroundService, IAsteriskService
{
    private readonly ILogger<AsteriskAmiService> _logger;
    private readonly IConfiguration _configuration;

    public AsteriskAmiService(
        ILogger<AsteriskAmiService> logger,
        IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var host = _configuration["Asterisk:AmiHost"] ?? "asterisk-magnus";
        var port = _configuration["Asterisk:AmiPort"] ?? "5038";

        _logger.LogInformation("AMI service inicializado (baseline). Host={Host}, Port={Port}", host, port);

        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
        }
    }

    public Task<bool> OriginateCallAsync(string extension, string context, string application, string data)
    {
        _logger.LogWarning(
            "OriginateCallAsync chamado em modo baseline. Extension={Extension}, Context={Context}, App={Application}",
            extension,
            context,
            application
        );

        return Task.FromResult(false);
    }

    public Task<string?> ExecuteCommandAsync(string command)
    {
        _logger.LogWarning("ExecuteCommandAsync chamado em modo baseline. Command={Command}", command);
        return Task.FromResult<string?>(null);
    }
}
