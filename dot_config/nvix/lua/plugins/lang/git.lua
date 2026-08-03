-- Git filetypes (commit/config/rebase/ignore/attributes) — treesitter only, no
-- LSP. From LazyVim's lang.git extra (cmp-git fragment dropped; we use blink).
if not require("config.profile").has("git") then
  return {}
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "git_config", "gitcommit", "git_rebase", "gitignore", "gitattributes" } },
  },
}
