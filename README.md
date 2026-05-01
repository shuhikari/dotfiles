# dotfiles

Configurações pessoais de desenvolvimento + padrões do time. Versionado pra
evoluir junto com o workflow.

## Estrutura

```
dotfiles/
├── README.md                    Este arquivo
├── install.sh                   Symlinks dos dotfiles pessoais (Mac)
│
├── lvim/                        LunarVim config (vtsls, inlay hints, telescope LSP)
├── tmux/                        Sessões persistentes, splits, vim-style nav
├── zsh/                         Modular: zshrc + exports + aliases + functions
├── git/                         gitconfig + conditional includes (auditore/tegra)
├── aerospace.toml               Tiling WM com workspace P pra apresentação
├── claude/commands/             /review e /spec slash commands
├── macos/                       Setup específico Mac (Open in LunarVim)
│
├── team-standards/              Padrões cross-platform (Mac/Linux/Windows)
│   ├── setup-project.sh         Instala husky+biome+knip num projeto
│   ├── biome.json               Config base de lint/format
│   ├── knip.json                Dead code detection
│   ├── commitlint.config.mjs    Conventional Commits
│   ├── .editorconfig            Universal
│   ├── husky/                   pre-commit, pre-push, commit-msg
│   ├── github-templates/        PR + issue templates + CODEOWNERS
│   ├── docs-templates/          README, CONTRIBUTING, feature spec, ADR
│   └── conventions/             branch-naming, commits, code-style
│
└── docs/
    ├── CHEATSHEET.md            Atalhos rápidos
    ├── code-review-workflow.md  Pipeline pre-commit/push/PR
    ├── windows-setup.md         Guia pra time em Windows nativo
    ├── overseer-architecture.md Servidor Oracle Free Tier
    └── adr/                     Architecture Decision Records
        ├── README.md
        ├── 001 — AeroSpace tiling
        ├── 002 — LunarVim como editor primário
        ├── 003 — Claude Code CLI strategy
        ├── 004 — Estrutura modular dos dotfiles
        ├── 005 — tmux pra sessões persistentes
        ├── 006 — eza como ls replacement
        ├── 007 — Pipeline pre-PR
        ├── 008 — Não adotar LiteLLM agora
        ├── 009 — Melhorias no gitconfig
        ├── 010 — Cross-platform strategy
        ├── 011 — Overseer no Oracle Free Tier
        └── 012 — Blog técnico público
```

## Instalação

### Pessoal (Mac)

```bash
git clone <este-repo> ~/dotfiles
cd ~/dotfiles
./install.sh

# Opcional
./macos/setup-open-in-lvim.sh   # Finder → Open With LunarVim
```

### WSL2 (Windows)

```bash
# Pré-requisito no PowerShell admin (uma vez):
#   wsl --install -d Ubuntu-24.04

# Dentro do WSL:
sudo apt update && sudo apt install -y git
git clone <este-repo> ~/dotfiles
bash ~/dotfiles/wsl/setup.sh
```

Setup completo em ~10 min. Detalhes em [wsl/README.md](wsl/README.md).

### Time (qualquer plataforma)

Em projetos novos ou existentes:

```bash
~/dotfiles/team-standards/setup-project.sh
```

Instala husky + biome + knip + commitlint + GitHub templates. Cross-platform
(Windows nativo, macOS, Linux).

Devs Windows: ver [docs/windows-setup.md](docs/windows-setup.md).

## Como evoluir

Cada mudança importante = ADR. Cada decisão arquitetural = ADR.

```bash
# 1. Edita arquivo no repo (não em ~/.config/)
# 2. Documenta decisão se for relevante
cp team-standards/docs-templates/adr-template.md docs/adr/0XX-titulo.md
# 3. Commit Conventional
git commit -am "feat(lvim): adiciona keymap pra X"
# 4. Push
git push

# Em outras máquinas:
git pull && ./install.sh
```

## Filosofia

1. **Versão controlada** — toda mudança é commit. Histórico explica o porquê.
2. **Decisões documentadas** — ADRs preservam contexto pra reavaliação.
3. **Cross-platform onde possível** — team-standards funciona em Windows.
4. **Personal e team separados** — meu setup é meu, padrões do time são do time.
5. **Não-impositivo** — devs do time mantêm preferências pessoais; só os
   padrões são compartilhados.

## Pré-requisitos

```bash
# Mac
brew install --cask ghostty lunarvim
brew install tmux gh eza
brew install --cask nikitabobko/tap/aerospace

# Windows nativo: ver docs/windows-setup.md

# Linux: equivalentes via apt/pacman
```

Variáveis de ambiente em `zsh/local.zsh` (gitignored):
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `OPENROUTER_API_KEY` (opcional)

## Quando algo quebra

| Sintoma | Solução |
|---|---|
| LunarVim travado pós-update | `lvim +":Lazy sync" +qa` |
| tmux config não recarrega | `tmux kill-server && tmux` |
| Symlinks corrompidos | `./install.sh` recria |
| Setup-project quebrou em existente | Verifica logs; remove `.husky/` e tenta de novo |
| Claude Code não acha config | `~/.claude/commands/` existe? `install.sh` cria. |
| Em Windows: hooks não rodam | Confirma Git for Windows + Node no PATH |

## Recursos

- [CHEATSHEET](docs/CHEATSHEET.md) — atalhos lvim, tmux, aliases
- [Code review workflow](docs/code-review-workflow.md) — pipeline detalhado
- [Windows setup](docs/windows-setup.md) — guia cross-platform
- [Overseer architecture](docs/overseer-architecture.md) — Oracle Free Tier setup
- [ADRs](docs/adr/README.md) — todas as decisões e razões

## Convenções deste repo

- Conventional Commits
- Sem `master`, só `main`
- Branches `feat/`, `fix/`, `chore/`, `docs/`
- ADRs nunca editados após Aceitos — criar nova substituindo se mudar de ideia
