# Setup Windows (sem WSL)

Guia pra devs do time que trabalham em Windows nativo. Se tu tem WSL e prefere
usar, ótimo — esse guia é pra quem quer/precisa ficar no Windows puro.

## O que funciona

✅ **Cross-platform (idêntico em Windows, macOS, Linux):**
- Node.js + pnpm/npm/yarn
- Git + Git for Windows (vem com Git Bash)
- biome, knip, husky, commitlint
- Claude Code (nativo Windows desde 2025, usa Git Bash internamente)
- gh CLI
- VSCode + extensions
- Docker Desktop

⚠️ **Funciona com tweaks:**
- LunarVim (instalável, mas requer setup mais manual)
- tmux (dentro de Git Bash, não tão suave)
- eza (via cargo ou winget)

❌ **Não funciona / sem equivalente direto:**
- AeroSpace (use FancyZones do PowerToys)
- Raycast (use PowerToys Run ou Flow Launcher)
- Ghostty no Windows ainda não é estável (use Windows Terminal)

## Setup essencial

### 1. Instalações base

Via PowerShell (admin):

```powershell
# Winget já vem em Windows 11. Se não tiver:
# https://learn.microsoft.com/en-us/windows/package-manager/winget/

winget install --id Git.Git
winget install --id GitHub.cli
winget install --id Microsoft.PowerToys
winget install --id Microsoft.WindowsTerminal
winget install --id Microsoft.VisualStudioCode
winget install --id OpenJS.NodeJS.LTS

# Opcionais
winget install --id eza-community.eza
winget install --id BurntSushi.ripgrep.MSVC   # rg (rápido grep)
winget install --id sharkdp.fd                # fd (find moderno)
winget install --id sharkdp.bat               # bat (cat com syntax highlight)
```

Reinicia o terminal depois.

### 2. Git config

```bash
# No Git Bash ou PowerShell (depois de instalar gh)
gh auth login

# Configura identidade
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Aplica as melhorias do nosso gitconfig (compatíveis Windows)
git config --global pull.rebase true
git config --global rerere.enabled true
git config --global branch.sort -committerdate
git config --global rebase.autoSquash true
git config --global commit.verbose true
git config --global diff.algorithm histogram
git config --global init.defaultBranch main
```

Pra config completa: copia `~/dotfiles/git/gitconfig` pra `~/.gitconfig`
(funciona idêntico no Windows desde que paths sejam ajustados se houver).

### 3. Node.js + pnpm

```powershell
# Verifica
node --version    # esperado: v20.x ou superior
npm --version

# Habilita pnpm via corepack (vem com Node 16.13+)
corepack enable
corepack prepare pnpm@latest --activate

pnpm --version
```

### 4. Claude Code

```powershell
# Native install (recomendado pela Anthropic em Windows)
irm https://claude.ai/install.ps1 | iex

# Reabre o terminal
claude --version

# Login
claude
# Segue o fluxo de auth
```

