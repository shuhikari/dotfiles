# ~/dotfiles/zsh/aliases.zsh
# Aliases organizados por categoria. Funções vão em functions.zsh.

# =====================================================================
# Editores
# =====================================================================

alias vim='nvim'
alias lvim='nvim'  # compatibilidade com hábito antigo
alias zshconfig='nvim ~/dotfiles/zsh/zshrc'
alias gitconfig='nvim ~/dotfiles/git/gitconfig'
alias dotr='cd ~/dotfiles'

# =====================================================================
# Clipboard (cross-OS)
# =====================================================================
# Usa: echo "texto" | clip
#      pwd | clip

if is_macos; then
  alias clip='pbcopy'
  alias paste='pbpaste'
elif is_wsl; then
  # clip.exe vem com Windows, acessível direto do WSL
  alias clip='clip.exe'
  alias paste='powershell.exe -command "Get-Clipboard"'
elif command -v xclip >/dev/null 2>&1; then
  alias clip='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'
elif command -v wl-copy >/dev/null 2>&1; then
  alias clip='wl-copy'
  alias paste='wl-paste'
fi

# =====================================================================
# WSL-specific helpers
# =====================================================================

if is_wsl; then
  # Abre arquivo/URL no Windows host (Explorer, browser default, etc)
  alias open='wslview'
  # Abre VSCode do Windows no diretório atual
  alias code='code.exe'
fi

# =====================================================================
# ls / eza
# =====================================================================
# eza: replacement moderno de ls com cores, git status inline, ícones.
# Se eza não estiver instalado, fallback pra ls com flags equivalentes.

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first --icons=auto'
  alias la='eza -la --git --group-directories-first --icons=auto'
  # lr → ver functions.zsh (aceita -g pra agrupar pastas, -n N pra limitar, -t pra inverter)
  alias lt='eza --tree --level=2 --git-ignore --icons=auto'
  alias lt3='eza --tree --level=3 --git-ignore --icons=auto'
else
  alias ll='ls -lh'
  alias la='ls -lha'
  # lr → ver functions.zsh
fi

# =====================================================================
# tmux
# =====================================================================

alias tl='tmux list-sessions'
alias tn='tmux new -s'
alias ta='tmux attach -t'
alias tk='tmux kill-session -t'
alias tks='tmux kill-server'
# tns, tcc, ts → ver functions.zsh

# =====================================================================
# git / GitHub CLI
# =====================================================================

alias gst='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias gca='git commit --amend --no-edit'
alias gwip='git add -A && git commit -m "wip" --no-verify'
alias glog='git log --oneline --graph --decorate -20'

# Alias customizado existente (mantido)
alias gitdp-rush='git psod && git co main && git merge dev && git psom && git co -'

# pr, prs, cu → ver functions.zsh

# =====================================================================
# Docker
# =====================================================================

alias dcp='docker-compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail 100'
alias dcr='docker compose restart'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}"'
alias dlogs='docker logs -f --tail 100'
alias dprune='docker system prune -af --volumes'

# =====================================================================
# Node / pnpm
# =====================================================================

alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrs='npm run start:dev'
alias nrt='npm run test'
alias nrtw='npm run test:watch'
alias nrl='npm run lint'
alias nrb='npm run build'
alias pi='pnpm install'

# =====================================================================
# Python (legacy alias)
# =====================================================================

alias python=python3
alias pip=pip3

# =====================================================================
# Versionamento / deploy aliases (mantidos do original)
# =====================================================================

alias v-patch='git plos && pnpm version patch && git psost'
alias v-patch-byd-back='cd ~/ws/byd/byd-accredited-backend && v-patch'
alias v-patch-byd-dash='cd ~/ws/byd/byd-accredited-dashboard && v-patch'
alias v-minor='git plos && pnpm version minor && git psost'
alias v-major='git plos && pnpm version major && git psost'

# =====================================================================
# Navegação rápida
# =====================================================================
# Aliases pessoais de Google Drive (contêm email da conta) ficam em
# zsh/local.zsh (gitignored). Veja zsh/local.zsh.example para o template.

alias obsidian-setup='cd "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"'

# =====================================================================
# AeroSpace
# =====================================================================

alias asreload='aerospace reload-config'
alias aslist='aerospace list-workspaces --all'

# =====================================================================
# Misc
# =====================================================================

alias rl='source ~/.zshrc'
alias jq.='jq .'
