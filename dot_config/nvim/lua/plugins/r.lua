return {
    {
    "R-nvim/R.nvim",
    config = function ()
            -- Create a table with the options to be passed to setup()
            local opts = {
                hook = {
                    on_filetype = function()
            vim.api.nvim_buf_set_keymap(0, "v", "<Space>", "<Plug>RDSendSelection", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<Space>", "<Plug>RDSendLine", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>rk", "<Cmd>lua require('r.run').action('levels')<CR>", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>t", "<Cmd>lua require('r.run').action('tail')<CR>", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>h", "<Cmd>lua require('r.run').action('head')<CR>", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>p", "<Cmd>lua require('r.run').action('print')<CR>", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>d", "<Cmd>lua require('r.run').action('dim')<CR>", {})
            vim.api.nvim_buf_set_keymap(0, "n", "<LocalLeader>s", "<Cmd>lua require('r.run').action('str')<CR>", {})
                    end
                },
                R_args = {"--quiet", "--no-save"},
                min_editor_width = 72,
                rconsole_width = 78,
                disable_cmds = {
                        "RClearConsole",
                        "RCustomStart",
                        "RSPlot",
                        "RSaveClose",
                    },
                }
                -- Check if the environment variable "R_AUTO_START" exists.
                -- If using fish shell, you could put in your config.fish:
                -- alias r "R_AUTO_START=true nvim"
                if vim.env.R_AUTO_START == "true" then
                    opts.auto_start = "on startup"
                    opts.objbr_auto_start = true
                end
                require("r").setup(opts)
            end,
        lazy = false
  },
  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function ()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "markdown", "markdown_inline", "r", "rnoweb", "yaml" },
        highlight = { enable = true },
      })
    end
  },
  "R-nvim/cmp-r",
  {
    "hrsh7th/nvim-cmp",
    config = function()
      require("cmp").setup({ sources = {{ name = "cmp_r" }}})
      require("cmp_r").setup({ })
    end,
  },
}
