# ── Homebrew bootstrap ────────────────────────────────────────────────────────
let brew_prefix = "/home/linuxbrew/.linuxbrew"

$env.HOMEBREW_PREFIX     = $brew_prefix
$env.HOMEBREW_CELLAR     = $"($brew_prefix)/Cellar"
$env.HOMEBREW_REPOSITORY = $brew_prefix
$env.PATH = ($env.PATH | prepend [
    $"($brew_prefix)/bin"
    $"($brew_prefix)/sbin"
])


# ── Shell integration bootstrap ───────────────────────────────────────────────
# Nu's `source` requires a static file path, so integrations that generate
# their init scripts dynamically must write to disk here in env.nu first.
# The resulting files are sourced in config.nu once the environment is ready.

#zoxide
zoxide init nushell | save -f ~/.zoxide.nu


#carapace completions
$env.CARAPACE_BRIDGES = 'cobra,argcomplete,clap'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
