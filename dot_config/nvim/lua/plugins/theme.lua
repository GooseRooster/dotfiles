local osc_palette = require("util.osc-palette")

return {
  {
    "tinted-theming/tinted-nvim",
    priority = 1000, -- load colorscheme early
    lazy = false, -- apply on startup
    opts = function(_, opts)
      opts.selector = {
        enabled = true,
        mode = "file",
        path = "~/.local/share/tinted-theming/tinty/current_scheme",
        watch = true,
      }

      -- Paint instantly from the last successfully OSC-queried terminal
      -- palette (if any) instead of waiting on the async query below.
      local cached = osc_palette.load_cached()
      if cached then
        opts.schemes = opts.schemes or {}
        opts.schemes["base16-osc-live"] = cached
      end

      return opts
    end,
    config = function(_, opts)
      require("tinted-nvim").setup(opts)

      -- Ask the host terminal for its live 16-color palette + fg/bg and
      -- synthesize a base16 scheme from it, so nvim follows whatever theme
      -- the terminal (Ghostty) currently has loaded -- including inside
      -- devcontainers, where no tinted-theming state is synced in. Silently
      -- no-ops if the terminal never answers; see lua/util/osc-palette.lua.
      vim.api.nvim_create_autocmd("UIEnter", {
        group = vim.api.nvim_create_augroup("osc_palette_refresh", { clear = true }),
        callback = function()
          osc_palette.refresh_async()
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function() -- deferred, not evaluated at spec-parse time
        local tinted = require("tinted-nvim")
        if osc_palette.load_cached() then
          tinted.load("base16-osc-live")
        else
          tinted.load(tinted.get_scheme())
        end
      end,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "tinted",
      },
    },
  },
}
