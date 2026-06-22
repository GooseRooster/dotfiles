-- lua/plugins/file-explorer.lua
return {
  -- Disable snacks explorer keymaps so mini.files can reclaim them
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
    },
    keys = {
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
  },

  -- ---------------------------------------------------------------------------
  -- mini.files  –  primary explorer (in-process, instant open, no subprocess)
  --
  -- Keymaps:
  --   <leader>fe / <leader>e   →  open at LSP/git root
  --   <leader>fE / <leader>E   →  open at cwd
  --   <leader>fm               →  open at current file's directory
  -- ---------------------------------------------------------------------------
  {
    "nvim-mini/mini.files",
    version = "*",
    event = "VeryLazy",
    init = function()
      -- Suppress netrw so mini.files handles directory arguments (nvim .)
      -- and netrw directory opens instead. Matches the yazi open_for_directories
      -- behaviour from before.
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesWindowUpdate",
        callback = function(ev)
          local widths = { 60, 20, 20, 10, 5 } -- center layout https://github.com/nvim-mini/mini.nvim/discussions/2173
          local state = require("mini.files").get_explorer_state()
          if not state or #state.branch == 0 then
            return
          end
          local ok, r = pcall(require("mini.files").get_explorer_state)
          if ok then
            state = r
          end
          if not state then
            vim.wait(50, function()
              local ok2, r2 = pcall(require("mini.files").get_explorer_state)
              if ok2 then
                state = r2
                return true
              end
              return false
            end, 10, false)
          end
          local path_this = vim.api.nvim_buf_get_name(ev.data.buf_id):match("^minifiles://%d+/(.*)$")
          local depth_this = 0
          for i, path in ipairs(state.branch) do
            if path == path_this then
              depth_this = i
              break
            end
          end
          if depth_this == 0 then
            return
          end
          local depth_offset = depth_this - state.depth_focus
          local i = math.abs(depth_offset) + 1
          local win_config = vim.api.nvim_win_get_config(ev.data.win_id)
          win_config.width = i <= #widths and widths[i] or widths[#widths]
          win_config.zindex = 99
          win_config.col = math.floor(0.5 * (vim.o.columns - widths[1]))
          local sign = depth_offset == 0 and 0 or (depth_offset > 0 and 1 or -1)
          for j = 1, math.abs(depth_offset) do
            local prev_win_width = (sign == -1 and widths[j + 1]) or widths[j] or widths[#widths]
            local new_col = win_config.col + sign * (prev_win_width + 2)
            if new_col < 0 or new_col + win_config.width > vim.o.columns then
              win_config.zindex = win_config.zindex - 1
              break
            end
            win_config.col = new_col
          end
          win_config.height = depth_offset == 0 and 44 or 40
          win_config.row = math.floor(0.5 * (vim.o.lines - win_config.height))
          win_config.footer = { { tostring(depth_offset), "Normal" } }
          vim.api.nvim_win_set_config(ev.data.win_id, win_config)
        end,
      })
    end,
    opts = {
      windows = {
        preview = false, -- keeps the popup compact; toggle with <tab> if configured
        width_focus = 30,
        width_nofocus = 15,
        width_preview = 40,
      },
      options = {
        -- Let mini.files handle directory buffers (netrw replacement)
        use_as_default_explorer = true,
      },
    },
    keys = {
      -- <leader>fe / <leader>e  →  root dir  (primary muscle-memory binding)
      {
        "<leader>fe",
        function()
          require("mini.files").open(LazyVim.root(), true)
        end,
        desc = "Explorer mini.files (root dir)",
      },
      {
        "<leader>e",
        "<leader>fe",
        desc = "Explorer mini.files (root dir)",
        remap = true,
      },
      -- <leader>fE / <leader>E  →  cwd
      {
        "<leader>fE",
        function()
          require("mini.files").open(vim.uv.cwd(), true)
        end,
        desc = "Explorer mini.files (cwd)",
      },
      {
        "<leader>E",
        "<leader>fE",
        desc = "Explorer mini.files (cwd)",
        remap = true,
      },
      -- <leader>fm  →  current file's directory  (handy for local context)
      {
        "<leader>fm",
        function()
          local buf_path = vim.api.nvim_buf_get_name(0)
          local dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.uv.cwd()
          require("mini.files").open(dir, true)
        end,
        desc = "Explorer mini.files (current file dir)",
      },
    },
  },

  -- ---------------------------------------------------------------------------
  -- yazi.nvim  –  secondary explorer (bulk ops, preview, multi-select, images)
  --
  -- Keymaps:
  --   <leader>fy               →  open at LSP/git root
  --   <leader>fY               →  open at cwd
  --   <leader>ft               →  toggle / resume last session
  -- ---------------------------------------------------------------------------
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
      -- snacks.nvim is already in LazyVim; listed here for bufdelete integration
      { "folke/snacks.nvim" },
    },
    ---@type YaziConfig
    opts = {
      -- mini.files now owns netrw/directory interception; yazi should not
      -- compete for those events
      open_for_directories = false,

      -- Open visible splits as yazi tabs for context on where you are
      open_multiple_tabs = true,

      -- Change nvim cwd when closing yazi without selecting a file
      change_neovim_cwd_on_close = false,

      -- Floating window appearance
      yazi_floating_window_border = "rounded",
      yazi_floating_window_winblend = 0,

      -- Highlight the hovered buffer in nvim while yazi is open
      highlight_groups = {
        hovered_buffer = nil,
        hovered_buffer_in_same_directory = nil,
      },

      -- Keymaps active while yazi is open (intercept input before yazi sees it)
      -- Only map keys yazi itself never needs
      keymaps = {
        show_help = "<f1>",
        open_file_in_vertical_split = "<c-v>",
        open_file_in_horizontal_split = "<c-x>",
        open_file_in_tab = "<c-t>",
        grep_in_directory = "<c-s>", -- opens snacks picker grep
        replace_in_directory = "<c-g>", -- opens grug-far if installed
        cycle_open_buffers = "<tab>",
        copy_relative_path_to_selected_files = "<c-y>",
        send_to_quickfix_list = "<c-q>",
        change_working_directory = "<c-\\>",
        open_and_pick_window = "<c-o>",
      },

      future_features = {
        use_cwd_file = true,
      },
    },
    keys = {
      -- <leader>fy  →  open at LSP/git root
      {
        "<leader>fy",
        function()
          require("yazi").yazi(nil, LazyVim.root())
        end,
        mode = { "n", "v" },
        desc = "Explorer Yazi (root dir)",
      },
      -- <leader>fY  →  open at cwd
      {
        "<leader>fY",
        "<cmd>Yazi cwd<cr>",
        mode = { "n", "v" },
        desc = "Explorer Yazi (cwd)",
      },
      -- <leader>ft  →  toggle / resume last yazi session
      {
        "<leader>ft",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume last Yazi session",
      },
    },
  },
}
