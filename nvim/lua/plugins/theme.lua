-- Colorscheme do Omarchy.
-- No Omarchy este arquivo é um symlink para ~/.local/state/omarchy/current/theme/neovim.lua,
-- reapontado a cada troca de tema do sistema. Sem Hyprland aqui, então fica estático.
-- Fonte: basecamp/omarchy@v4.0.0 themes/tokyo-night/neovim.lua
return {
  { "folke/tokyonight.nvim", priority = 1000 },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}
