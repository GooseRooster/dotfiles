# chafa-enhance.nu
#
# ImageMagick pre-processing helpers for chafa's symbol/braille (no-color,
# FGBG) output. FGBG mode binarizes every pixel against a single fixed
# global black/white threshold rather than adapting per cell, so it lives
# or dies on *local* tonal separation in the source image (the same thing
# raking/angled light gives you for free). These helpers boost local
# contrast with ImageMagick before chafa ever sees the image, so flatly
# lit source photos have a fighting chance in braille output.
#
# Usage:
#   source ~/.config/nushell/scripts/chafa-enhance.nu
#
#   # Individual stages, each reads a path or stdin bytes and writes PNG
#   # bytes to stdout, so they compose by piping:
#   im-clahe photo.jpg | im-unsharp | chafa -f symbols -c none --symbols braille -
#
#   # Or use the all-in-one wrapper:
#   chafa-detail photo.jpg --denoise --clahe --unsharp
#   chafa-detail photo.jpg --unsharp --sigmoidal --symbols block -- --colors 16
#
# Anything after a literal `--` on the chafa-detail command line is passed
# straight through to chafa, unparsed (standard nushell rest-arg convention).

# Read bytes from a path if given, otherwise from stdin. Internal helper
# so each im-* stage can be used standalone or piped from the previous one.
#
# NB: nushell only binds a block's incoming pipeline value to `$in` for
# its first statement; once other blocks (like an if/else) are involved
# it stops seeing the original input. So every caller below captures
# `$in` into a variable as its very first statement and passes it in
# explicitly, rather than letting this helper reach for `$in` itself.
def im-input [file: any, piped: any] {
    if $file != null {
        open --raw $file
    } else {
        $piped
    }
}

# Local contrast via CLAHE (contrast-limited adaptive histogram
# equalization). This is the closest software equivalent to raking light:
# it re-expands contrast within local tiles instead of over the whole
# frame, so it can pull detail out of flatly/diffusely lit images.
export def "im-clahe" [
    file?: path
    --geometry: string = "25x25%+128+3"  # tile-WxH{+%}+bins+clip-limit; see `magick -help clahe`
] {
    let piped = $in
    im-input $file $piped | ^magick - -clahe $geometry png:-
}

# Cheap "clarity" boost: an unsharp mask with a large sigma acts as a local
# contrast enhancer rather than an edge sharpener. Gentler and less prone
# to blotchy artifacts than CLAHE; a good first thing to try.
export def "im-unsharp" [
    file?: path
    --radius: float = 0        # 0 lets ImageMagick pick a radius from sigma
    --sigma: float = 8         # blur radius defining what counts as "local"
    --amount: float = 0.8      # effect strength
    --threshold: float = 0.02  # ignore tonal differences below this
] {
    let piped = $in
    let geom = $"($radius)x($sigma)+($amount)+($threshold)"
    im-input $file $piped | ^magick - -unsharp $geom png:-
}

# Global S-curve contrast. Unlike CLAHE/unsharp this can't invent local
# detail that isn't there, but it's a cheap way to push already-separated
# tones further toward the black/white extremes before chafa's own
# threshold sees them. Good as a final pass after a local-contrast stage.
export def "im-sigmoidal" [
    file?: path
    --contrast: float = 4    # steepness of the curve
    --midpoint: float = 50   # percent; where the curve pivots
] {
    let piped = $in
    let geom = $"($contrast)x($midpoint)%"
    im-input $file $piped | ^magick - -sigmoidal-contrast $geom png:-
}

# Median denoise. Local-contrast boosts amplify sensor/JPEG noise right
# alongside real edges, so run this first on noisy sources to keep the
# later stages from turning speckle into speckle-shaped braille dots.
export def "im-denoise" [
    file?: path
    --radius: int = 2  # pixels; box will be (2*radius+1)x(2*radius+1)
] {
    let piped = $in
    let geom = $"(2 * $radius + 1)x(2 * $radius + 1)"
    im-input $file $piped | ^magick - -statistic Median $geom png:-
}

