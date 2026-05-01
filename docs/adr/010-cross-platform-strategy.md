# ADR-010: Estratégia cross-platform (Windows sem WSL)

## Status
Aceito

## Contexto

Time da empresa trabalha primariamente em **Windows nativo, sem WSL**. Razões
podem ser: política IT, hardware corporate, preferência, ou simples não-adoção.

Maintainer dos dotfiles (eu) usa macOS. Stack pessoal usa LunarVim, tmux,
AeroSpace, Ghostty — todos macOS/Linux first.

Conflito: como compartilhar padrões e ferramentas com o time mantendo o
investimento pessoal num setup que não é diretamente portátil?

## Decisão

Separar dotfiles em duas categorias:

### Categoria A — Dotfiles pessoais (macOS-specific)

Permanecem no repo `dotfiles/`. Ferramentas:
- LunarVim config
- tmux config
- AeroSpace config
- Ghostty config
- "Open in LunarVim" .app
- Setup de symlinks via `install.sh`

Time **não usa** estes, e é OK. São ferramentas pessoais.

### Categoria B — Team standards (cross-platform)

Vivem em `dotfiles/team-standards/`. Funcionam em Windows nativo, macOS, Linux:

- **Code quality stack**: husky + biome + knip + commitlint
  - Tudo npm-based, funciona em Windows nativo
  - `husky` instala scripts compatíveis com `Git Bash`, `cmd`, `PowerShell`
- **Claude Code**: roda nativo no Windows desde 2025 via Git Bash, sem precisar de WSL
- **GitHub templates**: PR/issue templates, CODEOWNERS — só YAML/Markdown
- **Repository conventions**: branch naming, commits, code style — documentação
- **`.editorconfig`**: respeitado por VSCode, IntelliJ, Vim, Notepad++, todos
- **`/review` slash command** — funciona em qualquer plataforma onde Claude Code roda

### Categoria C — Inspirações para Windows

Onde possível, sugerir equivalentes Windows nativos:

| Mac (meu) | Windows nativo equivalente |
|---|---|
| Ghostty | Windows Terminal |
| AeroSpace | FancyZones (PowerToys) ou GlazeWM |
| Raycast | PowerToys Run / Flow Launcher |
| `eza` | `eza --version` funciona via winget ou cargo |
| LunarVim | LunarVim funciona em Windows com setup mais manual |
| tmux | tmux dentro de Git Bash funciona, mas não é tão suave |
| Shortcat | PowerToys Mouse Without Borders + atalhos custom |

## Consequências

**Positivas:**
- Time tem padrões aplicáveis sem ter que adotar setup de outra pessoa
- Cada dev mantém ergonomia preferida (alguns querem VSCode, outros JetBrains)
- Code quality é unificado independentemente de editor
- Onboarding cross-platform: `cd team-standards && ./setup-project.sh` instala tudo

**Negativas:**
- Manutenção de duas trilhas (pessoal vs team)
- Sandbox de Claude Code não disponível em Windows nativo, só com WSL ou Linux/macOS — devs Windows perdem essa camada de segurança
- Comandos shell em scripts custom precisam ser plataforma-agnósticos ou ter ramificações

## Alternativas consideradas

- **Forçar WSL no time** — descartado, cria fricção e depende de aprovação IT
- **Manter um único setup macOS-only** — exclui o time
- **Migrar tudo pra "tudo via VSCode + extensions"** — perde produtividade pessoal sem ganho real pro time
- **Devcontainer / GitHub Codespaces compartilhado** — viável futuramente,
  mas custa $$$ e adiciona dependência. Reavaliar quando time crescer.

## Quando reavaliar

- Se Anthropic adicionar sandbox nativo Windows pra Claude Code (issue #46740 aberto)
- Se time crescer pra ponto onde devcontainers fazem sentido economicamente
- Se a empresa aprovar WSL2 como ferramenta padrão (mudaria muito)

## Data
2026-04-26
