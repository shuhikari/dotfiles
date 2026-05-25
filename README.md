# dotfiles

Configurações pessoais de desenvolvimento + padrões do time. Versionado pra
evoluir junto com o workflow.

## Estrutura

```
dotfiles/
├── README.md                    Este arquivo
├── install.sh                   Symlinks dos dotfiles (cross-OS: macOS/WSL/Linux)
│
├── nvim/                        LazyVim config (vtsls, inlay hints, telescope LSP)
├── tmux/                        Sessões persistentes, splits, vim-style nav
├── zsh/                         Modular: zshrc + exports + aliases + functions
├── git/                         gitconfig + conditional includes (auditore/tegra)
├── aerospace.toml               Tiling WM com workspace P pra apresentação
├── claude/commands/             /review e /spec slash commands
├── macos/                       Setup específico Mac (Open in Neovim, migração)
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
        ├── 002 — LunarVim como editor primário (superseded por 013)
        ├── 003 — Claude Code CLI strategy
        ├── 004 — Estrutura modular dos dotfiles
        ├── 005 — tmux pra sessões persistentes
        ├── 006 — eza como ls replacement
        ├── 007 — Pipeline pre-PR
        ├── 008 — Não adotar LiteLLM agora
        ├── 009 — Melhorias no gitconfig
        ├── 010 — Cross-platform strategy
        ├── 011 — Overseer no Oracle Free Tier
        ├── 012 — Blog técnico público
        ├── 013 — Migração LunarVim → LazyVim
        └── 014 — Suporte a WSL2 nos dotfiles
```

## Instalação

### Pessoal (Mac)

```bash
git clone <este-repo> ~/dotfiles
cd ~/dotfiles
./install.sh   # Pergunta nome/email pro git na primeira instalação

# Opcional
./macos/setup-open-in-nvim.sh   # Finder → Open With Neovim
```

### WSL2 (Windows)

```bash
# Pré-requisito no PowerShell admin (uma vez):
#   wsl --install -d Ubuntu-24.04

# Dentro do WSL:
sudo apt update && sudo apt install -y git
git clone <este-repo> ~/dotfiles
bash ~/dotfiles/wsl/setup.sh   # Instala stack completa (~10 min)
~/dotfiles/install.sh          # Symlinks + identidade git
```

Detalhes em [wsl/README.md](wsl/README.md) e [docs/adr/014-wsl2-support.md](docs/adr/014-wsl2-support.md).

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
git commit -am "feat(nvim): adiciona keymap pra X"
# 4. Push
git push

