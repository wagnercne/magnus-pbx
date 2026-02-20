-- =================================================================
-- MAGNUS PBX - Correção de mídia e hangup para endpoints UDP
-- =================================================================
-- Objetivo:
-- - Evitar no-audio por direct media/NAT
-- - Melhorar robustez de sinalização de término de chamada
--
-- Este script só altera colunas que existirem no schema atual.
-- =================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='ps_endpoints' AND column_name='direct_media'
  ) THEN
    EXECUTE 'UPDATE ps_endpoints SET direct_media=''no'' WHERE transport=''transport-udp''';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='ps_endpoints' AND column_name='rewrite_contact'
  ) THEN
    EXECUTE 'UPDATE ps_endpoints SET rewrite_contact=''yes'' WHERE transport=''transport-udp''';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='ps_endpoints' AND column_name='rtp_symmetric'
  ) THEN
    EXECUTE 'UPDATE ps_endpoints SET rtp_symmetric=''yes'' WHERE transport=''transport-udp''';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='ps_endpoints' AND column_name='force_rport'
  ) THEN
    EXECUTE 'UPDATE ps_endpoints SET force_rport=''yes'' WHERE transport=''transport-udp''';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='ps_endpoints' AND column_name='timers'
  ) THEN
    EXECUTE 'UPDATE ps_endpoints SET timers=''no'' WHERE transport=''transport-udp''';
  END IF;
END $$;

-- Relatório básico (compatível com qualquer schema)
SELECT id, transport, context, identify_by
FROM ps_endpoints
WHERE transport='transport-udp'
ORDER BY id;
