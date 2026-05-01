# Architecture Decision Records (ADR)

Registros das decisões importantes do dotfiles. Por que foram tomadas, alternativas
consideradas, e quando reavaliá-las.

## Por que existir

Setup de ambiente é cheio de decisões pequenas que parecem óbvias mas
podem ser questionadas semanas depois. ADRs preservam o **porquê**, não só o **quê**.

Quando alguém (incluindo eu mesmo daqui a 6 meses) pergunta "por que estamos usando
LazyVim e não LunarVim?", a resposta está aqui em vez de perdida no histórico do git.

## Formato

Template em [`team-standards/docs-templates/adr-template.md`](../../team-standards/docs-templates/adr-template.md).

## Índice

| # | Título | Status |
|---|---|---|
| [001](001-aerospace-tiling-wm.md) | AeroSpace como tiling window manager | ✅ Aceito |
| [002](002-lunarvim-as-primary-editor.md) | LunarVim como editor primário | 🔵 Substituído por ADR-013 |
| [003](003-claude-code-cli-strategy.md) | Claude Code CLI como agente principal | ✅ Aceito |
| [004](004-modular-dotfiles-structure.md) | Estrutura modular do dotfiles | ✅ Aceito |
| [005](005-tmux-session-management.md) | tmux pra sessões persistentes | ✅ Aceito |
| [006](006-eza-as-ls-replacement.md) | eza como replacement do ls | ✅ Aceito |
| [007](007-pre-pr-code-review-workflow.md) | Pipeline de code review pré-PR | ✅ Aceito |
| [008](008-no-litellm-yet.md) | Não adotar LiteLLM no momento | ✅ Aceito |
| [009](009-gitconfig-improvements.md) | Melhorias no gitconfig | ✅ Aceito |
| [010](010-cross-platform-strategy.md) | Cross-platform strategy (Windows sem WSL) | ✅ Aceito |
| [011](011-overseer-oracle-free-tier.md) | Overseer Oracle Free Tier | 🟡 Proposto |
| [012](012-public-blog.md) | Blog técnico público | 🟡 Proposto |
| [013](013-lunarvim-to-lazyvim-migration.md) | Migração de LunarVim pra LazyVim | ✅ Aceito |
| [014](014-wsl2-support.md) | Suporte a WSL2 nos dotfiles | ✅ Aceito |

## Como adicionar uma nova ADR

1. Próximo número sequencial (não pula, não reusa)
2. `cp ../../team-standards/docs-templates/adr-template.md NNN-slug-curto.md`
3. Adiciona linha no índice acima
4. Commit: `docs(adr): NNN add decision about X`

Nunca edita ADR aceita pra "atualizar" — cria nova ADR que substitua a anterior
e marca a antiga como `Status: Substituído por ADR-XXX`.

Decisão é histórica. Se mudar de ideia, isso é informação valiosa.

## Status legend

- 🟡 **Proposto** — em discussão, não implementado
- ✅ **Aceito** — em uso ativo
- 🔵 **Substituído por ADR-XXX** — superseded
- ❌ **Rejeitado** — considerado e descartado (mantém pra histórico)
- 🔴 **Deprecated** — em uso mas planejando saída
