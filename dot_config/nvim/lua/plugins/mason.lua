-- Mason tools, derived from the environment profile (see config/profile.lua).
-- The always-on baseline plus the tools for whatever languages are enabled in
-- this environment — so a minimal/container profile never installs LSPs, DAP
-- adapters, or linters for languages it isn't using. Mason dedups, so overlap
-- with tools the LazyVim lang extras register themselves is harmless.
local profile = require("config.profile")

local ensure_installed = vim.list_extend({}, profile.baseline_mason)
for _, name in ipairs(profile.feature_order) do
  if profile.has(name) then
    vim.list_extend(ensure_installed, profile.features[name].mason)
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = ensure_installed,
    },
  },
}
