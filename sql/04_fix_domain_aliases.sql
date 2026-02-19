-- =================================================================
-- MAGNUS PBX - Correção de Domain Aliases
-- Executar quando o banco já existe com domínios errados
-- =================================================================

-- Garantir coluna esperada pelo PJSIP realtime
ALTER TABLE ps_domain_aliases
ADD COLUMN IF NOT EXISTS domain_alias VARCHAR(80);

-- Mostrar estado atual
SELECT 'ANTES:' as status, id, domain_alias, domain FROM ps_domain_aliases;

-- Corrigir para o domínio real usado no DNS do MikroTik
UPDATE ps_domain_aliases
SET
    domain_alias = COALESCE(domain_alias, domain, id || '.magnussystem.com.br'),
    domain = COALESCE(domain, domain_alias, id || '.magnussystem.com.br');

UPDATE ps_domain_aliases
SET
    domain_alias = id || '.magnussystem.com.br',
    domain = id || '.magnussystem.com.br'
WHERE
    domain_alias LIKE '%.magnus.local'
    OR domain_alias NOT LIKE '%.magnussystem.com.br';

-- Inserir se não existirem
INSERT INTO ps_domain_aliases (id, domain_alias, domain) VALUES
    ('belavista', 'belavista.magnussystem.com.br', 'belavista.magnussystem.com.br'),
    ('acme',      'acme.magnussystem.com.br', 'acme.magnussystem.com.br'),
    ('techno',    'techno.magnussystem.com.br', 'techno.magnussystem.com.br')
ON CONFLICT (id) DO UPDATE SET
    domain_alias = EXCLUDED.domain_alias,
    domain = EXCLUDED.domain;

CREATE UNIQUE INDEX IF NOT EXISTS idx_ps_domain_aliases_domain_alias
ON ps_domain_aliases(domain_alias);

-- Mostrar estado corrigido
SELECT 'DEPOIS:' as status, id, domain_alias, domain FROM ps_domain_aliases;

-- =================================================================
-- Verificação completa de saúde do multi-tenant
-- =================================================================

-- 1. Domain aliases estão corretos?
SELECT 
    da.id as slug,
    da.domain_alias,
    CASE WHEN da.domain_alias LIKE '%.magnussystem.com.br' 
         THEN '✓ OK' ELSE '✗ DOMÍNIO ERRADO' END as status
FROM ps_domain_aliases da;

-- 2. Endpoints têm contexto correto (ctx-{slug})?
SELECT 
    e.id,
    e.context,
    e.auth,
    e.aors,
    CASE WHEN e.context = 'ctx-' || split_part(e.id, '@', 2)
         THEN '✓ OK' ELSE '✗ CONTEXTO ERRADO' END as status_context
FROM ps_endpoints e
WHERE e.id LIKE '%@%';

-- 3. Auths existem para todos os endpoints?
SELECT 
    e.id as endpoint,
    a.username,
    CASE WHEN a.id IS NOT NULL THEN '✓ OK' ELSE '✗ SEM AUTH' END as status_auth,
    CASE WHEN aor.id IS NOT NULL THEN '✓ OK' ELSE '✗ SEM AOR' END as status_aor
FROM ps_endpoints e
LEFT JOIN ps_auths a ON a.id = e.auth
LEFT JOIN ps_aors aor ON aor.id = e.aors
WHERE e.id LIKE '%@%'
ORDER BY e.id;

-- 4. Resumo
SELECT 
    (SELECT COUNT(*) FROM tenants WHERE is_active = true)        AS tenants_ativos,
    (SELECT COUNT(*) FROM ps_endpoints WHERE id LIKE '%@%')      AS endpoints_multi_tenant,
    (SELECT COUNT(*) FROM ps_domain_aliases)                     AS domain_aliases,
    (SELECT COUNT(*) FROM ps_auths WHERE id LIKE '%@%')          AS auths;