Limitação Windows nativo: **`/sandbox` não funciona** (issue #46740). Pra security
enforcement completo precisaria de WSL. Pra fluxo dev normal, é OK.

### 5. Custom Claude commands

```powershell
mkdir $HOME\.claude\commands -Force
# Copia review.md e spec.md do dotfiles repo:
Copy-Item ~/dotfiles/claude/commands/review.md $HOME/.claude/commands/
Copy-Item ~/dotfiles/claude/commands/spec.md $HOME/.claude/commands/
```

Daí em qualquer projeto: `claude` → `/review` ou `/spec`.

### 6. Code quality stack

Em qualquer projeto Node/TS:

```bash
# Em Git Bash:
~/dotfiles/team-standards/setup-project.sh

# Ou se ainda não clonou os dotfiles, baixa só o script:
curl -O https://raw.githubusercontent.com/SEU-USER/dotfiles/main/team-standards/setup-project.sh
bash setup-project.sh
```

## Window management (substituto do AeroSpace)

### Opção 1: PowerToys FancyZones

Já vem com PowerToys. `Win+`` mostra zonas. Drag janelas pra zonas.

Customização: PowerToys Settings → FancyZones → Edit layouts.

### Opção 2: GlazeWM (tiling de verdade no Windows)

Tiling i3-like nativo Windows:

```powershell
winget install --id glzr-io.glazewm
```

Config em `~\.glaze-wm\config.yaml`. Muito similar a AeroSpace na filosofia.

## Launcher (substituto Raycast)

### PowerToys Run
Já vem com PowerToys. `Alt+Space` abre. Não tão poderoso quanto Raycast mas
serve pra launching de apps + cálculos rápidos.

### Flow Launcher
Mais próximo de Raycast em features:

```powershell
winget install --id Flow-Launcher.Flow-Launcher
```

Suporta plugins, atalhos custom, integração com aplicativos.

## Terminal

**Windows Terminal** é o padrão moderno. Já vem em Win 11.

Config útil em `settings.json`:

```json
{
  "defaultProfile": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
  "profiles": {
    "list": [
      {
        "name": "Git Bash",
        "commandline": "C:\\Program Files\\Git\\bin\\bash.exe -li",
        "icon": "C:\\Program Files\\Git\\mingw64\\share\\git\\git-for-windows.ico",
        "startingDirectory": "%USERPROFILE%"
      }
    ]
  }
}
```

Isso adiciona Git Bash como profile. Útil porque scripts dos dotfiles assumem
shell unix.

## Editor (VSCode com vim mode)

Se tu não usa LunarVim mas quer Vim-style navigation:

VSCode + extension **VSCodeVim** + esses settings em `settings.json`:

```json
{
  "editor.lineNumbers": "relative",
  "vim.useCtrlKeys": true,
  "vim.hlsearch": true,
  "vim.leader": " ",
  "vim.normalModeKeyBindingsNonRecursive": [
    {
      "before": ["<leader>", "f"],
      "commands": ["workbench.action.quickOpen"]
    },
    {
      "before": ["g", "d"],
      "commands": ["editor.action.revealDefinition"]
    }
  ]
}
```

Não substitui um Vim de verdade, mas dá muscle memory similar.

## tmux no Windows

Funciona em Git Bash:

```bash
# Em Git Bash (não em PowerShell)
pacman -S tmux  # se tiver MSYS2
# ou via WSL ($Subsystem Linux apesar de não usar como editor)
```

Honestamente, no Windows nativo, **Windows Terminal com múltiplas tabs/panes**
costuma ser mais simples que forçar tmux. tmux ganha valor real quando você usa
SSH em servidor remoto — aí sim, instala tmux **no servidor**, não localmente.

## Diferenças importantes

| Tarefa | macOS / Linux | Windows nativo |
|---|---|---|
| Path separator | `/` | `\` (mas Git Bash usa `/`) |
| Line endings | LF | CRLF (Git converte se config correto) |
| Home dir | `~` ou `$HOME` | `~` em Git Bash, `$env:USERPROFILE` em PS |
| Source de script | `source script.sh` | `. script.sh` ou em Git Bash idêntico |
| Symbolic links | `ln -s` | `mklink` (CMD) ou `New-Item -ItemType SymbolicLink` (PS) |

Configura Git pra normalizar line endings:

```bash
git config --global core.autocrlf input
```

Em projetos do time, adiciona `.gitattributes` no root:

```
* text=auto eol=lf
*.{cmd,bat,ps1} text eol=crlf
```

Garante que arquivos sempre commit com LF, mesmo no Windows.

## Quando considerar WSL2

Mesmo "sem WSL" sendo a regra atual, vale considerar WSL2 quando:
- Trabalhando com containers Docker complexos (WSL2 backend é melhor)
- Projeto exige scripts shell complexos que rodam mal em Git Bash
- Quer aproveitar `/sandbox` do Claude Code

WSL2 é Ubuntu/Debian/Alpine "dentro" do Windows. Acessível via `wsl` no PowerShell.
Não substitui Windows — coexiste.

## Suporte

Problemas específicos do Windows que não estão cobertos: pergunte no canal
do time. Adoção de Windows pelo time é levada a sério — issues serão
priorizadas pra que ninguém fique pra trás.
