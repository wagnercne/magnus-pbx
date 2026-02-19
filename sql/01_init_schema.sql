-- =================================================================
-- MAGNUS PBX - Schema Principal do Banco de Dados
-- Versão: 2.0 (Reestruturado em 17/02/2026)
-- =================================================================
-- Ordem de execução: 01_init_schema.sql → 02_sample_data.sql
-- =================================================================

-- Habilitar extensão para UUID (útil para IDs únicos)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================================
-- 1. ESTRUTURA SAAS (TENANTS)
-- ==========================================================
CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    name VARCHAR(100) NOT NULL,
    domain VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);
COMMENT ON TABLE tenants IS 'Tabela mestre para isolamento de clientes (SaaS Multi-Tenant)';

-- ==========================================================
-- 2. PJSIP CORE (CONECTIVIDADE SIP)
-- ==========================================================
CREATE TABLE ps_endpoints (
    id VARCHAR(40) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    transport VARCHAR(40),
    aors VARCHAR(200),
    auth VARCHAR(40),
    context VARCHAR(40),
    disallow VARCHAR(200) DEFAULT 'all',
    allow VARCHAR(200) DEFAULT 'opus,g722,ulaw,alaw,vp8,h264',
    webrtc VARCHAR(10) DEFAULT 'yes',
    dtls_auto_generate_cert VARCHAR(10) DEFAULT 'yes',
    force_rport BOOLEAN DEFAULT true,
    rewrite_contact BOOLEAN DEFAULT true,
    rtp_symmetric BOOLEAN DEFAULT true,
    ice_support BOOLEAN DEFAULT true,
    mailboxes VARCHAR(200) DEFAULT NULL
);
COMMENT ON TABLE ps_endpoints IS 'PJSIP Endpoints (ramais SIP/WebRTC)';

CREATE TABLE ps_auths (
    id VARCHAR(40) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    auth_type VARCHAR(10) DEFAULT 'userpass',
    password VARCHAR(80),
    username VARCHAR(80)
);
COMMENT ON TABLE ps_auths IS 'Credenciais de autenticação SIP';

CREATE TABLE ps_aors (
    id VARCHAR(40) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    max_contacts INT DEFAULT 1,
    remove_existing BOOLEAN DEFAULT true,
    qualify_frequency INT DEFAULT 60
);
COMMENT ON TABLE ps_aors IS 'Address of Record - Gerencia registro de dispositivos';

CREATE TABLE ps_contacts (
    id VARCHAR(255) PRIMARY KEY,
    uri VARCHAR(511),
    expiration_time BIGINT,
    qualify_frequency INT,
    outbound_proxy VARCHAR(255),
    path TEXT,
    user_agent VARCHAR(255),
    reg_server VARCHAR(255),
    authenticate_qualify BOOLEAN DEFAULT false,
    via_addr VARCHAR(255),
    via_port INT,
    call_id VARCHAR(255),
    endpoint VARCHAR(40),
    prune_on_boot BOOLEAN DEFAULT true,
    qualify_timeout NUMERIC(10,2) DEFAULT 3.0,
    qualify_2xx_only BOOLEAN DEFAULT true
);
COMMENT ON TABLE ps_contacts IS 'Contatos dinâmicos registrados (realtime)';

CREATE INDEX idx_ps_contacts_endpoint ON ps_contacts(endpoint);
CREATE INDEX idx_ps_contacts_expiration ON ps_contacts(expiration_time);

CREATE TABLE ps_domain_aliases (
    id VARCHAR(80) PRIMARY KEY,
    domain_alias VARCHAR(80) UNIQUE,
    domain VARCHAR(80)
);
COMMENT ON TABLE ps_domain_aliases IS 'Aliases de domínio para roteamento multi-tenant';

CREATE TABLE ps_endpoint_id_ips (
    id VARCHAR(255) PRIMARY KEY,
    endpoint VARCHAR(255),
    match VARCHAR(255),
    srv_lookups BOOLEAN DEFAULT false,
    match_header VARCHAR(255)
);
CREATE INDEX idx_ps_endpoint_id_ips_endpoint ON ps_endpoint_id_ips(endpoint);
CREATE INDEX idx_ps_endpoint_id_ips_match ON ps_endpoint_id_ips(match);
COMMENT ON TABLE ps_endpoint_id_ips IS 'Identificação de endpoints por IP/subnet (multi-tenant)';

-- ==========================================================
-- 3. DIALPLAN REALTIME (LÓGICA DE ROTEAMENTO)
-- ==========================================================
CREATE TABLE extensions (
    id BIGSERIAL PRIMARY KEY,
    context VARCHAR(40) NOT NULL,
    exten VARCHAR(40) NOT NULL,
    priority INT NOT NULL DEFAULT 1,
    app VARCHAR(40) NOT NULL,
    appdata VARCHAR(256),
    tenant_id INT REFERENCES tenants(id)
);
CREATE UNIQUE INDEX idx_extensions ON extensions (context, exten, priority);
COMMENT ON TABLE extensions IS 'Dialplan dinâmico (armazenado em banco)';

-- ==========================================================
-- 4. ATENDIMENTO E FILAS
-- ==========================================================
CREATE TABLE queues (
    name VARCHAR(128) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    strategy VARCHAR(128) DEFAULT 'ringall',
    timeout INT DEFAULT 30,
    announce_frequency INT DEFAULT 0,
    setinterfacevar BOOLEAN DEFAULT true
);
COMMENT ON TABLE queues IS 'Filas de atendimento (call queues)';

