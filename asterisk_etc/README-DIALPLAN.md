# Estrutura Modular do Dialplan

A partir de agora, o dialplan está organizado em **4 arquivos**:

## 📁 Arquitetura

```
asterisk_etc/
├── extensions-modular.conf      # ← Arquivo PRINCIPAL (use este!)
├── extensions-features.conf     # Feature codes (*43, *97, *500, etc)
├── routing.conf                 # Sub-rotinas (dial-internal, dial-outbound, etc)
└── tenants.conf                 # Contextos dos tenants (ctx-belavista, etc)
```

## 🔄 Como usar

1. **Copiar o novo arquivo principal:**
   ```bash
   cp asterisk_etc/extensions-modular.conf asterisk_etc/extensions.conf
   ```

2. **Reiniciar Asterisk:**
   ```bash
   docker compose restart asterisk-magnus
   ```

3. **Verificar se carregou:**
   ```bash
   docker compose exec asterisk-magnus asterisk -rx "dialplan show contexts"
   ```

## ✅ Benefícios

- **extensions-features.conf**: Todos os códigos `*XX` em um só lugar
  - Fácil adicionar novos feature codes
  - Modificar um não afeta os outros

- **routing.conf**: Lógica de discagem isolada
  - Interno, externo, emergência separados
  - Sub-rotinas reutilizáveis

- **tenants.conf**: Só adicionar novos contextos
  - `[ctx-{slug}](tenant-base)` herda tudo automaticamente
  - Customizações específicas opcional

- **extensions-modular.conf**: Arquivo principal enxuto
  - Só imports e configurações globais
  - Fácil de entender e documentar

## 🎯 Adicionar novo tenant

Edite apenas `tenants.conf`:

```asterisk
[ctx-novocondominio](tenant-base)
; Tenant: Novo Condomínio
; Herda automaticamente: features + routing
```

Pronto! Todos os feature codes e rotas funcionam automaticamente.

## 🔧 Adicionar novo feature code

Edite apenas `extensions-features.conf`:

```asterisk
; *77 - Call Pickup
exten => *77,1,NoOp(=== Call Pickup ===)
 same => n,Pickup()
 same => n,Hangup()
```

Todos os tenants recebem automaticamente via `[features-base]`.

## 📝 Arquivos antigos

- `extensions.conf` (antigo) → Monolítico, difícil manutenção
- `extensions_hibrido.conf` → Referência para abordagem híbrida
- `extensions_minivm.conf` → Exemplo de minivm (não usado)

Mantenha como backup mas use `extensions-modular.conf` em produção.
