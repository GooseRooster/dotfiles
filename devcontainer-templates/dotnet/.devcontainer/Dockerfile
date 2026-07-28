# .NET dev container image. The mcr dotnet/sdk image is Ubuntu-based and ships a
# non-root 'ubuntu' (uid 1000) user. Pin the tag to the .NET version you target.
FROM mcr.microsoft.com/dotnet/sdk:10.0

# openssh-client: ssh + ssh-keyscan for agent-forwarded git.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-client \
 && rm -rf /var/lib/apt/lists/*

# Baseline SSH host keys so agent-forwarded git verifies these hosts with no
# per-developer known_hosts file. '|| true' tolerates a transient network failure.
RUN ssh-keyscan -t rsa,ecdsa,ed25519 github.com ssh.dev.azure.com >> /etc/ssh/ssh_known_hosts 2>/dev/null || true

# ── ⟨blazor⟩ Blazor WebAssembly extras (uncomment if this is a Blazor WASM app) ──
# WASM native/AOT builds need python + the wasm-tools workload; headless Chrome is
# for in-container WASM remote-debugging (see scripts/dev.nu). Chrome is ~350 MB.
#
# RUN apt-get update \
#  && apt-get install -y --no-install-recommends python3 python3-pip \
#  && ln -sf /usr/bin/python3 /usr/bin/python \
#  && rm -rf /var/lib/apt/lists/*
# RUN dotnet workload install wasm-tools
# ARG INSTALL_CHROME=false
# RUN if [ "$INSTALL_CHROME" = "true" ]; then \
#       set -eux; \
#       apt-get update; \
#       apt-get install -y --no-install-recommends curl gpg ca-certificates; \
#       mkdir -p /etc/apt/keyrings; \
#       curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
#         | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg; \
#       echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
#         > /etc/apt/sources.list.d/google-chrome.list; \
#       apt-get update; \
#       apt-get install -y google-chrome-stable; \
#       rm -rf /var/lib/apt/lists/*; \
#     fi
#   ...and pass the arg from devcontainer.json:
#   "build": { "dockerfile": "Dockerfile", "args": { "INSTALL_CHROME": "true" } }
