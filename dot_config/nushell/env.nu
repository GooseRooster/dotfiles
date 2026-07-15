# ── Homebrew bootstrap ────────────────────────────────────────────────────────
let brew_prefix = "/home/linuxbrew/.linuxbrew"

$env.HOMEBREW_PREFIX     = $brew_prefix
$env.HOMEBREW_CELLAR     = $"($brew_prefix)/Cellar"
$env.HOMEBREW_REPOSITORY = $brew_prefix
$env.PATH = ($env.PATH | prepend [
    $"($brew_prefix)/bin"
    $"($brew_prefix)/sbin"
])


# ── Toolchain env (depends on brew being on PATH above) ────────────────────────
# Add any environment variables here for dev tooling, if needed

# dotnet - SSL dev cert location, dotnet root for tools.
# Roslyn LSP expects this populated, but brew doesn't do that for you.
def get-system-cert-dir [] {
    let candidates = [
        "/etc/ssl/certs"        # Debian/Ubuntu
        "/etc/pki/tls/certs"    # Fedora/RHEL/Bluefin
    ]
    $candidates | where {|p| ($p | path exists)} | first
}
$env.SSL_CERT_DIR = $"($env.HOME)/.aspnet/dev-certs/trust:(get-system-cert-dir)"
$env.DOTNET_ROOT  = $"(^brew --prefix dotnet | str trim)/libexec"

$env.PATH = ($env.PATH | prepend [
    #Dotnet tools on the PATH
    $"($env.HOME)/.dotnet/tools"
    #bootstrap rustup
    $"(^brew --prefix rustup | str trim)/bin"
    #Expose cargo packages on PATH
    $"($env.HOME)/.cargo/bin"
])


# ── Other environment variables ────────────────────────
$env.EDITOR = "/var/home/linuxbrew/.linuxbrew/bin/nvim"


# ── Shell integration bootstrap ───────────────────────────────────────────────
# Nu's `source` requires a static file path, so integrations that generate
# their init scripts dynamically must write to disk here in env.nu first.
# The resulting files are sourced in config.nu once the environment is ready.

#zoxide
#a "smarter cd" command. Makes it easier to jump to your favorite directories.
zoxide init nushell | save -f ~/.zoxide.nu


#carapace completions - shell completions for all kinds of cool stuff
$env.CARAPACE_BRIDGES = 'cobra,argcomplete,clap'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
