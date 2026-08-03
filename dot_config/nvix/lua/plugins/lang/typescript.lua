-- TypeScript / JavaScript (vtsls). Reproduced from LazyVim's lang.typescript
-- (init + vtsls), de-LazyVim'd. Trimmed the vtsls _typescript.moveToFileRefactoring
-- client-command override (~50 lines) — everything else is faithful.
if not require("config.profile").has("typescript") then
  return {}
end

return {
  { "mason-org/mason.nvim", opts = { ensure_installed = { "vtsls", "js-debug-adapter" } } },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "typescript", "tsx", "javascript", "jsdoc", "html", "css" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = { enableServerSideFuzzyMatch = true },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          -- stylua: ignore
          keys = {
            { "gD", function()
              local win = vim.api.nvim_get_current_win()
              local params = vim.lsp.util.make_position_params(win, "utf-16")
              Util.lsp.execute({
                command = "typescript.goToSourceDefinition",
                arguments = { params.textDocument.uri, params.position },
                open = true,
              })
            end, desc = "Goto Source Definition" },
            { "gR", function()
              Util.lsp.execute({
                command = "typescript.findAllFileReferences",
                arguments = { vim.uri_from_bufnr(0) },
                open = true,
              })
            end, desc = "File References" },
            { "<leader>cM", Util.lsp.action["source.addMissingImports.ts"], desc = "Add missing imports" },
            { "<leader>cD", Util.lsp.action["source.fixAll.ts"], desc = "Fix all diagnostics" },
            { "<leader>cV", function()
              Util.lsp.execute({
                title = "Select TypeScript Version",
                filter = "vtsls",
                command = "typescript.selectTypeScriptVersion",
              })
            end, desc = "Select TS workspace version" },
          },
        },
      },
      setup = {
        vtsls = function(_, opts)
          -- copy typescript settings to javascript
          opts.settings.javascript =
            vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
        end,
      },
    },
  },

  -- debug adapters for node/chrome/msedge (nvim-dap base in plugins/dap.lua)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      for _, adapterType in ipairs({ "node", "chrome", "msedge" }) do
        local pwaType = "pwa-" .. adapterType
        if not dap.adapters[pwaType] then
          dap.adapters[pwaType] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = { command = "js-debug-adapter", args = { "${port}" } },
          }
        end
        if not dap.adapters[adapterType] then
          dap.adapters[adapterType] = function(cb, config)
            local nativeAdapter = dap.adapters[pwaType]
            config.type = pwaType
            if type(nativeAdapter) == "function" then
              nativeAdapter(cb, config)
            else
              cb(nativeAdapter)
            end
          end
        end
      end

      local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      local vscode = require("dap.ext.vscode")
      vscode.type_to_filetypes["node"] = js_filetypes
      vscode.type_to_filetypes["pwa-node"] = js_filetypes

      for _, language in ipairs(js_filetypes) do
        if not dap.configurations[language] then
          local runtimeExecutable = nil
          if language:find("typescript") then
            runtimeExecutable = vim.fn.executable("tsx") == 1 and "tsx" or "ts-node"
          end
          dap.configurations[language] = {
            {
              type = "pwa-node",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtimeExecutable,
              skipFiles = { "<node_internals>/**", "node_modules/**" },
              resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
            },
            {
              type = "pwa-node",
              request = "attach",
              name = "Attach",
              processId = require("dap.utils").pick_process,
              cwd = "${workspaceFolder}",
              sourceMaps = true,
              runtimeExecutable = runtimeExecutable,
              skipFiles = { "<node_internals>/**", "node_modules/**" },
              resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
            },
          }
        end
      end
    end,
  },
}
