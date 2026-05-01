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

# lsn: top N arquivos mais recentes (default 10)
# Uso: lsn          → 10 mais recentes da pasta atual
#      lsn 5        → 5 mais recentes
#      lsn 20 ~/Downloads
lsn() {
  local n=${1:-10}
  local path=${2:-.}
  if command -v eza >/dev/null 2>&1; then
    eza -l --sort=modified --reverse --git "$path" | head -$n
  else
    ls -lth "$path" | head -$((n + 1))
  fi
}

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
