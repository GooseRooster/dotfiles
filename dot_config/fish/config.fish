source /usr/share/cachyos-fish-config/cachyos-config.fish

function reset
    clear
    fastfetch
end

zoxide init fish | source

starship init fish | source
