-- Ensures that most elements are styled with the noctalia scheme
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "default" } },
  { "folke/tokyonight.nvim", enabled = false },
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = { theme = "base16" },
    },
  },
}
