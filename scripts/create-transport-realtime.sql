-- ============================================
-- MAGNUS PBX - Criar tabela ps_transports
-- ============================================
-- 
-- Criar tabela para transport via realtime
-- Baseado no schema oficial do Asterisk PJSIP

-- Criar tabela ps_transports
CREATE TABLE IF NOT EXISTS ps_transports (
    id VARCHAR(40) PRIMARY KEY,
    async_operations INTEGER,
    bind VARCHAR(40),
    ca_list_file VARCHAR(200),
    ca_list_path VARCHAR(200),
    cert_file VARCHAR(200),
    cipher VARCHAR(200),
    domain VARCHAR(255),
    external_media_address VARCHAR(40),
    external_signaling_address VARCHAR(40),
    external_signaling_port INTEGER,
    method VARCHAR(40),
    local_net VARCHAR(40),
    password VARCHAR(40),
    priv_key_file VARCHAR(200),
    protocol VARCHAR(40),
    require_client_cert VARCHAR(40),
    verify_client VARCHAR(40),
    verify_server VARCHAR(40),
    tos VARCHAR(10),
    cos INTEGER,
    allow_reload VARCHAR(40),
    symmetric_transport VARCHAR(40)
);

-- Limpar dados anteriores (se existir)
DELETE FROM ps_transports WHERE id = 'transport-udp';

-- Criar transport UDP com domínios configurados
INSERT INTO ps_transports (
    id,
    protocol,
    bind,
    domain
) VALUES (
    'transport-udp',
    'udp',
    '0.0.0.0:5060',
    '10.3.2.253,belavista.magnussystem.com.br,acme.magnussystem.com.br,techno.magnussystem.com.br'
);

-- Verificar
SELECT id, protocol, bind, domain FROM ps_transports;
