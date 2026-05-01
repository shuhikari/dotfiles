-- Keymaps custom — carregados após LazyVim defaults
-- LazyVim já tem MUITO atalho útil (https://www.lazyvim.org/keymaps).
-- Aqui só as customizações que eu uso especificamente.

local map = vim.keymap.set

-- =====================================================================
-- Navegação entre splits sem precisar do <C-w>
-- =====================================================================
-- LazyVim já mapeia <C-h/j/k/l> por padrão pra isso, mas explicito
-- caso plugin de terminal sobrescreva.

map("n", "<C-h>", "<C-w>h", { desc = "Window: left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window: down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window: up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window: right" })

-- =====================================================================
-- Neo-tree: encontrar arquivo atual na árvore
-- =====================================================================
-- <leader>e (default) = toggle neo-tree
-- <leader>E (custom) = abre tree e foca no arquivo atual

map("n", "<leader>E", "<cmd>Neotree reveal<cr>", { desc = "Reveal file in tree" })

-- =====================================================================
-- Inlay hints toggle (LazyVim já tem <leader>uh por padrão)
-- =====================================================================
-- Mantém compatibilidade com hábito do LunarVim

map("n", "<leader>uh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  vim.notify("Inlay hints: " .. (enabled and "off" or "on"))
end, { desc = "Toggle inlay hints" })

-- =====================================================================
-- Trouble — atalhos consistentes com hábito do LunarVim
-- =====================================================================
-- LazyVim usa <leader>x por default; mantém consistente com lvim.

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP definitions/refs" })

-- =====================================================================
-- Aerial outline (precisa do plugin extras.editor.aerial habilitado)
-- =====================================================================

map("n", "<leader>o", "<cmd>AerialToggle!<cr>", { desc = "Toggle Aerial outline" })

-- =====================================================================
-- Claude Code num split lateral
-- =====================================================================

map("n", "<leader>cc", function()
  vim.cmd("vsplit | terminal claude")
  vim.cmd("startinsert")
end, { desc = "Open Claude Code in split" })

-- =====================================================================
-- Symbols / workspace (consistência com LunarVim)
-- =====================================================================

map("n", "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document symbols" })
map("n", "<leader>lS", "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "Workspace symbols" })
map("n", "<leader>lw", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", { desc = "Workspace symbols (dynamic)" })

-- =====================================================================
-- Salvar e sair rápido (vícios de produtividade)
-- =====================================================================

map("n", "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
map("i", "<C-s>", "<Esc><cmd>w<cr>a", { desc = "Save file (insert)" })

-- =====================================================================
-- Live grep (LazyVim usa <leader>/ ou <leader>sg; mantenho <leader>F também)
-- =====================================================================

map("n", "<leader>F", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
