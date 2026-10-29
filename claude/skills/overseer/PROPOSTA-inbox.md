# Proposta: inbox de atenção no Orca (inspirada no agentbox)

Status: **aguardando aprovação** (29/10/2026). Nada implementado.

## Problema

Na barra lateral do Orca não dá para saber quem precisa de atenção nem qual atender
primeiro, porque os agentes nem sempre resumem o que estão fazendo.

## Referência

https://github.com/savannahfeder/agentbox (GPL-3.0, Electron). É um inbox onde só aparecem
os agentes que terminaram ou travaram. Cada cartão traz o que o agente fez, o que precisa
e opções numeradas. As teclas 1/2/3 escolhem uma opção, E aprova, R responde, J/K navegam
e L adia. A prioridade é do usuário, por tag e ranking de projeto, e o agente não pode se
autopromover. Os campos do resumo são problem/progress/solution
(`renderer/src/threads/summary-rules.ts`).

Não dá para usar o agentbox direto, porque ele roda os próprios agentes e não enxerga as
sessões do Orca. A ideia é portar o conceito.

## Peças do Orca já conferidas (CLI 1.4.242)

- `orca worktree set --worktree <sel> --comment "…" --unread --workspace-status in-review`
  escreve o resumo no card da sidebar, liga a bolinha e troca a coluna.
- `orca terminal send --terminal <h> --text "1" --enter [--wait-submit N]` envia a resposta
  ao agente (bracket-paste em agente reconhecido).
- `orca terminal switch --terminal <h>` abre a aba (o overseer já usa).

## Camadas

1. **Cartão no fim do turno.** Uma regra no `CLAUDE.md` global faz o agente terminar com:
   ```
   📋 Fiz: <1 linha>
   ❓ Preciso de você: <decisão> | nada
   1) <opção> (recomendada)  2) …  3) …
   ⚡ Urgência: alta|média|baixa — <motivo>
   ```
   O custo extra em tokens é zero, porque quem escreve o cartão é o próprio agente.
2. **Hook `Stop` (tipo `command`, Python, sem LLM).** Lê o cartão e grava no card da
   worktree com `orca worktree set --comment "🔴 <decisão> (1/2/3)" --unread`. Quando há
   decisão pendente, troca o status para in-review. Quando o turno termina sem pedido,
   limpa só os comentários com o prefixo do próprio hook.
   - Falta conferir se o payload do `Stop` traz a última mensagem; sem ela, o hook lê a
     cauda da transcrição.
   - Agente sem cartão: o hook só marca "terminou sem cartão". Não usar o fallback com
     Haiku antes de medir quanto custa.
3. **Inbox web** (depois de validar as camadas 1 e 2 por alguns dias). Uma página local
   exposta só na tailnet (`tailscale serve`) e protegida por token. Lista só os cartões
   pendentes, ordenados pela prioridade dada pelo usuário. Teclas: J/K navegam, 1/2/3
   enviam a opção (`orca terminal send`), R responde em texto livre, Enter abre a aba.
   Reaproveita o `scripts/collect.py`.

## Restrições

- Sem chamada de LLM por turno. Hook e inbox são determinísticos; o custo de tokens
  continua só no agente.
- Prioridade só do usuário, nunca do agente.
- Enviar input a outro agente só com ação explícita do usuário.
- Limites da máquina: 16 GB, até 4 agentes em background, até 2 rodando teste ou build.

## Próximo passo

Implementar as camadas 1 e 2 e testar numa sessão descartável.
