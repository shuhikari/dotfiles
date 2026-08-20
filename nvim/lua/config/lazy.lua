-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim core. Importa lazyvim/plugins/, que inclui xtras.lua — este lê a lista
    -- de extras do lazyvim.json e faz os imports. Fonte única: gerencie com :LazyExtras,
    -- não com { import = "lazyvim.plugins.extras.*" } aqui.
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Customizações próprias
    { import = "plugins" },
  },
  defaults = {
    lazy = false,    -- LazyVim já lida com lazy-loading inteligente
    version = false, -- master/HEAD (LazyVim em master é estável)
  },
  install = { colorscheme = { "tokyonight-night", "habamax" } },
  checker = { enabled = true, notify = false },  -- check de updates em silêncio
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
