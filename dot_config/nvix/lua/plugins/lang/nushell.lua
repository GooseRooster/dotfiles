-- Nushell. LSP is `nu --lsp` (nu on PATH, no mason package). From lang.nushell.
if not require("config.profile").has("nushell") then
  return {}
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "nu" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { nushell = {} } },
  },
}
