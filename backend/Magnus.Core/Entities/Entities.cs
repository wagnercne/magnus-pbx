namespace Magnus.Core.Entities;

/// <summary>
/// Tenant (cliente/empresa) no sistema multi-tenant
/// </summary>
public class Tenant
{
    public int Id { get; set; }
    public Guid Uuid { get; set; } = Guid.NewGuid();
    public required string Slug { get; set; } // belavista, acme, etc
    public required string Name { get; set; }
    public string? Domain { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navegação
    public ICollection<Extension> Extensions { get; set; } = new List<Extension>();
    public ICollection<GateLog> GateLogs { get; set; } = new List<GateLog>();
    public ICollection<OutboundRoute> OutboundRoutes { get; set; } = new List<OutboundRoute>();
    public ICollection<PbxFeature> PbxFeatures { get; set; } = new List<PbxFeature>();
    public ICollection<Queue> Queues { get; set; } = new List<Queue>();
    public ICollection<Trunk> Trunks { get; set; } = new List<Trunk>();
}

/// <summary>
/// Ramal/Extension de um tenant
/// </summary>
public class Extension
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string Number { get; set; } // 1001, 1002, etc
    public string? Name { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// Log de eventos de portão
/// </summary>
public class GateLog
{
    public long Id { get; set; }
    public int TenantId { get; set; }
    public required string Extension { get; set; }
    public required string GateName { get; set; } // "social", "garagem", "fundos"
    public DateTime EventTime { get; set; } = DateTime.UtcNow;
    public string? UniqueId { get; set; } // Link com CDR do Asterisk
    public required string Action { get; set; } // "opened", "attempted", "denied"
    public string? IpAddress { get; set; }
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// Permissões de acesso ao portão
/// </summary>
public class Permission
{
    public int Id { get; set; }
    public int TenantId { get; set; }
    public required string Extension { get; set; }
    public required string GateName { get; set; }
    public bool CanOpen { get; set; } = true;
    public DateTime? ValidFrom { get; set; }
    public DateTime? ValidUntil { get; set; }
    public bool IsActive { get; set; } = true;
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// Tabela extensions (dialplan dinâmico) - ctx-dynamic
/// </summary>
public class DialplanExtension
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string Context { get; set; } // ctx-dynamic
    public required string Exten { get; set; } // _XXXX, _*X., etc
    public int Priority { get; set; }
    public required string App { get; set; } // NoOp, Set, Dial, etc
    public string? Appdata { get; set; }
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// CDR - Call Detail Records
/// </summary>
public class Cdr
{
    public long Id { get; set; }
    public string? CallDate { get; set; }
    public string? Clid { get; set; }
    public string? Src { get; set; }
    public string? Dst { get; set; }
    public string? DContext { get; set; }
    public string? Channel { get; set; }
    public string? DstChannel { get; set; }
    public string? LastApp { get; set; }
    public string? LastData { get; set; }
    public int? Duration { get; set; }
    public int? BillSec { get; set; }
    public string? Disposition { get; set; }
    public string? AmaFlags { get; set; }
    public string? AccountCode { get; set; }
    public string? UniqueId { get; set; }
    public string? UserField { get; set; }
}

/// <summary>
/// Rotas de saída (outbound routes)
/// </summary>
public class OutboundRoute
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string Name { get; set; }
    public required string Pattern { get; set; } // _9XXXXXXXX
    public required string TrunkName { get; set; }
    public int Priority { get; set; } = 1;
    public bool IsActive { get; set; } = true;
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// Features do PBX (IVR, grupos, etc)
/// </summary>
public class PbxFeature
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string FeatureType { get; set; } // ivr, ring_group, time_condition
    public required string Name { get; set; }
    public required string Context { get; set; }
    public string? Config { get; set; } // JSON com configurações
    public bool IsActive { get; set; } = true;
    
    // Navegação
    public Tenant? Tenant { get; set; }
}

/// <summary>
/// Filas de atendimento
/// </summary>
public class Queue
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string Name { get; set; }
    public string? Strategy { get; set; } // ringall, leastrecent, fewestcalls
    public int? Timeout { get; set; }
    public int? Retry { get; set; }
    public int? MaxLen { get; set; }
    public bool IsActive { get; set; } = true;
    
    // Navegação
    public Tenant? Tenant { get; set; }
    public ICollection<QueueMember> Members { get; set; } = new List<QueueMember>();
}

/// <summary>
/// Membros de fila
/// </summary>
public class QueueMember
{
    public int Id { get; set; }
    public required string QueueName { get; set; }
    public required string Interface { get; set; } // PJSIP/1001
    public int Penalty { get; set; } = 0;
    public bool Paused { get; set; } = false;
    
    // Navegação
    public Queue? Queue { get; set; }
}

/// <summary>
/// Logs de fila
/// </summary>
public class QueueLog
{
    public long Id { get; set; }
    public DateTime? Time { get; set; }
    public string? CallId { get; set; }
    public string? QueueName { get; set; }
    public string? Agent { get; set; }
    public string? Event { get; set; }
    public string? Data1 { get; set; }
    public string? Data2 { get; set; }
    public string? Data3 { get; set; }
    public string? Data4 { get; set; }
    public string? Data5 { get; set; }
}

/// <summary>
/// Troncos SIP
/// </summary>
public class Trunk
{
    public int Id { get; set; }
    public int? TenantId { get; set; }
    public required string Name { get; set; }
    public required string Provider { get; set; } // Vivo, Claro, etc
    public string? Host { get; set; }
    public string? Username { get; set; }
    public string? Secret { get; set; }
    public string? Context { get; set; }
    public bool IsActive { get; set; } = true;
    
    // Navegação
    public Tenant? Tenant { get; set; }
}
