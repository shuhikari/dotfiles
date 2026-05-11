# Cheatsheet

Referência rápida. Atualizar conforme novos atalhos forem adicionados.

---

## LunarVim

Leader = `<Space>`

### Navegação LSP

| Atalho | Ação |
|---|---|
| `gd` | Definições (Telescope, com preview) |
| `gr` | References |
| `gi` | Implementations |
| `gt` | Type definitions |
| `K` | Hover (assinatura + JSDoc) |
| `<C-k>` | Signature help (normal e insert mode) |
| `<leader>ls` | Símbolos do arquivo atual |
| `<leader>lS` | Símbolos do workspace |
| `<leader>lw` | Símbolos workspace dinâmico |
| `<leader>uh` | Toggle inlay hints |

### Diagnostics (Trouble.nvim)

| Atalho | Ação |
|---|---|
| `<leader>xx` | Todos os diagnostics |
| `<leader>xd` | Diagnostics do buffer atual |
| `<leader>xs` | Símbolos do arquivo |
| `<leader>xl` | LSP info painel direito |

### Outline e IA

| Atalho | Ação |
|---|---|
| `<leader>o` | Toggle Aerial (outline lateral) |
| `<leader>cc` | Abre Claude Code num split |

### NvimTree

| Atalho | Ação |
|---|---|
| `<CR>` ou `o` | Abrir / entrar na pasta |
| **`-`** | **Subir um nível** |
| `H` | Toggle hidden files |
| `?` | TODOS os atalhos |
| `a` | Criar arquivo (`/` no fim = pasta) |
| `r` | Rename |
| `d` | Delete |
| `<C-]>` | CWD pro nó atual |

### Telescope (defaults LunarVim)

| Atalho | Ação |
|---|---|
| `<leader>f` | Find files |
| `<leader>F` | Live grep |
| `<leader>sb` | Buffers |
| `<leader>sk` | Keymaps |

---

## tmux

Prefix = `C-a`

### Sessões

| Atalho | Ação |
|---|---|
| `prefix d` | Detach |
| `prefix s` | Switch entre sessões |
| `prefix $` | Renomear sessão |

### Janelas

| Atalho | Ação |
|---|---|
| `prefix c` | Nova janela (mantém CWD) |
| `prefix 1..9` | Ir pra janela N |
| `prefix ,` | Renomear |
| `prefix &` | Fechar |
| `prefix n / p` | Próxima / anterior |

### Painéis

| Atalho | Ação |
|---|---|
| `prefix \|` | Split vertical |
| `prefix -` | Split horizontal |
| `prefix h/j/k/l` | Navegar (vim-style) |
| `prefix H/J/K/L` | Resize 5 unidades |
| `prefix z` | Toggle zoom |
| `prefix x` | Fechar painel |

### Cópia

| Atalho | Ação |
|---|---|
| `prefix [` | Modo cópia |
| `v` | Begin selection |
| `y` | Copia pra clipboard |
| `Esc` | Sai |

### Misc

| Atalho | Ação |
|---|---|
| `prefix r` | Reload config |
| `prefix ?` | Lista todos atalhos |

---

## Shell aliases e funções

### Listagem (eza com fallback ls)

| Comando | Ação |
|---|---|
| `ls` | Lista com cores e ícones |
| `ll` | Long format + git status |
| `la` | Long + hidden files |
| **`lr`** | **Modificados, mais recentes no fim** |
| `lt` | Tree view, level 2 |
| `lt3` | Tree view, level 3 |
| `lsn [N]` | Top N mais recentes (default 10) |

### tmux

| Alias | Ação |
|---|---|
| `tn <n>` | Cria sessão |
| `ta <n>` | Anexa em sessão |
| `tl` | Lista sessões |
| `tk <n>` | Mata sessão |
| `tns` | Sessão com nome do CWD |
| `tcc` | Sessão com Claude Code split |
| `ts` | fzf picker pra trocar sessão |

### git / GitHub

| Alias | Ação |
|---|---|
| `gst` | git status -sb |
| `gd` / `gds` | diff / diff staged |
| `gca` | commit --amend --no-edit |
| `gwip` | wip commit (skip hooks) |
| `glog` | log decorado, 20 últimas |
| `pr` | gh pr view (cria draft se não existe) |
| `prs` | gh pr list --web |
| `cu` | Abre task ClickUp da branch (CU-xxx) |

### Docker

| Alias | Ação |
|---|---|
| `dcu` | docker compose up -d |
| `dcd` | docker compose down |
| `dcl` | docker compose logs -f |
| `dcr` | docker compose restart |
| `dps` | ps formatado |
| `dprune` | system prune -af --volumes |

### Node / pnpm

| Alias | Ação |
|---|---|
| `ni` / `pi` | npm/pnpm install |
| `nrd` / `nrs` | run dev / start:dev |
| `nrt` / `nrtw` | test / test:watch |
| `nrl` / `nrb` | lint / build |

### Versionamento (mantidos do original)

| Alias | Ação |
|---|---|
| `v-patch` / `v-minor` / `v-major` | pnpm version + push tags |
| `gitdp-rush` | psod + co main + merge dev + psom |

### Utilities

| Alias | Ação |
|---|---|
| `rl` | source ~/.zshrc |
| `mkcd` | mkdir + cd |
| `dotr` | cd ~/dotfiles |
| `zshconfig` / `gitconfig` | edita config no nvim |

---

## AeroSpace

Modifier = `cmd-ctrl`

### Foco e movimento

| Atalho | Ação |
|---|---|
| `cmd-ctrl-h/j/k/l` | Foco esquerda/baixo/cima/direita |
| `cmd-ctrl-shift-h/j/k/l` | Move janela |

### Workspaces

| Atalho | Ação |
|---|---|
| `cmd-ctrl-1..5` | Workspace 1-5 |
| `cmd-ctrl-m` | Messages |
| **`cmd-ctrl-p`** | **Presentation (sempre no projetor)** |
| `cmd-ctrl-shift-N/letra` | Move janela pra workspace |
| `cmd-ctrl-tab` | Workspace anterior |
| `cmd-ctrl-shift-tab` | Move workspace entre monitores |

### Misc

| Atalho | Ação |
|---|---|
| `cmd-ctrl-f` | Fullscreen (do AeroSpace) |
| `cmd-ctrl-shift-;` | Reload config |

---

## Claude Code

### Slash commands custom

| Comando | Ação |
|---|---|
| `/review` | Review estruturado do diff vs main |
| `/spec` | Ajuda a escrever feature spec |

### Modelos por uso

| Modelo | Use pra |
|---|---|
| Haiku 4.5 | Review rápido, classificação, tarefas simples |
| Sonnet 4.6 | Review arquitetural, refactor médio |
| Opus 4.7 | Decisões críticas, design complexo |

Trocar via `claude --model haiku` ou no CLAUDE.md do projeto.

---

## Code quality (em projeto)

```bash
pnpm lint          # check
pnpm lint:fix      # auto-fix
pnpm format        # format
pnpm type-check    # tsc --noEmit
pnpm dead-code     # knip
pnpm quality       # lint + type-check + dead-code
```

Antes de PR:
```bash
claude
> /review
```
