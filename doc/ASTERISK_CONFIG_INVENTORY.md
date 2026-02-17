# 📁 Inventário de Arquivos de Configuração do Asterisk

## 📊 Estatísticas Atuais

- **Total de arquivos**: 114 arquivos em `asterisk_etc/`
- **Recomendação**: ~30-40 arquivos essenciais
- **Limpeza sugerida**: ~70 arquivos podem ser removidos/movidos

---

## ✅ ESSENCIAIS (Obrigatórios)

### Core do Asterisk
- ✅ `asterisk.conf` - Configuração principal
- ✅ `modules.conf` - Módulos a carregar
- ✅ `logger.conf` - Sistema de logs
- ✅ `cli.conf` - CLI (Command Line Interface)
- ✅ `indications.conf` - Tons regionais (BR)
- ✅ `codecs.conf` - Configuração de codecs

### SIP/VoIP (PJSIP)
- ✅ `pjsip.conf` - Configuração principal PJSIP
- ✅ `pjsip_wizard.conf` - Templates PJSIP
- ✅ `pjproject.conf` - Stack PJSIP
- ✅ `rtp.conf` - RTP/SRTP
- ✅ `udptl.conf` - T.38 Fax

### WebRTC
- ✅ `http.conf` - HTTP/WebSocket
- ✅ `chan_websocket.conf` - WebSocket para WebRTC
- ✅ `ari.conf` - Asterisk REST Interface

### Dialplan
- ✅ `extensions.conf` - Dialplan principal
- ✅ `extensions-modular.conf` - Dialplan modular (Magnus custom)
- ✅ `extensions-features.conf` - Features codes (Magnus custom)
- ✅ `routing.conf` - Roteamento (Magnus custom)
- ✅ `tenants.conf` - Multi-tenant (Magnus custom)
- ✅ `features.conf` - Features (*97, transferência, etc)

### Database (Realtime)
- ✅ `res_config_pgsql.conf` - Driver PostgreSQL
- ✅ `res_pgsql.conf` - Conexão PostgreSQL
- ✅ `extconfig.conf` - Mapeamento realtime
- ✅ `sorcery.conf` - Sorcery (abstração de dados)

### CDR (Call Detail Records)
- ✅ `cdr.conf` - CDR geral
- ✅ `cdr_pgsql.conf` - CDR PostgreSQL
- ✅ `cdr_custom.conf` - CDR customizado

### Recursos
- ✅ `voicemail.conf` - Correio de voz
- ✅ `musiconhold.conf` - Música de espera
- ✅ `queues.conf` - Filas de atendimento
- ✅ `confbridge.conf` - Conferências
- ✅ `manager.conf` - AMI (Asterisk Manager Interface)

---

## 🟡 OPCIONAIS (Úteis mas não críticos)

### Recursos Avançados
- 🟡 `acl.conf` - Access Control Lists
- 🟡 `res_parking.conf` - Estacionamento de chamadas
- 🟡 `followme.conf` - Siga-me
- 🟡 `dundi.conf` - DUNDi (roteamento distribuído)
- 🟡 `dnsmgr.conf` - DNS Manager
- 🟡 `ccss.conf` - Call Completion
- 🟡 `res_stun_monitor.conf` - STUN para NAT

### Monitoramento
- 🟡 `prometheus.conf` - Métricas Prometheus
- 🟡 `statsd.conf` - StatsD
- 🟡 `res_snmp.conf` - SNMP
- 🟡 `hep.conf` - Homer Encapsulation Protocol

### Fax/CEL
- 🟡 `res_fax.conf` - Fax
- 🟡 `cel.conf` - Channel Event Logging
- 🟡 `cel_pgsql.conf` - CEL PostgreSQL

### Segurança/Geolocation
- 🟡 `stir_shaken.conf` - STIR/SHAKEN (autenticação de chamadas)
- 🟡 `geolocation.conf` - Geolocalização

