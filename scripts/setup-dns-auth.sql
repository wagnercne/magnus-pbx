-- ========================================
-- MAGNUS PBX - Configuração Autenticação DNS
-- ========================================
-- Este script configura a autenticação por domínio (DNS)
-- Atualiza ps_auths e ps_domain_aliases

-- ========================================
-- 1. ATUALIZAR PS_AUTHS
-- ========================================
-- Problema: Softphone envia username="1002", mas banco tem username="1002@belavista"
-- Solução: Remover @tenant do campo username

BEGIN;

UPDATE ps_auths SET username = '1001' WHERE id = '1001@belavista';
UPDATE ps_auths SET username = '1002' WHERE id = '1002@belavista';
UPDATE ps_auths SET username = '2001' WHERE id = '2001@acme';
UPDATE ps_auths SET username = '2002' WHERE id = '2002@acme';
UPDATE ps_auths SET username = '3001' WHERE id = '3001@techno';
UPDATE ps_auths SET username = '9999' WHERE id = '9999@teste';

-- Verificar mudanças
SELECT id, username, auth_type FROM ps_auths ORDER BY id;

COMMIT;

-- ========================================
-- 2. ATUALIZAR PS_DOMAIN_ALIASES
-- ========================================
-- Mapear domínios magnussystem.com.br para tenants

BEGIN;

-- Limpar domínios antigos (.local)
DELETE FROM ps_domain_aliases;

-- Adicionar novos domínios
INSERT INTO ps_domain_aliases (id, domain) VALUES
    ('belavista', 'belavista.magnussystem.com.br'),
    ('acme', 'acme.magnussystem.com.br'),
    ('techno', 'techno.magnussystem.com.br');

-- Verificar
SELECT * FROM ps_domain_aliases ORDER BY id;

COMMIT;

-- ========================================
-- 3. RESUMO DO QUE FOI FEITO
-- ========================================
-- ✅ ps_auths: username atualizado (sem @tenant)
-- ✅ ps_domain_aliases: Domínios magnussystem.com.br configurados
--
-- PRÓXIMOS PASSOS:
-- 1. Recarregar Asterisk: docker exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"
-- 2. Verificar: docker exec asterisk-magnus asterisk -rx "pjsip show endpoints"
-- 3. Configurar MikroTik Static DNS (ver MIKROTIK-CONFIG.md)
-- 4. Testar softphone com domínio
