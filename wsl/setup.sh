#!/usr/bin/env bash
# wsl/setup.sh
#
# Setup inicial completo de WSL2 (Ubuntu 22.04 ou 24.04) pra usar os dotfiles.
# Idempotente: pode rodar múltiplas vezes.
#
# Pré-requisitos do lado Windows (rodar no PowerShell admin):
#   wsl --install -d Ubuntu-24.04
#   wsl --set-default-version 2
#
# Depois entra no WSL e roda este script:
#   git clone <repo-dotfiles> ~/dotfiles
#   bash ~/dotfiles/wsl/setup.sh

set -euo pipefail

if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BLUE=''; NC=''
fi

step()  { echo -e "\n${BLUE}=== $* ===${NC}"; }
info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; exit 1; }

# ---------- Pré-checks ----------

[[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version || \
  error "Este script só roda em WSL. Detectado: $(uname -a)"

[[ -d ~/dotfiles ]] || error "~/dotfiles não encontrado. Clona primeiro: git clone <url> ~/dotfiles"

# ---------- Sistema base ----------

step "Atualizando sistema"
sudo apt update
sudo apt upgrade -y

step "Instalando ferramentas essenciais"
sudo apt install -y \
  build-essential curl wget git unzip \
  zsh tmux \
  ripgrep fd-find bat \
  jq htop \
  ca-certificates gnupg lsb-release \
  software-properties-common \
  xclip wslu \
  python3 python3-pip python3-venv

# fd-find no Ubuntu instala como `fdfind` — cria symlink pra `fd`
if ! command -v fd >/dev/null 2>&1; then
  mkdir -p ~/.local/bin
  ln -sf "$(which fdfind)" ~/.local/bin/fd
  info "Symlink criado: fd → fdfind"
fi

# bat no Ubuntu instala como `batcat` — symlink pra `bat`
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
  info "Symlink criado: bat → batcat"
fi

# ---------- zsh + oh-my-zsh ----------

step "Configurando zsh"

if [[ "$SHELL" != *"zsh"* ]]; then
  info "Mudando shell padrão pra zsh (vai pedir senha)..."
  chsh -s "$(which zsh)"
  warn "Logout/login do WSL pra aplicar"
fi

if [[ ! -d ~/.oh-my-zsh ]]; then
  info "Instalando oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Plugins do oh-my-zsh usados pelo nosso .zshrc
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]] || \
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# ---------- asdf (Go-based) ----------

step "Instalando asdf"

if ! command -v asdf >/dev/null 2>&1; then
  ASDF_VERSION="v0.19.0"
  ARCH="$(dpkg --print-architecture)"  # amd64 ou arm64
  curl -L "https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-${ARCH}.tar.gz" \
    -o /tmp/asdf.tar.gz
  sudo tar -xzf /tmp/asdf.tar.gz -C /usr/local/bin/
  rm /tmp/asdf.tar.gz
  info "asdf instalado: $(asdf --version)"
else
  info "asdf já instalado: $(asdf --version)"
fi

# ---------- Node via asdf ----------
#
# Usamos Node 22 LTS (não 20.x). Motivo: corepack do 20.19 dá pau em vários
# setups (em especial quem testa o mesmo projeto no Windows nativo, onde o
# corepack falha em atualizar o pnpm). 22 LTS evita isso e não temos
# dependência travada no 20.

step "Instalando Node.js 22 LTS"

if ! asdf plugin list 2>/dev/null | grep -q "^nodejs$"; then
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
fi

# Resolve dinamicamente o latest do canal 22.x — evita travar em patch específico.
NODE_TARGET="$(asdf latest nodejs 22)"
if ! asdf list nodejs 2>/dev/null | grep -q "$NODE_TARGET"; then
  asdf install nodejs "$NODE_TARGET"
fi
asdf set -u nodejs "$NODE_TARGET"
info "Node ativo: $NODE_TARGET"

# Garante shims resolvidos antes de seguir
~/.asdf/shims/node -e "" 2>/dev/null || true

