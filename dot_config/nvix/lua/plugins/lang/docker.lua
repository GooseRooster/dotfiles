-- Docker / Dockerfile / compose. dockerls + compose LS + hadolint lint. From
-- LazyVim's lang.docker extra (none-ls fragment dropped — we use nvim-lint).
if not require("config.profile").has("docker") then
  return {}
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "dockerfile-language-server", "docker-compose-language-service", "hadolint" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "dockerfile" } },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = { linters_by_ft = { dockerfile = { "hadolint" } } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
