-- dial.nvim helper + augends config, extracted from LazyVim's editor/dial.lua
-- extra (fully self-contained — no LazyVim/Util dependency). Kept out of the
-- plugin spec so editor.lua stays readable.

local M = {}

---@param increment boolean
---@param g? boolean
function M.dial(increment, g)
  local mode = vim.fn.mode(true)
  -- Use visual commands for VISUAL 'v', VISUAL LINE 'V' and VISUAL BLOCK '\22'
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

function M.opts()
  local augend = require("dial.augend")

  local logical_alias = augend.constant.new({
    elements = { "&&", "||" },
    word = false,
    cyclic = true,
  })

  local ordinal_numbers = augend.constant.new({
    elements = {
      "first",
      "second",
      "third",
      "fourth",
      "fifth",
      "sixth",
      "seventh",
      "eighth",
      "ninth",
      "tenth",
    },
    word = false,
    cyclic = true,
  })

  local months = augend.constant.new({
    elements = {
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    },
    word = true,
    cyclic = true,
  })

  return {
    dials_by_ft = {
      css = "css",
      vue = "vue",
      javascript = "typescript",
      typescript = "typescript",
      typescriptreact = "typescript",
      javascriptreact = "typescript",
      json = "json",
      lua = "lua",
      markdown = "markdown",
      sass = "css",
      scss = "css",
      python = "python",
    },
    groups = {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.decimal_int,
        augend.integer.alias.hex,
        augend.date.alias["%Y/%m/%d"],
        augend.constant.alias.en_weekday,
        augend.constant.alias.en_weekday_full,
        ordinal_numbers,
        months,
        augend.constant.alias.bool,
        augend.constant.alias.Bool,
        logical_alias,
      },
      vue = {
        augend.constant.new({ elements = { "let", "const" } }),
        augend.hexcolor.new({ case = "lower" }),
        augend.hexcolor.new({ case = "upper" }),
      },
      typescript = {
        augend.constant.new({ elements = { "let", "const" } }),
      },
      css = {
        augend.hexcolor.new({ case = "lower" }),
        augend.hexcolor.new({ case = "upper" }),
      },
      markdown = {
        augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
        augend.misc.alias.markdown_header,
      },
      json = {
        augend.semver.alias.semver,
      },
      lua = {
        augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }),
      },
      python = {
        augend.constant.new({ elements = { "and", "or" } }),
      },
    },
  }
end

return M
