# Brewfile Audit

Audit packages and extensions installed on this system against what is tracked in the chezmoi Brewfiles and `extensions.txt`. Use this periodically to keep the tracked lists up to date.

## Steps

### 1. Homebrew audit

Dump all currently installed Homebrew formulae, casks, and taps:

```bash
brew bundle dump --file=/tmp/brew-dump.Brewfile --force
```

Filter the dump to brew/tap/cask lines only, then compare against `base.Brewfile`, `base-extra.Brewfile`, `devtools.Brewfile`, and `theming.Brewfile`:

- **Additions** — in the dump but not tracked in any Brewfile (candidates to add)
- **Removals** — tracked in a Brewfile but not in the dump (candidates to remove or not yet installed)

### 2. Flatpak audit

List all installed Flatpak apps:

```bash
flatpak list --app --columns=application
```

Compare the output against the three flatpak Brewfiles:
- `base.flatpak.Brewfile`
- `gaming.flatpak.Brewfile`
- `multimedia.flatpak.Brewfile`

Show **additions** (installed but not tracked in any flatpak Brewfile) and **removals** (tracked but not installed).

### 3. Cargo audit

List installed cargo packages:

```bash
cargo install --list
```

Compare against `cargo.Brewfile` (lines matching `^cargo "..."`).

### 4. GNOME extension audit

List all installed extensions (user and system):

```bash
gnome-extensions list
```

Compare the output against `extensions.txt` (one extension UUID per line):

- **Additions** — installed but not in `extensions.txt` (ask whether to track them)
- **Removals** — in `extensions.txt` but not installed (ask whether to remove from the list or note as pending install)

Note: `extensions.txt` is a tracking list only — extensions are not auto-installed by the bootstrap. To install a missing extension, use the Extensions app or GNOME's web installer.

## Output Format

Present findings grouped as:

- **Homebrew additions** — `brew install X` candidates to add to `base.Brewfile`, `base-extra.Brewfile`, or `theming.Brewfile`
- **Homebrew removals** — entries in Brewfiles not currently installed
- **Flatpak additions** — installed apps not tracked in any `*.flatpak.Brewfile`
- **Flatpak removals** — tracked app IDs not currently installed
- **Cargo additions** — installed cargo packages not in `cargo.Brewfile`
- **Cargo removals** — tracked cargo packages not installed
- **Extension additions** — installed extensions not in `extensions.txt`
- **Extension removals** — UUIDs in `extensions.txt` not currently installed

After presenting the findings, ask the user which differences to reconcile. Offer to:
- Add missing entries to the appropriate Brewfile or `extensions.txt`
- Remove stale entries from the appropriate Brewfile or `extensions.txt`
- Reclassify entries between Brewfiles (e.g. a base app that should be gaming-gated)

## Known exclusions

- **`rustup`** — appears in `brew bundle dump` output but must NOT be added to any Brewfile. It is installed by a dedicated step in the bootstrap script because `brew bundle` does not handle rustup's install flow correctly.
- **GNOME classic-mode built-in extensions** — `apps-menu@gnome-shell-extensions.gcampax.github.com`, `launch-new-instance@gnome-shell-extensions.gcampax.github.com`, `places-menu@gnome-shell-extensions.gcampax.github.com`, and `window-list@gnome-shell-extensions.gcampax.github.com` show up in `gnome-extensions list` but must NOT be added to `extensions.txt`. They ship with `gnome-shell-extensions` itself rather than being separately installed, so they aren't meaningful to track.

## Brewfile Ownership

| File | Purpose |
|------|---------|
| `base.Brewfile` | Core CLI tools + everything Neovim needs, installed on every machine incl. dev containers via `bootstrap-cli.sh` (kept devcontainer-safe — no visual/GUI extras) |
| `base-extra.Brewfile` | Visual/misc CLI tools & GUI extras (fastfetch, chafa, cava, bbrew, nerd fonts, VS Code) — host bootstrap only via `bootstrap.sh`, not installed in dev containers |
| `devtools.Brewfile` | Language toolchains & container tooling — host bootstrap only, not installed in dev containers |
| `theming.Brewfile` | Theming tools (tinty, gnomad, gowall) — only when `theming_enabled` |
| `gaming.Brewfile` | Gaming CLI tools — only when `gaming_enabled` |
| `cargo.Brewfile` | Cargo packages — installed after rustup |
| `base.flatpak.Brewfile` | Flatpaks installed on every machine |
| `gaming.flatpak.Brewfile` | Gaming flatpaks — only when `gaming_enabled` |
| `multimedia.flatpak.Brewfile` | Multimedia flatpaks — only when `multimedia_enabled` |
| `extensions.txt` | GNOME Shell extension UUIDs — tracked but not auto-installed |
