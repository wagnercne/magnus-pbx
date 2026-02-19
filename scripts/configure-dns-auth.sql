-- ============================================================================
-- CONFIGURAÇÃO DE AUTENTICAÇÃO DNS - MAGNUS PBX
-- ============================================================================
-- Este script configura o banco de dados para autenticação baseada em DNS
-- onde softphones enviam username "1002" (sem @tenant) e o domínio no SIP
--
-- Executar: docker exec -i postgres-magnus psql -U admin_magnus -d magnus_pbx < scripts/configure-dns-auth.sql
-- ============================================================================

-- ============================================================================
-- 1. ATUALIZAR ps_auths: Corrigir campo username
-- ============================================================================
-- PROBLEMA: Softphones enviam username="1002" mas banco tem "1002@belavista"
-- SOLUÇÃO: Remover @tenant do campo username
-- ============================================================================

UPDATE ps_auths SET username = '1001' WHERE id = '1001@belavista';
UPDATE ps_auths SET username = '1002' WHERE id = '1002@belavista';
UPDATE ps_auths SET username = '2001' WHERE id = '2001@acme';
UPDATE ps_auths SET username = '3001' WHERE id = '3001@techno';
UPDATE ps_auths SET username = '9999' WHERE id = '9999@teste';

-- Verificar alterações
SELECT id, username, auth_type FROM ps_auths ORDER BY id;

-- ============================================================================
-- 2. ATUALIZAR ps_domain_aliases: Domínios de produção
-- ============================================================================
-- PROBLEMA: Banco tem domínios .local (desenvolvimento)
-- SOLUÇÃO: Adicionar domínios magnussystem.com.br (produção)
-- ============================================================================

-- Remover domínios antigos
DELETE FROM ps_domain_aliases;

-- Adicionar domínios de produção
INSERT INTO ps_domain_aliases (id, domain) VALUES
    ('belavista', 'belavista.magnussystem.com.br'),
    ('acme', 'acme.magnussystem.com.br'),
    ('techno', 'techno.magnussystem.com.br');

-- Verificar domínios configurados
SELECT id, domain FROM ps_domain_aliases ORDER BY id;

-- ============================================================================
-- 3. VERIFICAÇÕES FINAIS
-- ============================================================================

-- Verificar endpoints
SELECT id, context, aors, auth, transport FROM ps_endpoints ORDER BY id;

-- ============================================================================
-- RESULTADO ESPERADO:
-- ============================================================================
-- ps_auths:
--   1001@belavista → username: 1001
--   1002@belavista → username: 1002
--   2001@acme → username: 2001
--   3001@techno → username: 3001
--
-- ps_domain_aliases:
--   belavista → belavista.magnussystem.com.br
--   acme → acme.magnussystem.com.br
--   techno → techno.magnussystem.com.br
--
-- PRÓXIMOS PASSOS:
-- 1. Recarregar Asterisk: docker exec asterisk-magnus asterisk -rx "module reload res_pjsip.so"
-- 2. Configurar MikroTik Static DNS
-- 3. Testar registro do softphone
-- ============================================================================
