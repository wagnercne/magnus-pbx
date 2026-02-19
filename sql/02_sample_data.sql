-- =================================================================
-- MAGNUS PBX - Dados de Exemplo (Sample Data)
-- Versão: 2.0 (Reestruturado em 17/02/2026)
-- =================================================================
-- Dados para testes e validação inicial do sistema
-- =================================================================

-- ==========================================================
-- 1. CRIAR TENANTS DE EXEMPLO
-- ==========================================================
INSERT INTO tenants (name, domain, is_active) VALUES
    ('Condomínio Bela Vista', 'belavista', true),
    ('Empresa ACME Corp', 'acme', true),
    ('Techno Solutions', 'techno', true)
ON CONFLICT (domain) DO NOTHING;

-- ==========================================================
-- 2. RAMAL 1001@belavista (WebRTC)
-- ==========================================================
INSERT INTO ps_auths (id, tenant_id, auth_type, username, password) VALUES
    ('1001@belavista', 1, 'userpass', 'belavista_1001', 'magnus123')
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing) VALUES
    ('1001@belavista', 1, 5, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, identify_by, disallow, allow, webrtc, dtls_auto_generate_cert) VALUES
    ('1001@belavista', 1, 'transport-wss', '1001@belavista', '1001@belavista', 'ctx-belavista', 'auth_username,username', 'all', 'opus,g722,ulaw', 'yes', 'yes')
ON CONFLICT (id) DO NOTHING;

-- ==========================================================
-- 3. RAMAL 1002@belavista (SIP tradicional)
-- ==========================================================
INSERT INTO ps_auths (id, tenant_id, auth_type, username, password) VALUES
    ('1002@belavista', 1, 'userpass', 'belavista_1002', 'magnus123')
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing) VALUES
    ('1002@belavista', 1, 2, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, identify_by, disallow, allow) VALUES
    ('1002@belavista', 1, 'transport-udp', '1002@belavista', '1002@belavista', 'ctx-belavista', 'auth_username,username', 'all', 'ulaw,alaw,gsm')
ON CONFLICT (id) DO NOTHING;

-- ==========================================================
-- 4. RAMAL 2001@acme
-- ==========================================================
INSERT INTO ps_auths (id, tenant_id, auth_type, username, password) VALUES
    ('2001@acme', 2, 'userpass', 'acme_2001', 'acme2001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing) VALUES
    ('2001@acme', 2, 1, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, identify_by, disallow, allow) VALUES
    ('2001@acme', 2, 'transport-udp', '2001@acme', '2001@acme', 'ctx-acme', 'auth_username,username', 'all', 'ulaw,alaw')
ON CONFLICT (id) DO NOTHING;

-- ==========================================================
-- 5. RAMAL 3001@techno (WebRTC)
-- ==========================================================
INSERT INTO ps_auths (id, tenant_id, auth_type, username, password) VALUES
    ('3001@techno', 3, 'userpass', 'techno_3001', 'techno3001')
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing) VALUES
    ('3001@techno', 3, 5, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, identify_by, disallow, allow, webrtc, dtls_auto_generate_cert) VALUES
    ('3001@techno', 3, 'transport-wss', '3001@techno', '3001@techno', 'ctx-techno', 'auth_username,username', 'all', 'opus,vp8', 'yes', 'yes')
ON CONFLICT (id) DO NOTHING;

-- ==========================================================
-- 6. DOMAIN ALIASES (Para roteamento multi-tenant)
-- ==========================================================
-- CRÍTICO: 'domain_alias' deve ser EXATAMENTE o que o softphone usa como servidor SIP
-- Quando softphone registra em belavista.magnussystem.com.br com user=1001,
-- Asterisk busca ps_domain_aliases WHERE domain_alias='belavista.magnussystem.com.br'
-- Encontra id='belavista' → monta endpoint id: 1001@belavista → ctx-belavista
INSERT INTO ps_domain_aliases (id, domain_alias, domain) VALUES
    ('belavista', 'belavista.magnussystem.com.br', 'belavista.magnussystem.com.br'),
    ('acme', 'acme.magnussystem.com.br', 'acme.magnussystem.com.br'),
    ('techno', 'techno.magnussystem.com.br', 'techno.magnussystem.com.br')
ON CONFLICT (id) DO UPDATE SET
    domain_alias = EXCLUDED.domain_alias,
    domain = EXCLUDED.domain;

