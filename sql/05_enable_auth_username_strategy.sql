-- =================================================================
-- MAGNUS PBX - Estratégia SaaS: Auth Username Único por Tenant
-- Objetivo: permitir UserID curto (ex: 1001) em qualquer softphone/telefone,
-- usando AuthID globalmente único (ex: belavista_1001).
-- =================================================================

-- 1) Garantir coluna identify_by em ps_endpoints
ALTER TABLE ps_endpoints
ADD COLUMN IF NOT EXISTS identify_by VARCHAR(80);

-- 2) Popular/normalizar auth.username para formato slug_ramal
-- Exemplo: endpoint 1001@belavista -> auth.username = belavista_1001
UPDATE ps_auths a
SET username = split_part(e.id, '@', 2) || '_' || split_part(e.id, '@', 1)
FROM ps_endpoints e
WHERE e.auth = a.id
  AND e.id LIKE '%@%';

-- 3) Forçar endpoints a identificar primeiro por auth_username e depois username
UPDATE ps_endpoints
SET identify_by = 'auth_username,username'
WHERE id LIKE '%@%';

-- 4) Validação: mostrar resultado final
SELECT
  e.id AS endpoint_id,
  e.identify_by,
  a.id AS auth_id,
  a.username AS auth_username,
  e.context
FROM ps_endpoints e
LEFT JOIN ps_auths a ON a.id = e.auth
WHERE e.id LIKE '%@%'
ORDER BY e.id;

-- 5) Observação operacional para provisionamento
-- UserID (From): 1001
-- AuthID/Login (Digest): belavista_1001
-- Domain/Server: belavista.magnussystem.com.br
