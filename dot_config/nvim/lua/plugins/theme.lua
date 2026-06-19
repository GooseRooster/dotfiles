return {
  {
    "tinted-theming/tinted-nvim",
    priority = 1000, -- load colorscheme early
    lazy = false, -- apply on startup
    opts = {
      selector = {
        enabled = true,
        mode = "file",
        path = "~/.local/share/tinted-theming/tinty/current_scheme",
        watch = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function() -- deferred, not evaluated at spec-parse time
        require("tinted-nvim").load(require("tinted-nvim").get_scheme())
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
