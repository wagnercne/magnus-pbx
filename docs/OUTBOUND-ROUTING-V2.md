# Outbound Routing V2 (SaaS)

Versao: 1.0.0

## Objetivo

Remover mascaras fixas do dialplan e centralizar a regra de roteamento de saida no banco + backend, administrado pelo frontend SaaS.

## Componentes

- Dialplan: `asterisk_etc/magnus-conf.d/routing.conf`
  - Handler unico: `exten => _X.,1,Goto(dial-outbound,...)`
- API AGI: `GET /api/agi/get-outbound-route`
  - Entrada: `tenant` (slug) ou `tenantId`, `number`
  - Opcional: `format=text` retorna `trunk|numero_normalizado`
- Banco: `sql/11_outbound_routing_v2.sql`
  - `trunks`
  - `outbound_routes`
  - `outbound_route_rules`
  - `outbound_route_trunks`

## Fluxo de decisao

1. Usuario disca um numero externo.
2. Dialplan chama API `get-outbound-route` com tenant + numero.
3. Backend resolve tenant (slug ou id).
4. Backend busca rotas ativas por prioridade.
5. Backend avalia regras da rota por prioridade (`pattern`).
6. Na primeira regra que casar:
   - aplica normalizacao (`strip_digits`, `prepend_digits`)
   - seleciona tronco por prioridade/failover
7. Retorna para o Asterisk: `trunk|numero_normalizado`.
8. Dialplan executa: `Dial(PJSIP/${OUT_NUMBER}@${TRUNK_NAME},...)`.

## Compatibilidade

Se as tabelas V2 nao existirem, o backend faz fallback para o modelo legado de `outbound_routes` (`pattern` + `trunk_name`).

## Integracao com frontend SaaS

Tela de admin deve permitir:

- Cadastro de troncos por tenant
- Cadastro de rota de saida (nome, prioridade, ativo)
- Cadastro de regras da rota (pattern, strip, prepend, prioridade)
- Ordem de troncos por rota (failover)

## Exemplo rapido

- Rota: `CELULAR_BR`, prioridade `10`
- Regra: pattern `_9XXXXXXXX`, strip `0`, prepend `55`
- Troncos:
  1. `trunk_vivo` prioridade 10
  2. `trunk_claro` prioridade 20

Numero discado `911234567` => numero enviado `55911234567` via `trunk_vivo`.
