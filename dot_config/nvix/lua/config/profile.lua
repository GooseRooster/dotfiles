-- Environment-driven feature GATE. The single source of truth for WHICH
-- languages/features load in this environment. It answers `has("<name>")` and
-- nothing more — each feature's actual wiring lives in ONE self-contained file:
-- `plugins/lang/<name>.lua`, which starts with
--     if not require("config.profile").has("<name>") then return {} end
-- and then declares everything for that language (LSP server, formatter, linter,
-- treesitter parsers, mason tools, dap/test, extra plugins). Nothing here.
--
-- To add a language:
--   1. add its name to M.features below (and M.minimal_langs if it should load
--      inside dev containers too),
--   2. create plugins/lang/<name>.lua with the gate line above.
--   That's the whole checklist — no extras, no scattered overrides.
--
-- Why runtime (not chezmoi templating): the decision is read live from the
-- environment at every nvim startup, so a dev container can drive it purely via
-- `containerEnv` without re-running `chezmoi apply`. This file stays
-- byte-identical on every machine.
--
-- Control:
--   NVIM_PROFILE = "full" | "minimal"   coarse override (optional)
--   NVIM_LANGS   = "rust,python,..."    comma list of extra langs (minimal only)
--
-- Defaults: a host resolves to "full" (every feature), a dev container resolves
-- to "minimal" (M.minimal_langs + whatever NVIM_LANGS opts in).

local M = {}

local function env(name)
  local v = vim.env[name]
  if v == nil or v == "" then
    return nil
  end
  return v
end

-- All known language features. The full/host profile enables all of these; each
-- must have a matching plugins/lang/<name>.lua.
M.features = {
  "python",
  "rust",
  "typescript",
  "java",
  "clang",
  "cmake",
  "docker",
  "sql",
  "json",
  "yaml",
  "nushell",
  "git",
  "dotnet",
}

-- Enabled even in a minimal/container profile (the universally-useful ones).
M.minimal_langs = { "git", "json", "yaml", "docker", "nushell" }

-- Language-agnostic Mason tools + treesitter parsers, installed in EVERY profile.
-- (Consumed by plugins/mason.lua and plugins/treesitter.lua; per-language tools
-- and parsers are declared in the language's own lang/<name>.lua instead.)
M.baseline_mason = {
  "bash-language-server",
  "lua-language-server",
  "stylua",
  "shellcheck",
  "shfmt",
}

M.baseline_treesitter = {
  "bash",
  "c",
  "diff",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "printf",
  "query",
  "regex",
  "toml",
  "vim",
  "vimdoc",
  "xml",
}

function M.is_container()
  return env("DEVCONTAINER") ~= nil or env("CONTAINER_ID") ~= nil
end

function M.is_host()
  return not M.is_container()
end

local function resolve_profile()
  local p = env("NVIM_PROFILE")
  if p == "full" or p == "minimal" then
    return p
  end
  return M.is_host() and "full" or "minimal"
end

-- set of valid feature names, for validating NVIM_LANGS tokens
local known = {}
for _, name in ipairs(M.features) do
  known[name] = true
end

local function resolve_langs()
  local set = {}
  if resolve_profile() == "full" then
    for _, name in ipairs(M.features) do
      set[name] = true
    end
    return set
  end
  for _, name in ipairs(M.minimal_langs) do
    set[name] = true
  end
  local list = env("NVIM_LANGS")
  if list then
    for token in list:gmatch("[^,%s]+") do
      if known[token] then
        set[token] = true
      end
    end
  end
  return set
end

M.profile = resolve_profile()
M.langs = resolve_langs()

-- Is a given feature enabled in this environment?
function M.has(feature)
  return M.langs[feature] == true
end

-- Any language enabled at all? Used to gate the dap/test machinery, which is
-- pointless with zero languages.
function M.any_lang()
  return next(M.langs) ~= nil
end

return M
