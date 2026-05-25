#!/usr/bin/env bash
# windows/marktext/apply.sh
#
# Adiciona "Abrir com MarkText" ao menu de contexto do Windows Explorer.
# Roda no WSL e usa reg.exe pra importar diretamente em HKEY_CURRENT_USER
# (sem prompt de UAC).
#
# Uso:
#   bash ~/dotfiles/windows/marktext/apply.sh             # instala
#   bash ~/dotfiles/windows/marktext/apply.sh --uninstall # remove
#
# Detecta o user do Windows via cmd.exe e substitui no template.

set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ---- Pré-checks ----
grep -qi "microsoft\|wsl" /proc/version 2>/dev/null \
  || { echo "Este script só roda em WSL." >&2; exit 1; }

command -v reg.exe >/dev/null \
  || { echo "reg.exe não encontrado no PATH (precisa do interop WSL→Windows)." >&2; exit 1; }

# ---- Uninstall path ----
if [[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]]; then
  echo "Removendo entradas do menu de contexto..."
  reg.exe import "$(wslpath -w "$HERE/uninstall.reg")"
  echo "Pronto. Reabra o Windows Explorer pra ver."
  exit 0
fi

# ---- Detecta user Windows ----
WIN_USER="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')"
[[ -n "$WIN_USER" ]] \
  || { echo "Não consegui detectar o user do Windows (cmd.exe /c echo %USERNAME%)." >&2; exit 1; }

# ---- Verifica MarkText instalado ----
MARKTEXT_EXE="/mnt/c/Users/$WIN_USER/AppData/Local/Programs/MarkText/MarkText.exe"
if [[ ! -x "$MARKTEXT_EXE" ]]; then
  echo "Aviso: MarkText.exe não encontrado em:"
  echo "  $MARKTEXT_EXE"
  echo "Instale primeiro (https://github.com/marktext/marktext/releases) e rode de novo."
  echo "Seguindo mesmo assim (entradas vão apontar pro caminho default)..."
fi

# ---- Gera reg final ----
TMP_REG="$(mktemp --suffix=.reg)"
trap 'rm -f "$TMP_REG"' EXIT
sed "s|__WIN_USER__|$WIN_USER|g" "$HERE/install.reg.template" > "$TMP_REG"

# ---- Importa ----
echo "Importando entradas do menu de contexto pra HKEY_CURRENT_USER..."
reg.exe import "$(wslpath -w "$TMP_REG")"

echo
echo "Pronto. Clique direito numa pasta no Windows Explorer:"
echo "  - 'Abrir com MarkText'              (sobre o ícone da pasta)"
echo "  - 'Abrir esta pasta com MarkText'   (no espaço vazio dentro)"
echo
echo "Windows 11: as entradas podem aparecer atrás de 'Mostrar mais opções'."
echo "Pra remover: bash $HERE/apply.sh --uninstall"
