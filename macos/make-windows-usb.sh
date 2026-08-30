#!/usr/bin/env bash
#
# make-windows-usb.sh — cria um pendrive bootável do Windows (UEFI) no macOS.
#
# Por que não é só copiar a ISO:
#   - O firmware UEFI só garante boot a partir de FAT32/FAT16.
#   - FAT32 tem teto de 4 GiB por arquivo, e o sources/install.wim das ISOs
#     modernas do Windows 10/11 passa disso (tipicamente 4-7 GiB).
#   - Solução: copiar tudo menos o install.wim e recriá-lo fatiado em .swm
#     (o Windows Setup lê install.swm + install2.swm... nativamente).
#
# Uso:
#   ./make-windows-usb.sh -d disk4 -s /Volumes/CCCOMA_X64FRE_PT-BR_DV9
#   ./make-windows-usb.sh -d disk4 -s ~/Downloads/Win11_24H2_pt-BR.iso -n WIN11
#
set -euo pipefail

DISK=""
SRC=""
LABEL="WINDOWS"
SCHEME="MBR"
ASSUME_YES=0
SPLIT_MB=3800          # margem segura sob o limite de 4096 MiB do FAT32
MOUNTED_ISO=""

die()  { printf '\033[31merro:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33maviso:\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Uso: make-windows-usb.sh -d <diskN> -s <ISO ou volume montado> [opções]

  -d, --disk     identificador do pendrive (ex.: disk4). Obrigatório.
  -s, --source   caminho do .iso do Windows OU do volume já montado. Obrigatório.
  -n, --name     rótulo do volume FAT32 (máx. 11 chars, A-Z0-9). Padrão: WINDOWS
      --scheme   MBR (padrão) ou GPT. MBR boota em UEFI e em CSM/legacy.
      --split-mb tamanho de cada fatia .swm em MiB. Padrão: 3800
  -y, --yes      não pedir confirmação para apagar o disco.
  -h, --help     esta ajuda.
USAGE
}

cleanup() {
  if [[ -n "$MOUNTED_ISO" ]]; then
    info "Desmontando ISO ($MOUNTED_ISO)"
    hdiutil detach "$MOUNTED_ISO" -quiet || true
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--disk)     DISK="${2:?}"; shift 2 ;;
    -s|--source)   SRC="${2:?}";  shift 2 ;;
    -n|--name)     LABEL="${2:?}"; shift 2 ;;
    --scheme)      SCHEME="${2:?}"; shift 2 ;;
    --split-mb)    SPLIT_MB="${2:?}"; shift 2 ;;
    -y|--yes)      ASSUME_YES=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) die "argumento desconhecido: $1" ;;
  esac
done

[[ -n "$DISK" ]] || { usage; die "faltou -d <diskN>"; }
[[ -n "$SRC"  ]] || { usage; die "faltou -s <ISO ou volume>"; }

DISK="${DISK#/dev/}"
[[ "$DISK" =~ ^disk[0-9]+$ ]] || die "identificador inválido: '$DISK' (esperado algo como disk4)"
[[ "$SCHEME" == "MBR" || "$SCHEME" == "GPT" ]] || die "--scheme deve ser MBR ou GPT"
[[ "${#LABEL}" -le 11 ]] || die "rótulo '$LABEL' tem mais de 11 caracteres (limite do FAT32)"

command -v wimlib-imagex >/dev/null || die "wimlib não encontrado. Instale com: brew install wimlib"

# ---------------------------------------------------------------- guardrails
info "Validando disco de destino /dev/$DISK"
INFO="$(diskutil info "$DISK" 2>/dev/null)" || die "/dev/$DISK não existe"

# 'Device / Media Name' contém '/', então o sed usa '#' como delimitador.
field() { sed -nE "s#^[[:space:]]*$1:[[:space:]]+(.*)\$#\\1#p" <<<"$INFO" | head -1; }

[[ "$(field 'Whole')" == "Yes" ]] || die "/dev/$DISK não é um disco inteiro (passe diskN, não diskNsM)"
[[ "$(field 'Device Location')" == "External" ]] || \
  die "/dev/$DISK não é externo (Device Location='$(field 'Device Location')'). Abortando para não tocar em disco interno."
[[ "$(field 'Removable Media')" == "Removable" ]] || warn "mídia não reportada como removível"

MEDIA="$(field 'Device / Media Name')"
PROTO="$(field 'Protocol')"
SIZE="$(field 'Disk Size')"

# ------------------------------------------------------------------- origem
if [[ -f "$SRC" ]]; then
  info "Montando ISO: $SRC"
  MOUNTED_ISO="$(hdiutil attach -nobrowse -readonly "$SRC" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -1)"
  [[ -n "$MOUNTED_ISO" ]] || die "não consegui montar $SRC"
  SRC="$MOUNTED_ISO"
fi
[[ -d "$SRC" ]] || die "origem não encontrada: $SRC"
[[ -d "$SRC/sources" && -d "$SRC/efi" ]] || die "'$SRC' não parece uma ISO do Windows (faltam sources/ e efi/)"

