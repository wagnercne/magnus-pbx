-- Habilitar extensão para UUID (útil para IDs únicos de transações)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================================
-- 1. ESTRUTURA SAAS (TENANTS)
-- ==========================================================
CREATE TABLE tenants (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    name VARCHAR(100) NOT NULL, -- Nome do Condomínio/Empresa
    domain VARCHAR(100) UNIQUE, -- ex: belavista.magnuspbx.com
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);
COMMENT ON TABLE tenants IS 'Tabela mestre para isolamento de clientes (SaaS)';

-- ==========================================================
-- 2. PJSIP CORE (CONECTIVIDADE)
-- ==========================================================
CREATE TABLE ps_endpoints (
    id VARCHAR(40) PRIMARY KEY, -- ex: '1001@condominio1'
    tenant_id INT REFERENCES tenants(id),
    transport VARCHAR(40),
    aors VARCHAR(200),
    auth VARCHAR(40),
    context VARCHAR(40),
    disallow VARCHAR(200) DEFAULT 'all',
    allow VARCHAR(200) DEFAULT 'opus,g722,ulaw,alaw,vp8,h264',
    webrtc_ice_direction VARCHAR(10) DEFAULT 'both',
    dtls_ca_file VARCHAR(200),
    force_rport BOOLEAN DEFAULT true,
    rewrite_contact BOOLEAN DEFAULT true
);

CREATE TABLE ps_auths (
    id VARCHAR(40) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    auth_type VARCHAR(10) DEFAULT 'userpass',
    password VARCHAR(80),
    username VARCHAR(80)
);

CREATE TABLE ps_aors (
    id VARCHAR(40) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    max_contacts INT DEFAULT 1,
    remove_existing BOOLEAN DEFAULT true
);

-- Tabela para gerenciar múltiplos domínios (Ramal 100 pode existir em dois prédios)
CREATE TABLE ps_domain_aliases (
    id VARCHAR(80) PRIMARY KEY,
    domain VARCHAR(80)
);

-- ==========================================================
-- 3. DIALPLAN REALTIME (LÓGICA)
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

-- ==========================================================
-- 4. ATENDIMENTO E FILAS
-- ==========================================================
CREATE TABLE queues (
    name VARCHAR(128) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    strategy VARCHAR(128) DEFAULT 'ringall',
    timeout INT,
    announce_frequency INT,
    setinterfacevar BOOLEAN DEFAULT true
);

CREATE TABLE queue_members (
    queue_name VARCHAR(128) REFERENCES queues(name),
    interface VARCHAR(128),
    uniqueid SERIAL PRIMARY KEY
);

-- ==========================================================
-- 5. RELATÓRIOS E AUDITORIA (CDR/CEL/LOGS)
-- ==========================================================
CREATE TABLE cdr (
    accountcode VARCHAR(20),
    src VARCHAR(80),
    dst VARCHAR(80),
    dcontext VARCHAR(80),
    clid VARCHAR(80),
    channel VARCHAR(80),
    dstchannel VARCHAR(80),
    lastapp VARCHAR(80),
    lastdata VARCHAR(80),
    start TIMESTAMP WITHOUT TIME ZONE,
    answer TIMESTAMP WITHOUT TIME ZONE,
    "end" TIMESTAMP WITHOUT TIME ZONE,
    duration INT,
    billsec INT,
    disposition VARCHAR(45),
    amaflags INT,
    uniqueid VARCHAR(150) PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id)
);

CREATE TABLE queue_log (
    id BIGSERIAL PRIMARY KEY,
    time TIMESTAMP WITHOUT TIME ZONE,
    callid VARCHAR(255),
    queuename VARCHAR(255),
    agent VARCHAR(255),
    event VARCHAR(255),
    data1 VARCHAR(255),
    data2 VARCHAR(255),
    data3 VARCHAR(255)
);

-- Tabela Customizada Magnus: Abertura de Portões
CREATE TABLE gate_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT REFERENCES tenants(id),
    extension VARCHAR(40), -- Quem abriu
    gate_name VARCHAR(100), -- Qual portão (Entrada social, Garagem)
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uniqueid VARCHAR(150) -- Link com a chamada no CDR
);