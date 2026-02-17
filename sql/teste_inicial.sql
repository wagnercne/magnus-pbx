-- 1. Criar o primeiro Condomínio (Tenant)
INSERT INTO tenants (name, domain) 
VALUES ('Condomínio Bela Vista', 'belavista.magnus.local') 
RETURNING id; -- Vamos supor que o ID gerado seja 1

-- 2. Criar as credenciais de autenticação (ps_auths)
-- O ID aqui segue o padrão: 'ramal@tenant' para evitar duplicidade global
INSERT INTO ps_auths (id, tenant_id, auth_type, password, username)
VALUES ('1001@1', 1, 'userpass', 'magnus123', '1001');

-- 3. Criar o AOR (Address of Record - gerencia o registro do aparelho)
INSERT INTO ps_aors (id, tenant_id, max_contacts, remove_existing)
VALUES ('1001@1', 1, 1, true);

-- 4. Criar o Endpoint (O ramal em si, unindo Auth e AOR)
-- Note que aqui já configuramos suporte para WebRTC (essencial para sua interface Vue)
INSERT INTO ps_endpoints (id, tenant_id, transport, aors, auth, context, dtls_ca_file)
VALUES (
    '1001@1', 
    1, 
    'transport-wss', -- Nome do transporte que definiremos no asterisk
    '1001@1', 
    '1001@1', 
    'ctx-belavista', -- Contexto de discagem deste condomínio
    '/etc/asterisk/keys/asterisk.pem'
);

-- 5. Criar uma regra básica no Dialplan (extensions)
-- Se alguém discar 1001 no contexto do Bela Vista, o Asterisk toca o ramal 1001
INSERT INTO extensions (context, exten, priority, app, appdata, tenant_id)
VALUES ('ctx-belavista', '1001', 1, 'Dial', 'PJSIP/1001@1', 1);