# devcontainer-templates

Ready-to-copy dev container templates. Drop one into a repo with
`devcontainer-init <template> [target-dir]` (see `~/.local/bin/devcontainer-init`),
then fill in the `⟨…⟩` TODO markers.

## Templates
- **base** — language-agnostic skeleton. The reusable starting point; copy it to
  create a new language template.
- **dotnet** — base + .NET SDK + NuGet private-feed auth + trust-once dev HTTPS cert,
  with Blazor-WASM extras as opt-in TODOs.
- **ci-compose** — inherits an existing CI `docker-compose.yml` and layers dev-only
  tweaks on top. Follows the same conventions, but expresses the container plumbing
  (userns/network/volumes/env) in `docker-compose.override.yml`, since `runArgs`/
  `mounts` are ignored for compose-based dev containers.

## The semantic skeleton
Every (non-compose) template shares one layout. Only the `⟨lang⟩` layers change per
language — everything else is copied verbatim plumbing:

```
.devcontainer/
  devcontainer.json   # user + keep-id, network toggle, brew-on-PATH, SSH agent,
                      #   local/ hook, ports; ⟨lang: extra mounts/env⟩
  Dockerfile          # base image; ssh-keyscan; ⟨lang: toolchain⟩
  scripts/
    setup-repo.sh     # /tmp 1777 fix; ⟨lang: restore + tool install + extras⟩
    setup-local.sh    # IDENTICAL everywhere — runs local/setup.sh if present
  local.example/      # config.sh (DOTFILES_REPO + git identity), setup.sh
                      #   (brew self-install + chezmoi bootstrap + git identity), README
  .gitignore          # nested: ignores local/ (+ .certs/) → template is self-contained
  .gitattributes      # nested: * text eol=lf → CRLF fix travels with the template
  README.md           # what's inside + host prereqs; ⟨lang: cert/trust notes⟩
```

## What's baked in (and why)
Hard-won lessons from running these under **rootless podman on WSL**:
- **`--userns=keep-id`** + run as the base image's uid-1000 user + `updateRemoteUserUID:false`
  — otherwise the host user maps to container root and the bind-mounted workspace
  isn't writable.
- **`/tmp` → `1777` in setup-repo.sh** — devcontainer Feature build steps can leave
  `/tmp` as `0755 root`, which breaks any non-root tool that creates temp dirs there
  (e.g. every `dotnet`/MSBuild call). Features run after the Dockerfile, so it's fixed
  in post-create.
- **Homebrew installed by the personal hook, not a Feature** (leaner base),
  with `/home/linuxbrew/.linuxbrew/bin` added to `remoteEnv.PATH`
  so brew tools (nushell, ...) resolve in every `exec`.
- **SSH agent forwarding** (socket mount + `SSH_AUTH_SOCK`) + `ssh-keyscan`'d host keys
  — push over SSH with no private keys in the container and no known_hosts prompt.
- **Gitignored `local/` personalization hook** — the team base is reproducible; the
  dotfiles/editor step is per-developer and never committed.
- **Nested `.gitignore` + `.gitattributes`** — keep templates self-contained and force
  LF (CRLF silently breaks bash-sourced `config.sh`).
- **Shared clipboard with the host** — `initializeCommand` publishes the host
  compositor's Wayland socket at a fixed path (`scripts/host-clipboard-shim.sh`), the
  container bind-mounts it as `/run/host-clipboard/wayland-0` + `WAYLAND_DISPLAY`, and
  `wl-clipboard` is in the image. So `wl-copy`/`wl-paste` — and hence nvim's clipboard
  provider and nushell's `clip` — drive the host clipboard (on WSL, the Windows one).
  Hosts with no Wayland session get a placeholder file and fall back to OSC 52; see
  `.config/nvim/lua/config/clipboard.lua` and `.config/nushell/clipboard.nu`.

## Adding a new language template
1. `cp -r base <language>` (e.g. `node`, `python`, `go`).
2. In `Dockerfile`: set the base image and install the toolchain at `⟨toolchain⟩`.
   If the base image's uid-1000 user isn't `vscode` (mcr dotnet/sdk uses `ubuntu`),
   update `remoteUser`, the common-utils `username`, and every `/home/<user>` path.
3. In `scripts/setup-repo.sh`: add the restore/tool-install at `⟨toolchain⟩`.
4. In `devcontainer.json`: add language mounts/env/ports; enable `--network=host` if
   the app needs host reachability / VPN egress.
5. Add any language "extras" following the dotnet template's pattern — e.g. dotnet's
   dev-cert export + Kestrel env + trust notes. Each language brings its own version
   of that kind of jiggery-pokery; the skeleton around it stays the same.
6. Update `README.md` (host prereqs + any trust/cert notes) and the nested `.gitignore`
   (add language-specific gitignored dirs, like dotnet's `.certs/`).
