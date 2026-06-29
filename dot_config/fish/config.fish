alias fastfetch='fastfetch --config ~/.config/fastfetch/config.jsonc'

function fish_greeting
    fastfetch
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end

function history
    builtin history --show-time='%F %T ' $argv
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons=always' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons=always' # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons=always' # long format
alias lt='eza -aT --color=always --group-directories-first --icons=always' # tree listing
alias l.="eza -a | grep -e '^\.'" # show only dotfiles

function reset
    cd
    clear
    fastfetch
end

zoxide init fish | source

starship init fish | source

set -gx SSL_CERT_DIR "$HOME/.aspnet/dev-certs/trust:/etc/pki/tls/certs"
fish_add_path ~/.dotnet/tools
set -gx DOTNET_ROOT (brew --prefix dotnet)/libexec

fish_add_path (brew --prefix rustup)/bin
fish_add_path ~/.cargo/bin
