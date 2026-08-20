# Clipboard helpers — one command that works on a host and inside a dev container.
#
# Backend is resolved at call time (so sourcing this file is always safe):
#   wayland : a live Wayland socket + wl-clipboard. On a host that's the local
#             compositor; in a dev container it's the HOST's socket, forwarded by
#             devcontainer.json (on WSLg that clipboard is the Windows one).
#   osc52   : no usable socket -- write the text to the terminal as an OSC 52
#             escape, and the terminal puts it on the clipboard of whatever
#             machine IT runs on. Copy-only: reading back needs the terminal to
#             answer a query, which most don't.
#
# `copy` is already taken (the cp wrapper in config.nu), hence `clip`.

# Which backend is usable right now.
def clip-backend [] {
    # WAYLAND_DISPLAY is either an absolute socket path (what the dev containers
    # set) or a name under XDG_RUNTIME_DIR (what a normal desktop session sets) --
    # libwayland accepts both.
    let name = ($env.WAYLAND_DISPLAY? | default "")
    let sock = if $name == "" {
        ""
    } else if ($name | str starts-with "/") {
        $name
    } else {
        ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | str trim)") | path join $name
    }
    # Presence of the env var proves nothing: the dev containers always set it, and
    # on a host with no Wayland session the mount is a placeholder regular file. It
    # has to actually be a socket (`path expand` resolves the symlink first).
    let live = $sock != "" and ($sock | path expand | path type) == "socket"
    if $live and (which wl-copy | is-not-empty) { "wayland" } else { "osc52" }
}

# Copy pipeline input to the host clipboard.
#   "hello" | clip
#   git rev-parse HEAD | clip
def clip []: any -> nothing {
    let input = $in
    # Strings go through untouched; structured input is rendered the way it would
    # print, so `ls | clip` copies the table you just looked at.
    let text = if ($input | describe) == "string" { $input } else { $input | to text }
    match (clip-backend) {
        # out+err> /dev/null is load-bearing: wl-copy forks into the background and
        # stays alive to serve the selection (the Wayland clipboard is owned by a
        # live client). The daemon inherits our stdout/stderr, so without this it
        # holds the caller's pipe open and anything downstream of `clip` hangs
        # until the clipboard is next replaced.
        "wayland" => { $text | ^wl-copy out+err> /dev/null }
        _ => {
            # /dev/tty, not stdout: stdout may be redirected, and the escape has to
            # reach the terminal emulator itself. `char -u "1b"` is ESC ("esc" is
            # not a valid `char` name); `char bel` terminates the sequence.
            try {
                (char -u "1b") + $"]52;c;($text | encode base64)" + (char bel)
                    | save --raw --append /dev/tty
            } catch {
                # No controlling terminal (cron, a pipeline in a script, ...).
                error make {msg: "clip: no clipboard socket, and no terminal to send an OSC 52 escape to"}
            }
        }
    }
}

# Read the clipboard back into the pipeline.
def "clip get" []: nothing -> string {
    if (clip-backend) != "wayland" {
        error make {msg: "clip get: no clipboard socket here (OSC 52 is copy-only) -- use the terminal's own paste, e.g. Ctrl+Shift+V"}
    }
    ^wl-paste --no-newline
}
