-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.maplocalleader = "\\"
vim.g.mapleader = "\\"
vim.cmd("set foldmethod=syntax")
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.opt.smartcase = true
vim.opt.autoindent = true
vim.opt.encoding = "utf-8"
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.mousemoveevent = true
