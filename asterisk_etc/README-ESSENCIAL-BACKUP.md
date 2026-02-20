# Asterisk ETC - Essencial x Backup

Este documento registra a organização aplicada em `asterisk_etc` para manter foco no cenário atual (SIP/PJSIP multi-tenant) e facilitar manutenção.

## Essencial (mantido na raiz)

### Núcleo de execução
- `asterisk.conf`
- `modules.conf`
- `logger.conf`
- `manager.conf`
- `cli.conf`, `cli_aliases.conf`, `cli_permissions.conf`

### SIP/PJSIP e mídia
- `pjsip.conf`
- `sorcery.conf`
- `extconfig.conf`
- `res_pgsql.conf`
- `rtp.conf`
- `codecs.conf`
- `pjproject.conf`
- `res_parking.conf`

### Dialplan (modular)
- `extensions.conf` (loader)
- `extensions_additional.conf` (base gerenciada)
- `extensions_custom.conf` (custom local)
- `extensions-features.conf`
- `routing.conf`
- `tenants.conf`

### Features (modular)
- `features.conf` (loader)
- `features_general_additional.conf`
- `features_general_custom.conf`
- `features_featuremap_additional.conf`
- `features_featuremap_custom.conf`
- `features_applicationmap_additional.conf`
- `features_applicationmap_custom.conf`

### Operação PBX comum
- `voicemail.conf`
- `musiconhold.conf`
- `indications.conf`
- `confbridge.conf`
- `queues.conf`, `queuerules.conf`
- `http.conf`, `ari.conf`, `stasis.conf`, `udptl.conf`

## Movido para backup

Tudo abaixo foi movido para `asterisk_etc/backup` por ser legado, duplicado, opcional ou fora do escopo atual:

- `extensions-modular.conf`
- `extensions_hibrido.conf`
- `extensions_minivm.conf`
- `config_test.conf`
- `test_sorcery.conf`
- `res_pgsql.conf.old`
- `chan_dahdi.conf`
- `iax.conf`, `iaxprov.conf`
- `ooh323.conf`
- `motif.conf`, `xmpp.conf`
- `unistim.conf`, `users.conf`
- `adsi.conf`, `asterisk.adsi`, `telcordia-1.adsi`
- `meetme.conf`
- `res_ldap.conf`, `res_corosync.conf`, `res_snmp.conf`
- `res_stun_monitor.conf`, `resolver_unbound.conf`
- `hep.conf`, `prometheus.conf`, `statsd.conf`, `stir_shaken.conf`
- `geolocation.conf`, `calendar.conf`, `dundi.conf`, `ccss.conf`, `dbsep.conf`
- `phoneprov.conf`, `aeap.conf`, `res_http_media_cache.conf`

## Observação

Nada foi apagado; somente movido para `backup` para reversão simples, se necessário.
