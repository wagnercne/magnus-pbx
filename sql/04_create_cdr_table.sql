-- ============================================
-- Magnus PBX - Tabela de CDR (Call Detail Records)
-- ============================================

-- Criar tabela CDR para armazenar histórico de chamadas
CREATE TABLE IF NOT EXISTS cdr (
    id SERIAL PRIMARY KEY,
    
    -- Informações Básicas
    calldate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    clid VARCHAR(80) NOT NULL DEFAULT '',
    src VARCHAR(80) NOT NULL DEFAULT '',
    dst VARCHAR(80) NOT NULL DEFAULT '',
    dcontext VARCHAR(80) NOT NULL DEFAULT '',
    
    -- Canais
    channel VARCHAR(80) NOT NULL DEFAULT '',
    dstchannel VARCHAR(80) NOT NULL DEFAULT '',
    lastapp VARCHAR(80) NOT NULL DEFAULT '',
    lastdata VARCHAR(80) NOT NULL DEFAULT '',
    
    -- Duração e Status
    duration INTEGER NOT NULL DEFAULT 0,
    billsec INTEGER NOT NULL DEFAULT 0,
    disposition VARCHAR(45) NOT NULL DEFAULT '',
    amaflags INTEGER NOT NULL DEFAULT 0,
    
    -- Accounting
    accountcode VARCHAR(20) NOT NULL DEFAULT '',
    uniqueid VARCHAR(150) NOT NULL DEFAULT '',
    userfield VARCHAR(255) NOT NULL DEFAULT '',
    
    -- Extra Fields (Asterisk 13+)
    peeraccount VARCHAR(80) NULL DEFAULT '',
    linkedid VARCHAR(150) NOT NULL DEFAULT '',
    sequence INTEGER NOT NULL DEFAULT 0
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS cdr_calldate_idx ON cdr(calldate);
CREATE INDEX IF NOT EXISTS cdr_src_idx ON cdr(src);
CREATE INDEX IF NOT EXISTS cdr_dst_idx ON cdr(dst);
CREATE INDEX IF NOT EXISTS cdr_uniqueid_idx ON cdr(uniqueid);
CREATE INDEX IF NOT EXISTS cdr_linkedid_idx ON cdr(linkedid);
CREATE INDEX IF NOT EXISTS cdr_dcontext_idx ON cdr(dcontext);
CREATE INDEX IF NOT EXISTS cdr_disposition_idx ON cdr(disposition);

-- Grant permissions
GRANT SELECT, INSERT ON cdr TO admin_magnus;
GRANT USAGE, SELECT ON SEQUENCE cdr_id_seq TO admin_magnus;

-- Comentários
COMMENT ON TABLE cdr IS 'Call Detail Records - Histórico de todas as chamadas';
COMMENT ON COLUMN cdr.calldate IS 'Data/hora da chamada';
COMMENT ON COLUMN cdr.src IS 'Ramal de origem';
COMMENT ON COLUMN cdr.dst IS 'Destino discado';
COMMENT ON COLUMN cdr.dcontext IS 'Contexto (tenant)';
COMMENT ON COLUMN cdr.duration IS 'Duração total da chamada (segundos)';
COMMENT ON COLUMN cdr.billsec IS 'Duração cobrada/conversação (segundos)';
COMMENT ON COLUMN cdr.disposition IS 'Status: ANSWERED, NO ANSWER, BUSY, FAILED';
COMMENT ON COLUMN cdr.uniqueid IS 'ID único da chamada';
COMMENT ON COLUMN cdr.linkedid IS 'ID de transferências relacionadas';

-- View helper para queries mais legíveis
CREATE OR REPLACE VIEW cdr_readable AS
SELECT 
    id,
    calldate AS "Data/Hora",
    src AS "Origem",
    dst AS "Destino",
    dcontext AS "Contexto",
    CASE disposition
        WHEN 'ANSWERED' THEN 'Atendida'
        WHEN 'NO ANSWER' THEN 'Não Atendida'
        WHEN 'BUSY' THEN 'Ocupado'
        WHEN 'FAILED' THEN 'Falhou'
        ELSE disposition
    END AS "Status",
    duration AS "Duração Total (s)",
    billsec AS "Duração Conversa (s)",
    channel AS "Canal",
    lastapp AS "Última App",
    uniqueid AS "ID Único"
FROM cdr
ORDER BY calldate DESC;

COMMENT ON VIEW cdr_readable IS 'View legível do CDR com labels em português';
