# WSL2 Setup

Setup completo dos dotfiles em WSL2 (Ubuntu 22.04 ou 24.04).

## Pré-requisitos no Windows

PowerShell como **administrador** (uma vez):

```powershell
# Habilita WSL2
wsl --install -d Ubuntu-24.04
wsl --set-default-version 2

# Reinicia o Windows
```

Após reiniciar e configurar usuário/senha do Ubuntu, prossegue.

## Setup dos dotfiles

Dentro do WSL (Ubuntu):

```bash
# 1. Instalar git (se não tiver)
sudo apt update && sudo apt install -y git

# 2. Clonar dotfiles
git clone <url-do-repo> ~/dotfiles

# 3. Rodar o setup
bash ~/dotfiles/wsl/setup.sh
```

O script é idempotente — pode rodar de novo sem quebrar nada.

## O que o setup faz

1. Atualiza Ubuntu (`apt update && apt upgrade`)
2. Instala ferramentas base: zsh, tmux, ripgrep, fd-find, bat, gh, jq, etc.
3. Instala oh-my-zsh + plugins (zsh-autosuggestions, zsh-completions)
4. Instala asdf 0.19+ (Go-based)
5. Instala Node.js 20 via asdf, ativa pnpm via corepack
6. Instala Neovim 0.11.2 via asdf
7. Instala eza, gh CLI, starship
8. Instala Claude Code CLI nativo
9. Aplica symlinks dos dotfiles (`install.sh`)
10. Mostra próximos passos

Tempo total estimado: 8-15 min dependendo de rede.

## Pós-setup

```bash
# Logout/login pra aplicar zsh
exit
# No PowerShell:
wsl --terminate Ubuntu-24.04
wsl

# Bootstrap LazyVim (2x)
nvim          # primeira: Lazy clona plugins
:q
nvim          # segunda: Mason instala LSPs (vtsls, biome, prisma, etc)
:Mason        # acompanha
:LazyHealth   # confirma

# Login Claude Code
claude
```

## Performance — onde colocar código

WSL2 tem dois sistemas de arquivos:

| Path | Disco real | Velocidade |
|---|---|---|
| `~/...` (ex: `~/ws/projeto`) | ext4 do WSL | 🟢 Rápido (nativo) |
| `/mnt/c/Users/...` | NTFS Windows | 🔴 ~10x mais lento |

**Regra**: clone repos em `~/ws/` dentro do WSL. NUNCA em `/mnt/c/`.

Diferença prática:
- `pnpm install` em projeto NestJS: `~/ws` ~30s, `/mnt/c` ~5min
- `git status` em monorepo: `~/ws` instantâneo, `/mnt/c` 3-10s

## Integração WSL ↔ Windows

| Operação | Comando |
|---|---|
| Abrir Explorer no diretório atual | `explorer.exe .` |
| Abrir VSCode do Windows no projeto | `code .` |
| Copia texto pro clipboard do Windows | `echo "texto" \| clip` (alias) |
| Cola do clipboard do Windows | `paste` (alias) |
| Abrir URL/arquivo com app default Windows | `wslview <arquivo-ou-url>` |
| Acessar serviços rodando no WSL | `localhost:PORTA` no Windows |

VSCode + extension "WSL" é a integração mais fluida pra time que prefere VSCode:
edita do Windows, código vive no WSL, terminal nativo do WSL embedded.

## Docker no WSL

Duas opções:

**Opção 1: Docker Desktop (recomendado pra iniciantes)**
- Instala Docker Desktop pro Windows
- Em Settings → Resources → WSL Integration: ativa pra Ubuntu-24.04
- Comandos `docker` e `docker compose` ficam disponíveis no WSL nativamente

**Opção 2: Docker Engine direto no WSL**
- Instala Docker Engine via apt no Ubuntu
- Mais leve (sem GUI), mas perde integração com containers do Windows
- Precisa setar `systemd` no `/etc/wsl.conf` pra rodar Docker como service

Pra dev individual, opção 1 é mais simples.

## Janelas / window management

WSL não substitui o Windows nesse aspecto. AeroSpace (do macOS) e similares
não rodam aqui. Use:

- **PowerToys FancyZones** — gerencia janelas Windows com zonas customizáveis
- **GlazeWM** — tiling i3-like nativo Windows (ver `docs/windows-setup.md`)
- **Terminal**: Windows Terminal já é o padrão moderno; configura Ubuntu como
  profile padrão e usa `wt` pra abrir nova janela

## Equivalência de ferramentas (macOS → WSL)

| macOS | WSL2 | Notas |
|---|---|---|
| Homebrew | apt | Linuxbrew opcional se quiser brew em WSL |
| `pbcopy`/`pbpaste` | `clip.exe`/`paste` (aliases) | Já configurado no `aliases.zsh` |
| AeroSpace | FancyZones / GlazeWM | No Windows, não no WSL |
| Ghostty | Windows Terminal | Configurar font + theme |
| Raycast | PowerToys Run / Flow Launcher | No Windows |
| Finder | Windows Explorer / `explorer.exe .` | |
| Activity Monitor | Task Manager (Win) / `htop` (WSL) | |

## Troubleshooting

### `nvim` lento ao abrir
- Provavelmente está em `/mnt/c/`. Move o projeto pro `~/`.

### Permissões estranhas em `/mnt/c/`
- WSL monta NTFS com permissões UNIX simuladas. Edita `/etc/wsl.conf`:
  ```ini
  [automount]
  options = "metadata,umask=22,fmask=11"
  ```
- `wsl --shutdown` no PowerShell, abre WSL de novo.

### `claude` não acha o terminal
- Claude Code requer terminal interativo. Confirma `echo $TERM` retorna algo
  (ex: `xterm-256color`). Se vazio, adiciona `export TERM=xterm-256color`
  no `~/.zshrc`.

### Hooks do git lentos
- Se o repo está em `/mnt/c/`, husky vai sofrer. Move pro `~/`.

### tmux com ESC delay
- Já tratado no `tmux.conf` com `escape-time 10`. Se notar lag, abre issue.
