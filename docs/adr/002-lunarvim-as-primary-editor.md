# ADR-002: LunarVim como editor primário

## Status
Aceito

## Contexto

Avaliamos migrar pra Cursor ou Zed pra obter melhor experiência de IA inline e
performance, dado que o setup anterior de LunarVim tinha dois pontos de falha:

1. Navegação `gd` (go-to-definition) falhava silenciosamente em projetos TS grandes
2. LSP "burro" — sem inlay hints, sem signature help automático

Considerações:
- Workflow já usa Claude Code CLI como agente principal — IA "in editor" não é crítico
- Muscle memory de Vim representa investimento de anos
- M1 Pro 16GB com Docker rodando: cada MB de RAM importa
- Cursor é Electron (~500-800MB RAM), Zed é Rust (~200-400MB)

## Decisão

Manter LunarVim e corrigir as duas falhas reais. Não migrar pra Cursor/Zed.

Mudanças aplicadas:
- Trocar `tsserver` por `vtsls` (mais rápido, melhor monorepo support)
- Ativar inlay hints automaticamente via LspAttach autocmd
- Adicionar `lsp_signature.nvim` para signature help ao digitar
- Mapear navegação LSP via Telescope pickers (`gd`, `gr`, `gi`, `gt`) com preview
- Adicionar Trouble.nvim (diagnostics navegáveis) e Aerial.nvim (outline)

## Consequências

**Positivas:**
- Zero migração, zero perda de muscle memory
- Performance baseline preservada (Vim < Electron, Vim < Zed em RAM)
- Investimento em Vim continua composto
- Stack focado: editor edita, agente CLI roda em terminal separado

**Negativas:**
- Sem features agênticas avançadas tipo Cursor Composer (mas Claude Code CLI cobre)
- Angular language service tem polish menor que VSCode/Cursor (compensa com `ng` CLI)
- Debug visual de Node menos refinado que VSCode

## Alternativas consideradas

- **Cursor** — overkill: paga por features que já temos no Claude Code CLI.
- **Zed** — bom editor, mas migração custa semanas de muscle memory pra benefício marginal
  no caso. Zed seria escolha se NÃO já tivéssemos Vim setup há anos.
- **VSCode + Vim plugin** — duas mentalidades simultâneas, pior dos dois mundos.

## Quando reavaliar

- Se LSP no Neovim regredir significativamente em alguma release
- Se Cursor incluir feature crítica não disponível em Claude Code CLI
- Se trocar de hardware (16GB RAM deixar de ser constraint)

## Data
2026-04-26
