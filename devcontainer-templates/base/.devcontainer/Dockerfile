# Base dev container image — language-agnostic starting point.
# base:ubuntu is Ubuntu with common dev tooling and a non-root 'vscode' (uid 1000).
# Add your language SDK/tools where marked ⟨toolchain⟩ (see the dotnet template).
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# openssh-client: ssh + ssh-keyscan for agent-forwarded git.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-client \
 && rm -rf /var/lib/apt/lists/*

# Baseline SSH host keys so agent-forwarded git verifies common hosts with no
# per-developer known_hosts file. Add/trim hosts as needed. '|| true' so a
# transient network failure doesn't fail the build.
RUN ssh-keyscan -t rsa,ecdsa,ed25519 github.com ssh.dev.azure.com >> /etc/ssh/ssh_known_hosts 2>/dev/null || true

# ⟨toolchain⟩ Install your language SDK/tools here. Bake heavy, cacheable things
# (SDKs, workloads) into the image as root; leave repo-level bits to setup-repo.sh.
