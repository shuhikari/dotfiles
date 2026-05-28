# claude/profile-switch.zsh — alterna credenciais do Claude Code via CLAUDE_CONFIG_DIR.
#
# Cada perfil tem seu próprio diretório em $CLAUDE_PROFILES_DIR/<nome>/, isolando:
#   - .credentials.json (OAuth) ou ANTHROPIC_API_KEY (se setada no shell)
#   - histórico, projects/, logs, .claude.json
#
# Configs compartilhados (CLAUDE.md, settings.json, commands/, skills/) são
# symlinks gerenciados pelo install.sh, então não duplicam entre perfis.
#
# Perfis padrão criados em install.sh: auditore, hmax, sintetiza.
#
# Setup inicial (uma vez por perfil, em cada máquina):
#   claude-profile auditore && claude /login   # autentica naquele perfil
#   claude-profile hmax     && claude /login
#   claude-profile sintetiza && claude /login

export CLAUDE_PROFILES_DIR="${CLAUDE_PROFILES_DIR:-$HOME/.claude-profiles}"

# Perfil padrão na inicialização do shell. Define em zsh/local.zsh se quiser:
#   export CLAUDE_DEFAULT_PROFILE=auditore
: "${CLAUDE_DEFAULT_PROFILE:=}"

claude-profile() {
  emulate -L zsh
  local name="$1"
  if [[ -z $name ]]; then
    echo "uso: claude-profile <nome>" >&2
    echo "perfis disponíveis:" >&2
    claude-profile-list >&2
    return 2
  fi
  local target="$CLAUDE_PROFILES_DIR/$name"
  if [[ ! -d $target ]]; then
    echo "perfil '$name' não existe em $CLAUDE_PROFILES_DIR" >&2
    echo "rode './install.sh' no dotfiles pra criar os perfis padrão" >&2
    return 1
  fi
  export CLAUDE_CONFIG_DIR="$target"
  echo "claude profile → $name ($target)"
}

claude-profile-list() {
  emulate -L zsh
  if [[ ! -d $CLAUDE_PROFILES_DIR ]]; then
    echo "(nenhum perfil em $CLAUDE_PROFILES_DIR — rode ./install.sh)"
    return 0
  fi
  local p
  for p in "$CLAUDE_PROFILES_DIR"/*(N/); do
    echo "  $(basename "$p")"
  done
}

claude-profile-current() {
  emulate -L zsh
  if [[ -z ${CLAUDE_CONFIG_DIR:-} ]]; then
    echo "(default — \$CLAUDE_CONFIG_DIR não setado, usa ~/.claude)"
  else
    echo "$(basename "$CLAUDE_CONFIG_DIR") ($CLAUDE_CONFIG_DIR)"
  fi
}

# Atalhos: troca perfil + roda claude num shot. A chain expand do `claude`
# (aliás em aliases.zsh com --dangerously-skip-permissions) continua valendo.
alias cc-auditore='CLAUDE_CONFIG_DIR=$CLAUDE_PROFILES_DIR/auditore claude'
alias cc-hmax='CLAUDE_CONFIG_DIR=$CLAUDE_PROFILES_DIR/hmax claude'
alias cc-sintetiza='CLAUDE_CONFIG_DIR=$CLAUDE_PROFILES_DIR/sintetiza claude'

# Aplica perfil padrão se setado em local.zsh (silencioso se não houver).
if [[ -n $CLAUDE_DEFAULT_PROFILE ]]; then
  claude-profile "$CLAUDE_DEFAULT_PROFILE" >/dev/null 2>&1 || true
fi
