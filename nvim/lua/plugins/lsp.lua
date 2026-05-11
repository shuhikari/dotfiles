-- Override do LSP — usa vtsls em vez de ts_ls (default do LazyVim com extras.lang.typescript)
-- vtsls é mais rápido em monorepos. LazyVim master tem registry novo do Mason
-- então vtsls está disponível.

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = true },

      servers = {
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
              preferences = {
                importModuleSpecifier = "non-relative",
              },
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
              },
            },
            vtsls = {
              experimental = {
                completion = { enableServerSideFuzzyMatch = true },
              },
            },
          },
        },
      },
    },
  },

  -- Garante que vtsls é instalado pelo Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vtsls",
        "biome",         -- formatter/linter
        "prisma-language-server",
        "json-lsp",
      })
    end,
  },
}