WIM="$SRC/sources/install.wim"
ESD="$SRC/sources/install.esd"
IMG=""
[[ -f "$WIM" ]] && IMG="$WIM"
[[ -z "$IMG" && -f "$ESD" ]] && IMG="$ESD"
[[ -n "$IMG" ]] || die "não achei sources/install.wim nem sources/install.esd em '$SRC'"

IMG_BYTES="$(stat -f %z "$IMG")"
FAT32_LIMIT=$((4 * 1024 * 1024 * 1024))
SRC_BYTES="$(du -sk "$SRC" | awk '{print $1 * 1024}')"
DISK_BYTES="$(diskutil info -plist "$DISK" | plutil -extract TotalSize raw - 2>/dev/null || echo 0)"

if [[ "$DISK_BYTES" -gt 0 && "$SRC_BYTES" -gt "$DISK_BYTES" ]]; then
  die "a origem ($((SRC_BYTES/1024/1024)) MiB) não cabe em /dev/$DISK ($((DISK_BYTES/1024/1024)) MiB)"
fi

# ------------------------------------------------------------- confirmação
cat <<EOF

  Destino ......... /dev/$DISK — $MEDIA ($PROTO, $SIZE)
  Origem .......... $SRC
  Imagem .......... $(basename "$IMG") — $((IMG_BYTES/1024/1024)) MiB
  Esquema ......... $SCHEME + FAT32, rótulo "$LABEL"
  install.wim ..... $([[ "$IMG_BYTES" -ge "$FAT32_LIMIT" ]] && echo "acima de 4 GiB → será fatiado em .swm de ${SPLIT_MB} MiB" || echo "abaixo de 4 GiB → cópia direta")

  TODO o conteúdo de /dev/$DISK será APAGADO. Isso é irreversível.

EOF

if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -r -p "Digite APAGAR para confirmar: " reply
  [[ "$reply" == "APAGAR" ]] || die "cancelado pelo usuário"
fi

# ------------------------------------------------------------------ formata
info "Formatando /dev/$DISK como FAT32 ($SCHEME), rótulo $LABEL"
diskutil unmountDisk force "$DISK" >/dev/null 2>&1 || true
diskutil eraseDisk MS-DOS "$LABEL" "$SCHEME" "$DISK"

DEST="$(diskutil info -plist "${DISK}s1" | plutil -extract MountPoint raw - 2>/dev/null || true)"
[[ -z "$DEST" ]] && DEST="/Volumes/$LABEL"
[[ -d "$DEST" ]] || die "partição não montou em $DEST"
info "Pendrive montado em $DEST"

# -------------------------------------------------------------------- copia
info "Copiando arquivos (exceto a imagem grande) — pode levar vários minutos"
rsync -rlt --progress --exclude "sources/install.wim" --exclude "sources/install.esd" \
      --exclude ".Spotlight-V100" --exclude ".fseventsd" --exclude ".Trashes" \
      "$SRC/" "$DEST/"

# ----------------------------------------------------------- imagem grande
if [[ "$IMG_BYTES" -lt "$FAT32_LIMIT" ]]; then
  info "Imagem cabe no FAT32 — copiando $(basename "$IMG") direto"
  rsync -rlt --progress "$IMG" "$DEST/sources/"
else
  info "Fatiando $(basename "$IMG") em pedaços de ${SPLIT_MB} MiB (wimlib)"
  wimlib-imagex split "$IMG" "$DEST/sources/install.swm" "$SPLIT_MB"
fi

# ------------------------------------------------------------- verificação
info "Verificando o resultado"
FAIL=0
for f in "efi/boot/bootx64.efi" "bootmgr" "sources/boot.wim"; do
  if [[ -e "$DEST/$f" ]]; then
    printf '  ok   %s\n' "$f"
  else
    printf '  FALTA %s\n' "$f"; FAIL=1
  fi
done
if [[ "$IMG_BYTES" -lt "$FAT32_LIMIT" ]]; then
  [[ -e "$DEST/sources/$(basename "$IMG")" ]] && printf '  ok   sources/%s\n' "$(basename "$IMG")" || { printf '  FALTA sources/%s\n' "$(basename "$IMG")"; FAIL=1; }
else
  n=$(ls "$DEST"/sources/install*.swm 2>/dev/null | wc -l | tr -d ' ')
  [[ "$n" -ge 2 ]] && printf '  ok   %s fatias .swm em sources/\n' "$n" || { printf '  FALTA fatias .swm\n'; FAIL=1; }
fi
if find "$DEST" -type f -size +4194303k 2>/dev/null | grep -q .; then
  warn "existe arquivo >4 GiB no destino — o FAT32 não deveria ter aceitado"; FAIL=1
fi

sync
diskutil eject "$DISK" >/dev/null && info "Pendrive ejetado — pode remover"

[[ "$FAIL" -eq 0 ]] || die "verificação encontrou problemas (ver acima)"
info "Pronto. Boote pelo menu de boot do PC selecionando o pendrive em modo UEFI."
