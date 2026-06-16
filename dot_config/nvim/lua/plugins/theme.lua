return {
  {
    "uZer/pywal16.nvim",
    config = function()
      local pywal16 = require("pywal16")
      pywal16.setup()
      vim.cmd.colorscheme("pywal16")

      -- Watch for pywal color regeneration and reload
      local watcher = (vim.uv or vim.loop).new_fs_event()
      watcher:start(
        vim.fn.expand("~/.cache/wal/colors.json"),
        {},
        vim.schedule_wrap(function()
          pywal16.setup()
          vim.cmd.colorscheme("pywal16")
        end)
      )
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local pywal16 = require("pywal16")
        pywal16.setup()
      end,
    },
  },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = { theme = "pywal16-nvim" },
    },
  },
}
