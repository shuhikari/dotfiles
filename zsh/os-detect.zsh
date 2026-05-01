# ~/dotfiles/zsh/os-detect.zsh
# Detecta o OS atual e exporta variáveis pra outros módulos usarem.
# Carregado primeiro no zshrc, antes de exports/aliases/functions.

# Identifica o OS
case "$(uname -s)" in
  Darwin)
    export DOTFILES_OS="macos"
    export DOTFILES_BREW_PREFIX="/opt/homebrew"
    ;;
  Linux)
    if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
      export DOTFILES_OS="wsl"
    else
      export DOTFILES_OS="linux"
    fi
    export DOTFILES_BREW_PREFIX=""  # WSL/Linux usa apt, não brew (a menos que linuxbrew)
    ;;
  *)
    export DOTFILES_OS="unknown"
    ;;
esac

# Helper functions
is_macos() { [[ "$DOTFILES_OS" == "macos" ]]; }
is_wsl()   { [[ "$DOTFILES_OS" == "wsl" ]]; }
is_linux() { [[ "$DOTFILES_OS" == "linux" || "$DOTFILES_OS" == "wsl" ]]; }
