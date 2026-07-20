return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    opts = {},
  },
  {
    "Kicamon/markdown-table-mode.nvim",
    config = function()
      require("markdown-table-mode").setup()
    end,
  },
  {
    "roodolv/markdown-toggle.nvim",
    config = function()
      require("markdown-toggle").setup({
        keymaps = {
          toggle = {
            ["<C-q>"] = "quote",
            ["<C-l>"] = "list",
            ["<Leader><C-l>"] = "list_cycle",
            ["<C-n>"] = "olist",
            ["<M-x>"] = "checkbox",
            ["<Leader><M-x>"] = "checkbox_cycle",
            ["<C-h>"] = "heading",
            ["<Leader><C-h>"] = "heading_toggle",
          },
        },
      })
    end,
  },
}