# Plain grayscale conversion, useful if you want to inspect what chafa's
# FGBG mode will actually be thresholding against.
export def "im-grayscale" [
    file?: path
] {
    let piped = $in
    im-input $file $piped | ^magick - -colorspace Gray png:-
}

# Global histogram stretch. Chafa already does its own (more conservative)
# version of this internally for FGBG mode, so this is mostly here for
# comparison/experimentation rather than routine use.
export def "im-normalize" [
    file?: path
] {
    let piped = $in
    im-input $file $piped | ^magick - -auto-level png:-
}

# All-in-one: chain the requested correction stages in a single ImageMagick
# invocation (avoids repeated decode/encode) and pipe the result straight
# into chafa. Stages run in this order when enabled: denoise, clahe,
# unsharp, sigmoidal, grayscale.
export def "chafa-detail" [
    file: path                          # source image
    --denoise                           # median-filter first (see im-denoise)
    --denoise-radius: int = 2
    --clahe                             # local contrast via CLAHE (see im-clahe)
    --clahe-geometry: string = "25x25%+128+3"
    --unsharp                           # local contrast via large-radius unsharp (see im-unsharp)
    --unsharp-radius: float = 0
    --unsharp-sigma: float = 8
    --unsharp-amount: float = 0.8
    --unsharp-threshold: float = 0.02
    --sigmoidal                         # global S-curve, applied last (see im-sigmoidal)
    --sigmoidal-contrast: float = 4
    --sigmoidal-midpoint: float = 50
    --grayscale                         # convert to grayscale before handing off to chafa
    --magick-extra: string = ""         # extra raw ImageMagick operators, e.g. "-blur 0x1"
    --chafa-preprocess                  # let chafa ALSO run its own global stretch (usually redundant/can reclip your work)
    --symbols: string = "braille"       # forwarded as chafa --symbols
    --colors: string = "none"           # forwarded as chafa --colors
    --format: string = "symbols"        # forwarded as chafa --format
    --dry-run                           # print the commands instead of running them
    ...chafa_args                       # anything else, forwarded verbatim to chafa (put after --)
] {
    if not ($file | path exists) {
        error make {msg: $"chafa-detail: file not found: ($file)"}
    }

    mut magick_args = []

    if $denoise {
        $magick_args = ($magick_args | append ["-statistic" "Median" ($denoise_radius | into string)])
    }
    if $clahe {
        $magick_args = ($magick_args | append ["-clahe" $clahe_geometry])
    }
    if $unsharp {
        let geom = $"($unsharp_radius)x($unsharp_sigma)+($unsharp_amount)+($unsharp_threshold)"
        $magick_args = ($magick_args | append ["-unsharp" $geom])
    }
    if $sigmoidal {
        let geom = $"($sigmoidal_contrast)x($sigmoidal_midpoint)%"
        $magick_args = ($magick_args | append ["-sigmoidal-contrast" $geom])
    }
    if $grayscale {
        $magick_args = ($magick_args | append ["-colorspace" "Gray"])
    }
    if $magick_extra != "" {
        $magick_args = ($magick_args | append ($magick_extra | split row " " | where {|x| $x != ""}))
    }

    let preprocess_flag = if $chafa_preprocess { "on" } else { "off" }
    let chafa_full_args = ([
        "-f" $format
        "-c" $colors
        "--symbols" $symbols
        "--preprocess" $preprocess_flag
    ] | append $chafa_args)

    if $dry_run {
        print $"magick ($file) (($magick_args | str join ' ')) png:-"
        print $"  | chafa (($chafa_full_args | str join ' ')) -"
        return
    }

    (^magick $file ...$magick_args png:-) | ^chafa ...$chafa_full_args -
}
