-- Mason tools to keep installed across machines.
-- Most overlap with the enabled lang.* extras (see extras.lua); listed in full so the
-- set is self-documenting and survives upstream extra changes.
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "cmakelang",
        "cmakelint",
        "codelldb",
        "css-lsp",
        "docker-compose-language-service",
        "dockerfile-language-server",
        "gradle-language-server",
        "hadolint",
        "html-lsp",
        "java-debug-adapter",
        "java-test",
        "jdtls",
        "js-debug-adapter",
        "json-lsp",
        "lua-language-server",
        "neocmakelsp",
        "pyright",
        "ruff",
        "rust-analyzer",
        "shellcheck",
        "shfmt",
        "some-sass-language-server",
        "sqlfluff",
        "stylua",
        "typescript-language-server",
        "vtsls",
        "yaml-language-server",
      },
    },
  },
}
