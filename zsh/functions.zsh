# ~/dotfiles/zsh/functions.zsh
# Funções zsh. Mais flexíveis que aliases (aceitam args, lógica condicional).

# =====================================================================
# tmux
# =====================================================================

# tns: cria/anexa sessão com nome do diretório atual
tns() {
  local name=$(basename "$PWD" | tr ' .' '_-')
  tmux new -A -s "$name"
}

# tcc: cria sessão com Claude Code num split vertical
tcc() {
  local name="cc-$(basename "$PWD" | tr ' .' '_-')"
  if tmux has-session -t "$name" 2>/dev/null; then
    tmux attach -t "$name"
  else
    tmux new-session -d -s "$name" -c "$PWD"
    tmux split-window -h -t "$name" -c "$PWD" "claude"
    tmux select-pane -t "$name":0.0
    tmux attach -t "$name"
  fi
}

# ts: lista sessões com fzf picker
ts() {
  if ! command -v fzf >/dev/null; then
    tmux list-sessions
    return
  fi
  local session
  session=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | fzf --height 40%)
  [[ -n $session ]] && tmux attach -t "$session"
}

# =====================================================================
# Listagem
# =====================================================================

# lr: lista por data de modificação (padrão: mais recentes no fim, junto do prompt)
# Uso: lr [-g] [-t] [-n N] [path...]
#   -g    agrupa pastas separadamente (padrão: misturado)
#   -t    inverte: mais recentes no topo (com -n N, lista os N mais recentes)
#   -n N  limita aos N primeiros da listagem (combina com -t pra top N recentes)
lr() {
  emulate -L zsh
  local group=0 limit=0 top=0
  while [[ $1 == -* ]]; do
    case "$1" in
      -g) group=1; shift ;;
      -t) top=1; shift ;;
      -n) limit=$2; shift 2 ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  if command -v eza >/dev/null 2>&1; then
    local -a opts
    opts=(-l --git --icons=auto --sort=modified)
    (( group )) && opts+=(--group-directories-first)
    (( top )) && opts+=(--reverse)  # eza --sort=modified ASC = antigos primeiro / recentes no fim
    if (( limit > 0 )); then
      eza "${opts[@]}" "$@" | head -n "$limit"
    else
      eza "${opts[@]}" "$@"
    fi
  else
    local flags='-ltrh'
    (( top )) && flags='-lth'
    if (( limit > 0 )); then
      ls $flags "$@" | head -n $((limit + 1))
    else
      ls $flags "$@"
    fi
  fi
}

# lsn: alias retrocompatível (top N mais recentes)
lsn() { lr -n "${1:-10}" "${@:2}"; }

# =====================================================================
# GitHub
# =====================================================================

# pr: abre PR atual no browser, cria draft se não existir
pr() {
  gh pr view --web 2>/dev/null && return
  gh pr create --draft --fill --web
}

alias prs='gh pr list --web'
alias prc='gh pr create --draft --fill --web'

# cu: abre task ClickUp da branch atual (padrão CU-xxx no nome)
cu() {
  local branch task_id
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    echo "Não é um repositório git"
    return 1
  }
  task_id=$(echo "$branch" | grep -oE '(CU|cu)-[a-z0-9]+' | head -1 | sed 's/^cu-/CU-/')
  if [[ -z $task_id ]]; then
    echo "Branch '$branch' não tem padrão CU-xxx"
    return 1
  fi
  open "https://app.clickup.com/t/${task_id#CU-}"
}

# =====================================================================
# Utilities
# =====================================================================

# mkcd: cria pasta e entra nela
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# extract: descompacta qualquer formato comum
# (oh-my-zsh já tem o plugin "extract", mas mantém aqui pra portabilidade)
# Uso: extract arquivo.tar.gz

# =====================================================================
# ssh-agent persistente entre shells
# =====================================================================
#
# Reusa o mesmo agent em todos os shells (passphrase digitada 1x por boot).
# Sem isso, cada novo terminal precisa de `eval "$(ssh-agent -s)"` + ssh-add
# pra que `git push` por SSH funcione.

_ssh_agent_env="$HOME/.ssh/agent-env"

if [[ -f $_ssh_agent_env ]] && source "$_ssh_agent_env" >/dev/null 2>&1 \
   && kill -0 "${SSH_AGENT_PID:-0}" 2>/dev/null; then
  :  # agent já rodando, reutilizado
else
  ssh-agent -s > "$_ssh_agent_env" 2>/dev/null \
    && chmod 600 "$_ssh_agent_env" \
    && source "$_ssh_agent_env" >/dev/null
fi
unset _ssh_agent_env

# Adiciona chave padrão se existir e ainda não estiver no agent.
if [[ -f $HOME/.ssh/id_ed25519 ]] && command -v ssh-add >/dev/null; then
  _key_fp=$(ssh-keygen -lf "$HOME/.ssh/id_ed25519" 2>/dev/null | awk '{print $2}')
  if [[ -n $_key_fp ]] && ! ssh-add -l 2>/dev/null | grep -q "$_key_fp"; then
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
  fi
  unset _key_fp
fi
