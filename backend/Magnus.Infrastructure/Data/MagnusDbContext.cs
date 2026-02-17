using Magnus.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace Magnus.Infrastructure.Data;

public class MagnusDbContext : DbContext
{
    public MagnusDbContext(DbContextOptions<MagnusDbContext> options) : base(options)
    {
    }
    
    // Tabelas principais
    public DbSet<Tenant> Tenants { get; set; }
    public DbSet<Extension> Extensions { get; set; }
    public DbSet<GateLog> GateLogs { get; set; }
    public DbSet<Permission> Permissions { get; set; }
    
    // Tabelas de dialplan e rotas
    public DbSet<DialplanExtension> DialplanExtensions { get; set; }
    public DbSet<OutboundRoute> OutboundRoutes { get; set; }
    public DbSet<PbxFeature> PbxFeatures { get; set; }
    public DbSet<Trunk> Trunks { get; set; }
    
    // Tabelas de filas
    public DbSet<Queue> Queues { get; set; }
    public DbSet<QueueMember> QueueMembers { get; set; }
    public DbSet<QueueLog> QueueLogs { get; set; }
    
    // CDR
    public DbSet<Cdr> Cdrs { get; set; }
    
    // Tabelas Asterisk PJSIP (para leitura)
    public DbSet<PsEndpoint> PsEndpoints { get; set; }
    public DbSet<PsAuth> PsAuths { get; set; }
    public DbSet<PsAor> PsAors { get; set; }
    public DbSet<PsContact> PsContacts { get; set; }
    public DbSet<PsTransport> PsTransports { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Configuração de Tenant
        modelBuilder.Entity<Tenant>(entity =>
        {
            entity.ToTable("tenants");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Slug).IsUnique();
            entity.HasIndex(e => e.Uuid).IsUnique();
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Uuid).HasColumnName("uuid");
            entity.Property(e => e.Slug).HasColumnName("slug").HasMaxLength(50);
            entity.Property(e => e.Name).HasColumnName("name").HasMaxLength(100);
            entity.Property(e => e.Domain).HasColumnName("domain").HasMaxLength(100);
            entity.Property(e => e.IsActive).HasColumnName("is_active");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            entity.Property(e => e.UpdatedAt).HasColumnName("updated_at");
        });
        
        // Configuração de Extension
        modelBuilder.Entity<Extension>(entity =>
        {
            entity.ToTable("extensions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.TenantId, e.Number }).IsUnique();
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Number).HasColumnName("extension").HasMaxLength(20);
            entity.Property(e => e.Name).HasColumnName("name").HasMaxLength(100);
            entity.Property(e => e.Email).HasColumnName("email").HasMaxLength(100);
            entity.Property(e => e.IsActive).HasColumnName("active");
            entity.Property(e => e.CreatedAt).HasColumnName("created_at");
            
            entity.HasOne(e => e.Tenant)
                  .WithMany(t => t.Extensions)
                  .HasForeignKey(e => e.TenantId);
        });
        
        // Configuração de GateLog
        modelBuilder.Entity<GateLog>(entity =>
        {
            entity.ToTable("gate_logs");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TenantId);
            entity.HasIndex(e => e.EventTime);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Extension).HasColumnName("extension").HasMaxLength(40);
            entity.Property(e => e.GateName).HasColumnName("gate_name").HasMaxLength(100);
            entity.Property(e => e.EventTime).HasColumnName("event_time");
            entity.Property(e => e.UniqueId).HasColumnName("uniqueid").HasMaxLength(150);
            entity.Property(e => e.Action).HasColumnName("action").HasMaxLength(20);
            entity.Property(e => e.IpAddress).HasColumnName("ip_address").HasMaxLength(50);
        });
        
        // Configuração de Permission
        modelBuilder.Entity<Permission>(entity =>
        {
            entity.ToTable("permissions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.TenantId, e.Extension, e.GateName });
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Extension).HasColumnName("extension");
            entity.Property(e => e.GateName).HasColumnName("gate_name");
            entity.Property(e => e.CanOpen).HasColumnName("can_open");
            entity.Property(e => e.ValidFrom).HasColumnName("valid_from");
            entity.Property(e => e.ValidUntil).HasColumnName("valid_until");
            entity.Property(e => e.IsActive).HasColumnName("is_active");
        });
        
        // Configuração de DialplanExtension
        modelBuilder.Entity<DialplanExtension>(entity =>
        {
            entity.ToTable("extensions");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.Context, e.Exten, e.Priority });
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Context).HasColumnName("context");
            entity.Property(e => e.Exten).HasColumnName("exten");
            entity.Property(e => e.Priority).HasColumnName("priority");
            entity.Property(e => e.App).HasColumnName("app");
            entity.Property(e => e.Appdata).HasColumnName("appdata");
        });
        
        // Configuração de CDR
        modelBuilder.Entity<Cdr>(entity =>
        {
            entity.ToTable("cdr");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UniqueId);
            entity.HasIndex(e => e.CallDate);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CallDate).HasColumnName("calldate");
            entity.Property(e => e.Clid).HasColumnName("clid");
            entity.Property(e => e.Src).HasColumnName("src");
            entity.Property(e => e.Dst).HasColumnName("dst");
            entity.Property(e => e.DContext).HasColumnName("dcontext");
            entity.Property(e => e.Channel).HasColumnName("channel");
            entity.Property(e => e.DstChannel).HasColumnName("dstchannel");
            entity.Property(e => e.LastApp).HasColumnName("lastapp");
            entity.Property(e => e.LastData).HasColumnName("lastdata");
            entity.Property(e => e.Duration).HasColumnName("duration");
            entity.Property(e => e.BillSec).HasColumnName("billsec");
            entity.Property(e => e.Disposition).HasColumnName("disposition");
            entity.Property(e => e.AmaFlags).HasColumnName("amaflags");
            entity.Property(e => e.AccountCode).HasColumnName("accountcode");
            entity.Property(e => e.UniqueId).HasColumnName("uniqueid");
            entity.Property(e => e.UserField).HasColumnName("userfield");
        });
        
        // Configuração de OutboundRoute
        modelBuilder.Entity<OutboundRoute>(entity =>
        {
            entity.ToTable("outbound_routes");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TenantId);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Name).HasColumnName("name");
            entity.Property(e => e.Pattern).HasColumnName("pattern");
            entity.Property(e => e.TrunkName).HasColumnName("trunk_name");
            entity.Property(e => e.Priority).HasColumnName("priority");
            entity.Property(e => e.IsActive).HasColumnName("is_active");
        });
        
        // Configuração de PbxFeature
        modelBuilder.Entity<PbxFeature>(entity =>
        {
            entity.ToTable("pbx_features");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TenantId);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.FeatureType).HasColumnName("feature_type");
            entity.Property(e => e.Name).HasColumnName("name");
            entity.Property(e => e.Context).HasColumnName("context");
            entity.Property(e => e.Config).HasColumnName("config");
            entity.Property(e => e.IsActive).HasColumnName("is_active");
        });
        
        // Configuração de Queue
        modelBuilder.Entity<Queue>(entity =>
        {
            entity.ToTable("queues");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TenantId);
            entity.HasIndex(e => e.Name);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Name).HasColumnName("name");
            entity.Property(e => e.Strategy).HasColumnName("strategy");
            entity.Property(e => e.Timeout).HasColumnName("timeout");
            entity.Property(e => e.Retry).HasColumnName("retry");
            entity.Property(e => e.MaxLen).HasColumnName("maxlen");
            entity.Property(e => e.IsActive).HasColumnName("is_active");
        });
        
        // Configuração de QueueMember
        modelBuilder.Entity<QueueMember>(entity =>
        {
            entity.ToTable("queue_members");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.QueueName, e.Interface });
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.QueueName).HasColumnName("queue_name");
            entity.Property(e => e.Interface).HasColumnName("interface");
            entity.Property(e => e.Penalty).HasColumnName("penalty");
            entity.Property(e => e.Paused).HasColumnName("paused");
        });
        
        // Configuração de QueueLog
        modelBuilder.Entity<QueueLog>(entity =>
        {
            entity.ToTable("queue_log");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Time);
            entity.HasIndex(e => e.CallId);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Time).HasColumnName("time");
            entity.Property(e => e.CallId).HasColumnName("callid");
            entity.Property(e => e.QueueName).HasColumnName("queuename");
            entity.Property(e => e.Agent).HasColumnName("agent");
            entity.Property(e => e.Event).HasColumnName("event");
            entity.Property(e => e.Data1).HasColumnName("data1");
            entity.Property(e => e.Data2).HasColumnName("data2");
            entity.Property(e => e.Data3).HasColumnName("data3");
            entity.Property(e => e.Data4).HasColumnName("data4");
            entity.Property(e => e.Data5).HasColumnName("data5");
        });
        
        // Configuração de Trunk
        modelBuilder.Entity<Trunk>(entity =>
        {
            entity.ToTable("trunks");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TenantId);
            entity.HasIndex(e => e.Name);
            
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.TenantId).HasColumnName("tenant_id");
            entity.Property(e => e.Name).HasColumnName("name");
            entity.Property(e => e.Provider).HasColumnName("provider");
            entity.Property(e => e.Host).HasColumnName("host");
            entity.Property(e => e.Username).HasColumnName("username");
            entity.Property(e => e.Secret).HasColumnName("secret");
            entity.Property(e => e.Context).HasColumnName("context");
            entity.Property(e => e.IsActive).HasColumnName("is_active");
        });
        
        // Tabelas PJSIP (somente leitura)
        modelBuilder.Entity<PsEndpoint>(entity =>
        {
            entity.ToTable("ps_endpoints");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Context).HasColumnName("context");
            entity.Property(e => e.Transport).HasColumnName("transport");
        });
        
        modelBuilder.Entity<PsAuth>(entity =>
        {
            entity.ToTable("ps_auths");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Username).HasColumnName("username");
        });
        
        modelBuilder.Entity<PsAor>(entity =>
        {
            entity.ToTable("ps_aors");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
        });
        
        modelBuilder.Entity<PsContact>(entity =>
        {
            entity.ToTable("ps_contacts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Uri).HasColumnName("uri");
        });
        
        modelBuilder.Entity<PsTransport>(entity =>
        {
            entity.ToTable("ps_transports");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Protocol).HasColumnName("protocol");
            entity.Property(e => e.Bind).HasColumnName("bind");
        });
    }
}

// Classes para tabelas PJSIP
public class PsEndpoint
{
    public string Id { get; set; } = string.Empty;
    public int? TenantId { get; set; }
    public string? Context { get; set; }
    public string? Transport { get; set; }
}

public class PsAuth
{
    public string Id { get; set; } = string.Empty;
    public int? TenantId { get; set; }
    public string? Username { get; set; }
}

public class PsAor
{
    public string Id { get; set; } = string.Empty;
    public int? TenantId { get; set; }
}

public class PsContact
{
    public string Id { get; set; } = string.Empty;
    public int? TenantId { get; set; }
    public string? Uri { get; set; }
}

public class PsTransport
{
    public string Id { get; set; } = string.Empty;
    public string? Protocol { get; set; }
    public string? Bind { get; set; }
}
