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
    config = function(_, opts)
      require("lualine").setup(opts)

      -- trouble.nvim's lualine breadcrumb (the "current function" segment,
      -- e.g. "f config") patches its text color to match lualine's
      -- background, but caches that patched highlight group permanently and
      -- only invalidates it via a ColorScheme autocmd registered by trouble's
      -- OWN setup() -- which may never run if trouble is only used through
      -- this lualine integration. Reset that cache ourselves on every
      -- ColorScheme (including our async OSC-driven reload) so it doesn't
      -- render a stale, mismatched block against the current colors.
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("fix_trouble_lualine_highlight_cache", { clear = true }),
        callback = function()
          local ok, trouble_highlights = pcall(require, "trouble.config.highlights")
          if ok then
            trouble_highlights._fixed = {}
          end
          if package.loaded["lualine"] then
            require("lualine").refresh()
          end
        end,
      })
    end,
  },
  {
    -- noice.nvim renders LSP hover (K) and signature help itself, bypassing
    -- Neovim's native floating-window path -- so `vim.o.winborder` (set in
    -- config/options.lua) doesn't reach it. Its "hover" view (which
    -- signature help also falls back to) defaults to `border.style = "none"`;
    -- override to match everything else's border style.
    "folke/noice.nvim",
    opts = {
      views = {
        hover = {
          border = { style = "single" },
        },
      },
    },
  },
}
