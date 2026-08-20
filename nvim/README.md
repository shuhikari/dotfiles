# nvim — LazyVim com os overrides do Omarchy

Réplica da config Neovim do [Omarchy](https://omarchy.org) (a distro Arch do DHH) adaptada
para macOS. O Omarchy não usa editor próprio: é **Neovim + LazyVim** com poucos overrides.

Aplicado em 20260820-025552. Symlink: `~/.config/nvim` → `~/dotfiles/nvim`.

## O que veio do Omarchy

| Arquivo | Origem |
|---|---|
| `lua/plugins/theme.lua` | [`themes/tokyo-night/neovim.lua`](https://github.com/basecamp/omarchy/blob/v4.0.0/themes/tokyo-night/neovim.lua) (colorscheme `tokyonight-night`) |
| `lua/plugins/snacks-animated-scrolling-off.lua` | [`config/nvim/lua/plugins/`](https://github.com/basecamp/omarchy/blob/v2.1.2/config/nvim/lua/plugins/snacks-animated-scrolling-off.lua) |
| `plugin/after/transparency.lua` | [`config/nvim/plugin/after/`](https://github.com/basecamp/omarchy/blob/v2.1.2/config/nvim/plugin/after/transparency.lua) — cópia literal, 38 grupos com `bg = "none"` |
| `editor.neo-tree` em `lazyvim.json` | único extra que o Omarchy habilita ([v2.1.2](https://github.com/basecamp/omarchy/blob/v2.1.2/config/nvim/lazyvim.json)) |

Não replicado (depende de Hyprland): troca de tema sincronizada com o sistema e o
atalho `Super + Shift + N`. Ver [manual/16-neovim.md](https://github.com/basecamp/omarchy/blob/v4.0.0/manual/16-neovim.md).

## Extras — fonte única

Os extras vivem **só** em `lazyvim.json`. O `lua/config/lazy.lua` não deve conter
`{ import = "lazyvim.plugins.extras.*" }`: o core do LazyVim já lê o JSON via
`lazyvim/plugins/xtras.lua` e declarar nos dois lugares gera import duplicado.

Gerencie com `:LazyExtras` (`x` habilita/desabilita).

## Cheatsheet

Picker = **snacks**, explorer = **neo-tree** (a combinação do Omarchy).

| Tecla | Ação |
|---|---|
| `<Space><Space>` | Buscar arquivo na raiz do projeto |
| `<Space>sg` | Grep com preview |
| `<Space>e` | Abrir/fechar a árvore (neo-tree) |
| `Ctrl+w w` | Pular entre árvore e editor |
| `a` / `A` (na árvore) | Novo arquivo / novo diretório |
| `?` (na árvore) | Todos os comandos da árvore |
| `Shift+H` / `Shift+L` | Buffer anterior / próximo |
| `<Space>bd` / `<Space>bo` | Fechar buffer / fechar os outros |
| `<Space>gg` | LazyGit flutuante |
| `<Space>uw` | Alternar soft wrap |

### Agente no editor (`ai.claudecode`)

Não faz parte do Omarchy — lá os agentes rodam no terminal. Aqui é o extra oficial
do LazyVim ([`coder/claudecode.nvim`](https://github.com/coder/claudecode.nvim)).

| Tecla | Ação |
|---|---|
| `<Space>ac` | Abrir/fechar o painel do Claude |
| `<Space>af` | Focar o painel |
| `<Space>ar` / `<Space>aC` | Retomar sessão (`--resume`) / continuar a última |
| `<Space>ab` | Mandar o buffer atual como contexto |
| `<Space>as` (visual) | Mandar a seleção |
| `<Space>as` (na árvore) | Mandar o arquivo sob o cursor |
| `<Space>aa` / `<Space>ad` | Aceitar / recusar o diff proposto |

## Rollback

A config é versionada. Para voltar ao estado anterior aos overrides:

```bash
git -C ~/dotfiles checkout main       # volta a config inteira
nvim --headless "+Lazy! restore" +qa  # volta os plugins ao lazy-lock do main
```

Para reverter só um pedaço (ex.: trazer o telescope de volta), edite `lazyvim.json`
ou use `:LazyExtras`. Backup físico fora do git feito em `nvim.bak-20260820-025552`.
