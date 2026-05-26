#!/usr/bin/env bash
# install-mcp-aws.sh — instala servidores MCP da AWS (awslabs/mcp) em escopo `user`.
#
# Opcional. Não rodado pelo install.sh principal — você roda quando quiser:
#   ./install-mcp-aws.sh
#
# Servidores instalados (escopo user, valem em todos os projetos):
#   - aws-knowledge       (HTTP remote, sem auth) — docs + blogs + What's New + Well-Architected
#   - aws-documentation   (stdio via uvx)         — só docs oficiais, isolado
#   - aws-pricing         (stdio via uvx)         — pricing pra dimensionar custo
#
# Idempotente. `claude mcp add` falha se já existe; o script ignora esse erro.
# Pra remover: claude mcp remove <name> --scope user

set -euo pipefail

if [[ -t 1 ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }

command -v claude >/dev/null || { error "Claude Code CLI não encontrado no PATH."; exit 1; }

# Garante uv/uvx (necessário pros servidores stdio).
ensure_uv() {
  if command -v uvx >/dev/null; then
    info "uvx já disponível: $(command -v uvx)"
    return 0
  fi

  warn "uvx não encontrado. Instalando via installer oficial da Astral (curl | sh)."
  warn "Source: https://astral.sh/uv/install.sh — instala em ~/.local/bin/ (escopo user)."
  read -r -p "Prosseguir? [y/N]: " reply
  case "$reply" in
    y|Y|yes|YES)
      curl -LsSf https://astral.sh/uv/install.sh | sh
      # uv installer adiciona ~/.local/bin ao PATH via shell rc; força aqui pra esta sessão.
      export PATH="$HOME/.local/bin:$PATH"
      command -v uvx >/dev/null || { error "uvx ainda não está no PATH após instalação. Reabre o shell e roda de novo."; exit 1; }
      info "uv instalado: $(uv --version)"
      ;;
    *)
      warn "Pulando uv. Só o AWS Knowledge (remote) será adicionado."
      return 1
      ;;
  esac
}

# Adiciona um servidor; ignora se já existe.
add_server() {
  local name="$1"; shift
  if claude mcp list 2>/dev/null | grep -q "^${name}:"; then
    info "Já configurado: $name (pulando)"
    return 0
  fi
  if claude mcp add --scope user "$@"; then
    info "Adicionado: $name"
  else
    error "Falha ao adicionar $name"
    return 1
  fi
}

# 1. AWS Knowledge — HTTP remote, sem dependência local
add_server "aws-knowledge" \
  --transport http aws-knowledge https://knowledge-mcp.global.api.aws

# 2/3. Documentation + Pricing — stdio via uvx
if ensure_uv; then
  add_server "aws-documentation" \
    -e FASTMCP_LOG_LEVEL=ERROR \
    -e AWS_DOCUMENTATION_PARTITION=aws \
    aws-documentation \
    -- uvx awslabs.aws-documentation-mcp-server@latest

  add_server "aws-pricing" \
    -e FASTMCP_LOG_LEVEL=ERROR \
    aws-pricing \
    -- uvx awslabs.aws-pricing-mcp-server@latest
fi

echo
info "Estado atual dos MCPs:"
claude mcp list 2>&1 | grep -E "^aws-" || warn "Nenhum AWS MCP listado."
