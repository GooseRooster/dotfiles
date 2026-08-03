# nvix

A self-rolled, distro-free Neovim config. It reproduces the useful parts of the old LazyVim setup — LSP/DAP/treesitter/format IDE plumbing, the editor niceties, the environment-gated language profile — while owning every layer, with no `LazyVim/LazyVim` dependency.

**This file is the source of truth for agents** (opencode, Claude Code, copilot-cli). `CLAUDE.md` just points here. For live build status and the remaining worklist, read `PROJECT.md`.

## Why this exists

- **Own the layers.** LazyVim gave 107 default keymaps, an LSP loop, format/root glue, and per-language bundles behind a distro. nvix vendors the small glue it actually needs and writes the rest as plain specs — so keymaps and load behavior are fully under our control.
- **Runs parallel to the live config.** nvix is a separate `NVIM_APPNAME`, isolated in `~/.config/nvix` + `~/.local/share/nvix` + `~/.local/state/nvix` + `~/.cache/nvix`. The daily-driver LazyVim config at `~/.config/nvim` is never touched. Iterate here freely.
- **Light where it counts.** Container/host profile gating (see below) keeps a dev container from installing tooling it won't use. Prefer the smallest change; boring tech over shiny when boring works.

## Run / test

- **Launch:** `NVIM_APPNAME=nvix nvim` (or the `nvix` shell command once the Nushell `def` is applied — Phase 6).
- **Plugins:** `:Lazy` (status, no load errors), `:Lazy sync`. Headless: `NVIM_APPNAME=nvix nvim --headless "+Lazy! sync" +qa`.
- **Health:** `:checkhealth`, `:Mason` (should show only the profile-correct tool set), `:NvixFormatInfo` (conform + LSP formatter resolution), `:NvixRoot` (root detection).
- **Startup cost:** `:Lazy profile` or `vim-startuptime`.
- **Force a lean profile:** `NVIM_PROFILE=minimal NVIM_LANGS=python NVIM_APPNAME=nvix nvim`.

## Architecture

```
init.lua              -> require("config.lazy")
lua/config/
  lazy.lua            bootstrap lazy.nvim; import "plugins" ONLY; VeryLazy wiring
  options.lua         editor options (ported, LazyVim.* -> Util.*); sets mapleader
  keymaps.lua         all keymaps (nvix owns them); plain vim.keymap.set
  autocmds.lua        autocmds (nvix_ augroup prefix)
  profile.lua         environment-driven feature gate (SEE BELOW) — the core idea
lua/util/             the vendored "glue" that replaces lazyvim.util
  init.lua            Util global: over lazy.core.util + is_win/has/opts/dedup/notify/statuscolumn
  root.lua            root detection (lsp -> .git/lua -> cwd); Util.root() / Util.root.git()
  format.lua          conform+LSP formatter registry, autoformat toggle, BufWritePre autocmd
  lsp.lua             code-action filter helper + LSP fallback formatter   (Phase 3)
  icons.lua           nerd-font icon table (replaces LazyVim.config.icons)
lua/plugins/          one plugin spec per file; we own every spec
  ui.lua              snacks (backbone), colorscheme; later lualine/noice/animate
  editor.lua          flash, gitsigns, which-key, mini.*, todo, trouble, ...   (Phase 2)
  lsp.lua completion.lua formatting.lua treesitter.lua mason.lua              (Phase 3)
  dap.lua test.lua notes.lua tools.lua                                        (Phase 4/5)
  lang/<feature>.lua  per-language specs, each gated by profile.has(<feature>)
```

Load order: `config/lazy.lua` requires `util` (sets the `Util` global) and `config.options` before `lazy.setup`, then loads keymaps/autocmds and calls `Util.format.setup()` / `Util.root.setup()` on the `VeryLazy` event.

## The profile system (the important idea)

`lua/config/profile.lua` is the **single source of truth** for which languages/features load. It reads the environment at every startup:

- A **host** resolves to `full` (every feature). A **dev container** (`$DEVCONTAINER` / `$CONTAINER_ID`) resolves to `minimal` (a small baseline + `$NVIM_LANGS`).
- `NVIM_PROFILE=full|minimal` overrides the coarse decision; `NVIM_LANGS=rust,python` opts extra langs into a minimal profile.
- `profile.lua` is a **pure gate** — it only answers `has("<name>")`. It holds the feature registry (`M.features`), `minimal_langs`, and the always-on `baseline_mason`/`baseline_treesitter`. It contains NO per-language data.
- **Each language owns everything in one file: `plugins/lang/<name>.lua`.** It starts with `if not require("config.profile").has("<name>") then return {} end` and then declares that language's LSP server(s), formatter, linter, treesitter parsers (`opts.ensure_installed` on the treesitter spec), mason tools (`opts.ensure_installed` on the mason spec), dap/test adapters, and any extra plugins. When the feature is off, the file returns `{}` and contributes nothing (lean containers).
- Fragments merge into the shared plugins via lazy's opts merge + `opts_extend` (mason/treesitter `ensure_installed`, lsp `servers.*.keys`).

**To add a language:** (1) add its name to `M.features` in `profile.lua` (+ `minimal_langs` if it should load in containers); (2) create `plugins/lang/<name>.lua` with the gate line. That's it — no `:LazyExtras`, no `lazyvim.json`, no scattered overrides.

## Conventions

- **Lua style:** stylua, 2-space indent, column width 120 (`stylua.toml`). Run stylua before committing.
- **Spec shape:** every file under `plugins/` returns a lazy.nvim spec (a table or list of tables). Language specs gate with `enabled = require("config.profile").has("<feature>")`. Prefer explicit `event`/`ft`/`cmd`/`keys` lazy-loading — controlling load behavior is a goal, not an afterthought.
- **`opts_extend` is ours to declare.** lazy.nvim merges list-valued opts only where a spec declares `opts_extend` (e.g. mason `ensure_installed`, lsp `servers.*.keys`, blink `sources.default`). The profile-driven merging depends on it — declare it on our specs; don't assume it. (`servers` itself is a map, deep-merged automatically — do NOT put it in `opts_extend`.)
- **lazy's `import` is NOT recursive.** `config/lazy.lua` imports both `"plugins"` and `"plugins.lang"`. Any new subdirectory under `plugins/` needs its own `{ import = "plugins.<dir>" }` line, or its files are silently ignored — no error, they just never load.
- **Glue lives in `Util`, not `LazyVim`.** Vendored files call `Util.*`. Never reintroduce the `LazyVim` global or `require("lazyvim.*")`.
- **NEVER paste raw nerd-font glyphs into a Lua file via an agent editor.** BMP private-use codepoints (U+E000–U+F8FF) get silently stripped by some tools. Instead: reference `require("util.icons")`, use `vim.fn.nr2char(0x____)`, or `cp`/`sed` the file from a byte-faithful source. Verify with `grep -oP '[^\x00-\x7F]' <file> | wc -l`.

## Guardrails

- **Don't reintroduce LazyVim.** If a behavior is missing, vendor the ~small function from the on-disk LazyVim source (`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`) into `util/`, renaming `LazyVim.` to `Util.` — don't import the distro.
- **Keep it light.** Don't add a plugin where an option or a few lines do. Question every dependency. The container profile must stay lean.
- **Smallest change that works.** Read the surrounding code first. Match the existing spec style. Explicit over clever.
- **Update `PROJECT.md`** when you finish a phase item or make a decision worth remembering.
