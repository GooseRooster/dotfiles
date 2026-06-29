# ── Homebrew bootstrap ────────────────────────────────────────────────────────
let brew_prefix = "/home/linuxbrew/.linuxbrew"

$env.HOMEBREW_PREFIX     = $brew_prefix
$env.HOMEBREW_CELLAR     = $"($brew_prefix)/Cellar"
$env.HOMEBREW_REPOSITORY = $brew_prefix
$env.PATH = ($env.PATH | prepend [
    $"($brew_prefix)/bin"
    $"($brew_prefix)/sbin"
])

zoxide init nushell | save -f ~/.zoxide.nu
