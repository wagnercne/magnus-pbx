-- ============================================================================
-- MAGNUS PBX - Configurar ps_endpoint_id_ips para DNS Authentication
-- ============================================================================
-- 
-- Esta tabela faz o MATCH entre domínios e endpoints
-- Permite que softphones registrem usando domínio completo
-- 
-- Exemplo: 1001@belavista.magnussystem.com.br → endpoint 1001@belavista
-- ============================================================================

-- Limpar registros existentes
DELETE FROM ps_endpoint_id_ips;

-- ============================================================================
-- TENANT: BELAVISTA (belavista.magnussystem.com.br)
-- ============================================================================

INSERT INTO ps_endpoint_id_ips (id, endpoint, match, srv_lookups, match_header) VALUES
    ('belavista', '1001@belavista', 'belavista.magnussystem.com.br', false, NULL),
    ('belavista', '1002@belavista', 'belavista.magnussystem.com.br', false, NULL);

-- ============================================================================
-- TENANT: ACME (acme.magnussystem.com.br)
-- ============================================================================

INSERT INTO ps_endpoint_id_ips (id, endpoint, match, srv_lookups, match_header) VALUES
    ('acme', '2001@acme', 'acme.magnussystem.com.br', false, NULL);

-- ============================================================================
-- TENANT: TECHNO (techno.magnussystem.com.br)
-- ============================================================================

INSERT INTO ps_endpoint_id_ips (id, endpoint, match, srv_lookups, match_header) VALUES
    ('techno', '3001@techno', 'techno.magnussystem.com.br', false, NULL);

-- ============================================================================
-- TENANT: TESTE (belavista.magnussystem.com.br - ramal especial)
-- ============================================================================

INSERT INTO ps_endpoint_id_ips (id, endpoint, match, srv_lookups, match_header) VALUES
    ('teste', '9999@teste', 'belavista.magnussystem.com.br', false, NULL);

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================

SELECT 
    id AS tenant,
    endpoint,
    match AS dominio,
    srv_lookups
FROM ps_endpoint_id_ips
ORDER BY id, endpoint;

-- RESULTADO ESPERADO:
-- tenant    | endpoint        | dominio                         | srv_lookups
-- ----------+-----------------+---------------------------------+-------------
-- acme      | 2001@acme       | acme.magnussystem.com.br        | false
-- belavista | 1001@belavista  | belavista.magnussystem.com.br   | false
-- belavista | 1002@belavista  | belavista.magnussystem.com.br   | false
-- techno    | 3001@techno     | techno.magnussystem.com.br      | false
-- teste     | 9999@teste      | belavista.magnussystem.com.br   | false
