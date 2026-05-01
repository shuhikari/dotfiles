-- Autocmds custom — LazyVim já tem vários úteis por padrão.
-- Aqui só os que adiciono especificamente.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Habilita inlay hints automaticamente quando LSP attacha
autocmd("LspAttach", {
  group = augroup("UserInlayHints", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- Highlight no yank (visualização rápida do que foi copiado)
-- LazyVim já tem isso, mantém comentado pra referência:
-- autocmd("TextYankPost", {
--   group = augroup("UserYankHighlight", { clear = true }),
--   callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
-- })

-- Auto-format on save em projetos com biome.json
autocmd("BufWritePre", {
  group = augroup("UserFormatOnSave", { clear = true }),
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.json", "*.md" },
  callback = function()
    -- Só formata se o projeto tiver biome.json (evita rodar em projetos legados)
    local biome_config = vim.fn.findfile("biome.json", ".;")
    if biome_config ~= "" then
      vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
    end
  end,
})
