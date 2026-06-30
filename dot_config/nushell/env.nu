# ── Homebrew bootstrap ────────────────────────────────────────────────────────
let brew_prefix = "/home/linuxbrew/.linuxbrew"

$env.HOMEBREW_PREFIX     = $brew_prefix
$env.HOMEBREW_CELLAR     = $"($brew_prefix)/Cellar"
$env.HOMEBREW_REPOSITORY = $brew_prefix
$env.PATH = ($env.PATH | prepend [
    $"($brew_prefix)/bin"
    $"($brew_prefix)/sbin"
])

#Some integrations need to be setup here before they can be sourced in config.
#zoxide
zoxide init nushell | save -f ~/.zoxide.nu

#carapace completions
$env.CARAPACE_BRIDGES = 'cobra,argcomplete,clap'
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
