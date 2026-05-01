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

  -- Conform: silencia formatters que não usamos no nosso stack
  -- Biome cobre JS/TS/JSON; não precisamos de prettier, fish_indent, markdownlint-cli2.
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- Remove formatters padrão que não usamos
      opts.formatters_by_ft.fish = nil
      -- Markdown: usa só markdownlint se tiver, senão deixa sem formatter
      opts.formatters_by_ft.markdown = { "markdownlint-cli2", stop_after_first = true }
      return opts
    end,
  },
}
