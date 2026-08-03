-- YAML. yamlls + SchemaStore schemas + line folding. From LazyVim's lang.yaml.
if not require("config.profile").has("yaml") then
  return {}
end

return {
  { "mason-org/mason.nvim", opts = { ensure_installed = { "yaml-language-server" } } },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "yaml" } },
  },
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          capabilities = {
            textDocument = {
              foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
            },
          },
          before_init = function(_, new_config)
            new_config.settings.yaml.schemas = vim.tbl_deep_extend(
              "force",
              new_config.settings.yaml.schemas or {},
              require("schemastore").yaml.schemas()
            )
          end,
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              keyOrdering = false,
              format = { enable = true },
              validate = true,
              schemaStore = { enable = false, url = "" },
            },
          },
        },
      },
    },
  },
}
