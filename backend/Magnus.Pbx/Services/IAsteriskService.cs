namespace Magnus.Pbx.Services;

public interface IAsteriskService
{
    Task<bool> OriginateCallAsync(string extension, string context, string application, string data);
    Task<string?> ExecuteCommandAsync(string command);
}
