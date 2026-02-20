# Estrutura Modular do Dialplan

A partir de agora, o dialplan estA organizado em **4 arquivos**:

## Y Arquitetura

```
asterisk_etc/
aaa extensions-modular.conf      # a Arquivo PRINCIPAL (use este!)
aaa extensions-features.conf     # Feature codes (*43, *97, *500, etc)
aaa routing.conf                 # Sub-rotinas (dial-internal, dial-outbound, etc)
aaa tenants.conf                 # Contextos dos tenants (ctx-belavista, etc)
```

## Y Como usar

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

## a BenefAcios

- **extensions-features.conf**: Todos os cAdigos `*XX` em um sA lugar
  - FAcil adicionar novos feature codes
  - Modificar um nAo afeta os outros

- **routing.conf**: LAgica de discagem isolada
  - Interno, externo, emergAncia separados
  - Sub-rotinas reutilizAveis

- **tenants.conf**: SA adicionar novos contextos
  - `[ctx-{slug}](tenant-base)` herda tudo automaticamente
  - CustomizaAAes especAficas opcional

- **extensions-modular.conf**: Arquivo principal enxuto
  - SA imports e configuraAAes globais
  - FAcil de entender e documentar

## YZ Adicionar novo tenant

Edite apenas `tenants.conf`:

```asterisk
[ctx-novocondominio](tenant-base)
; Tenant: Novo CondomAnio
; Herda automaticamente: features + routing
```

Pronto! Todos os feature codes e rotas funcionam automaticamente.

## Y Adicionar novo feature code

Edite apenas `extensions-features.conf`:

```asterisk
; *77 - Call Pickup
exten => *77,1,NoOp(=== Call Pickup ===)
 same => n,Pickup()
 same => n,Hangup()
```

Todos os tenants recebem automaticamente via `[features-base]`.

## Y Arquivos antigos

- `extensions.conf` (antigo) a MonolAtico, difAcil manutenAAo
- `extensions_hibrido.conf` a ReferAncia para abordagem hAbrida
- `extensions_minivm.conf` a Exemplo de minivm (nAo usado)

Mantenha como backup mas use `extensions-modular.conf` em produAAo.

