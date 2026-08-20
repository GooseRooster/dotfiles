# Dev container (base skeleton)

A reusable, language-agnostic dev container that bakes in the hard-won container
plumbing. Copy it for a new stack and fill in the `⟨toolchain⟩` bits. Open with
VS Code ("Reopen in Container") or the devcontainer CLI (`devcontainer up`).

## What's baked in
- Non-root user under rootless-podman `--userns=keep-id` (workspace stays writable)
- `/tmp` restored to `1777` in post-create (Features can clobber it → breaks tools)
- Homebrew on `PATH` for every `exec` (brew is installed by the personal hook, not a Feature)
- **SSH agent forwarding** — private keys never enter the container; common git host
  keys pre-seeded so pushing just works
- Gitignored `local/` personalization hook (dotfiles/editor), never committed
- Nested `.gitignore` + `.gitattributes` so the template is self-contained and LF-safe
- Shared clipboard with the host (`wl-copy`/`wl-paste`) — see [Clipboard](#clipboard)

## Host prerequisites
- **SSH agent** running with your git key loaded, launched from a shell where
  `SSH_AUTH_SOCK` is set (`ssh-add -l` to check).

## Adapting it
1. Set the base image + toolchain in `Dockerfile` (`⟨toolchain⟩`).
2. Add repo-level setup in `scripts/setup-repo.sh` (`⟨toolchain⟩`).
3. If you change the base image, update `remoteUser`, the common-utils `username`,
   and the `/home/<user>` paths to that image's uid-1000 user.
4. Add `forwardPorts` (or uncomment `--network=host`) for your app's ports.

## Clipboard
The container shares the host's clipboard, so yanking in a terminal editor inside
it lands in your normal paste buffer (on WSL that is the Windows clipboard).

How it works: `initializeCommand` runs `scripts/host-clipboard-shim.sh` on your
**host**, which publishes your compositor's Wayland socket at the fixed path
`~/.cache/devcontainer/clipboard/wayland-0`. `devcontainer.json` bind-mounts that
to `/run/host-clipboard/wayland-0` and sets `WAYLAND_DISPLAY` to it, so
`wl-copy`/`wl-paste` (installed in the image) talk to your host compositor:

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
- `devcontainer.json` — the environment definition
- `Dockerfile` — base image + your toolchain
- `scripts/setup-repo.sh` — baseline setup (`/tmp` fix + your toolchain)
- `scripts/host-clipboard-shim.sh` — runs on the **host** (`initializeCommand`);
  publishes the host Wayland socket at a fixed path for the clipboard mount
- `scripts/setup-local.sh` — runs your gitignored `local/setup.sh` if present
- `local.example/` — template for personal setup
- `.gitignore` / `.gitattributes` — nested, keep the template self-contained + LF-safe
