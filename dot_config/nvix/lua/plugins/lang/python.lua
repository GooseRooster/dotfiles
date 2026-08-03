-- Python. Everything for the feature lives here (LSP, dap, test, venv, parsers,
-- mason tools), gated by the single profile check below. Reproduced from
-- LazyVim's lang.python extra, de-LazyVim'd (dropped recommended/nvim-cmp bits).
if not require("config.profile").has("python") then
  return {}
end

return {
  { "mason-org/mason.nvim", opts = { ensure_installed = { "pyright", "ruff", "debugpy" } } },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "python", "ninja", "rst" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ruff = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = { settings = { logLevel = "error" } },
        },
      },
      setup = {
        ruff = function()
          -- let pyright own hover; ruff handles lint/format
          Snacks.util.lsp.on({ name = "ruff" }, function(_, client)
            client.server_capabilities.hoverProvider = false
          end)
        end,
      },
    },
  },

  -- test adapter (neotest base is declared in plugins/test.lua)
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python" },
    opts = { adapters = { ["neotest-python"] = {} } },
  },

  -- debug adapter (nvim-dap base is declared in plugins/dap.lua)
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      -- stylua: ignore
      keys = {
        { "<leader>dPt", function() require("dap-python").test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require("dap-python").test_class() end, desc = "Debug Class", ft = "python" },
      },
      config = function()
        require("dap-python").setup("debugpy-adapter")
      end,
    },
  },

  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    ft = "python",
    opts = { options = { notify_user_on_venv_activation = true } },
    keys = { { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" } },
  },
}