CREATE TABLE queue_members (
    uniqueid SERIAL PRIMARY KEY,
    queue_name VARCHAR(128) REFERENCES queues(name),
    interface VARCHAR(128) NOT NULL,
    membername VARCHAR(128),
    state_interface VARCHAR(128),
    penalty INT DEFAULT 0,
    paused CHAR(1) DEFAULT '0',
    reason_paused VARCHAR(80),
    wrapuptime INT DEFAULT 0,
    ringinuse CHAR(1) DEFAULT '1',
    ignorebusy CHAR(1) DEFAULT '0'
);
COMMENT ON TABLE queue_members IS 'Membros das filas (agentes)';

CREATE INDEX idx_queue_members_name ON queue_members(queue_name);
CREATE INDEX idx_queue_members_interface ON queue_members(interface);

-- ==========================================================
-- 5. CDR - CALL DETAIL RECORDS (RELATÓRIOS DE CHAMADAS)
-- ==========================================================
-- Estrutura moderna do Asterisk 22 com suporte a linkedid
CREATE TABLE cdr (
    id BIGSERIAL PRIMARY KEY,
    calldate TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    clid VARCHAR(80),
    src VARCHAR(80),
    dst VARCHAR(80),
    dcontext VARCHAR(80),
    channel VARCHAR(80),
    dstchannel VARCHAR(80),
    lastapp VARCHAR(80),
    lastdata VARCHAR(80),
    duration INTEGER DEFAULT 0,
    billsec INTEGER DEFAULT 0,
    disposition VARCHAR(45),
    amaflags INTEGER DEFAULT 0,
    accountcode VARCHAR(20),
    uniqueid VARCHAR(150) NOT NULL,
    userfield VARCHAR(255),
    peeraccount VARCHAR(80),
    linkedid VARCHAR(150),
    sequence INTEGER,
    tenant_id INT REFERENCES tenants(id)
);

-- Índices para performance em consultas CDR
CREATE INDEX cdr_calldate_idx ON cdr(calldate);
CREATE INDEX cdr_src_idx ON cdr(src);
CREATE INDEX cdr_dst_idx ON cdr(dst);
CREATE INDEX cdr_uniqueid_idx ON cdr(uniqueid);
CREATE INDEX cdr_linkedid_idx ON cdr(linkedid);
CREATE INDEX cdr_dcontext_idx ON cdr(dcontext);
CREATE INDEX cdr_disposition_idx ON cdr(disposition);
CREATE INDEX cdr_tenant_idx ON cdr(tenant_id);

-- View para consultas amigáveis em português
CREATE VIEW cdr_readable AS
SELECT 
    id,
    calldate AS "Data/Hora",
    clid AS "Identificador",
    src AS "Origem",
    dst AS "Destino",
    dcontext AS "Contexto",
    duration AS "Duração Total (s)",
    billsec AS "Duração Conversa (s)",
    disposition AS "Status",
    lastapp AS "Última Aplicação",
    accountcode AS "Código Conta",
    uniqueid AS "ID Único",
    linkedid AS "ID Ligação",
    tenant_id AS "Tenant ID"
FROM cdr;

COMMENT ON TABLE cdr IS 'Registro detalhado de chamadas (Call Detail Records)';

-- ==========================================================
-- 6. QUEUE LOG (EVENTOS DE FILA)
-- ==========================================================
CREATE TABLE queue_log (
    id BIGSERIAL PRIMARY KEY,
    time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    callid VARCHAR(255),
    queuename VARCHAR(255),
    agent VARCHAR(255),
    event VARCHAR(255),
    data1 VARCHAR(255),
    data2 VARCHAR(255),
    data3 VARCHAR(255),
    data4 VARCHAR(255),
    data5 VARCHAR(255)
);
CREATE INDEX queue_log_time_idx ON queue_log(time);
CREATE INDEX queue_log_callid_idx ON queue_log(callid);
CREATE INDEX queue_log_queuename_idx ON queue_log(queuename);
COMMENT ON TABLE queue_log IS 'Log detalhado de eventos de filas de atendimento';

-- ==========================================================
-- 7. GATE LOGS (CONTROLE DE PORTÕES - CUSTOM MAGNUS)
-- ==========================================================
CREATE TABLE gate_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    extension VARCHAR(40),
    gate_name VARCHAR(100),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uniqueid VARCHAR(150),
    success BOOLEAN DEFAULT true,
    notes TEXT
);
CREATE INDEX gate_logs_tenant_idx ON gate_logs(tenant_id);
CREATE INDEX gate_logs_event_time_idx ON gate_logs(event_time);
COMMENT ON TABLE gate_logs IS 'Log de abertura de portões (funcionalidade customizada Magnus PBX)';

-- ==========================================================
-- 8. PERMISSÕES
-- ==========================================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_magnus;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_magnus;
GRANT SELECT ON cdr_readable TO admin_magnus;

-- ==========================================================
-- 9. INFORMAÇÕES DO SCHEMA
-- ==========================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Schema Magnus PBX v2.0 criado com sucesso!';
    RAISE NOTICE '📊 Tabelas criadas:';
    RAISE NOTICE '   - tenants (Multi-tenant SaaS)';
    RAISE NOTICE '   - ps_endpoints, ps_auths, ps_aors (PJSIP)';
    RAISE NOTICE '   - extensions (Dialplan Realtime)';
    RAISE NOTICE '   - queues, queue_members (Filas)';
    RAISE NOTICE '   - cdr (Call Detail Records com 20 campos)';
    RAISE NOTICE '   - queue_log (Eventos de fila)';
    RAISE NOTICE '   - gate_logs (Controle de portões)';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Próximo passo: Executar 02_sample_data.sql';
END $$;
