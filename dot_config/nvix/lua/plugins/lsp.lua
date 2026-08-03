-- LSP — reproduced from LazyVim's lsp/init.lua, de-LazyVim'd:
--   * native vim.lsp.config()/vim.lsp.enable(); mason-lspconfig automatic_enable
--     enables mason-managed servers, we enable non-mason ones ourselves
--   * blink capabilities set EXPLICITLY on vim.lsp.config("*") (avoids the
--     load-order gap where the first server attaches before blink registers caps)
--   * method-gated keymaps via Util.lsp.set (Snacks-based)
--   * diagnostics icons from util/icons; the top-level opts.capabilities
--     deprecation path is dropped (use servers["*"].capabilities)
-- Per-language servers are merged in via plugins/lang/*.lua (opts_extend servers).

local icons = require("util.icons")

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
    opts_extend = { "servers.*.keys" },
    opts = function()
      ---@class NvixLspOpts
      local ret = {
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = "if_many",
            prefix = "●",
          },
          severity_sort = true,
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
              [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
              [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
              [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
            },
          },
        },
        inlay_hints = {
          enabled = true,
          exclude = { "vue" },
        },
        codelens = {
          enabled = false,
        },
        folds = {
          enabled = true,
        },
        -- options for vim.lsp.buf.format (bufnr/filter handled by util/format)
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        ---@type table<string, table|boolean>
        servers = {
          ["*"] = {
            capabilities = {
              workspace = {
                fileOperations = { didRename = true, willRename = true },
              },
            },
            -- stylua: ignore
            keys = {
              { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
              { "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
              { "gr", vim.lsp.buf.references, desc = "References", nowait = true },
              { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
              { "gy", vim.lsp.buf.type_definition, desc = "Goto T[y]pe Definition" },
              { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
              { "K", function() return vim.lsp.buf.hover() end, desc = "Hover" },
              { "gK", function() return vim.lsp.buf.signature_help() end, desc = "Signature Help", has = "signatureHelp" },
              { "<c-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "Signature Help", has = "signatureHelp" },
              { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
              { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
              { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens" },
              { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", mode = { "n" }, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
              { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
              { "<leader>cA", Util.lsp.action.source, desc = "Source Action", has = "codeAction" },
              { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight", desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight", desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight", desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
              { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight", desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
              {
                "<leader>co",
                Util.lsp.action["source.organizeImports"],
                desc = "Organize Imports",
                has = "codeAction",
                enabled = function(buf)
                  local code_actions = vim.tbl_filter(function(action)
                    return action:find("^source%.organizeImports%.?$")
                  end, Util.lsp.code_actions({ bufnr = buf }))
                  return #code_actions > 0
                end,
              },
            },
          },
          -- stylua is a formatter, not a server; keep mason-lspconfig from
          -- trying to enable it as an LSP (mirrors LazyVim's base exclusion).
          stylua = { enabled = false },
          lua_ls = {
            settings = {
              Lua = {
                workspace = { checkThirdParty = false },
                codeLens = { enable = true },
                completion = { callSnippet = "Replace" },
                doc = { privateName = { "^_" } },
                hint = {
                  enable = true,
                  setType = false,
                  paramType = true,
                  paramName = "Disable",
                  semicolon = "Disable",
                  arrayIndex = "Disable",
                },
              },
            },
          },
        },
        -- optional per-server setup override; return true to skip lspconfig setup
        ---@type table<string, fun(server:string, opts:table):boolean?>
        setup = {},
      }
      return ret
    end,
    config = function(_, opts)
      -- register the LSP fallback formatter (conform is primary, priority 100)
      Util.format.register(Util.lsp.formatter())

      -- method-gated keymaps per server
      local names = vim.tbl_keys(opts.servers)
      table.sort(names)
      for _, server in ipairs(names) do
        local server_opts = opts.servers[server]
        if type(server_opts) == "table" and server_opts.keys then
          Util.lsp.set({ name = server ~= "*" and server or nil }, server_opts.keys)
        end
      end

      -- inlay hints
      if opts.inlay_hints.enabled then
        Snacks.util.lsp.on({ method = "textDocument/inlayHint" }, function(buffer)
          if
            vim.api.nvim_buf_is_valid(buffer)
            and vim.bo[buffer].buftype == ""
            and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
          then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
          end
        end)
      end

      -- folds (LSP folding range)
      if opts.folds.enabled then
        Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
          if Util.set_default("foldmethod", "expr") then
            Util.set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
          end
        end)
      end

      -- code lens
      if opts.codelens.enabled and vim.lsp.codelens then
        Snacks.util.lsp.on({ method = "textDocument/codeLens" }, function(buffer)
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = buffer,
            callback = vim.lsp.codelens.refresh,
          })
        end)
      end

      -- diagnostics
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      -- blink completion capabilities (set explicitly, see header note)
      local ok_blink, blink = pcall(require, "blink.cmp")
      if ok_blink then
        opts.servers["*"] = opts.servers["*"] or {}
        opts.servers["*"].capabilities =
          vim.tbl_deep_extend("force", blink.get_lsp_capabilities(), opts.servers["*"].capabilities or {})
      end

      if opts.servers["*"] then
        vim.lsp.config("*", opts.servers["*"])
      end

      -- servers available through mason-lspconfig
      local have_mason = Util.has("mason-lspconfig.nvim")
      local mason_all = have_mason
          and vim.tbl_keys(require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package)
        or {}
      local mason_exclude = {} ---@type string[]

      ---@return boolean? use_mason
      local function configure(server)
        if server == "*" then
          return false
        end
        local sopts = opts.servers[server]
        sopts = sopts == true and {} or (not sopts) and { enabled = false } or sopts

        if sopts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
          return
        end

        local use_mason = sopts.mason ~= false and vim.tbl_contains(mason_all, server)
        local setup = opts.setup[server] or opts.setup["*"]
        if setup and setup(server, sopts) then
          mason_exclude[#mason_exclude + 1] = server
        else
          vim.lsp.config(server, sopts)
          if not use_mason then
            vim.lsp.enable(server)
          end
        end
        return use_mason
      end

      local install = vim.tbl_filter(configure, vim.tbl_keys(opts.servers))
      if have_mason then
        require("mason-lspconfig").setup({
          ensure_installed = install,
          automatic_enable = { exclude = mason_exclude },
        })
      end
    end,
  },
}
