-- =================================================================
-- MAGNUS PBX - Correção de perfil UDP (desativar WebRTC/DTLS)
-- =================================================================
-- Problema corrigido:
-- 488 Not Acceptable Here + "SRTP support module is not loaded or available"
-- em ramais SIP UDP que estavam com parâmetros WebRTC/DTLS habilitados.
-- =================================================================

BEGIN;

-- Para endpoints no transport UDP, desabilitar perfil WebRTC/DTLS
UPDATE ps_endpoints
SET
    webrtc = 'no',
    dtls_auto_generate_cert = 'no'
WHERE transport = 'transport-udp';

COMMIT;

-- Relatório pós-correção
SELECT id, transport, webrtc, dtls_auto_generate_cert, identify_by, context
FROM ps_endpoints
ORDER BY id;