---

## ❌ DESNECESSÁRIOS (Podem ser removidos)

### Protocolos Obsoletos
- ❌ `iax.conf` - IAX (obsoleto, usar PJSIP)
- ❌ `ooh323.conf` - H.323 (obsoleto)
- ❌ `mgcp.conf` - MGCP (legado)
- ❌ `skinny.conf` - Cisco SCCP (legado)
- ❌ `unistim.conf` - Nortel UNISTIM

### Hardware Local (não Docker)
- ❌ `chan_dahdi.conf` - Placas DAHDI (hardware)
- ❌ `chan_mobile.conf` - Bluetooth celular
- ❌ `console.conf` - Console local
- ❌ `alsa.conf` - ALSA (áudio local)
- ❌ `oss.conf` - OSS (áudio local)

### Conferências Antigas
- ❌ `meetme.conf` - MeetMe (obsoleto, usar ConfBridge)
- ❌ `minivm.conf` - MiniVM (obsoleto)

### CDR/CEL Não Usados
- ❌ `cdr_adaptive_odbc.conf` - Usamos PostgreSQL
- ❌ `cdr_odbc.conf` - Usamos PostgreSQL
- ❌ `cdr_manager.conf` - CDR via AMI (não necessário)
- ❌ `cdr_sqlite3_custom.conf` - Usamos PostgreSQL
- ❌ `cdr_tds.conf` - Usamos PostgreSQL
- ❌ `cdr_beanstalkd.conf` - Usamos PostgreSQL
- ❌ `cel_odbc.conf` - Usamos PostgreSQL
- ❌ `cel_sqlite3_custom.conf` - Usamos PostgreSQL
- ❌ `cel_tds.conf` - Usamos PostgreSQL
- ❌ `cel_beanstalkd.conf` - Usamos PostgreSQL

### Database Drivers Não Usados
- ❌ `res_config_mysql.conf` - Usamos PostgreSQL
- ❌ `res_config_odbc.conf` - Usamos PostgreSQL
- ❌ `res_config_sqlite3.conf` - Usamos PostgreSQL
- ❌ `res_odbc.conf` - Usamos PostgreSQL
- ❌ `res_ldap.conf` - Não usamos LDAP
- ❌ `res_curl.conf` - Se não usar webhooks

### Outros
- ❌ `agents.conf` - Sistema de agentes antigo
- ❌ `festival.conf` - TTS Festival (se não usar)
- ❌ `dbsep.conf` - Database separator (legado)
- ❌ `alarmreceiver.conf` - Alarmes (uso específico)
- ❌ `phoneprov.conf` - Provisionamento telefones (se auto-provisionamento não usado)
- ❌ `calendar.conf` - Calendário (uso específico)
- ❌ `xmpp.conf` - XMPP/Jabber (raro)
- ❌ `motif.conf` - Google Talk (descontinuado)
- ❌ `res_corosync.conf` - Corosync (cluster - se não usar)
- ❌ `sla.conf` - Shared Line Appearance (raro)
- ❌ `smdi.conf` - SMDI (muito específico)
- ❌ `ss7.timers` - SS7 (telefonia legado)

### Arquivos de Template/Exemplo
- ❌ `extensions.ael` - AEL (linguagem alternativa - não usamos)
- ❌ `extensions.lua` - Lua (não usamos)
- ❌ `extensions_hibrido.conf` - Template antigo
- ❌ `extensions_minivm.conf` - Template antigo
- ❌ `app_skel.conf` - Skeleton (exemplo)
- ❌ `config_test.conf` - Testes
- ❌ `test_sorcery.conf` - Testes
- ❌ `aeap.conf` - AEAP (novo, experimental)

### ADSI (Obsoleto)
- ❌ `adsi.conf` - ADSI (display em telefones analógicos)
- ❌ `asterisk.adsi` - ADSI
- ❌ `telcordia-1.adsi` - ADSI

