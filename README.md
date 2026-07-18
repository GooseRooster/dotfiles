# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io) for Linux

Should technically work on any system, the only hard requirements are:

- Bash (obviously)
- Chezmoi
- Flatpak
- Homebrew

The theming tools and extension list are GNOME based, and the gaming performance script assumes tuned-adm availability. 

## What's included

- **Nushell** with starship, zoxide, carapace, television, and yazi
- **Neovim** with tinted-theming live colour sync
- **Theming** via [tinty](https://github.com/tinted-theming/tinty) (base16/base24 schemes, synced across terminal, editor, browser, and more)
- **Fastfetch** greeting on shell open
- **Brewfiles** split by category — base CLI, base-extra, devtools, cargo, theming, gaming, multimedia
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

The bootstrap script is interactive — it will prompt for these optional features:

| Flag | What it enables |
|------|-----------------|
| `--gaming` | Steam, emulators (PCSX2, Dolphin), Vesktop, Bottles, LACT, GPU Screen Recorder |
| `--multimedia` | Stremio, mpv (Flatpak) |
| `--theming` | tinty, gnomad, gowall; syncs schemes to terminal, editor, browser, Discord |
| `--podman-alias` | Sets `DOCKER_HOST` to podman's user socket and aliases `docker` → `podman` in nushell (both engines stay installed). Toggle later via `podman_alias_enabled` in `chezmoi.toml`. |

These can also be passed as flags to skip the prompts (useful for scripted installs):

```bash
./bootstrap.sh --gaming --theming --no-multimedia
```

The script is safe to re-run — it skips anything already installed.

### What bootstrap does

1. Delegates to `bootstrap-cli.sh` — base CLI tools, LazyVim starter, `chezmoi apply` (see below)
2. Installs base extras from `base-extra.Brewfile` (visual/GUI host tools — fastfetch, chafa, cava, bbrew, nerd fonts, VS Code)
3. Installs rustup via Homebrew and bootstraps the stable toolchain
4. Installs cargo packages (`cargo-cross` for cross-compilation)
5. Installs the dev tool chain from `devtools.Brewfile` (language toolchains, container tooling)
6. Installs theming tools if enabled
7. Installs Flatpaks (base always; gaming/multimedia conditionally)
8. Writes `~/.config/chezmoi/chezmoi.toml` with your chosen feature flags
9. Creates directories tinty needs for its hooks
10. Runs `chezmoi apply` again (idempotent, picks up your feature flags)

GNOME Shell extensions are tracked in `extensions.txt` but not auto-installed — install them manually via the Extensions app or GNOME's web installer.

### Dev container / CLI-only setup

`bootstrap-cli.sh` is a standalone, lean entrypoint meant for dev containers or
anywhere you just want your shell and editor, not the full desktop setup. Point
your dev container's dotfile setup at it after `chezmoi init`:

```bash
chezmoi init https://github.com/<your-username>/<your-fork>.git
cd "$(chezmoi source-path)"
chmod +x bootstrap-cli.sh
./bootstrap-cli.sh --devcontainer
```

It installs `base.Brewfile` (shell essentials and everything Neovim needs to
run — lazygit, tree-sitter-cli, etc.), clones the
[LazyVim](https://www.lazyvim.org) starter into `~/.config/nvim` since this
repo's Neovim config is built to sit on top of LazyVim, then runs
`chezmoi apply`. It does not install visual/GUI extras (`base-extra.Brewfile`
— fastfetch, chafa, cava, bbrew, nerd fonts, VS Code) or language toolchains
or container tooling (`devtools.Brewfile`) — those are host-bootstrap only,
and a dev container is expected to supply its own toolchain.

**Homebrew itself must already be on `PATH` before this script runs** — unlike
the full host `bootstrap.sh`, it deliberately doesn't install Homebrew for
you. In a dev container, install it declaratively as part of the container
spec (e.g. a devcontainer Feature) rather than at script runtime — see
[Dev container templates](#dev-container-templates) below for working
examples.

The `--devcontainer` flag doesn't install anything itself — it just records
`devcontainer_enabled = true` in `~/.config/chezmoi/chezmoi.toml`, so
`chezmoi apply` skips desktop/GUI/optional-feature dotfiles that have no
purpose in a container (ghostty, mpv, tinty theming, the GNOME-keyboard-shortcut
`termapp` helper, etc. — see `.chezmoiignore.tmpl`). Everything `bootstrap-cli.sh`
actually installs (nushell, starship, Neovim, yazi) is unaffected.

### Dev container templates

`devcontainer-templates/` has two example `.devcontainer` setups:

| Template | Use when |
|----------|----------|
| `standalone` | You don't have existing container infra — just a base image + Homebrew (via a Feature) + this repo's `bootstrap-cli.sh`. |
| `ci-compose` | Your CI already builds/deploys via a `Dockerfile`/`docker-compose.yml` you want the dev container to inherit, with dev-only tweaks (workspace mount, `sleep infinity`, Homebrew) layered on top via `docker-compose.override.yml` and a Feature — without touching the CI compose file itself. |

Both use the [`ghcr.io/meaningful-ooo/devcontainer-features/homebrew`](https://github.com/meaningful-ooo/devcontainer-features) Feature to install Homebrew declaratively before `postCreateCommand` runs `bootstrap-cli.sh --devcontainer`. That Feature's prerequisite installer only branches on `debian`/`ubuntu`/`alpine` base images — an Oracle Linux (or other dnf-based) CI image will need that patched, or its prerequisites (curl, git, a C compiler) baked in ahead of time.

Deploy either template into a repo you're working on with `devcontainer-init` (installed to `~/.local/bin` on full host setups only — see `dot_local/bin/executable_devcontainer-init`):

```bash
devcontainer-init ci-compose /path/to/some-repo
```

Then review the `// TODO` comments in the copied `.devcontainer/devcontainer.json` (and `docker-compose.override.yml` for `ci-compose`) to point it at your actual compose file and service name.

### WSL (Ubuntu) setup

For an Ubuntu instance under WSL2 that you use to drive dev containers, run
`bootstrap-cli.sh` with `--wsl`:

```bash
chezmoi init https://github.com/<your-username>/<your-fork>.git
cd "$(chezmoi source-path)"
chmod +x bootstrap-cli.sh
./bootstrap-cli.sh --wsl
```

Like the plain CLI setup it skips language toolchains (those belong inside your
dev containers), but it additionally:

- Installs `wsl.Brewfile` on top of `base.Brewfile` — the dev container CLI,
  Claude Code, and fastfetch.
- Records `wsl_enabled = true` in `~/.config/chezmoi/chezmoi.toml`, so
  `chezmoi apply` skips GUI-only dotfiles (ghostty, mpv, tinty theming, the
  `termapp` helper) while **keeping** `devcontainer-init` — in WSL you want to
  scaffold dev containers into your repos.
- Appends a login block to `~/.bashrc` that loads Homebrew's environment, shows
  the fastfetch greeting, and drops you into nushell on each interactive shell.
- Runs `setup-docker-wsl.sh` to install **both** Docker Engine (no Docker
  Desktop, from Docker's official apt repo) and **Podman**, add you to the
  `docker` group, and enable systemd in `/etc/wsl.conf`. **This step needs
  `sudo`.** We keep both engines installed, but default to Podman: its
  docker-compatible user socket (`podman.socket`) is enabled via a
  chezmoi-managed systemd user unit, nushell points `DOCKER_HOST` at it and
  aliases `docker` → `podman` (see `dot_config/nushell/podman-alias.nu.tmpl`), so
  tools like `lazydocker` and the dev container CLI work against Podman out of the
  box. Use `command docker` or the full binary path if you need the real Docker.
  `--wsl` forces `podman_alias_enabled = true`; on other machines it's an opt-in
  prompt (see below).

> **Homebrew must already be on `PATH`** before running this (same as the
> dev-container setup) — install it first via <https://brew.sh>.

After it finishes, **restart WSL** so systemd and your new `docker` group
membership take effect:

```powershell
# From Windows PowerShell:
wsl --shutdown
```

Reopen the distro, then verify Docker with `docker run hello-world`. The Docker
setup can also be re-run on its own at any time with `./setup-docker-wsl.sh`.

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
| `base.Brewfile` | Always (`bootstrap-cli.sh` or `bootstrap.sh`) |
| `base-extra.Brewfile` | Always, host bootstrap only — visual/misc CLI tools (fastfetch, chafa, cava, bbrew) & GUI extras (nerd fonts, VS Code); skipped for devcontainer installs |
| `devtools.Brewfile` | Always, host bootstrap only — language toolchains & container tooling, not installed by `bootstrap-cli.sh` |
| `wsl.Brewfile` | `bootstrap-cli.sh --wsl` only — dev container CLI, Claude Code, fastfetch (on top of `base.Brewfile`) |
| `cargo.Brewfile` | Always, host bootstrap only (after rustup) |
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

```bash
WINEDLLOVERRIDES="dwmapi=n,b" PROTON_ENABLE_WAYLAND=1 /var/home/gooze/.local/bin/game-performance.sh %command%

```

Always use the full path as Steam has trouble with home directory expansion.

What it does:

- Enables performance power profile
- Disables nightlight

When the game closes, performance profile will be restored to Balanced and nightlight will be restored.

Note: For Steam on flatpak, you will need to give it access to this directory, and the ability to spawn on the host: 

```bash
flatpak --user override --filesystem=~/.local/bin:ro com.valvesoftware.Steam
flatpak --user override --talk-name=org.freedesktop.Flatpak com.valvesoftware.Steam
```

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

## Windows VM (Podman Quadlet)

Running Windows 11 as a systemd-managed Podman Quadlet
([dockur/windows](https://github.com/dockur/windows)), for one-off MSVC/native
builds that don't play well under Wine. Runs **rootful** (not rootless) — see
rationale below. This step is manual — not every host wants a Windows VM — so
it isn't wired into `bootstrap.sh`.

### Why rootful, not rootless

dockur/windows needs three things: `/dev/kvm`, `/dev/net/tun`, and
`CAP_NET_ADMIN`. On Bluefin, `/dev/kvm` is world-writable (`666`) via a
Universal Blue udev rule, so device access alone isn't the blocker.

The actual blocker is `/dev/net/tun`: QEMU needs to call `ioctl(TUNSETIFF)` on
it to create a tap interface, which requires **real** `CAP_NET_ADMIN` on the
host's network namespace. Rootless Podman's `--cap-add NET_ADMIN` only grants
that capability inside the container's own unprivileged user namespace — it
cannot hand out real host-level `CAP_NET_ADMIN`:

```nu
podman run --rm -it --device /dev/kvm --device /dev/net/tun --cap-add NET_ADMIN alpine sh -c "ls -la /dev/kvm /dev/net/tun"
# /dev/kvm: fine
# /dev/net/tun: Permission denied
```

So: **rootful Quadlet**, unit lives in `/etc/containers/systemd/`, managed via
`systemctl` (not `--user`).

### Deploying the Quadlet

`container_templates/windows.container` is the Quadlet template. Notes on the
fields:

- `Volume=...:Z` — the `:Z` SELinux relabel suffix is required on Fedora
  Atomic/Bluefin (SELinux enforcing). Podman doesn't auto-relabel bind mounts
  the way Docker's compatibility shim does.
- `AutoUpdate=registry` — lets `podman-auto-update.timer` pull new
  `dockurr/windows` wrapper-image versions. This does **not** touch the
  Windows install itself (persisted in `/storage`); it only updates the
  QEMU/wrapper tooling.
- Deliberately **no `Restart=` directive** — a clean in-guest shutdown should
  release the RAM, not trigger an immediate restart. Start/stop like any other
  on-demand dev environment:
  ```nu
  sudo systemctl start windows.service
  sudo systemctl stop windows.service
  ```


```nu
open ~/container_templates/windows.container
| str replace --all "<YOUR_USER>" (whoami)
| save -f /tmp/windows.container

sudo mkdir -p /etc/containers/systemd
sudo cp /tmp/windows.container /etc/containers/systemd/windows.container

# make sure the bind-mount targets exist — Podman won't create them
sudo mkdir -p $"/var/home/(whoami)/vms/windows/storage"
sudo mkdir -p $"/var/home/(whoami)/vms/windows/shared"

# Disable COW on the storage volume before it has any files (see below) - ONLY NEEDED FOR BTRFS
sudo chattr +C $"/var/home/(whoami)/vms/windows/storage"

sudo systemctl daemon-reload
sudo systemctl start windows.service
sudo systemctl status windows.service
```

### Disabling COW on the storage volume (BTRFS hosts)

Bluefin's root filesystem is BTRFS. QEMU's qcow2 disk images do their own
copy-on-write bookkeeping internally — layering that under BTRFS's own COW
causes write amplification and fragmentation over time (same reason
libvirt/virt-manager docs recommend disabling COW for VM image directories on
BTRFS hosts). dockur/windows prints a warning about this at boot if it
detects BTRFS under `/storage`.

**Must be done before any files exist in the directory** — `chattr +C` only
applies to newly created files, not retroactively. Run it immediately after
`mkdir`, before starting the service for the first time (see the snippet
above).

What you give up, for this specific directory: checksumming (bit-rot
detection — acceptable for a disposable build VM), transparent compression
(the virtual disk takes its full logical size on disk), and slightly fuzzy
snapshot behavior at the edges (first write after a BTRFS snapshot forces one
COW break, briefly reintroducing fragmentation before settling back to nocow).
What you get: no COW-on-COW write amplification, meaningfully better
sustained I/O for NTFS-inside-qcow2's constant small random writes. Right
trade for an occasional-use dev VM.

### Connecting — RustConn (Flatpak)

RustConn (`io.github.totoshko88.RustConn`, in `base.flatpak.Brewfile`) is an
RDP client. Connection profile:

| Field | Value | Notes |
|---|---|---|
| Name | `Dockur Windows` (or any label) | Cosmetic only |
| Host | `127.0.0.1` | Rootful container publishes RDP to host loopback |
| Port | `3389` | Matches `PublishPort=3389:3389/tcp` in the Quadlet |
| Username | `Docker` | dockur/windows default account (fixed unless overridden via `USERNAME:`/`PASSWORD:` env vars in the Quadlet, which we didn't) |
| Domain | *(blank)* | Local account, not domain-joined |
| Jump Host | `(None)` | Direct loopback connection, no SSH tunnel |
| Password | `admin` | dockur/windows default |

### Troubleshooting: `xterm-ghostty: unknown terminal type` under `sudo`

Running `sudo systemctl status windows.service` (or any `sudo` command) from
a Ghostty terminal can print:

```
'xterm-ghostty': unknown terminal type.
```

The Ghostty AppImage cask installs the `xterm-ghostty` terminfo entry to
`~/.local/share/terminfo/x/xterm-ghostty` (the user-scoped ncurses search
path) — correct for a normal shell. But Fedora/Bluefin's `sudoers` sets
`Defaults always_set_home`, unconditionally resetting `$HOME` to root's home
for any `sudo`'d command, so ncurses under `sudo` looks in
`/root/.local/share/terminfo`, finds nothing, and falls back to the
compiled-in terminal database, which doesn't include `xterm-ghostty`.

`bootstrap.sh`'s Ghostty step now installs the compiled terminfo entry into
`/etc/terminfo`, which is in ncurses' default search path regardless of
`$HOME` and writable even on immutable Fedora Atomic — so this shouldn't come
up on a host set up via this repo's bootstrap. If you hit it anyway (e.g. the
cask was installed outside this repo's bootstrap), fix it manually:

```nu
sudo mkdir -p /etc/terminfo/x
sudo cp ~/.local/share/terminfo/x/xterm-ghostty /etc/terminfo/x/xterm-ghostty
```

Or work around it per-invocation: `sudo env TERM=xterm-256color <command>`.
