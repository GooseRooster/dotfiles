return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    opts = function(_, opts)
      local navic = require("nvim-navic")
      local has_devicons, devicons = pcall(require, "nvim-web-devicons")
      local static = {}

      -- ~  --------------------------------------------------------------
      -- ~  Colors — pulled from standard highlight groups at render time
      -- instead of a specific colorscheme's palette module. These groups
      -- (Statement, String, Type, Constant, Exception) exist in nearly
      -- every colorscheme's syntax highlighting, so this survives a
      -- colorscheme swap without editing this file. Not a guarantee of a
      -- good-looking result on any arbitrary scheme — just a much better
      -- bet than hardcoding hex.

      local function hl_fg(group, fallback)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        if ok and hl and hl.fg then
          return string.format("#%06x", hl.fg)
        end
        return fallback
      end

      local icons = {
        error = " ",
        warn = " ",
        info = " ",
        hint = " ",
        added = " ",
        modified = "~ ",
        removed = " ",
        lock = "",
        touched = "●",
        git_branch = "",
      }

      -- Control-char mode keys (block-visual / block-select) generated via
      -- string.char() rather than embedded as literal invisible bytes —
      -- same reasoning as the separator fix: don't hand-transcribe
      -- anything that isn't meant to be visible text.
      local CTRL_V = string.char(22)
      local CTRL_S = string.char(19)

      local mode_labels = {
        n = "N",
        no = "N",
        nov = "N",
        noV = "N",
        [CTRL_V] = "V-B",
        niI = "N",
        niR = "N",
        niV = "N",
        nt = "N",
        i = "I",
        ic = "I",
        ix = "I",
        v = "V",
        V = "V-L",
        R = "R",
        Rc = "R",
        Rv = "R",
        Rx = "R",
        c = "C",
        cv = "C",
        ce = "C",
        s = "S",
        S = "S-L",
        [CTRL_S] = "S-B",
        t = "T",
        r = "P",
        ["r?"] = "P",
        rm = "P",
        ["!"] = "!",
      }

      local mode_colors = {
        n = hl_fg("Statement", "#e46876"),
        no = hl_fg("Statement", "#e46876"),
        ["!"] = hl_fg("Statement", "#e46876"),
        t = hl_fg("Statement", "#e46876"),
        i = hl_fg("String", "#98bb6c"),
        ic = hl_fg("String", "#98bb6c"),
        v = hl_fg("Type", "#7fb4ca"),
        V = hl_fg("Type", "#7fb4ca"),
        [CTRL_V] = hl_fg("Type", "#7fb4ca"),
        c = hl_fg("Constant", "#e6c384"),
        cv = hl_fg("Constant", "#e6c384"),
        ce = hl_fg("Constant", "#e6c384"),
        R = hl_fg("Exception", "#957fb8"),
        Rv = hl_fg("Exception", "#957fb8"),
        s = hl_fg("Constant", "#e6c384"),
        S = hl_fg("Constant", "#e6c384"),
        [CTRL_S] = hl_fg("Constant", "#e6c384"),
      }

      local function mode_label()
        local m = vim.fn.mode()
        return mode_labels[m] or m:upper():sub(1, 1)
      end

      local function mode_color()
        return mode_colors[vim.fn.mode()] or mode_colors.n
      end

      -- ~  --------------------------------------------------------------
      -- ~  Helpers

      local function ftype_icon()
        local full = vim.api.nvim_buf_get_name(0)
        local filename = vim.fn.fnamemodify(full, ":t")
        local ext = vim.fn.fnamemodify(filename, ":e")
        if has_devicons then
          static.icon, static.color = devicons.get_icon_color(filename, ext, { default = true })
          return static.icon and static.icon .. " "
        end
      end

      local function is_buf_named()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end

      local function is_git_repo()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
      end

      -- ~  --------------------------------------------------------------
      -- ~  Stack-specific extras — all gated behind `cond` so they take up
      -- zero width when not relevant, same philosophy as the diff/branch
      -- components only showing inside a git repo.

      -- Active LSP clients (e.g. Roslyn) attached to the current buffer.
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ""
        end
        local names = {}
        for _, c in ipairs(clients) do
          table.insert(names, c.name)
        end
        return table.concat(names, ", ")
      end

      -- overseer.nvim task summary — running/failed/succeeded counts.
      -- Useful for `dotnet build` runs kicked off via overseer: shows a
      -- running spinner-equivalent and failure count without needing to
      -- open the task list.
      local function overseer_tasks()
        local ok, overseer = pcall(require, "overseer")
        if not ok then
          return {}
        end
        return overseer.list_tasks({})
      end

      local function overseer_status()
        local tasks = overseer_tasks()
        if #tasks == 0 then
          return ""
        end
        local running, failed, succeeded = 0, 0, 0
        for _, t in ipairs(tasks) do
          if t.status == "RUNNING" then
            running = running + 1
          elseif t.status == "FAILURE" then
            failed = failed + 1
          elseif t.status == "SUCCESS" then
            succeeded = succeeded + 1
          end
        end
        local parts = {}
        if running > 0 then
          table.insert(parts, " " .. running)
        end
        if failed > 0 then
          table.insert(parts, " " .. failed)
        end
        if running == 0 and failed == 0 and succeeded > 0 then
          table.insert(parts, " " .. succeeded)
        end
        return table.concat(parts, " ")
      end

      -- nvim-dap active session indicator — only appears while debugging.
      local function dap_active()
        local ok, dap = pcall(require, "dap")
        return ok and dap.session() ~= nil
      end

      local function dap_status()
        local ok, dap = pcall(require, "dap")
        if not ok then
          return ""
        end
        local session = dap.session()
        if not session then
          return ""
        end
        return " " .. (session.config and session.config.name or "debug")
      end

      -- harpoon2 — shows this buffer's slot (e.g. "2/4") only if it's
      -- actually harpooned in the current list.
      local function harpoon_status()
        local ok, harpoon = pcall(require, "harpoon")
        if not ok then
          return ""
        end
        local list_ok, list = pcall(function()
          return harpoon:list()
        end)
        if not list_ok or not list or not list.items then
          return ""
        end
        local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
        for i, item in ipairs(list.items) do
          if item.value and vim.fn.fnamemodify(item.value, ":p") == current then
            return string.format("󰛢 %d/%d", i, #list.items)
          end
        end
        return ""
      end

      -- ~  --------------------------------------------------------------
      -- ~  Config

      local config = {
        options = {
          component_separators = "",
          section_separators = "",
          always_divide_middle = true,
          globalstatus = true,
          -- Auto-derives section colors from whatever colorscheme is
          -- active instead of hardcoding a theme table.
          theme = "auto",
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {
          lualine_a = { "filename" },
          lualine_b = { "location" },
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        -- Breadcrumb stays in the winbar (top), unchanged from before.
        winbar = {
          lualine_c = {
            {
              function()
                return navic.get_location()
              end,
              cond = navic.is_available,
            },
          },
        },
      }
      config.inactive_winbar = config.winbar

      local status_c = function(c)
        table.insert(config.sections.lualine_c, c)
      end
      local status_x = function(c)
        table.insert(config.sections.lualine_x, c)
      end

      -- ~  --------------------------------------------------------------
      -- ~  Left

      status_c({
        function()
          return "| "
        end,
        padding = { left = 0 },
      })

      status_c({
        mode_label,
        color = function()
          return { fg = mode_color(), gui = "bold" }
        end,
        padding = { right = 1 },
      })

      status_c({
        ftype_icon,
        cond = is_buf_named,
        color = function()
          return { fg = static.color }
        end,
        padding = { left = 1, right = 0 },
      })

      status_c({
        "filename",
        cond = is_buf_named,
        path = 0,
        symbols = {
          modified = icons.touched,
          readonly = icons.lock,
          unnamed = "[No Name]",
          newfile = "[New]",
        },
      })

      status_c({
        harpoon_status,
        cond = function()
          return harpoon_status() ~= ""
        end,
      })

      -- ~  --------------------------------------------------------------
      -- ~  Mid

      status_c({
        function()
          return "%="
        end,
      })

      -- ~  --------------------------------------------------------------
      -- ~  Right

      status_x({
        dap_status,
        cond = dap_active,
        color = { fg = hl_fg("Exception", "#e46876") },
      })

      status_x({
        overseer_status,
        cond = function()
          return overseer_status() ~= ""
        end,
      })

      status_x({
        lsp_clients,
        icon = "",
        cond = function()
          return lsp_clients() ~= ""
        end,
      })

      status_x({
        "diff",
        cond = is_git_repo,
        source = function()
          local gs = vim.b.gitsigns_status_dict
          if gs then
            return { added = gs.added, modified = gs.changed, removed = gs.removed }
          end
        end,
        symbols = { added = icons.added, modified = icons.modified, removed = icons.removed },
        colored = true,
      })

      status_x({
        "diagnostics",
        sources = { "nvim_lsp", "nvim_diagnostic" },
        symbols = { error = icons.error, warn = icons.warn, info = icons.info, hint = icons.hint },
      })

      status_x({ "branch", icon = icons.git_branch })

      status_x({
        function()
          return " |"
        end,
        padding = { right = 0 },
      })

      return config
    end,
  },

  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("navic_attach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then
            require("nvim-navic").attach(client, args.buf)
          end
        end,
      })
    end,
    opts = {
      highlight = true,
      depth_limit = 5,
      depth_limit_indicator = "…",
      separator = " › ",
    },
  },
}
