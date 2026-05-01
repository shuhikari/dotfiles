# ADR-005: tmux para gestão de sessões persistentes

## Status
Aceito

## Contexto

Ghostty é o terminal emulator escolhido. Tem splits e tabs nativos, suficiente
pra UX leve. Porém:

1. Ghostty fechado = todos os processos terminam. Acidentalmente fechar o app =
   perder contexto de trabalho que estava em progresso.
2. Workflow futuro inclui SSH em servidores GCP. Se conexão SSH cai, processo
   termina. Sem multiplexer, perde-se trabalho.
3. Múltiplas sessões Claude Code (uma por projeto) precisam organização — Zed
   tem dashboard visual pra isso, mas tu não usa Zed.

## Decisão

Adotar tmux como camada de sessão persistente, complementando (não substituindo)
Ghostty.

Workflow:
- Cada projeto vira uma sessão tmux nomeada (`tns` cria com nome do diretório)
- Sessão sobrevive a fechar Ghostty, reboot (com tmux-resurrect), SSH disconnect
- Funcoes helper: `tns`, `tcc` (sessão com Claude Code split), `ts` (fzf picker)

Config minimalista em `tmux/tmux.conf`:
- Prefix muda pra `C-a` (mais ergonômico que `C-b`)
- Splits com `|` (vertical) e `-` (horizontal), mantendo CWD
- Vim-style nav entre panes (`h/j/k/l`)
- `tmux-resurrect` + `tmux-continuum` pra restore após reboot

Em servidores remotos: `ssh server -t "tmux new -A -s remote"` — qualquer
desconexão é transparente.

## Consequências

**Positivas:**
- Sessões sobrevivem a falhas/fechamentos
- Mesma config funciona local e em qualquer servidor SSH
- Muscle memory tmux é transferível pra qualquer ambiente Linux
- Multi-sessão Claude Code organizado por projeto

**Negativas:**
- Mais uma camada a aprender (~3-4 dias de adaptação)
- Ghostty + tmux = nesting de keybinds — alguns conflitos (resolvíveis na config)
- Renderer de cores às vezes precisa de tunning (`xterm-256color` vs `xterm-ghostty`)

## Alternativas consideradas

- **Só Ghostty splits/tabs** — funciona enquanto não fecha o app. Falha em SSH disconnect.
- **zellij** — alternativa moderna ao tmux, mais user-friendly. Descartado porque
  tmux é universal: todo servidor Linux tem ou aceita instalar.
- **screen** — antiquado, sem features importantes de tmux.
- **Agent Deck** (TUI manager pra Claude) — interessante mas adiciona dependência;
  tmux puro com naming convention resolve sem ferramenta extra.

## Quando reavaliar

- Se zellij ganhar adoção massiva em servers Linux (improvável)
- Se Ghostty ganhar persistência de sessão nativa (improvável dado escopo do projeto)
- Se tmux quebrar em alguma versão ou ficar sem manutenção (improvável, é estável há décadas)

## Data
2026-04-26
