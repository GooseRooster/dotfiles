-- Bootstrap lazy.nvim and the nvix plugin set.
-- No LazyVim import — this config imports only `plugins/` and owns every spec.

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

-- Load the Util global + editor options before lazy. options.lua sets mapleader,
-- which must be set before lazy.nvim registers any lazy key handlers.
require("util")
require("config.options")

require("lazy").setup({
  spec = {
    { import = "plugins" },
    -- lazy's import is not recursive, so language specs under plugins/lang/
    -- need their own import line.
    { import = "plugins.lang" },
  },
  defaults = {
    -- Custom specs load at startup by default; per-spec event/ft/cmd/keys opt
    -- into lazy-loading explicitly. This keeps load behavior under our control.
    lazy = false,
    version = false, -- always use the latest git commit
  },
  install = { colorscheme = { "habamax" } },
  checker = {
    enabled = true, -- periodically check for plugin updates
    notify = false,
  },
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

-- Keymaps, autocmds, and the util setups run on VeryLazy, once plugins (Snacks,
-- conform, lspconfig, …) are available for the maps and autoformat autocmd.
Util.on_very_lazy(function()
  require("config.keymaps")
  require("config.autocmds")
  Util.format.setup()
  Util.root.setup()
  -- Util.format.register(Util.lsp.formatter())  -- wired in Phase 3 (LSP)
end)
