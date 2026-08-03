-- JSON. jsonls + SchemaStore schemas. From LazyVim's lang.json extra.
if not require("config.profile").has("json") then
  return {}
end

return {
  { "mason-org/mason.nvim", opts = { ensure_installed = { "json-lsp" } } },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "json", "json5" } },
  },
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jsonls = {
          before_init = function(_, new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = { enable = true },
              validate = { enable = true },
            },
          },
        },
      },
    },
  },
}
