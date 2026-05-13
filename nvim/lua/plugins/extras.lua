-- Plugins extras pra completar paridade com setup anterior do LunarVim

return {
  -- Signature help inline ao digitar (mostra parâmetros enquanto chama função)
  {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    opts = {
      bind = true,
      handler_opts = { border = "rounded" },
      hint_enable = false,         -- não mostra hint inline (uso só no popup)
      floating_window = true,
      always_trigger = false,
      hi_parameter = "Search",
      max_height = 12,
      max_width = 80,
      transparency = nil,
      timer_interval = 200,
      toggle_key = "<C-k>",        -- toggle signature popup
    },
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end,
  },

  -- Aerial outline (já habilitado via extras.editor.aerial, aqui só configura)
  {
    "stevearc/aerial.nvim",
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        max_width = { 40, 0.2 },
        min_width = 20,
        default_direction = "right",
      },
      attach_mode = "global",
      filter_kind = false,
      show_guides = true,
    },
  },

  -- Trouble.nvim (já vem com LazyVim, aqui só ajusta)
  {
    "folke/trouble.nvim",
    opts = {
      auto_close = true,
      focus = true,
    },
  },

  -- refactoring.nvim passou a requerer lewis6991/async.nvim (commit 29bada4);
  -- o extras do LazyVim ainda não declara essa dep, então adicionamos aqui.
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "lewis6991/async.nvim" },
  },
}
