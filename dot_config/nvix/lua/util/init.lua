-- Small support library for nvix. This is the trimmed, de-LazyVim'd replacement
-- for the parts of `lazyvim.util` that the vendored `root`/`format`/`lsp`
-- submodules and the ported keymaps/options rely on.
--
-- Most heavy helpers are FREE: lazy.nvim ships `lazy.core.util` with
-- norm/try/merge/notify, and we keep lazy.nvim. The metatable below falls back
-- to it, then lazy-loads our own submodules (util.root, util.format, util.lsp).
--
-- Exposed globally as `Util` (see the bottom) so vendored files can call
-- `Util.norm(...)` etc. and Vimscript `v:lua.Util.*` works from options.lua.

local LazyUtil = require("lazy.core.util")

---@class NvixUtil: LazyUtilCore
---@field root NvixUtil.root
---@field format NvixUtil.format
---@field lsp NvixUtil.lsp
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require("util." .. k)
    return t[k]
  end,
})

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param name string
function M.get_plugin(name)
  return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
  local plugin = M.get_plugin(name)
  path = path and "/" .. path or ""
  return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has(plugin)
  return M.get_plugin(plugin) ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      fn()
    end,
  })
end

function M.is_loaded(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

---@param name string
function M.opts(name)
  local plugin = M.get_plugin(name)
  if not plugin then
    return {}
  end
  local Plugin = require("lazy.core.plugin")
  return Plugin.values(plugin, "opts", false)
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
  local ret = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(ret, v)
      seen[v] = true
    end
  end
  return ret
end

-- Override the default notification title.
for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "nvix"
    return LazyUtil[level](msg, opts)
  end
end

-- Safe wrapper around snacks statuscolumn (used by options.lua's statuscolumn).
function M.statuscolumn()
  return package.loaded.snacks and require("snacks.statuscolumn").get() or ""
end

local _defaults = {} ---@type table<string, boolean>

-- Set a local option to a default value only if it's safe to do so: i.e. the
-- option still matches its global value, is a known default, or was last set by
-- a $VIMRUNTIME script. Avoids clobbering an ftplugin's choice. Trimmed from
-- lazyvim.util.set_default (debug + config._options branches removed). Used by
-- the treesitter FileType callback for indentexpr/foldmethod/foldexpr.
---@param option string
---@param value string|number|boolean
---@return boolean was_set
function M.set_default(option, value)
  local l = vim.api.nvim_get_option_value(option, { scope = "local" })
  local g = vim.api.nvim_get_option_value(option, { scope = "global" })
  _defaults[("%s=%s"):format(option, value)] = true
  local key = ("%s=%s"):format(option, l)
  if l ~= g and not _defaults[key] then
    local info = vim.api.nvim_get_option_info2(option, { scope = "local" })
    ---@param e vim.fn.getscriptinfo.ret
    local scriptinfo = vim.tbl_filter(function(e)
      return e.sid == info.last_set_sid
    end, vim.fn.getscriptinfo())
    local by_rtp = #scriptinfo == 1 and vim.startswith(scriptinfo[1].name, vim.fn.expand("$VIMRUNTIME"))
    if not by_rtp then
      return false
    end
  end
  vim.api.nvim_set_option_value(option, value, { scope = "local" })
  return true
end

_G.Util = M

return M
