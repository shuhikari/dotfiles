#!/usr/bin/env bash
# install.sh — symlinks dos dotfiles. Cross-OS: macOS, WSL2, Linux.
#
# NÃO instala team-standards (esses são instalados por projeto via setup-project.sh).
# NÃO instala dependências do sistema. Use:
#   - macOS: instala manualmente via brew
#   - WSL2: roda ./wsl/setup.sh primeiro (instala tudo)
#
# Idempotente. Faz backup de arquivos pré-existentes.

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }

# Detecta OS
case "$(uname -s)" in
  Darwin)  OS="macos" ;;
  Linux)
    if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
      OS="wsl"
    else
      OS="linux"
    fi
    ;;
  *) OS="unknown" ;;
esac

info "OS detectado: $OS"
info "Dotfiles dir: $DOTFILES_DIR"
echo

backup_if_exists() {
  local target="$1"
  if [[ -e $target && ! -L $target ]]; then
    mkdir -p "$BACKUP_DIR"
    info "Backup: $target → $BACKUP_DIR/"
    mv "$target" "$BACKUP_DIR/$(basename "$target")"
  elif [[ -L $target ]]; then
    rm "$target"
  fi
}

link() {
  local src="$1" dst="$2"
  [[ -e $src ]] || { error "Source não existe: $src"; return 1; }
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  info "Linked: $dst"
}

# ----- Cross-OS (sempre linka) -----

# Neovim (LazyVim)
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# tmux
link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

# zsh
link "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# git
link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Claude Code custom commands
mkdir -p "$HOME/.claude/commands"
for cmd in "$DOTFILES_DIR"/claude/commands/*.md; do
  [[ -e $cmd ]] || continue
  link "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# ----- macOS-specific -----

if [[ "$OS" == "macos" ]]; then
  [[ -f "$DOTFILES_DIR/aerospace.toml" ]] && link "$DOTFILES_DIR/aerospace.toml" "$HOME/.aerospace.toml"
fi

# ----- WSL/Linux-specific -----

if [[ "$OS" == "wsl" || "$OS" == "linux" ]]; then
  warn "AeroSpace não aplicável (use FancyZones/GlazeWM no Windows ou i3/sway no Linux)"
fi

# ----- local.zsh (não comitado, criar do template se faltar) -----

if [[ ! -f "$DOTFILES_DIR/zsh/local.zsh" ]]; then
  cp "$DOTFILES_DIR/zsh/local.zsh.example" "$DOTFILES_DIR/zsh/local.zsh"
  warn "Criado zsh/local.zsh a partir do template. Edita pra adicionar API keys."
fi

# ----- Resumo -----

echo
if [[ -d $BACKUP_DIR ]]; then
  warn "Arquivos antigos salvos em: $BACKUP_DIR"
fi

info "Instalação concluída ($OS)."
echo
case "$OS" in
  macos)
    info "Próximos passos (macOS):"
    echo "  1. exec zsh (recarrega shell)"
    echo "  2. ./macos/migrate-to-lazyvim.sh (se ainda em LunarVim)"
    echo "  3. nvim (inicializa Lazy + Mason)"
    echo "  4. Em projetos: ./team-standards/setup-project.sh"
    ;;
  wsl|linux)
    info "Próximos passos (WSL/Linux):"
    echo "  1. exec zsh (recarrega shell)"
    echo "  2. nvim (inicializa Lazy + Mason)"
    echo "  3. Em projetos: ./team-standards/setup-project.sh"
    if [[ "$OS" == "wsl" ]]; then
      echo
      echo "  ${YELLOW}Performance:${NC} mantém código em ~/ws/, NÃO em /mnt/c/"
    fi
    ;;
esac
