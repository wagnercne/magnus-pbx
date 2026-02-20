# 🎯 RESUMO: Qual dialplan usar?

## ✅ Você tem 2 opções:

### Opção 1: MONOLÍTICO (Atual - Recomendado para começar)

**Arquivo:** `asterisk_etc/extensions.conf` (já existe e funciona)

**Vantagens:**
- ✅ Já está funcionando
- ✅ Tudo em um lugar só
- ✅ Não precisa mudar nada

**Use se:** Você quer começar a testar o sistema sem complicações.

---

### Opção 2: MODULAR (Organizado - Recomendado para produção)

**Arquivos:**
- `asterisk_etc/extensions-modular.conf` → Principal (20 linhas)
- `asterisk_etc/extensions-features.conf` → Feature codes (*43, *97, *500)
- `asterisk_etc/routing.conf` → Lógica de discagem
- `asterisk_etc/tenants.conf` → Contextos dos tenants

**Vantagens:**
- ✅ Organizado por responsabilidade
- ✅ Fácil adicionar features (edita 1 arquivo)
- ✅ Fácil adicionar tenants (edita 1 arquivo)
- ✅ Melhor para manutenção em longo prazo

**Use se:** Sistema entrou em produção e você vai adicionar muitos tenants/features.

---

## 📝 Como migrar (quando quiser)

**NA VM LINUX:**

```bash
# 1. Sincronizar arquivos do Windows (se ainda não estiverem na VM)
# Use seu método preferido: scp, rsync, git, editor manual

# 2. Ativar o dialplan modular
chmod +x scripts/ativar-dialplan-modular.sh
./scripts/ativar-dialplan-modular.sh

# 3. Testar
docker compose exec asterisk-magnus asterisk -rx "dialplan show *43@ctx-belavista"
```

---

## ⚠️ IMPORTANTE

1. **Ambos os dialplans têm o mesmo conteúdo** (features, rotas, tudo igual)
2. **A diferença é só organização** (1 arquivo vs 4 arquivos)
3. **Não há vantagem de performance** (Asterisk processa igual)
4. **Escolha baseado em seu fluxo de trabalho**

---

## 🔍 Como saber qual está ativo agora?

```bash
docker compose exec asterisk-magnus head -5 /etc/asterisk/extensions.conf
```

**Se aparecer:**
- `"Multi-tenant Extensions"` → Monolítico ativo
- `"Master Dialplan"` e `"ESTRUTURA MODULAR"` → Modular ativo

---

## 💡 Minha recomendação

**Para teste/dev:** Continue com monolítico (mais simples)

**Para produção (10+ tenants):** Migre para modular (mais organizado)

**Para aprender:** Teste o monolítico agora, migre em 1-2 semanas quando estiver confortável

---

📖 **Documentação completa:** [MIGRACAO_DIALPLAN.md](MIGRACAO_DIALPLAN.md)
