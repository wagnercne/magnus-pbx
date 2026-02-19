-- =================================================================
-- MAGNUS PBX - Habilitar TenantID em endpoints PJSIP
-- =================================================================
-- Objetivo:
-- - Popular tenantid nos endpoints para rastreio em AMI/ARI/CDR/CEL
-- - Manter compatibilidade sem alterar autenticação SIP
-- =================================================================

BEGIN;

-- 1) Garantir coluna tenantid
ALTER TABLE ps_endpoints
ADD COLUMN IF NOT EXISTS tenantid VARCHAR(80);

-- 2) Preencher tenantid a partir do endpoint id (ramal@slug)
UPDATE ps_endpoints
SET tenantid = split_part(id, '@', 2)
WHERE id LIKE '%@%'
  AND (tenantid IS NULL OR tenantid = '');

-- 3) Sincronizar tenantid com slug atual (normalização)
UPDATE ps_endpoints
SET tenantid = split_part(id, '@', 2)
WHERE id LIKE '%@%'
  AND tenantid <> split_part(id, '@', 2);

COMMIT;

-- Relatório final
SELECT
  id AS endpoint_id,
  tenantid,
  context,
  identify_by,
  auth,
  aors
FROM ps_endpoints
WHERE id LIKE '%@%'
ORDER BY id;