# Em outras máquinas:
git pull && ./install.sh
```

## Claude Code (CLAUDE.md, commands e skills)

Este repo versiona a config global do [Claude Code](https://claude.com/claude-code).
O `install.sh` cria os symlinks automaticamente — não precisa copiar nada na mão.

### O que é cada coisa

| Arquivo / pasta no repo | Symlink criado | Pra que serve |
|---|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Diretrizes globais que o Claude lê **em toda conversa, em todo projeto**. Inclui regras de commit, ações destrutivas, atribuição, etc. |
| `claude/commands/*.md` | `~/.claude/commands/*.md` | Slash commands pessoais. Ex: `/review`, `/spec`, `/dotfiles-sync` — basta digitar a `/` no prompt do Claude. |
| `claude/skills/*` (opcional) | `~/.claude/skills/*` | Skills customizadas (workflows mais complexos que slash commands). |

### Como adicionar uma diretriz global (CLAUDE.md)

1. Abre `claude/CLAUDE.md` no editor.
2. Adiciona a regra na seção apropriada (ou cria uma nova seção `## Nome`).
3. Commit + push.
4. Em **outras máquinas**, roda `~/dotfiles/install.sh` (ou usa o slash command `/dotfiles-sync`) pra puxar a mudança. Como é symlink, a máquina onde você editou já está atualizada na hora.

### Como adicionar um slash command novo

1. Cria `claude/commands/<nome>.md` — o arquivo é o próprio prompt que o Claude vai executar quando você digitar `/<nome>`.
   ```markdown
   ---
   description: Descrição curta que aparece no autocomplete
   ---

   Instruções pro Claude executar quando o usuário rodar /<nome>.
   ```
2. Roda `~/dotfiles/install.sh` (linka o novo arquivo em `~/.claude/commands/`).
3. Em outra sessão do Claude Code, `/<nome>` já aparece no autocomplete.

Exemplos prontos: `claude/commands/review.md`, `claude/commands/spec.md`.

### Como adicionar uma skill

Skills são workflows mais elaborados (com sub-arquivos, scripts, etc.). Se não
existir a pasta `claude/skills/` ainda, crie:

```bash
mkdir -p claude/skills/<nome-da-skill>
```

Adicione o conteúdo da skill nesse diretório (estrutura segue a doc oficial do
Claude Code). Rode `~/dotfiles/install.sh` — ele detecta a pasta e linka
automaticamente em `~/.claude/skills/`.

### Testando se está funcionando

```bash
ls -la ~/.claude/CLAUDE.md             # deve ser symlink → ~/dotfiles/claude/CLAUDE.md
ls -la ~/.claude/commands/             # deve listar review.md, spec.md, etc.
```

Se não estiver linkado, roda `~/dotfiles/install.sh` de novo.

### Só quero a config do Claude (sem clonar o repo inteiro)

Útil se você não usa meu nvim/tmux/zsh mas quer as **diretrizes globais**
(otimização de tokens via subagentes, regras de atribuição, ações destrutivas)
e/ou os slash commands.

**Opção 1 — copiar arquivos avulsos (mais simples):**

```bash
mkdir -p ~/.claude/commands

# Diretrizes globais (orquestração de subagentes pra economia de tokens, regras de git, etc.)
curl -fsSL https://raw.githubusercontent.com/shuhikari/dotfiles/main/claude/CLAUDE.md \
  -o ~/.claude/CLAUDE.md

# Slash commands (pegue só os que quiser)
for cmd in review spec dotfiles-sync; do
  curl -fsSL "https://raw.githubusercontent.com/shuhikari/dotfiles/main/claude/commands/${cmd}.md" \
    -o "$HOME/.claude/commands/${cmd}.md"
done
```

Edite o `~/.claude/CLAUDE.md` à vontade — é seu agora, não recebe update
automático.

**Opção 2 — sparse checkout (mantém atualizado via `git pull`):**

```bash
git clone --filter=blob:none --no-checkout \
  https://github.com/shuhikari/dotfiles.git ~/.claude-source
cd ~/.claude-source
git sparse-checkout init --cone
git sparse-checkout set claude
git checkout main

# Linka só o que interessa
ln -sf ~/.claude-source/claude/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/commands
ln -sf ~/.claude-source/claude/commands/*.md ~/.claude/commands/

# Pra atualizar depois:
# cd ~/.claude-source && git pull
```

**O que você ganha levando só o `CLAUDE.md`:**

- Delegação automática de leituras/buscas pra subagente `Explore` (read-only,
  modelo mais barato) — economiza tokens do Opus.
- Subagentes mecânicos rodam em Sonnet/Haiku por default.
- Regras inegociáveis de atribuição (nada de `Co-Authored-By` ou `Generated with Claude Code`).
- Confirmação obrigatória antes de qualquer ação git destrutiva.
- Padrão de commit conventional, uma linha, sem corpo.

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
brew install --cask ghostty
brew install tmux gh eza lazygit fzf
asdf plugin add neovim https://github.com/richin13/asdf-neovim.git
asdf install neovim latest && asdf set -u neovim latest
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
| LazyVim travado pós-update | `nvim +":Lazy sync" +qa` |
| tmux config não recarrega | `tmux kill-server && tmux` |
| Symlinks corrompidos | `./install.sh` recria |
| Setup-project quebrou em existente | Verifica logs; remove `.husky/` e tenta de novo |
| Claude Code não acha config | `~/.claude/commands/` existe? `install.sh` cria. |
| Em Windows: hooks não rodam | Confirma Git for Windows + Node no PATH |

## Recursos

- [CHEATSHEET](docs/CHEATSHEET.md) — atalhos nvim, tmux, aliases
- [Code review workflow](docs/code-review-workflow.md) — pipeline detalhado
- [Windows setup](docs/windows-setup.md) — guia cross-platform
- [Overseer architecture](docs/overseer-architecture.md) — Oracle Free Tier setup
- [ADRs](docs/adr/README.md) — todas as decisões e razões

## Convenções deste repo

- Conventional Commits
- Sem `master`, só `main`
- Branches `feat/`, `fix/`, `chore/`, `docs/`
- ADRs nunca editados após Aceitos — criar nova substituindo se mudar de ideia
