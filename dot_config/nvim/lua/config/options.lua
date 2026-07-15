-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.exrc = true
vim.opt.shell = vim.fn.exepath("nu")

-- Give every floating window (LSP hover/signature help, blink.cmp's
-- completion/doc menus, noice's cmdline popup, :h, etc.) a default border,
-- so they stand out against the background instead of blending into it.
vim.opt.winborder = "single"
