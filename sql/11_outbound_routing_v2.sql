-- =================================================================
-- MAGNUS PBX - Outbound Routing V2 (SaaS)
-- Versao: 1.0.0
-- =================================================================
-- Objetivo:
-- - Remover mascaras fixas do dialplan
-- - Permitir cadastro de troncos/rotas no frontend SaaS
-- - Suportar prioridade e failover entre troncos
-- =================================================================

-- ----------------------------------------------------------
-- 1) Troncos SIP por tenant
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS trunks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    trunk_name VARCHAR(80) NOT NULL,
    provider_name VARCHAR(120),
    technology VARCHAR(20) NOT NULL DEFAULT 'PJSIP',
    endpoint_name VARCHAR(120) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_trunks_tenant_name UNIQUE (tenant_id, trunk_name)
);

CREATE INDEX IF NOT EXISTS idx_trunks_tenant_active
    ON trunks (tenant_id, is_active);

-- ----------------------------------------------------------
-- 2) Rotas de saida por tenant
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS outbound_routes (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    route_name VARCHAR(120) NOT NULL,
    priority INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_outbound_routes_tenant_name UNIQUE (tenant_id, route_name)
);

CREATE INDEX IF NOT EXISTS idx_outbound_routes_tenant_priority
    ON outbound_routes (tenant_id, is_active, priority);

-- ----------------------------------------------------------
-- 3) Regras de match da rota
-- pattern segue estilo Asterisk: _9XXXXXXXX, _00X., etc
-- strip_digits/remove prefixo discado, prepend_digits adiciona prefixo
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS outbound_route_rules (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES outbound_routes(id) ON DELETE CASCADE,
    rule_name VARCHAR(120) NOT NULL,
    pattern VARCHAR(80) NOT NULL,
    strip_digits INT NOT NULL DEFAULT 0,
    prepend_digits VARCHAR(40),
    priority INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_outbound_route_rules_route_priority
    ON outbound_route_rules (route_id, is_active, priority);

-- ----------------------------------------------------------
-- 4) Sequencia de troncos por rota (failover)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS outbound_route_trunks (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES outbound_routes(id) ON DELETE CASCADE,
    trunk_name VARCHAR(80) NOT NULL,
    priority INT NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_outbound_route_trunks_route_priority
    ON outbound_route_trunks (route_id, is_active, priority);

-- ----------------------------------------------------------
-- 5) Compatibilidade minima para base legada
-- Se havia coluna antiga (name/pattern/trunk_name), mantemos uso no backend como fallback.
-- ----------------------------------------------------------

-- ----------------------------------------------------------
-- 6) Permissoes
-- ----------------------------------------------------------
GRANT ALL PRIVILEGES ON TABLE trunks TO admin_magnus;
GRANT ALL PRIVILEGES ON TABLE outbound_routes TO admin_magnus;
GRANT ALL PRIVILEGES ON TABLE outbound_route_rules TO admin_magnus;
GRANT ALL PRIVILEGES ON TABLE outbound_route_trunks TO admin_magnus;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_magnus;

DO $$
BEGIN
    RAISE NOTICE '✅ Outbound Routing V2 pronto.';
    RAISE NOTICE '   - trunks';
    RAISE NOTICE '   - outbound_routes';
    RAISE NOTICE '   - outbound_route_rules';
    RAISE NOTICE '   - outbound_route_trunks';
END $$;
