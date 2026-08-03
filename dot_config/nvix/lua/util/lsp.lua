-- LSP helpers, vendored from lazyvim.util.lsp (LazyVim -> Util). Provides:
--   * Util.lsp.set(filter, spec) — the Snacks-based, method-gated keymap setter
--     (LSP keys only bind on buffers whose client supports the `has = ...` method)
--   * Util.lsp.formatter() — the LSP fallback formatter registered into util/format
--   * Util.lsp.action[...] / Util.lsp.code_actions — code-action helpers
-- The deprecated M.get() and the trouble-based M.execute() are intentionally omitted.

---@class NvixUtil.lsp
local M = {}

---@param filter vim.lsp.get_clients.Filter
---@param spec table
function M.set(filter, spec)
  local Keys = require("lazy.core.handler.keys")
  for _, keys in pairs(Keys.resolve(spec)) do
    local filters = {} ---@type vim.lsp.get_clients.Filter[]
    if keys.has then
      local methods = type(keys.has) == "string" and { keys.has } or keys.has
      for _, method in ipairs(methods) do
        method = method:find("/") and method or ("textDocument/" .. method)
        filters[#filters + 1] = vim.tbl_extend("force", vim.deepcopy(filter), { method = method })
      end
    else
      filters[#filters + 1] = filter
    end

    for _, f in ipairs(filters) do
      local opts = Keys.opts(keys)
      opts.lsp = f
      opts.enabled = keys.enabled
      Snacks.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
    end
  end
end

---@param opts? LazyFormatter|{filter?: (string|vim.lsp.get_clients.Filter)}
function M.formatter(opts)
  opts = opts or {}
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  ---@cast filter vim.lsp.get_clients.Filter
  local ret = {
    name = "LSP",
    primary = true,
    priority = 1,
    format = function(buf)
      M.format(Util.merge({}, filter, { bufnr = buf }))
    end,
    sources = function(buf)
      local clients = vim.lsp.get_clients(Util.merge({}, filter, { bufnr = buf }))
      local sources = vim.tbl_filter(function(client)
        return client:supports_method("textDocument/formatting")
          or client:supports_method("textDocument/rangeFormatting")
      end, clients)
      return vim.tbl_map(function(client)
        return client.name
      end, sources)
    end,
  }
  return Util.merge(ret, opts)
end

---@param opts? table
function M.format(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {}, Util.opts("nvim-lspconfig").format or {})
  local ok, conform = pcall(require, "conform")
  -- prefer conform for LSP formatting when available (better diffing)
  if ok then
    opts.formatters = nil
    conform.format(opts)
  else
    vim.lsp.buf.format(opts)
  end
end

---@class NvixLspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler
---@field filter? string|vim.lsp.get_clients.Filter
---@field title? string

---@param opts NvixLspCommand
function M.execute(opts)
  local filter = opts.filter or {}
  filter = type(filter) == "string" and { name = filter } or filter
  local buf = vim.api.nvim_get_current_buf()
  ---@cast filter vim.lsp.get_clients.Filter
  local client = vim.lsp.get_clients(Util.merge({}, filter, { bufnr = buf }))[1]

  local params = { command = opts.command, arguments = opts.arguments }
  if opts.open then
    require("trouble").open({ mode = "lsp_command", params = params })
  else
    vim.list_extend(params, { title = opts.title })
    return client:exec_cmd(params, { bufnr = buf }, opts.handler)
  end
end

M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = { only = { action }, diagnostics = {} },
      })
    end
  end,
})

---@param filter? vim.lsp.get_clients.Filter
function M.code_actions(filter)
  filter = filter or {}
  local ret = {} ---@type string[]
  for _, client in ipairs(vim.lsp.get_clients(filter)) do
    vim.list_extend(ret, vim.tbl_get(client, "server_capabilities", "codeActionProvider", "codeActionKinds") or {})
    local regs = client.dynamic_capabilities:get("codeActionProvider", filter)
    for _, reg in ipairs(regs or {}) do
      vim.list_extend(ret, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
    end
  end
  return Util.dedup(ret)
end

return M
