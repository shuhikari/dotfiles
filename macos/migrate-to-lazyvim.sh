#!/usr/bin/env bash
# migrate-to-lazyvim.sh
#
# Migra de LunarVim pra LazyVim mantendo paridade de atalhos e funcionalidades.
# Idempotente: pode interromper e rodar de novo (não quebra estado).
#
# Compatível com asdf legacy (bash, <0.16) e novo (Go, >=0.16).

set -euo pipefail

DATE=$(date +%Y%m%d-%H%M%S)
DOTFILES_DIR="$HOME/dotfiles"

# Cores
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BLUE=''; NC=''
fi

step()  { echo -e "\n${BLUE}=== $* ===${NC}"; }
info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }
ask()   { read -p "$(echo -e ${YELLOW}[?]${NC} $1) " -n 1 -r; echo; }

# ---------- Helpers ----------

# Define versão global compatível com asdf legacy e Go-based
# https://asdf-vm.com/manage/versions.html
asdf_set_global() {
  local plugin="$1" version="$2"
  local asdf_version
  asdf_version=$(asdf --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  local major minor
  major=$(echo "$asdf_version" | cut -d. -f1)
  minor=$(echo "$asdf_version" | cut -d. -f2)

  # >=0.16 usa "set -u", <0.16 usa "global"
  if [[ "$major" -gt 0 ]] || [[ "$minor" -ge 16 ]]; then
    asdf set -u "$plugin" "$version"
  else
    asdf global "$plugin" "$version"
  fi
}

# ---------- Confirmação inicial ----------

cat <<EOF

Esse script vai:
  1. Fazer backup do LunarVim
  2. Garantir Neovim 0.11.2+ via asdf (LazyVim master requer 0.11+)
  3. Instalar LazyVim em ~/.config/nvim
  4. Linkar o config do dotfiles
  5. Aguardar Lazy sync inicial (precisa rodar 1x manualmente depois)

LunarVim NÃO vai ser desinstalado — fica como fallback até confirmares
que LazyVim está OK. Depois tu pode remover manualmente.

EOF

ask "Prosseguir? [y/N]:"
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

# ---------- Fase 1: Backup ----------

step "Fase 1: Backup"

if [ -d ~/.local/share/lunarvim ]; then
  mv ~/.local/share/lunarvim ~/.local/share/lunarvim.backup-$DATE
  info "LunarVim backupeado: ~/.local/share/lunarvim.backup-$DATE"
fi

if [ -d ~/.cache/lvim ]; then
  rm -rf ~/.cache/lvim
  info "Cache LunarVim limpo"
fi

if [ -d ~/.config/nvim ] && [ ! -L ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.backup-$DATE
  info "~/.config/nvim existente backupeado"
elif [ -L ~/.config/nvim ]; then
  rm ~/.config/nvim
  info "Symlink antigo de ~/.config/nvim removido"
fi

# ---------- Fase 2: asdf neovim plugin ----------

step "Fase 2: Plugin asdf-neovim"

if ! command -v asdf &>/dev/null; then
  error "asdf não instalado. Instala primeiro: brew install asdf"
  exit 1
fi

asdf_version=$(asdf --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
info "asdf versão: $asdf_version"

if ! asdf plugin list 2>/dev/null | grep -q "^neovim$"; then
  asdf plugin add neovim https://github.com/richin13/asdf-neovim.git
  info "Plugin asdf-neovim adicionado"
else
  info "Plugin asdf-neovim já existe"
fi

# ---------- Fase 3: Instala Neovim ----------

step "Fase 3: Neovim 0.11.2"

NVIM_TARGET="0.11.2"

if asdf list neovim 2>/dev/null | grep -q "$NVIM_TARGET"; then
  info "Neovim $NVIM_TARGET já instalado"
else
  info "Instalando Neovim $NVIM_TARGET (pode demorar 2-3 min)..."
  asdf install neovim "$NVIM_TARGET"
fi

asdf_set_global neovim "$NVIM_TARGET"
info "Neovim global: $(nvim --version 2>/dev/null | head -1 || echo 'reabra terminal pra refresh do PATH')"

# ---------- Fase 4: Symlink do config ----------

step "Fase 4: Linkar config do dotfiles"

if [ ! -d "$DOTFILES_DIR/nvim" ]; then
  error "Não encontrado: $DOTFILES_DIR/nvim"
  error "Faz git pull no dotfiles primeiro pra puxar a config do LazyVim"
  exit 1
fi

ln -s "$DOTFILES_DIR/nvim" ~/.config/nvim
info "Symlink: ~/.config/nvim → $DOTFILES_DIR/nvim"

# ---------- Fase 5: Bootstrap lazy.nvim ----------

step "Fase 5: Inicialização do LazyVim"

cat <<EOF

${GREEN}Setup automatizado concluído.${NC}

Agora precisa rodar manualmente uma vez pra:
  - lazy.nvim clonar todos os plugins (~30s)
  - Mason instalar LSP servers (~2-3 min)
  - Treesitter compilar parsers (~1 min)

Comandos:

  ${YELLOW}1.${NC} Abre Neovim:
       nvim

  ${YELLOW}2.${NC} Aguarda lazy.nvim mostrar painel de instalação. Quando completar:
       :q

  ${YELLOW}3.${NC} Reabre. Aguarda Mason auto-install dos LSPs:
       nvim
       :Mason         (vê progresso)
       :LazyHealth    (verifica que tudo OK)

  ${YELLOW}4.${NC} Testa em arquivo .ts real:
       cd ~/ws/algum-projeto
       nvim src/main.ts
       (aguarda 5s pra LSP attachar)
       :LspInfo       (deve mostrar vtsls attached)

  ${YELLOW}5.${NC} Testa atalhos:
       <Space>e       → toggle file tree (Neo-tree)
       <Space>f       → find files
       <Space>F       → live grep
       <Space>cc      → abre Claude Code num split
       gd, gr, K      → LSP nav e hover

Se algo falhar, manda print da saída + :messages e :LspLog.

${BLUE}Pra reverter pra LunarVim:${NC}
  rm ~/.config/nvim
  mv ~/.local/share/lunarvim.backup-$DATE ~/.local/share/lunarvim
  $(if [[ "$asdf_version" =~ ^0\.(0|1[0-5])\. ]]; then echo "asdf global neovim 0.9.5"; else echo "asdf set -u neovim 0.9.5"; fi)

EOF
