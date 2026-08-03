-- UI backbone: snacks.nvim + icons. Colorscheme lives in theme.lua; statusline
-- in lualine.lua; cmdline/messages in noice.lua; animations in animate.lua.

return {
  -- icons (mock nvim-web-devicons so everything routes through mini.icons)
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- ui components (noice/dap-ui/etc. dependency)
  { "MunifTanjim/nui.nvim", lazy = true },

  -- snacks.nvim — picker, dashboard, notifier, indent, scroll, words, bigfile,
  -- quickfile, statuscolumn, terminal, input. Bare snacks ships most modules
  -- DISABLED; we enable exactly the ones we rely on (the Snacks.toggle.* and
  -- Snacks.words.* keymaps ported in Phase 2 depend on these being on).
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true }, -- auto-disable heavy features on huge files (container-friendly)
      quickfile = { enabled = true }, -- paint the file before plugins finish loading
      indent = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true }, -- replaces vim-illuminate (reference highlight + ]]/[[ jumps)
      notifier = { enabled = true },
      statuscolumn = { enabled = true },
      input = { enabled = true },
      picker = { enabled = true },
      terminal = {},
      explorer = { enabled = false }, -- yazi is the sole file explorer (Phase 5)
      dashboard = {
        enabled = true,
        preset = {
          header = [[

              ██████   █████ █████   █████ █████ █████ █████
              ░░██████ ░░███ ░░███   ░░███ ░░███ ░░███ ░░███ 
              ░███░███ ░███  ░███    ░███  ░███  ░░███ ███  
              ░███░░███░███  ░███    ░███  ░███   ░░█████   
              ░███ ░░██████  ░░███   ███   ░███    ███░███  
              ░███  ░░█████   ░░░█████░    ░███   ███ ░░███ 
              █████  ░░█████    ░░███      █████ █████ █████
              ░░░░░    ░░░░░      ░░░      ░░░░░ ░░░░░ ░░░░░ 
					]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}
