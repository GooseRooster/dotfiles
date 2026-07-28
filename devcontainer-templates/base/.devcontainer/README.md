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

## Host prerequisites
- **SSH agent** running with your git key loaded, launched from a shell where
  `SSH_AUTH_SOCK` is set (`ssh-add -l` to check).

## Adapting it
1. Set the base image + toolchain in `Dockerfile` (`⟨toolchain⟩`).
2. Add repo-level setup in `scripts/setup-repo.sh` (`⟨toolchain⟩`).
3. If you change the base image, update `remoteUser`, the common-utils `username`,
   and the `/home/<user>` paths to that image's uid-1000 user.
4. Add `forwardPorts` (or uncomment `--network=host`) for your app's ports.

## Personalization (optional)
Opt-in and never committed — see [`local.example/README.md`](local.example/README.md).

## Files
- `devcontainer.json` — the environment definition
- `Dockerfile` — base image + your toolchain
- `scripts/setup-repo.sh` — baseline setup (`/tmp` fix + your toolchain)
- `scripts/setup-local.sh` — runs your gitignored `local/setup.sh` if present
- `local.example/` — template for personal setup
- `.gitignore` / `.gitattributes` — nested, keep the template self-contained + LF-safe