# ---------- pnpm via asdf ----------
#
# Antes usávamos corepack. Trocamos pra plugin asdf nativo: instala binário
# direto, sem depender da versão do Node nem do estado do corepack.

step "Instalando pnpm via asdf"

if ! asdf plugin list 2>/dev/null | grep -q "^pnpm$"; then
  asdf plugin add pnpm https://github.com/jonathanmorley/asdf-pnpm.git
fi

PNPM_TARGET="$(asdf latest pnpm)"
if ! asdf list pnpm 2>/dev/null | grep -q "$PNPM_TARGET"; then
  asdf install pnpm "$PNPM_TARGET"
fi
asdf set -u pnpm "$PNPM_TARGET"
info "pnpm ativo: $PNPM_TARGET"

# ---------- bun via asdf ----------

step "Instalando bun via asdf"

if ! asdf plugin list 2>/dev/null | grep -q "^bun$"; then
  asdf plugin add bun https://github.com/cometkim/asdf-bun.git
fi

BUN_TARGET="$(asdf latest bun)"
if ! asdf list bun 2>/dev/null | grep -q "$BUN_TARGET"; then
  asdf install bun "$BUN_TARGET"
fi
asdf set -u bun "$BUN_TARGET"
info "bun ativo: $BUN_TARGET"

# ---------- Neovim 0.11.2 via asdf ----------

step "Instalando Neovim 0.11.2"

if ! asdf plugin list 2>/dev/null | grep -q "^neovim$"; then
  asdf plugin add neovim https://github.com/richin13/asdf-neovim.git
fi

NVIM_TARGET="0.11.2"
if ! asdf list neovim 2>/dev/null | grep -q "$NVIM_TARGET"; then
  info "Baixando Neovim $NVIM_TARGET (pode demorar 2-3min)..."
  asdf install neovim "$NVIM_TARGET"
fi
asdf set -u neovim "$NVIM_TARGET"

# ---------- Ferramentas modernas (eza, gh) ----------

step "Instalando eza, gh CLI, starship"

# eza (replacement do ls)
if ! command -v eza >/dev/null 2>&1; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
    sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi

# GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
fi

# Starship prompt
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# ---------- Claude Code CLI ----------

step "Instalando Claude Code CLI"

if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
  info "Claude Code instalado. Faz login com: claude"
else
  info "Claude Code já instalado: $(claude --version 2>/dev/null || echo 'OK')"
fi

# ---------- Symlinks dos dotfiles ----------

step "Aplicando symlinks dos dotfiles"

bash ~/dotfiles/install.sh

# ---------- Conclusão ----------

cat <<EOF

${GREEN}✅ Setup WSL concluído.${NC}

Próximos passos:

  ${YELLOW}1.${NC} Logout/login do WSL pra aplicar mudança de shell:
       exit
       wsl --terminate Ubuntu-24.04   (no PowerShell)
       wsl   (reentrar)

  ${YELLOW}2.${NC} No primeiro zsh, abre nvim pra inicializar LazyVim:
       nvim
       (aguarda Lazy clonar plugins, :q quando terminar)
       nvim
       (aguarda Mason instalar LSPs, :q)

  ${YELLOW}3.${NC} Em qualquer projeto Node/TS:
       cd /mnt/c/dev/algum-projeto    # acessa Windows fs (lento)
       cd ~/ws/algum-projeto          # acessa WSL fs (rápido)

       ~/dotfiles/team-standards/setup-project.sh

  ${YELLOW}4.${NC} Login no Claude Code:
       claude

${BLUE}Performance dica:${NC} mantém código em \$HOME (~/ws/...) e NÃO em /mnt/c/.
WSL lê do disco Windows ~10x mais lento. Cloná no \$HOME do WSL é 10x mais rápido
em git/npm/build.

${BLUE}Integração com Windows:${NC}
  - Abre Explorer no diretório atual:    explorer.exe .
  - Abre VSCode do Windows no projeto:   code .
  - Copia pra clipboard do Windows:      echo 'texto' | clip
  - Acessa serviços rodando no WSL:      localhost no Windows funciona direto

EOF
