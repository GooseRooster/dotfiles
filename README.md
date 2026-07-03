# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io) for Fedora Atomic / Universal Blue desktops.

Focused around GNOME images, currently Bluefin.

## What's included

- **Nushell** with starship, zoxide, carapace, television, and yazi
- **Neovim** with tinted-theming live colour sync
- **Theming** via [tinty](https://github.com/tinted-theming/tinty) (base16/base24 schemes, synced across terminal, editor, browser, and more)
- **Fastfetch** greeting on shell open
- **Brewfiles** split by category — base CLI, cargo, theming, gaming, multimedia
- **GNOME extensions** tracked in `extensions.txt`

## Prerequisites

- [Homebrew](https://brew.sh) installed and on `$PATH`
- Flatpak configured with the Flathub remote
- A running GNOME session (for extension installation)

## Getting started

**Fork this repository** on GitHub first so you can commit your own changes back to your own copy.

Then initialise chezmoi against your fork and run the bootstrap:

```bash
chezmoi init https://github.com/<your-username>/<your-fork>.git
cd "$(chezmoi source-path)"
chmod +x bootstrap.sh
./bootstrap.sh
```

`chezmoi init` clones the repository into `~/.local/share/chezmoi` without applying anything yet. The bootstrap script handles `chezmoi apply` at the end, after writing your feature flags into `~/.config/chezmoi/chezmoi.toml` — so your dotfiles are applied with the right settings from the start.

The bootstrap script is interactive — it will prompt for three optional feature sets:

| Flag | What it installs |
|------|-----------------|
| `--gaming` | Steam, emulators (PCSX2, Dolphin), Vesktop, Bottles, LACT, GPU Screen Recorder |
| `--multimedia` | Stremio, mpv (Flatpak) |
| `--theming` | tinty, gnomad, gowall; syncs schemes to terminal, editor, browser, Discord |

These can also be passed as flags to skip the prompts (useful for scripted installs):

```bash
./bootstrap.sh --gaming --theming --no-multimedia
```

The script is safe to re-run — it skips anything already installed.

### What bootstrap does

1. Installs base CLI tools from `base.Brewfile`
2. Installs rustup via Homebrew and bootstraps the stable toolchain
3. Installs cargo packages (`cargo-cross` for cross-compilation)
4. Installs theming tools if enabled
5. Installs Flatpaks (base always; gaming/multimedia conditionally)
6. Writes `~/.config/chezmoi/chezmoi.toml` with your chosen feature flags
7. Creates directories tinty needs for its hooks
8. Runs `chezmoi apply`

GNOME Shell extensions are tracked in `extensions.txt` but not auto-installed — install them manually via the Extensions app or GNOME's web installer.

### Re-running with different flags

The bootstrap writes feature flags to `~/.config/chezmoi/chezmoi.toml` on first run and skips that step on subsequent runs. To change flags later, edit the file directly and apply:

```bash
# Edit ~/.config/chezmoi/chezmoi.toml — set gaming_enabled/multimedia_enabled/theming_enabled
chezmoi apply
```

## Day-to-day dotfile management

| Command | What it does |
|---------|-------------|
| `cze <file>` | Edit a dotfile and apply immediately |
| `chezmoi apply` | Apply all source changes to home |
| `chezmoi cd` | Open a shell in the source directory (uses nushell) |

Auto-commit and auto-push are enabled — every `chezmoi edit` commits and pushes to git.

## Keeping Brewfiles up to date

Open Claude Code in the chezmoi source directory and run `/brewfile-audit`. It will diff your currently installed packages against the tracked Brewfiles and offer to reconcile any gaps.

The Brewfile layout:

| File | Installed when |
|------|---------------|
| `base.Brewfile` | Always |
| `cargo.Brewfile` | Always (after rustup) |
| `theming.Brewfile` | `theming_enabled = true` |
| `gaming.Brewfile` | `gaming_enabled = true` |
| `base.flatpak.Brewfile` | Always |
| `gaming.flatpak.Brewfile` | `gaming_enabled = true` |
| `multimedia.flatpak.Brewfile` | `multimedia_enabled = true` |

---

## Running terminal apps from gnome kb shortcuts

The termapp script sets up brew and nushell before calling whatever application was passed as an argument. You can use any terminal emulator with this but the example here is for Ghostty. Use it in your GNOME keyboard shortcuts:

```bash
ghostty -e termapp yazi
```
## Game performance script
If the gaming option is enabled, game-performance.sh script will also be installed. You can use this in steam launch options like so:

```
WINEDLLOVERRIDES="dwmapi=n,b" PROTON_ENABLE_WAYLAND=1 /var/home/gooze/.local/bin/game-performance.sh %command%

```

Always use the full path as Steam has trouble with home directory expansion.

What it does:

- Enables performance power profile
- Disables nightlight

When the game closes, performance profile will be restored to Balanced and nightlight will be restored.


## Distrobox

[Distrobox](https://distrobox.it) is useful for packages that aren't available via Homebrew or Flatpak — things like distro-specific toolchains, system libraries, or packages that need root access to install properly.

### Creating a container with Homebrew available

Homebrew lives at `/home/linuxbrew/.linuxbrew` on the host. Mounting it read-only into a container makes all your installed formulae accessible without reinstalling:

```bash
distrobox create --name mybox \
  --image docker.io/library/ubuntu:24.04 \
  --volume /home/linuxbrew/.linuxbrew:/home/linuxbrew/.linuxbrew:ro
```

If you use [DistroShelf](https://github.com/ranfdev/DistroShelf), paste the following into the **Mounted Volumes** field when creating the container:

```
/home/linuxbrew/.linuxbrew:/home/linuxbrew/.linuxbrew:ro
```

Once inside the container, add Homebrew to PATH:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Entering a container with nushell

The `dbx` shell function drops you into a container with nushell already running:

```nushell
def dbx [name: string] {
  ^distrobox enter $name -- nu
}
```

Usage:

```
dbx mybox
```

### Exporting binaries from a container

If a tool only exists inside a container, you can export its binary to the host so it's available everywhere:

```bash
# Run from inside the container
distrobox-export --bin /usr/bin/my-tool --export-path ~/.local/bin
```

The exported binary is a shim that transparently enters the container when invoked from the host — no manual `distrobox enter` needed.
