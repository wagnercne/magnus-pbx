-- ============================================================================
-- CONFIGURAÇÃO DE AUTENTICAÇÃO DNS - MAGNUS PBX
-- ============================================================================
-- Este script configura o banco de dados para autenticação baseada em DNS
-- onde softphones enviam username "1002" (sem @tenant) e o domínio no SIP
--
-- Executar: docker exec -i postgres-magnus psql -U admin_magnus -d magnus_pbx < configure-dns-auth.sql
-- ============================================================================

BEGIN;

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

-- Verificar AORs
SELECT id, max_contacts, qualify_frequency FROM ps_aors ORDER BY id;

-- Verificar configuração completa de autenticação
SELECT 
    e.id as endpoint,
    e.context,
    a.username,
    a.password,
    a.auth_type,
    d.domain
FROM ps_endpoints e
LEFT JOIN ps_auths a ON e.id = a.id
LEFT JOIN ps_domain_aliases d ON SPLIT_PART(e.id, '@', 2) = d.id
ORDER BY e.id;

COMMIT;

-- ============================================================================
-- RESULTADO ESPERADO:
-- ============================================================================
-- Endpoint: 1001@belavista
--   Username: 1001 (sem @belavista)
--   Password: magnus123
--   Domain: belavista.magnussystem.com.br
--
-- Endpoint: 1002@belavista  
--   Username: 1002 (sem @belavista)
--   Password: magnus123
--   Domain: belavista.magnussystem.com.br
--
-- Endpoint: 2001@acme
--   Username: 2001 (sem @acme)
--   Password: magnus456
--   Domain: acme.magnussystem.com.br
--
-- Endpoint: 3001@techno
--   Username: 3001 (sem @techno)
--   Password: magnus789
--   Domain: techno.magnussystem.com.br
-- ============================================================================

-- FLUXO DE AUTENTICAÇÃO DNS:
-- 
-- 1. Softphone configurado:
--    Servidor: belavista.magnussystem.com.br
--    Usuário: 1002
--    Senha: magnus123
--
-- 2. DNS resolve (MikroTik Static DNS):
--    belavista.magnussystem.com.br → 10.3.2.253
--
-- 3. SIP REGISTER enviado:
--    To: sip:1002@belavista.magnussystem.com.br
--    From: sip:1002@belavista.magnussystem.com.br
--    Authorization: username="1002"
--
-- 4. Asterisk recebe:
--    - Domain: belavista.magnussystem.com.br (do header SIP)
--    - Username: 1002 (do Authorization)
--
-- 5. Asterisk procura:
--    - ps_domain_aliases WHERE domain='belavista.magnussystem.com.br' → id='belavista'
--    - ps_endpoints WHERE id='1002@belavista' → encontrado!
--    - ps_auths WHERE id='1002@belavista' AND username='1002' → valida senha
--
-- 6. Resultado: AUTENTICADO ✅
-- ============================================================================
