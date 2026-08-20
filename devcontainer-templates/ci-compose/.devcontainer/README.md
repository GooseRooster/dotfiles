# Dev container (ci-compose)

Inherits an existing **CI `docker-compose.yml`** and layers dev-only tweaks + the
rootless-podman plumbing on top via `docker-compose.override.yml`. Use this when
you want to develop inside the same service your CI already builds. Same conventions
as the base/dotnet templates (`local/` hook, brew-on-PATH, SSH agent forwarding).

## Compose flavour — the key difference
For compose-based dev containers, `runArgs` and `mounts` in `devcontainer.json` are
**ignored**. Container-level settings live in `docker-compose.override.yml`:
- `userns_mode: "keep-id"` — rootless-podman workspace writability
- `network_mode: "host"` — optional (commented)
- `volumes` — workspace + SSH agent socket + host Wayland socket (clipboard)
- `environment` — `SSH_AUTH_SOCK`, `DEVCONTAINER`, `NVIM_LANGS`, `WAYLAND_DISPLAY`
- `command: sleep infinity` — keep the container up to attach to

## Adapt it to your CI image (TODOs)
1. `dockerComposeFile` → your real CI compose file; `service` → the service name
   (matched in the override too).
2. `remoteUser` → a **non-root, uid-1000** user that exists in the CI image (keep-id
   maps your host uid there). If the image only has root, add a uid-1000 user, or the
   bind-mounted workspace won't be writable.
3. `/tmp` fix + brew prereqs assume **passwordless sudo** and a **Debian/Ubuntu**
   base — adjust `setup-repo.sh` / `local.example/setup.sh` for other distros.

## Host prerequisites
- **SSH agent** running with your git key loaded, and `SSH_AUTH_SOCK` set in the
  shell you launch from (`ssh-add -l` to check). Compose interpolates it at parse time.

## Clipboard
The container shares the host's clipboard, so yanking in a terminal editor inside
it lands in your normal paste buffer (on WSL that is the Windows clipboard).

How it works: `initializeCommand` runs `scripts/host-clipboard-shim.sh` on your
**host**, which publishes your compositor's Wayland socket at the fixed path
`~/.cache/devcontainer/clipboard/wayland-0`. `docker-compose.override.yml` mounts
that at `/run/host-clipboard/wayland-0` and sets `WAYLAND_DISPLAY` to it, so
`wl-copy`/`wl-paste` (installed best-effort by `setup-repo.sh`, since the CI image
isn't ours) talk to your host compositor:

    echo hello | wl-copy       # now pasteable on the host
    wl-paste                   # prints whatever you copied on the host

Any Wayland compositor works (Mutter, KWin, Hyprland, Sway, niri, and WSLg's
Weston) — it's the core clipboard protocol, nothing compositor-specific.

**No Wayland session on your host?** Nothing breaks: the shim writes a placeholder
file, the mount stays valid, and `wl-copy` simply fails to connect. Terminal
editors configured for it then fall back to OSC 52 escape sequences, which copy via
the terminal itself. VS Code users are unaffected either way — the editor runs on
the host and uses the host clipboard directly.

**After a host reboot / WSL restart**, a *reused* container has a stale socket (a
bind mount pins the inode). Recreate it — `devc rebuild`, or
`devcontainer up --remove-existing-container`.

## Personalization (optional)
Opt-in and never committed — see [`local.example/README.md`](local.example/README.md).

## Files
- `devcontainer.json` — service / user / remoteEnv / lifecycle
- `docker-compose.override.yml` — dev-only container settings (userns, network, volumes, env)
- `scripts/setup-repo.sh` — baseline setup (`/tmp` fix + your repo bits)
- `scripts/host-clipboard-shim.sh` — runs on the **host** (`initializeCommand`);
  publishes the host Wayland socket at a fixed path for the clipboard mount
- `scripts/setup-local.sh` — runs your gitignored `local/setup.sh` if present
- `local.example/` — template for personal setup
- `.gitignore` / `.gitattributes` — nested, keep the template self-contained + LF-safe
