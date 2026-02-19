-- =================================================================
-- MAGNUS PBX - Migração para Endpoint ID sem @ (slug_ramal)
-- =================================================================
-- Objetivo:
-- - Eliminar dependência de 'ramal@slug' no provisionamento dos dispositivos
-- - Padronizar endpoint/auth/aor como slug_ramal (ex: belavista_1001)
-- - Manter tenant/contexto para isolamento multi-tenant
--
-- Resultado de provisionamento recomendado após migração:
-- - UserID: belavista_1001
-- - AuthID/Login: belavista_1001
-- - Domain/Server: belavista.magnussystem.com.br
-- =================================================================

BEGIN;

-- 1) Garantir colunas usadas na estratégia
ALTER TABLE ps_endpoints ADD COLUMN IF NOT EXISTS tenantid VARCHAR(80);
ALTER TABLE ps_endpoints ADD COLUMN IF NOT EXISTS identify_by VARCHAR(80);

-- 2) Criar mapa de conversão (old -> new)
CREATE TEMP TABLE tmp_endpoint_id_map AS
SELECT
    e.id AS old_id,
    split_part(e.id, '@', 2) || '_' || split_part(e.id, '@', 1) AS new_id,
    split_part(e.id, '@', 2) AS tenant_slug,
    split_part(e.id, '@', 1) AS extension_number
FROM ps_endpoints e
WHERE e.id LIKE '%@%';

-- 3) Atualizar AUTH (id e username)
UPDATE ps_auths a
SET
    id = m.new_id,
    username = m.new_id
FROM tmp_endpoint_id_map m
WHERE a.id = m.old_id;

-- 4) Atualizar AOR id
UPDATE ps_aors a
SET id = m.new_id
FROM tmp_endpoint_id_map m
WHERE a.id = m.old_id;

-- 5) Atualizar endpoint id + refs internas
UPDATE ps_endpoints e
SET
    id = m.new_id,
    auth = m.new_id,
    aors = m.new_id,
    tenantid = m.tenant_slug,
    identify_by = 'username'
FROM tmp_endpoint_id_map m
WHERE e.id = m.old_id;

-- 6) Atualizar tabela de identificação por IP (se houver uso)
UPDATE ps_endpoint_id_ips i
SET endpoint = m.new_id
FROM tmp_endpoint_id_map m
WHERE i.endpoint = m.old_id;

-- 7) Atualizar contatos ativos (evita lixo durante transição)
UPDATE ps_contacts c
SET endpoint = m.new_id
FROM tmp_endpoint_id_map m
WHERE c.endpoint = m.old_id;

-- 8) Atualizar interfaces em filas (se existir referência antiga)
UPDATE queue_members
SET interface = REPLACE(interface, m.old_id, m.new_id)
FROM tmp_endpoint_id_map m
WHERE interface LIKE '%' || m.old_id || '%';

COMMIT;

-- =================================================================
-- RELATÓRIO DE PROVISIONAMENTO
-- =================================================================
SELECT
    e.id AS endpoint_id,
    e.id AS userid_device,
    e.id AS authid_login,
    da.domain_alias AS sip_domain,
    a.password AS password,
    e.tenantid,
    e.context,
    e.identify_by
FROM ps_endpoints e
JOIN ps_auths a ON a.id = e.auth
LEFT JOIN ps_domain_aliases da ON da.id = e.tenantid
WHERE e.id LIKE '%_%'
ORDER BY e.id;

-- =================================================================
-- CHECKS
-- =================================================================
-- 1) Endpoints ainda no formato antigo
SELECT id FROM ps_endpoints WHERE id LIKE '%@%';

-- 2) Auths sem correspondência de endpoint
SELECT a.id
FROM ps_auths a
LEFT JOIN ps_endpoints e ON e.auth = a.id
WHERE e.id IS NULL
ORDER BY a.id;
