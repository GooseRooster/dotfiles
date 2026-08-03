# nvix — build status

Living worklist for the nvix build. Read `AGENTS.md` first for architecture and conventions. Update this file when you finish an item or make a decision worth keeping.

## Goal

Full-parity, distro-free reproduction of the old LazyVim config (`~/.config/nvim`), built in `~/.config/nvix` and run isolated via `NVIM_APPNAME=nvix`. Eventually promote to daily driver.

## Decisions (locked)

- **Name:** `nvix` (NVIM_APPNAME + launcher command).
- **Scope:** full parity — all ~13 languages, all editor/coding plugins, custom stacks (easy-dotnet, markdown-plus, zk, cairn, yazi, ufo, goto-preview).
- **Manager:** keep `lazy.nvim`. Not native `vim.pack`. Not Kickstart-as-base.
- **Redundancy pruning:** use **flash** (drop `leap.nvim`); use **snacks.words** (drop `vim-illuminate`). Keep `mini.animate` + `smear-cursor` in **all** profiles including containers (no host-gating — animations are fine in containers).
- **Proving languages (wire/verify first):** Python, Rust, .NET, TypeScript.
- **Docs:** `AGENTS.md` canonical, `CLAUDE.md` thin pointer, this file for state.

## Phase checklist

- [x] **Phase 1 — skeleton boots.** `init.lua`, `config/{lazy,options,autocmds,profile}.lua`, `util/{init,root,format,icons}.lua`, `plugins/ui.lua` (snacks + osc-colors + dashboard). Boots clean headless; `Util` global, snacks, format/root setup all verified. `stylua.toml` carried.
- [x] **Phase 2 — core editor.** `config/keymaps.lua` (LazyVim's ~107 defaults, de-LazyVim'd + user overrides appended so they win); `plugins/editor.lua` (flash, gitsigns, which-key, mini.ai/pairs/surround/hipatterns, todo-comments, trouble, grug-far, ts-comments, dial, yanky, neogen, inc-rename, outline, vim-startuptime — NO leap, NO illuminate); `plugins/treesitter.lua` (main branch, profile-driven `ensure_installed`) + textobjects + ts-autotag; vendored `util/treesitter.lua`; `util/dial.lua` (dial augends); `set_default` added to `util/init.lua`. Boots clean; keymaps + flash/surround/dial + treesitter highlighting all verified. NOTE: navic lives in the carried `lualine.lua` (Phase 5), not here.
  - Deferred parity: mini.hipatterns **tailwind** integration dropped for leanness (hex-color highlight kept).
- [x] **Phase 3 — LSP + completion + format/lint.** `plugins/mason.lua` (profile-driven `ensure_installed`, `opts_extend`, install loop). `plugins/lsp.lua` (native `vim.lsp.config`/`enable`; mason-lspconfig `automatic_enable`; blink caps set explicitly on `vim.lsp.config("*")`; method-gated keymaps via `Util.lsp.set`; diagnostics/inlay/folds via `Snacks.util.lsp.on`; `opts_extend = {"servers","servers.*.keys"}`; keeps `stylua = { enabled = false }`). `util/lsp.lua` (set/formatter/action/code_actions). `plugins/completion.lua` (blink.cmp, LuaSnip preset, lazydev; dropped the AI-`<Tab>`/expand plumbing). `plugins/luasnip.lua` (carried; C# xmldoc autosnippet). `plugins/formatting.lua` (conform, registers as primary on VeryLazy) + `plugins/linting.lua` (nvim-lint). **Verified on Lua:** lua_ls attaches, gd/gr/cr/K bind buffer-local, blink loads, conform active + LSP fallback. Per-language servers merge in via `lang/*.lua` (Phase 4). NOTE: `Util.format.register(Util.lsp.formatter())` runs in lsp.lua's config (not lazy.lua) — the commented line in lazy.lua stays commented.
- [x] **Phase 4 — proving languages + dap/test.** Wrote `lang/{python,rust,typescript,dotnet}.lua`, `plugins/test.lua` (neotest base), carried `plugins/dap.lua` (custom UI) + `easy-dotnet.lua` + `lazydotnet.lua` (all `any_lang`/`has("dotnet")`-gated), vendored `Util.lsp.execute`. **Python verified end-to-end** (pyright+ruff attach, dap-python loads, ruff-LSP format active, python parser). rust/typescript/dotnet **config-verified** (specs/plugins/mason/parsers/servers register + merge); full runtime attach pending first real use (needs rust-analyzer/vtsls/roslyn downloads).
  - **Architecture refinement:** per-feature mason/treesitter data moved OUT of `profile.lua` INTO each `lang/<name>.lua` (via `opts_extend`). `profile.lua` = feature registry + baselines + gate only; `mason.lua`/`treesitter.lua` = baseline only. Adding a language = add name to `M.features` + write one `lang/<name>.lua` (gate line + everything). The "one place" model.
  - **Critical fix:** lazy's `import` is NOT recursive — added `{ import = "plugins.lang" }` to `config/lazy.lua`. Without it every `lang/*.lua` was silently ignored (Phase 3's Lua only worked because lua_ls lives in base `lsp.lua`). Recorded as a gotcha in AGENTS.md.
  - **.NET consolidated:** `easy-dotnet.lua` + `lazydotnet.lua` folded into `lang/dotnet.lua` (assembled byte-faithfully to preserve icon glyphs), so the whole .NET stack is one file per the one-place model. Standalone files removed.
