require'lspconfig'.r_language_server.setup{}
require'lspconfig'.bashls.setup{}

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.code_actions.shellcheck,
    null_ls.builtins.formatting.styler,
    null_ls.builtins.formatting.foramt_r,
  },
})

