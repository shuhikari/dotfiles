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
├── claude/profile-switch.zsh    Multi-perfil (auditore/hmax/sintetiza) via CLAUDE_CONFIG_DIR
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
        ├── 014 — Suporte a WSL2 nos dotfiles
        └── 015 — Multi-perfil Claude Code via CLAUDE_CONFIG_DIR
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
| `claude/settings.json` | `~/.claude/settings.json` | Settings globais do Claude Code (theme, `attribution.commit: ""` pra suprimir Co-Authored-By, etc.). Loadado no startup da sessão. |
| `claude/commands/*.md` | `~/.claude/commands/*.md` | Slash commands pessoais. Ex: `/review`, `/spec`, `/dotfiles-sync` — basta digitar a `/` no prompt do Claude. |
| `claude/skills/*` (opcional) | `~/.claude/skills/*` | Skills customizadas (workflows mais complexos que slash commands). |
| `claude/install-mcp-aws.sh` (opcional) | — (não linka, é um script) | Adiciona MCPs da AWS (Knowledge + Documentation + Pricing) em escopo `user`. Rode `~/dotfiles/claude/install-mcp-aws.sh` quando quiser. |

### MCPs opcionais (AWS)

O `install.sh` principal **não** instala servidores MCP — eles ocupam contexto
do Claude enquanto estão configurados, então fica opt-in. Pra adicionar a suíte
oficial da AWS ([awslabs/mcp](https://github.com/awslabs/mcp)):

```bash
~/dotfiles/claude/install-mcp-aws.sh
```

Instala em escopo `user` (vale em todos os projetos):

- **aws-knowledge** — HTTP remote, sem auth. Docs + blogs + What's New + Well-Architected.
- **aws-documentation** — stdio via `uvx`. Só docs oficiais. Requer `uv` (o script instala se faltar).
- **aws-pricing** — stdio via `uvx`. Pricing pra dimensionar custo.

Pra remover depois: `claude mcp remove <nome> --scope user`.

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

## Múltiplas credenciais Claude (profiles)

Pra atender clientes/empresas diferentes (cada um com sua conta/plano Claude),
o dotfiles suporta **3 perfis isolados** out-of-the-box: `auditore`, `hmax`,
`sintetiza`. Cada perfil tem seu próprio `.credentials.json` (OAuth) e
histórico, mas **compartilha** os configs comuns (`CLAUDE.md`, `settings.json`,
`commands/`, `skills/`) via symlinks. Detalhes arquiteturais em
[ADR-015](docs/adr/015-claude-multi-credential-profiles.md).

### Como funciona

`install.sh` cria a estrutura:

```
~/.claude-profiles/
├── auditore/         (CLAUDE_CONFIG_DIR quando perfil ativo)
│   ├── CLAUDE.md         → symlink pra ~/dotfiles/claude/CLAUDE.md
│   ├── settings.json     → symlink pra ~/dotfiles/claude/settings.json
│   ├── commands/         → symlink pra ~/dotfiles/claude/commands/
│   ├── skills/           → symlink pra ~/dotfiles/claude/skills/  (se existir)
│   ├── .credentials.json (gerado por `claude /login`, isolado)
│   ├── projects/         (histórico isolado)
│   └── .claude.json      (estado isolado)
├── hmax/             (mesma estrutura)
└── sintetiza/        (mesma estrutura)
```

A variável `CLAUDE_CONFIG_DIR` aponta o Claude Code pro perfil ativo.

### Setup inicial (uma vez por máquina, por perfil)

Depois de rodar `./install.sh` e `exec zsh`:

```bash
# Autentica cada perfil (browser abre uma vez por perfil)
claude-profile auditore && claude /login
claude-profile hmax     && claude /login
claude-profile sintetiza && claude /login
```

WSL: se o callback OAuth do browser falhar (problema conhecido em WSL2), o
Claude Code aceita o code colado manualmente no prompt `Paste code here if prompted`.

### Uso dia-a-dia

Três formas de operar:

**1. Atalho num shot** — troca + roda `claude` direto:

```bash
cc-auditore        # equivalente a: CLAUDE_CONFIG_DIR=~/.claude-profiles/auditore claude
cc-hmax
cc-sintetiza
```

**2. Trocar a sessão atual** — pra rodar comandos arbitrários (`claude /status`, `claude mcp list`, scripts, etc.):

```bash
claude-profile auditore     # exporta CLAUDE_CONFIG_DIR na sessão atual
claude                      # roda no perfil auditore
claude mcp list             # também no perfil auditore
```

**3. Inspeção:**

```bash
claude-profile-list         # lista os 3 perfis
claude-profile-current      # mostra perfil ativo (ou "default" se nenhum)
```

### Perfil padrão por máquina

Pra abrir o terminal já com um perfil ativo, adiciona em `zsh/local.zsh`
(gitignored, específico da máquina):

```bash
export CLAUDE_DEFAULT_PROFILE=auditore
```

O `profile-switch.zsh` aplica automaticamente no startup do shell.

### Adicionar um novo perfil

1. Edita `install.sh` e adiciona o nome no array `CLAUDE_PROFILES`:
   ```bash
   CLAUDE_PROFILES=(auditore hmax sintetiza novo-cliente)
   ```
2. Edita `claude/profile-switch.zsh` e adiciona um alias `cc-<nome>`:
   ```bash
   alias cc-novo-cliente='CLAUDE_CONFIG_DIR=$CLAUDE_PROFILES_DIR/novo-cliente claude'
   ```
3. Roda `./install.sh` (cria o dir + symlinks) e `exec zsh` (recarrega alias).
4. Autentica: `claude-profile novo-cliente && claude /login`.
5. Commit + push pras outras máquinas pegarem.

### Remover um perfil

```bash
rm -rf ~/.claude-profiles/<nome>     # apaga credenciais + histórico (ação local, não afeta dotfiles)
# Remove do array CLAUDE_PROFILES em install.sh e o alias em profile-switch.zsh
```

### Trocar conta dentro de um perfil

```bash
claude-profile <nome>
claude /logout && claude /login
```

### Por que não API Keys?

API key (`ANTHROPIC_API_KEY`) cobra **por token consumido** ao preço do
console, sem teto. Planos Max/Teams via OAuth dão **uso pesado de Claude Code
dentro de assinatura fixa** — muito mais barato pra quem usa horas/dia. O setup
de perfis serve tanto pra OAuth quanto pra API key (se você setar
`ANTHROPIC_API_KEY` no shell, ela vence o OAuth do perfil — útil pra testar
override pontual).

### Quando algo quebra

| Sintoma | Solução |
|---|---|
| `claude-profile` não encontrado | `exec zsh` (recarregou `profile-switch.zsh`?) |
| Perfil não isolando credenciais | `claude-profile-current` confirma `CLAUDE_CONFIG_DIR` setado? |
| Symlinks no perfil quebrados | `./install.sh` recria (idempotente) |
| Login não persiste entre sessões | Permissão do dir: `chmod 0700 ~/.claude-profiles/<nome>` |
| `cc-<nome>` abre sem o `--dangerously-skip-permissions` | Alias `claude` em `aliases.zsh` precisa existir (chain expand) |

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
