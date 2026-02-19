-- ============================================
-- MAGNUS PBX - Configurar Transport via Realtime
-- ============================================
-- 
-- Criar transport UDP no banco com suporte a múltiplos domínios
-- Isso resolve o problema de "No matching endpoint found"

-- Limpar transport anterior (se existir)
DELETE FROM ps_transports WHERE id = 'transport-udp';

-- Criar transport UDP com domínios configurados
INSERT INTO ps_transports (
    id,
    protocol,
    bind,
    domain
) VALUES (
    'transport-udp',
    'udp',
    '0.0.0.0:5060',
    '10.3.2.253,belavista.magnussystem.com.br,acme.magnussystem.com.br,techno.magnussystem.com.br'
);

-- Verificar
SELECT * FROM ps_transports;
