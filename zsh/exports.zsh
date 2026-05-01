# ~/dotfiles/zsh/exports.zsh
# Variáveis de ambiente e PATH. Cross-platform: macOS + WSL/Linux.

# =====================================================================
# Linguagem e editor
# =====================================================================

export LANG=en_US.UTF-8
export EDITOR='nvim'
export VISUAL='nvim'

# =====================================================================
# Path base por OS
# =====================================================================

if is_macos; then
  # Homebrew em ARM Mac
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif is_wsl; then
  # WSL: ferramentas instaladas via apt já estão no PATH
  # Linuxbrew opcional (se preferir homebrew em WSL)
  if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Local bin (binários instalados pelo user) — ambos OS
export PATH="$HOME/.local/bin:$PATH"

# =====================================================================
# Linguagens e package managers (cross-OS)
# =====================================================================

# Cargo (Rust)
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Bun
export BUN_INSTALL="$HOME/.bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm — path varia por OS
if is_macos; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"

# Deno
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"

# =====================================================================
# Java (só Mac por ora; em WSL instala via SDKMAN ou apt)
# =====================================================================

if is_macos && [[ -d "/opt/homebrew/opt/openjdk@17" ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# =====================================================================
# Mobile dev — só macOS (WSL não suporta Android Studio nativo bem)
# =====================================================================

if is_macos; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export ANDROID_PLATFORM_TOOLS="$ANDROID_HOME/platform-tools"
  [[ -d "$ANDROID_PLATFORM_TOOLS" ]] && export PATH="$ANDROID_PLATFORM_TOOLS:$PATH"

  export FLUTTER_PATH="$HOME/.tools/flutter/bin"
  [[ -d "$FLUTTER_PATH" ]] && export PATH="$FLUTTER_PATH:$PATH"

  ANDROID_STUDIO_BASE="$HOME/Library/Application Support/JetBrains/Toolbox"
  export ANDROID_APP="$ANDROID_STUDIO_BASE/apps/AndroidStudio/ch-0/221.6008.13.2211.9619390/Android Studio.app"
  export CAPACITOR_ANDROID_STUDIO_APP="$ANDROID_APP"
  export CAPACITOR_ANDROID_STUDIO_PATH="$ANDROID_STUDIO_BASE/scripts/studio"

  export TOOLBOX_SCRIPTS="$HOME/.tools/toolbox"
  [[ -d "$TOOLBOX_SCRIPTS" ]] && export PATH="$TOOLBOX_SCRIPTS:$PATH"
fi

# =====================================================================
# Compiler flags (só macOS, libiconv via Homebrew)
# =====================================================================

if is_macos; then
  export PATH="/opt/homebrew/opt/libiconv/bin:$PATH"
  export LDFLAGS="-L/opt/homebrew/opt/libiconv/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/libiconv/include -I/opt/homebrew/opt/openjdk/include"
fi

# =====================================================================
# asdf (Go-based, >=0.16) — cross-OS
# =====================================================================

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$ASDF_DATA_DIR/shims:$PATH"
export ASDF_NODEJS_LEGACY_FILE_DYNAMIC_STRATEGY=latest_available

# Completions do asdf (gera uma vez, depois carrega do cache)
if command -v asdf >/dev/null && [[ ! -f "$ASDF_DATA_DIR/completions/_asdf" ]]; then
  mkdir -p "$ASDF_DATA_DIR/completions"
  asdf completion zsh > "$ASDF_DATA_DIR/completions/_asdf" 2>/dev/null
fi
fpath=("$ASDF_DATA_DIR/completions" $fpath)

# =====================================================================
# WSL-specific
# =====================================================================

if is_wsl; then
  # Permite abrir URLs/arquivos no Windows via wslview
  export BROWSER="wslview"

  # Display pra GUI apps via WSLg (se precisar, ex.: Android emulator não funciona)
  export DISPLAY=":0"

  # Faz Docker Desktop do Windows visível em CLI no WSL
  # (já configurado automaticamente pelo Docker Desktop, redundância segura)
  export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"
fi

# =====================================================================
# Misc
# =====================================================================

# Starship prompt config
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

# gcloud Python (se Python específico for necessário)
if is_macos; then
  export CLOUDSDK_PYTHON="/usr/local/bin/python3.12"
fi

# Windsurf
[[ -d "$HOME/.codeium/windsurf/bin" ]] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Antigravity
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
