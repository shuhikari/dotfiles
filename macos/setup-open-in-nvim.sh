#!/usr/bin/env bash
# setup-open-in-nvim.sh
#
# Cria um app "Open in Neovim.app" em /Applications que recebe arquivos
# do Finder (Open With...) e abre no Ghostty rodando nvim (LazyVim).
#
# Uso:
#   ./setup-open-in-nvim.sh
#
# Depois:
#   1. No Finder, click direito num arquivo .ts/.js/.md → Open With → Other...
#   2. Marca "Always Open With", seleciona "Open in Neovim"
#   3. Pra fazer default em TODOS arquivos do tipo: Get Info (⌘I) →
#      Open With → escolhe "Open in Neovim" → "Change All..."

set -euo pipefail

APP_NAME="Open in Neovim"
APP_DIR="/Applications/${APP_NAME}.app"
EXECUTABLE_NAME="open-in-nvim"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; exit 1; }

# ----- Pré-checks -----

[[ "$(uname)" == "Darwin" ]] || error "Esse script é apenas para macOS."

command -v nvim >/dev/null || error "nvim não encontrado no PATH. Instala Neovim primeiro (asdf install neovim)."
[[ -d "/Applications/Ghostty.app" ]] || error "Ghostty.app não encontrado em /Applications."

# ----- Remove instalação anterior se existir -----

if [[ -d "$APP_DIR" ]]; then
  warn "Removendo instalação anterior em $APP_DIR"
  rm -rf "$APP_DIR"
fi

# ----- Cria estrutura do .app -----

info "Criando $APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# ----- Info.plist -----

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>open-in-nvim</string>
    <key>CFBundleIdentifier</key>
    <string>local.openinnvim</string>
    <key>CFBundleName</key>
    <string>Open in Neovim</string>
    <key>CFBundleDisplayName</key>
    <string>Open in Neovim</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>All Files</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.item</string>
                <string>public.text</string>
                <string>public.source-code</string>
                <string>public.script</string>
                <string>public.shell-script</string>
                <string>public.json</string>
                <string>public.xml</string>
                <string>public.yaml</string>
                <string>public.plain-text</string>
                <string>public.data</string>
            </array>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

# ----- Executável -----

cat > "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}" <<'BASH'
#!/bin/bash
# Recebe caminhos via argv quando arquivo é aberto via "Open With".
# Abre Ghostty rodando nvim com o arquivo (ou diretório).

set -e

# Garante PATH com locais comuns onde nvim e ghostty cli costumam viver
# Inclui asdf shims pra pegar a versão de nvim gerenciada por asdf.
export PATH="$HOME/.asdf/shims:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"

if [[ $# -eq 0 ]]; then
    # Click no app sem arquivo: abre nvim na home
    open -na "Ghostty.app" --args \
        --working-directory="$HOME" \
        -e "nvim"
    exit 0
fi

file_path="$1"

if [[ -f "$file_path" ]]; then
    dir_path=$(dirname "$file_path")
    # Escapa aspas simples no caminho (raro, mas seguro)
    safe_path=$(printf %s "$file_path" | sed "s/'/'\\\\''/g")
    open -na "Ghostty.app" --args \
        --working-directory="$dir_path" \
        -e "nvim '$safe_path'"
elif [[ -d "$file_path" ]]; then
    open -na "Ghostty.app" --args \
        --working-directory="$file_path" \
        -e "nvim ."
else
    # Caminho inválido — abre Ghostty básico
    open -na "Ghostty.app"
fi
BASH

chmod +x "$APP_DIR/Contents/MacOS/${EXECUTABLE_NAME}"

# ----- Registra com Launch Services pra aparecer em "Open With" -----

info "Registrando com Launch Services"
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
    -f "$APP_DIR" 2>/dev/null || true

# Forca rebuild dos defaults pra aparecer no menu Open With
killall Finder 2>/dev/null || true

# ----- Concluído -----

info "App criado: $APP_DIR"
echo
info "Como usar:"
echo "  1. No Finder, click direito num arquivo (ex: .ts, .md)"
echo "  2. Open With → Other..."
echo "  3. Selecione 'Open in Neovim' (na pasta /Applications)"
echo "  4. Marque 'Always Open With' se quiser default pra esse tipo"
echo
info "Pra fazer default em TODOS arquivos de uma extensão:"
echo "  1. Get Info no arquivo (⌘I)"
echo "  2. Open With → 'Open in Neovim'"
echo "  3. Click 'Change All...' → confirma"
echo
warn "Caso o app não apareça em 'Open With', reinicia o Finder ou o Mac."
warn "Se Ghostty não estiver no PATH ou em /Applications, edita o script:"
warn "  /Applications/${APP_NAME}.app/Contents/MacOS/${EXECUTABLE_NAME}"
