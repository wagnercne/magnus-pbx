# 🔄 MIGRAÇÃO PARA DIALPLAN MODULAR

## 📋 Situação Atual

Você tem **extensions.conf monolítico** (262 linhas, tudo em um arquivo).

Eu criei 4 arquivos modulares para melhor organização:

```
asterisk_etc/
├── extensions-modular.conf       ← Arquivo principal (20 linhas)
├── extensions-features.conf      ← Feature codes (*43, *97, *500, etc)
├── routing.conf                  ← Sub-rotinas (dial-internal, dial-outbound)
└── tenants.conf                  ← Contextos dos tenants (ctx-belavista, etc)
```

## ⚠️ IMPORTANTE: Ambiente Multi-Máquina

Você edita no **Windows** mas executa na **VM Linux**.

**NÃO sincronize a pasta `asterisk_etc/` inteira**, pois pode sobrescrever arquivos!

## 🎯 Migração Manual (3 cenários)

### Cenário 1: Continuar com monolítico (Mais Simples)

Se o `*43` já está funcionando, **não faça nada**!

O `extensions.conf` atual já tem tudo que precisa.

### Cenário 2: Migrar para modular (Recomendado para longo prazo)

**NA VM LINUX**, execute estes comandos:

```bash
cd /path/to/MAGNUS-PBX

# 1. Backup do arquivo atual
cp asterisk_etc/extensions.conf asterisk_etc/extensions.conf.backup

# 2. Copiar os 3 novos arquivos (se não existirem ainda na VM)
# ATENÇÃO: Se você editou esses arquivos na VM, pule este passo!

# Opção A: Se os arquivos foram sincronizados do Windows, só ative:
cp asterisk_etc/extensions-modular.conf asterisk_etc/extensions.conf

# Opção B: Se os arquivos NÃO estão na VM, copie do Windows primeiro
# (via scp, rsync, ou editor de texto manual)

# 3. Reiniciar Asterisk
docker compose restart asterisk-magnus

# 4. Verificar se carregou
docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts"
```

### Cenário 3: Testar modular sem afetar produção

```bash
# 1. Testar o novo dialplan sem substituir
docker compose exec asterisk-magnus asterisk -rx "dialplan reload"

# 2. Se der erro, voltar ao backup
cp asterisk_etc/extensions.conf.backup asterisk_etc/extensions.conf
docker compose restart asterisk-magnus
```

## 📝 Arquivos que você DEVE sincronizar (Caso opte por modular)

Se optar pela migração, copie do Windows para a VM:

```bash
# Na VM, após sincronizar os arquivos do Windows:
cd asterisk_etc/

# Verificar se os 4 arquivos chegaram
ls -lh extensions-modular.conf extensions-features.conf routing.conf tenants.conf

# Ativar o modular
cp extensions-modular.conf extensions.conf

# Reiniciar
cd ..
docker compose restart asterisk-magnus
```

## ✅ Arquivos que você NÃO deve sobrescrever

**NUNCA sobrescreva diretamente na VM sem verificar:**

- `extensions.conf` (pode estar customizado)
- `pjsip.conf` (configurações específicas da VM)
- `res_config_pgsql.conf` (pode ter senhas diferentes)
- `modules.conf` (já foi corrigido para carregar pbx_config.so)

## 🎯 Minha Recomendação

**Para agora (enquanto testa):**

Continue com o `extensions.conf` monolítico atual. Ele já funciona!

**Para o futuro (quando estiver estável):**

Migre para o modular. Benefícios:
- Adicionar feature code: editar 1 arquivo de 20 linhas
- Adicionar tenant: editar 1 arquivo de 10 linhas
- Debug mais fácil: saber exatamente onde está cada coisa

## 🔍 Como saber qual dialplan está ativo

Na VM:

```bash
# Ver qual arquivo o Asterisk está lendo
docker compose exec asterisk-magnus asterisk -rx "core show file version extensions.conf"

# Ver primeiras linhas do arquivo ativo
docker compose exec asterisk-magnus head -20 /etc/asterisk/extensions.conf

# Se aparecer "ESTRUTURA MODULAR" = modular ativo
# Se aparecer "Multi-tenant Extensions" = monolítico ativo
```

## 📞 Teste Rápido

Independente de qual usar, teste:

```bash
# Na VM
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"
```

Se aparecer o `*43`, está funcionando! 🎉

---

**Em resumo:**
- ✅ Monolítico atual já funciona → Continue com ele
- ✅ Modular é melhor organização → Migre quando estiver confortável
- ⚠️ Não deixe o scripts/deploy.sh copiar automaticamente (já corrigido!)
