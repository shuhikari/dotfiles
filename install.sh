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

# Renderiza um .example para o arquivo real, substituindo placeholders {{VAR}}.
# Não sobrescreve se o destino já existir (idempotente).
render_template() {
  local example="$1" target="$2"
  shift 2
  [[ -f $target ]] && return 0
  [[ -f $example ]] || { error "Template não existe: $example"; return 1; }
  local tmp; tmp=$(mktemp)
  cp "$example" "$tmp"
  while [[ $# -gt 0 ]]; do
    local placeholder="$1" value="$2"; shift 2
    if [[ "$OS" == "macos" ]]; then
      sed -i '' "s|{{${placeholder}}}|${value}|g" "$tmp"
    else
      sed -i "s|{{${placeholder}}}|${value}|g" "$tmp"
    fi
  done
  mv "$tmp" "$target"
  info "Gerado: $target (a partir de $(basename "$example"))"
}

prompt_default() {
  local prompt="$1" default="$2" reply
  read -r -p "$prompt [$default]: " reply
  echo "${reply:-$default}"
}

# ----- Cross-OS (sempre linka) -----

# Neovim (LazyVim)
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# tmux
link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

# zsh
link "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# Starship prompt
link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# ----- git (gera arquivos reais a partir dos .example, gitignored) -----

if [[ ! -f "$DOTFILES_DIR/git/gitconfig" ]]; then
  warn "Configurando identidade git (rodado só na primeira instalação)."
  GIT_NAME=$(prompt_default "Nome completo" "$(git config --global user.name 2>/dev/null || echo)")
  GIT_EMAIL=$(prompt_default "Email principal" "$(git config --global user.email 2>/dev/null || echo)")
  AUDITORE_EMAIL=$(prompt_default "Email Auditore (~/ws/auditore e ~/ws/byd)" "$GIT_EMAIL")
  TEGRA_EMAIL=$(prompt_default "Email Tegra (~/ws/tegra) — Enter pra pular" "")

  render_template "$DOTFILES_DIR/git/gitconfig.example" \
                  "$DOTFILES_DIR/git/gitconfig" \
                  GIT_NAME "$GIT_NAME" GIT_EMAIL "$GIT_EMAIL"
  render_template "$DOTFILES_DIR/git/gitconfig-auditore.example" \
                  "$DOTFILES_DIR/git/gitconfig-auditore" \
                  AUDITORE_EMAIL "$AUDITORE_EMAIL"
  if [[ -n $TEGRA_EMAIL ]]; then
    render_template "$DOTFILES_DIR/git/gitconfig-tegra.example" \
                    "$DOTFILES_DIR/git/gitconfig-tegra" \
                    TEGRA_EMAIL "$TEGRA_EMAIL"
  fi
fi

link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Claude Code — CLAUDE.md global (diretrizes valem em todos os projetos)
mkdir -p "$HOME/.claude"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Claude Code — settings.json (theme, attribution, etc. — vale em todos os projetos)
link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"

# Claude Code custom commands
mkdir -p "$HOME/.claude/commands"
for cmd in "$DOTFILES_DIR"/claude/commands/*.md; do
  [[ -e $cmd ]] || continue
  link "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# Claude Code custom skills (se existir o diretório)
if [[ -d "$DOTFILES_DIR/claude/skills" ]]; then
  mkdir -p "$HOME/.claude/skills"
  for skill in "$DOTFILES_DIR"/claude/skills/*; do
    [[ -e $skill ]] || continue
    link "$skill" "$HOME/.claude/skills/$(basename "$skill")"
  done
fi

# ----- Claude Code — multi-perfil (credenciais isoladas por org/cliente) -----
#
# Cada perfil tem seu próprio CLAUDE_CONFIG_DIR em ~/.claude-profiles/<nome>/,
# isolando .credentials.json (OAuth) e histórico. Configs compartilhados
# (CLAUDE.md, settings.json, commands/, skills/) são symlinks pro dotfiles.
# Setup inicial em cada perfil: `claude-profile <nome> && claude /login`.

CLAUDE_PROFILES_DIR="$HOME/.claude-profiles"
CLAUDE_PROFILES=(auditore hmax sintetiza)

mkdir -p "$CLAUDE_PROFILES_DIR"
chmod 0700 "$CLAUDE_PROFILES_DIR"

for profile in "${CLAUDE_PROFILES[@]}"; do
  profile_dir="$CLAUDE_PROFILES_DIR/$profile"
  mkdir -p "$profile_dir"
  chmod 0700 "$profile_dir"

  # Symlinks pro config compartilhado (sobrescreve atomicamente com -fn)
  ln -sfn "$DOTFILES_DIR/claude/CLAUDE.md"    "$profile_dir/CLAUDE.md"
  ln -sfn "$DOTFILES_DIR/claude/settings.json" "$profile_dir/settings.json"
  ln -sfn "$DOTFILES_DIR/claude/commands"     "$profile_dir/commands"
  if [[ -d "$DOTFILES_DIR/claude/skills" ]]; then
    ln -sfn "$DOTFILES_DIR/claude/skills" "$profile_dir/skills"
  fi
  info "Perfil Claude: $profile ($profile_dir)"
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
    echo "  4. ./macos/setup-open-in-nvim.sh (opcional: 'Open With Neovim' no Finder)"
    echo "  5. Em projetos: ./team-standards/setup-project.sh"
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