- [x] **Phase 5 — remaining langs + custom stacks.** `lang/{java,clang,cmake,docker,sql,json,yaml,nushell,git}.lua` (all de-LazyVim'd from the extras; dropped recommended/nvim-cmp/none-ls/edgy fragments; clangd_extensions AST codicons dropped). Carried (cp, glyph-preserving): `markdown.lua`+`zk.lua` (notes), `peek.lua`/`regions.lua`/`numbertoggle.lua`/`twilight.lua`/`file-explorer.lua`/`cairn.lua` (tools), `lualine.lua`+`theme.lua` (ui). Authored `noice.lua` (+ nui/mini.icons in ui.lua) and `animate.lua` (mini.animate + smear-cursor, all profiles). **Full-profile load verified clean:** 73 plugins, 31 mason tools, 42 treesitter parsers, servers vtsls/jsonls/clangd/neocmake configured, lualine present. Per-language runtime attach beyond Python/Lua is config-verified (pending first real use).
  - Note: kept the user's original file layout for carried plugins (peek/regions/etc.) rather than consolidating into tools.lua/notes.lua — lower risk, glyph-safe, matches their existing structure. The "one file" model is about *languages* (`lang/*.lua`); general editor plugins keep their own files.
- [ ] **Phase 6 — launcher + promote.** Add `def --wrapped nvix [...args] { with-env { NVIM_APPNAME: "nvix" } { ^nvim ...$args } }` to chezmoi `dot_config/nushell/config.nu`; `chezmoi add -r ~/.config/nvix` (make `lua/config/options.lua` a `.tmpl` for the brew nu-shell path); final startup comparison vs the LazyVim config.

## Carry-over vs vendor vs authored

- **Carry verbatim (use `cp`, then rename LazyVim->Util / adjust gating — never retype, to preserve nerd glyphs):** `plugins/lualine.lua`, `plugins/dap.lua`, `plugins/theme.lua` (osc-colors), `plugins/{markdown,zk,easy-dotnet,lazydotnet,file-explorer,peek,regions,luasnip,cairn,twilight,numbertoggle,grug,mason,treesitter}.lua`. Source: `~/.config/nvim/lua/`. (Note: the old `util/osc-palette.lua` is intentionally NOT carried — the `GooseRooster/osc-colors.nvim` plugin replaces it.)
- **Vendored from LazyVim** (`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`, LazyVim->Util): `util/root.lua` (done), `util/format.lua` (done), `util/icons.lua` (done, extracted), `util/lsp.lua` (Phase 3), `config/{keymaps,options,autocmds}.lua` (options/autocmds done).
- **Authored fresh:** `config/lazy.lua`, `config/profile.lua` (converted from the carried one — extras payload dropped), `util/init.lua`, `plugins/{ui,lsp,completion,formatting,editor,tools,notes,test}.lua`, `plugins/lang/*.lua`.

## Gotchas (learned; don't rediscover)

- **Glyph transport:** agent editors strip BMP private-use nerd glyphs. Reference `util/icons.lua`, use `vim.fn.nr2char(0x____)`, or `cp`/`sed` from a byte-faithful source. Check: `grep -oP '[^\x00-\x7F]' <file> | wc -l`. This is WHY icon-heavy files are `cp`'d, not retyped.
- **`opts_extend` must be declared** on our own mason/lsp/blink specs or profile-driven list merging silently replaces instead of merges.
- **Bare snacks ships modules disabled** — enable each one we use in `plugins/ui.lua` opts (dashboard/notifier/statuscolumn/indent/scroll/words/bigfile/quickfile/picker/input/terminal). `Snacks.toggle.*` and `Snacks.words.*` keymaps no-op otherwise.
- **blink capabilities:** set them explicitly on `vim.lsp.config("*")` (don't rely on blink's plugin-load auto-register — load-order bug on first buffer).
- **VeryLazy wiring:** `Util.format.setup()`, `Util.root.setup()`, and (Phase 3) `Util.format.register(Util.lsp.formatter())` must be called from `config/lazy.lua`'s `on_very_lazy` — nothing else triggers autoformat / root cache / LSP formatter.
- **Don't port `util/cmp.lua`** — nvim-cmp-specific, dead under blink.
- **osc-colors needs a real TTY** (OSC palette round-trip) — `colors_name` is nil under `--headless`; that's expected, it works interactively.

## Promote-to-daily-driver checklist (Phase 6+)

- [ ] All phases green; `:checkhealth` clean; parity spot-check on muscle-memory keymaps (`<leader>ff/sg/gg`, `]d`/`[d`, `<leader>bd`).
- [ ] `nvix` startup <= the LazyVim config (`vim-startuptime`).
- [ ] Promoted into chezmoi (`dot_config/nvix/`), options templated for brew path, Nushell `def` committed.
- [ ] Optional: point `nvim` itself at nvix (swap `NVIM_APPNAME`/default) once confident.

## References

- Decoupling audit: `~/notes/nvim-lazyvim-decoupling-audit.md`
- Approved plan: `~/.claude/plans/this-is-great-research-wise-unicorn.md`
- LazyVim source (vendor/reference): `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/`
- Old config (carry-over source): `~/.config/nvim/lua/`
