-- ============================================
-- MAGNUS PBX - Script de Correção e Validação
-- Executar APÓS aplicar as novas configurações
-- ============================================

-- 1. Verificar tenants ativos
SELECT 
    id,
    name as tenant_name,
    domain,
    is_active
FROM tenants 
WHERE is_active = true;

-- 2. Verificar endpoints e seus contextos
SELECT 
    e.id as endpoint_id,
    e.context,
    e.transport,
    e.aors,
    e.auth,
    t.name as tenant_name
FROM ps_endpoints e
LEFT JOIN tenants t ON e.tenant_id = t.id
ORDER BY t.name, e.id;

-- ============================================
-- 3. CORRIGIR CONTEXTOS DOS ENDPOINTS
-- ============================================
-- Todos os endpoints devem ter context='ctx-{slug}'
-- Extrair o slug do ID (formato ramal@slug)

-- Para tenant 'belavista':
UPDATE ps_endpoints 
SET context = 'ctx-belavista',
    transport = 'transport-udp'
WHERE id LIKE '%@belavista';

-- Para tenant 'acme':
UPDATE ps_endpoints 
SET context = 'ctx-acme',
    transport = 'transport-udp'
WHERE id LIKE '%@acme';

-- Para tenant 'techno':
UPDATE ps_endpoints 
SET context = 'ctx-techno',
    transport = 'transport-udp'
WHERE id LIKE '%@techno';

-- ============================================
-- 4. SCRIPT GENÉRICO (Para todos os tenants)
-- ============================================
-- Corrigir contextos automaticamente baseado no slug

UPDATE ps_endpoints e
SET context = 'ctx-' || split_part(e.id, '@', 2),
    transport = 'transport-udp'
WHERE e.id LIKE '%@%';

-- ============================================
-- 5. VERIFICAR AUTENTICAÇÃO
-- ============================================
SELECT 
    id,
    auth_type,
    username,
    CASE 
        WHEN password IS NOT NULL THEN '***OCULTO***'
        ELSE 'SEM SENHA'
    END as senha_status
FROM ps_auths
ORDER BY id;

-- ============================================
-- 6. VERIFICAR AORs
-- ============================================
SELECT 
    id,
    max_contacts,
    remove_existing
FROM ps_aors
ORDER BY id;

-- ============================================
-- 7. CRIAR TENANT E RAMAIS DE TESTE
-- ============================================
-- Use este script para testar rapidamente

-- Inserir tenant de teste
INSERT INTO tenants (name, domain, is_active) 
VALUES ('Empresa Teste', 'teste.magnus.local', true)
ON CONFLICT DO NOTHING;

-- Pegar o ID do tenant
DO $$
DECLARE
    tenant_test_id INT;
BEGIN
    SELECT id INTO tenant_test_id FROM tenants WHERE domain = 'teste.magnus.local';
    
    -- Inserir endpoint de teste
    INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, disallow, allow)
    VALUES (
        '9999@teste',
        tenant_test_id,
        'transport-udp',
        '9999@teste',
        '9999@teste',
        'ctx-teste',
        'all',
        'ulaw,alaw,gsm'
    ) ON CONFLICT (id) DO UPDATE SET context = 'ctx-teste';
    
    -- Inserir auth
    INSERT INTO ps_auths (id, tenant_id, auth_type, username, password)
    VALUES (
        '9999@teste',
        tenant_test_id,
        'userpass',
        '9999',
        'senha9999'
    ) ON CONFLICT (id) DO NOTHING;
    
    -- Inserir aor
    INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing)
    VALUES (
        '9999@teste',
        tenant_test_id,
        1,
        true
    ) ON CONFLICT (id) DO NOTHING;
END $$;

-- ============================================
-- 8. VALIDAÇÕES FINAIS
-- ============================================

-- Verificar se todos os endpoints têm contexto ctx-*
SELECT 
    id,
    context,
    CASE 
        WHEN context LIKE 'ctx-%' THEN '✓ OK'
        ELSE '✗ ERRO: Contexto inválido'
    END as status
FROM ps_endpoints;

-- Verificar se todos os endpoints têm auth e aor correspondentes
SELECT 
    e.id as endpoint,
    CASE WHEN a.id IS NOT NULL THEN '✓' ELSE '✗' END as tem_auth,
    CASE WHEN aor.id IS NOT NULL THEN '✓' ELSE '✗' END as tem_aor
FROM ps_endpoints e
LEFT JOIN ps_auths a ON e.auth = a.id
LEFT JOIN ps_aors aor ON e.aors = aor.id
ORDER BY e.id;

-- ============================================
-- 9. LIMPAR TABELA EXTENSIONS (se existir)
-- ============================================
-- Como não usamos mais Realtime para extensions,
-- podemos limpar a tabela (OPCIONAL)

-- CUIDADO: Só execute se tiver certeza!
-- DELETE FROM extensions;

-- ============================================
-- 10. ESTATÍSTICAS
-- ============================================
SELECT 
    (SELECT COUNT(*) FROM tenants WHERE is_active = true) as tenants_ativos,
    (SELECT COUNT(*) FROM ps_endpoints) as total_endpoints,
    (SELECT COUNT(*) FROM ps_auths) as total_auths,
    (SELECT COUNT(*) FROM ps_aors) as total_aors;
