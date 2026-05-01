-- Opções carregadas ANTES do LazyVim setup
-- LazyVim define defaults sane; aqui só os overrides pessoais.
-- Veja todos os defaults em: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Desabilita providers que não usamos (silencia warnings do checkhealth)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
-- node_provider deixa habilitado (LazyVim usa pra alguns plugins)

-- UI
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"

-- Comportamento
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Splits abrem em direção mais natural (à direita / abaixo)
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Persistência
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

-- Performance
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500   -- which-key responde mais rápido (default LazyVim já é 300)

-- Clipboard: integra com sistema (macOS pbcopy/pbpaste, Linux xclip/wl-clipboard)
vim.opt.clipboard = "unnamedplus"
