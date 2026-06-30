# ── Environment ───────────────────────────────────────────────────────────────
$env.SSL_CERT_DIR = $"($env.HOME)/.aspnet/dev-certs/trust:/etc/pki/tls/certs"
$env.DOTNET_ROOT  = $"(^brew --prefix dotnet | str trim)/libexec"

$env.PATH = ($env.PATH | prepend [
    $"($env.HOME)/.dotnet/tools"
    $"(^brew --prefix rustup | str trim)/bin"
    $"($env.HOME)/.cargo/bin"
])

# ── General nu config ───────────────────────────────────────────────────────
$env.config.show_banner = false


# ── Functions and aliases ───────────────────────────────────────────────────────
export alias grep = rg


# ── fastfetch shorthand ───────────────────────────────────────────────────────
def fastfetch [...args: string] {
  # Only want the greeting to fire if we are not within a container. 
  if not ("CONTAINER_ID" in $env) {
    ^fastfetch --config ~/.config/fastfetch/config.jsonc ...$args
  }
}

# ── Dotfile listing ───────────────────────────────────────────────────────────
def "l." [] {
    ls -a | where name =~ '^\.'
}

# ── Yazi — cd on exit ─────────────────────────────────────────────────────────
def --env y [...args: string] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX" | str trim)
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp | str trim)
    if $cwd != "" and $cwd != $env.PWD and ($cwd | path type) == "dir" {
        cd $cwd
    }
    rm -f $tmp
}

# ── Backup a file ─────────────────────────────────────────────────────────────
def backup [filename: path] {
    cp $filename $"($filename).bak"
}

# ── Smart copy — auto-recurse if source is a directory ───────────────────────
def copy [...args: string] {
    if ($args | length) == 2 and ($args.0 | path type) == "dir" {
        let from = ($args.0 | str trim --right --char "/")
        cp -r $from $args.1
    } else {
        cp ...$args
    }
}

# ── Reset — home, clear, greeting ────────────────────────────────────────────
def --env reset [] {
    cd ~
    clear
    fastfetch
}

# ── Distrobox : enter container, bootstrap nu ──────────────────────────────────────────── 
def dbx [name: string] {
  ^distrobox enter $name -- nu
}



# ── Custom completions ────────────────────────────────────────────
# Carapace - see env.nu for script bootstrap
# Should handle the vast majority of things
source $"($nu.cache-dir)/carapace.nu"

# dotnet - we delegate to dotnet's built in completion library.
def "nu-complete dotnet" [context: string] {
    dotnet complete $context | lines
}

export extern "dotnet" [
    ...args: string@"nu-complete dotnet"
]



# ── Prompt & navigation ───────────────────────────────────────────────────────
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")
# See env.nu for script bootstrap - zoxide makes folder nav way easier.
source ~/.zoxide.nu



# ── Greeting ──────────────────────────────────────────────────────────────────
fastfetch
