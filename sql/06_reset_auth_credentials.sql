-- =================================================================
-- MAGNUS PBX - Reset/Normalização de Credenciais SIP (SaaS)
-- =================================================================
-- Objetivo:
-- 1) Padronizar autenticação com AuthID único global por tenant
-- 2) Manter UserID curto no dispositivo (ex: 1001)
-- 3) Evitar dependência de @slug no campo usuário do telefone
--
-- Resultado esperado no provisionamento:
-- - UserID: 1001
-- - AuthID/Login: belavista_1001
-- - Domain/Server: belavista.magnussystem.com.br
--
-- ATENÇÃO:
-- - Este script reseta as senhas para um padrão temporário.
-- - Troque as senhas em produção após validação inicial.
-- =================================================================

BEGIN;

-- 0) Garantir coluna identify_by para estratégia de identificação
ALTER TABLE ps_endpoints
ADD COLUMN IF NOT EXISTS identify_by VARCHAR(80);

-- 1) Garantir que todo endpoint tenha auth vinculado
UPDATE ps_endpoints
SET auth = id
WHERE (auth IS NULL OR auth = '')
  AND id LIKE '%@%';

-- 2) Criar auth faltante para endpoints existentes
INSERT INTO ps_auths (id, tenant_id, auth_type, username, password)
SELECT
    e.auth,
    e.tenant_id,
    'userpass',
    split_part(e.id, '@', 2) || '_' || split_part(e.id, '@', 1),
    'Trocar@123'
FROM ps_endpoints e
LEFT JOIN ps_auths a ON a.id = e.auth
WHERE e.id LIKE '%@%'
  AND a.id IS NULL;

-- 3) Normalizar auth existente para padrão SaaS
UPDATE ps_auths a
SET
    auth_type = 'userpass',
    username = split_part(e.id, '@', 2) || '_' || split_part(e.id, '@', 1),
    password = 'Trocar@123'
FROM ps_endpoints e
WHERE e.auth = a.id
  AND e.id LIKE '%@%';

-- 4) Forçar identificação adequada por AuthID + Username
UPDATE ps_endpoints
SET identify_by = 'auth_username,username'
WHERE id LIKE '%@%';

COMMIT;

-- =================================================================
-- RELATÓRIO FINAL DE PROVISIONAMENTO
-- =================================================================
SELECT
    e.id                                           AS endpoint_id,
    split_part(e.id, '@', 1)                       AS userid_device,
    a.username                                     AS authid_login,
    da.domain_alias                                AS sip_domain,
    a.password                                     AS senha_temporaria,
    e.identify_by                                  AS identify_by,
    e.context                                      AS dialplan_context
FROM ps_endpoints e
JOIN ps_auths a ON a.id = e.auth
LEFT JOIN ps_domain_aliases da ON da.id = split_part(e.id, '@', 2)
WHERE e.id LIKE '%@%'
ORDER BY e.id;

-- =================================================================
-- CHECKS DE CONSISTÊNCIA
-- =================================================================
-- 1) Auth username duplicado (não pode em SaaS)
SELECT username, COUNT(*)
FROM ps_auths
GROUP BY username
HAVING COUNT(*) > 1;

-- 2) Endpoints sem auth
SELECT id, auth
FROM ps_endpoints
WHERE id LIKE '%@%'
  AND (auth IS NULL OR auth = '');