-- ==========================================================
-- 7. ENDPOINT IDENTIFICATION (Multi-Tenant por IP)
-- ==========================================================
-- SOLUÇÃO PARA SOFTPHONES QUE NÃO ENVIAM @tenant NO USERNAME
-- 
-- Quando softphone registra com username=1002 (sem @belavista),
-- Asterisk usa o IP de origem para identificar o endpoint correto.
--
-- Exemplo: IP 192.168.15.100 -> endpoint=1001@belavista
--
-- MATCH PATTERNS:
-- - IP exato: '192.168.15.100'
-- - Subnet: '192.168.15.0/24'
-- - Range: '192.168.15.100-192.168.15.200'
-- ==========================================================

-- Exemplo: Mapear range de IPs para tenants específicos
-- (Descomente e ajuste conforme sua rede)

-- Tenant Belavista: IPs 192.168.15.1-192.168.15.99
-- INSERT INTO ps_endpoint_id_ips (id, endpoint, match) VALUES
--     ('id_bv_network', '1001@belavista', '192.168.15.0/26');

-- Tenant ACME: IPs 192.168.15.100-192.168.15.199  
-- INSERT INTO ps_endpoint_id_ips (id, endpoint, match) VALUES
--     ('id_acme_network', '2001@acme', '192.168.15.100/26');

-- OU usar IP exato por ramal (para testes):
-- INSERT INTO ps_endpoint_id_ips (id, endpoint, match) VALUES
--     ('id_1001', '1001@belavista', '192.168.15.100'),
--     ('id_1002', '1002@belavista', '192.168.15.101'),
--     ('id_2001', '2001@acme', '192.168.15.200');

-- ==========================================================
-- 8. FILA DE ATENDIMENTO (EXEMPLO)
-- ==========================================================
INSERT INTO queues (name, tenant_id, strategy, timeout) VALUES
    ('suporte', 1, 'rrmemory', 30)
ON CONFLICT (name) DO NOTHING;

INSERT INTO queue_members (queue_name, interface) VALUES
    ('suporte', 'PJSIP/1001@belavista'),
    ('suporte', 'PJSIP/1002@belavista')
ON CONFLICT DO NOTHING;

-- ==========================================================
-- 9. CDR DE TESTE (OPCIONAL - SIMULAÇÃO)
-- ==========================================================
-- Inserir alguns CDRs de exemplo para testar consultas
INSERT INTO cdr (calldate, src, dst, dcontext, duration, billsec, disposition, uniqueid, linkedid, tenant_id) VALUES
    (NOW() - INTERVAL '1 hour', '1001', '1002', 'ctx-belavista', 125, 120, 'ANSWERED', '1234567890.1', '1234567890.1', 1),
    (NOW() - INTERVAL '2 hours', '1002', '1001', 'ctx-belavista', 45, 40, 'ANSWERED', '1234567890.2', '1234567890.2', 1),
    (NOW() - INTERVAL '3 hours', '1001', '*43', 'ctx-belavista', 30, 30, 'ANSWERED', '1234567890.3', '1234567890.3', 1),
    (NOW() - INTERVAL '4 hours', '1001', '1002', 'ctx-belavista', 0, 0, 'NO ANSWER', '1234567890.4', '1234567890.4', 1),
    (NOW() - INTERVAL '5 hours', '2001', '1001', 'ctx-acme', 0, 0, 'FAILED', '1234567890.5', '1234567890.5', 2);

-- ==========================================================
-- 9. INFORMAÇÕES DOS DADOS CRIADOS
-- ==========================================================
DO $$
DECLARE
    total_tenants INT;
    total_endpoints INT;
    total_cdrs INT;
BEGIN
    SELECT COUNT(*) INTO total_tenants FROM tenants;
    SELECT COUNT(*) INTO total_endpoints FROM ps_endpoints;
    SELECT COUNT(*) INTO total_cdrs FROM cdr;
    
    RAISE NOTICE '✅ Dados de exemplo criados com sucesso!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Estatísticas:';
    RAISE NOTICE '   - % tenants criados', total_tenants;
    RAISE NOTICE '   - % endpoints/ramais criados', total_endpoints;
    RAISE NOTICE '   - % CDRs de exemplo', total_cdrs;
    RAISE NOTICE '';
    RAISE NOTICE '🔑 Credenciais de teste:';
    RAISE NOTICE '   - UserID=1001 / AuthID=belavista_1001 / Pass=magnus123';
    RAISE NOTICE '   - UserID=1002 / AuthID=belavista_1002 / Pass=magnus123';
    RAISE NOTICE '   - UserID=2001 / AuthID=acme_2001 / Pass=acme2001';
    RAISE NOTICE '   - UserID=3001 / AuthID=techno_3001 / Pass=techno3001';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Configure seu softphone e disque *43 para teste!';
END $$;
