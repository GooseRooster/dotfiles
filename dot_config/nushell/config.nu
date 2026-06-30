# ── General nu config ───────────────────────────────────────────────────────
$env.config.show_banner = false
$env.config.edit_mode = 'vi'


# ── Aliases ──────────────────────────────────────────────────────────────────
export alias grep = rg


# ── Functions: misc ───────────────────────────────────────────────────────────
def fastfetch [...args: string] {
  # Only want the greeting to fire if we are not within a container.
  if not ("CONTAINER_ID" in $env) {
    ^fastfetch --config ~/.config/fastfetch/config.jsonc ...$args
  }
}


# ── Functions: navigation ─────────────────────────────────────────────────────
# Dotfile listing
def "l." [] {
    ls -a | where name =~ '^\.'
}

# Yazi — cd on exit
def --env y [...args: string] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX" | str trim)
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp | str trim)
    if $cwd != "" and $cwd != $env.PWD and ($cwd | path type) == "dir" {
        cd $cwd
    }
    rm -f $tmp
}

# Make a dir and cd into it
def --env mkcd [name: string] {
    mkdir $name
    cd $name
}

# Home, clear, greeting
def --env home [] {
    cd ~
    clear
    fastfetch
}

# Distrobox: enter container, bootstrap nu
def dbx [name: string] {
  ^distrobox enter $name -- nu
}


# ── Functions: file ops ───────────────────────────────────────────────────────
# Backup a file
def backup [filename: path] {
    cp $filename $"($filename).bak"
}

# Smart copy — auto-recurse if source is a directory
def copy [...args: string] {
    if ($args | length) == 2 and ($args.0 | path type) == "dir" {
        let from = ($args.0 | str trim --right --char "/")
        cp -r $from $args.1
    } else {
        cp ...$args
    }
}


# ── Functions: dotfiles ───────────────────────────────────────────────────────
# Chezmoi: edit then apply in one step
def cze [...args: string] {
    chezmoi edit ...$args
    chezmoi apply
}


# ── Custom completions ────────────────────────────────────────────────────────
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


# ── Prompt & shell integrations ───────────────────────────────────────────────
let autoload_dir = ($nu.data-dir | path join "vendor/autoload")
mkdir $autoload_dir

# starship - the pretty prompt that shows things like toolchain version and git branch
starship init nu | save -f ($autoload_dir | path join "starship.nu")

# See env.nu for script bootstrap - zoxide makes folder nav way easier.
source ~/.zoxide.nu

# Shell integration for tv - fuzzy finder for lots of cool things.
tv init nu | save -f ($autoload_dir | path join "tv.nu")


# ── Greeting ───────────────────────────────────────────────────────────────────
fastfetch