### Arquivos Backup/Old
- ❌ `res_pgsql.conf.old` - Backup (remover)

---

## 🎯 Recomendação de Limpeza

### 1. Criar pasta de arquivos não utilizados
```bash
cd /srv/magnus-pbx/asterisk_etc
mkdir -p _unused
```

### 2. Mover arquivos desnecessários
```bash
# Protocolos obsoletos
mv iax.conf ooh323.conf mgcp.conf skinny.conf unistim.conf _unused/

# Hardware local
mv chan_dahdi.conf chan_mobile.conf console.conf alsa.conf oss.conf _unused/

# Conferências antigas
mv meetme.conf minivm.conf extensions_minivm.conf _unused/

# CDR/CEL não usados
mv cdr_adaptive_odbc.conf cdr_odbc.conf cdr_manager.conf cdr_sqlite3_custom.conf cdr_tds.conf cdr_beanstalkd.conf _unused/
mv cel_odbc.conf cel_sqlite3_custom.conf cel_tds.conf cel_beanstalkd.conf _unused/

# Database drivers não usados
mv res_config_mysql.conf res_config_odbc.conf res_config_sqlite3.conf res_odbc.conf res_ldap.conf _unused/

# ADSI
mv adsi.conf asterisk.adsi telcordia-1.adsi _unused/

# Templates/Exemplos
mv extensions.ael extensions.lua extensions_hibrido.conf app_skel.conf config_test.conf test_sorcery.conf aeap.conf _unused/

# Outros
mv agents.conf festival.conf dbsep.conf alarmreceiver.conf phoneprov.conf calendar.conf _unused/
mv xmpp.conf motif.conf res_corosync.conf sla.conf smdi.conf ss7.timers _unused/

# Backup
mv res_pgsql.conf.old _unused/
```

### 3. Adicionar ao .gitignore
```bash
echo "asterisk_etc/_unused/" >> .gitignore
```

---

## 📝 Arquivos Específicos Magnus PBX

Estes são configurações customizadas do projeto Magnus:

- ✅ `extensions-modular.conf` - Dialplan modular (nosso)
- ✅ `extensions-features.conf` - Códigos de recursos (nosso)
- ✅ `routing.conf` - Roteamento multi-tenant (nosso)
- ✅ `tenants.conf` - Configuração de tenants (nosso)
- ✅ `README-DIALPLAN.md` - Documentação (nosso)

---

## 🔍 Como Verificar se um Arquivo é Usado

```bash
# Ver se o módulo está carregado
docker compose exec asterisk-magnus asterisk -rx "module show like <nome_modulo>"

# Ver referências no código
grep -r "nome_arquivo.conf" /etc/asterisk/

# Ver logs de erros ao remover
docker compose logs asterisk-magnus | grep -i "failed\|error\|warning"
```

---

## ✅ Checklist de Limpeza

- [ ] Fazer backup da pasta `asterisk_etc/` antes de remover
- [ ] Criar pasta `_unused/`
- [ ] Mover arquivos desnecessários para `_unused/`
- [ ] Reiniciar Asterisk e verificar logs
- [ ] Testar funcionalidades principais (*43, *97, chamadas)
- [ ] Se tudo funcionar por 1 semana, deletar `_unused/`
- [ ] Atualizar .gitignore
- [ ] Commit das mudanças

---

## 📚 Referência

Arquivos MÍNIMOS para um Asterisk funcional com PJSIP + PostgreSQL + WebRTC:

1. asterisk.conf
2. modules.conf
3. logger.conf
4. pjsip.conf
5. pjproject.conf
6. rtp.conf
7. http.conf
8. extensions.conf
9. res_config_pgsql.conf
10. extconfig.conf
11. cdr.conf
12. cdr_pgsql.conf

**Com esses 12 arquivos o Asterisk já funciona!** Os outros 102 são para recursos extras.
