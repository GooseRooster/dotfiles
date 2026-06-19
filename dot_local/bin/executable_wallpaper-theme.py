#!/usr/bin/env python3
"""
wallpaper-theme.py
Watches GNOME wallpaper changes, generates a Material You 16-color palette
via materialyoucolor-python, writes pywal16's colors.json, runs wal --restore
to stamp all wal templates, then nudges GTK to reload CSS in running apps.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

import gi
gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib

from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.palettes.core_palette import CorePalette

WAL_BIN          = Path.home() / ".local" / "bin" / "wal"
CACHE_DIR        = Path.home() / ".cache" / "wal"
CC_ACCENT_CSS    = Path.home() / ".config" / "gtk-4.0" / "custom-accent.css"
_ACCENT_RE       = re.compile(r'@define-color\s+accent_color\s+(#[0-9a-fA-F]{6})\s*;')

# How long to wait after wal finishes before starting the gtk-theme toggle.
# Gives Chroma Chameleon time to finish writing its CSS files first.
GTK_RELOAD_DELAY_MS = 2000

# Gap between setting gtk-theme to '' and restoring it.
# Apps need this time to process the "theme removed" signal before getting
# the "theme restored" signal — 1 s matches the approach that reliably works.


def argb_to_hex(argb: int) -> str:
    r = (argb >> 16) & 0xFF
    g = (argb >> 8)  & 0xFF
    b =  argb        & 0xFF
    return f"#{r:02x}{g:02x}{b:02x}"


def extract_palette(image_path: Path) -> list[str]:
    """Return 16 hex colors derived from the wallpaper via materialyoucolor."""
    quantized = ImageQuantizeCelebi(str(image_path), 128, 128)
    dominant  = Score.score(quantized)[0]
    core      = CorePalette.of(dominant)

    # Dark-mode terminal color convention:
    #   0  background        7  foreground
    #   1  red / error       8  bright background
    #   2  green / secondary 9  bright red
    #   3  yellow / tertiary 10 bright green
    #   4  blue / primary    11 bright yellow
    #   5  magenta           12 bright blue
    #   6  cyan              13 bright magenta
    #                        14 bright cyan
    #                        15 bright white
    tones = [
        core.n1.tone(6),      # 0  background
        core.error.tone(55),  # 1  red
        core.a2.tone(60),     # 2  green
        core.a3.tone(70),     # 3  yellow
        core.a1.tone(70),     # 4  blue / primary accent
        core.a1.tone(50),     # 5  magenta
        core.a2.tone(50),     # 6  cyan
        core.n1.tone(90),     # 7  foreground
        core.n1.tone(15),     # 8  bright bg
        core.error.tone(70),  # 9  bright red
        core.a2.tone(80),     # 10 bright green
        core.a3.tone(85),     # 11 bright yellow
        core.a1.tone(85),     # 12 bright blue
        core.a1.tone(65),     # 13 bright magenta
        core.a2.tone(70),     # 14 bright cyan
        core.n1.tone(98),     # 15 bright white
    ]
    return [argb_to_hex(t) for t in tones]


def chroma_chameleon_accent() -> str | None:
    """Read the accent color Chroma Chameleon wrote to the GTK4 CSS, if available."""
    try:
        m = _ACCENT_RE.search(CC_ACCENT_CSS.read_text())
        return m.group(1) if m else None
    except OSError:
        return None


def write_wal_cache(wallpaper_path: Path, colors: list[str]) -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    data = {
        "wallpaper": str(wallpaper_path),
        "alpha": "100",
        "special": {
            "background": colors[0],
            "foreground": colors[7],
            "cursor":     colors[4],
        },
        "colors": {f"color{i}": colors[i] for i in range(16)},
    }
    (CACHE_DIR / "colors.json").write_text(json.dumps(data, indent=2))


def run_wal() -> None:
    """Apply all wal templates from the cached colors.json."""
    subprocess.run(
        [str(WAL_BIN), "-R", "-n"],
        check=True,
    )


def schedule_gtk_reload() -> None:
    """Toggle color-scheme in-process so running GTK apps re-read their CSS.

    Uses Gio.Settings directly instead of spawning gsettings subprocesses —
    the write goes to dconf over a local socket and returns immediately, with
    the D-Bus notification to other apps sent asynchronously by GLib. No
    subprocess overhead, no blocking the event loop.
    """
    iface = Gio.Settings.new("org.gnome.desktop.interface")

    def _reload() -> bool:
        try:
            current = iface.get_string("color-scheme")
            opposite = "prefer-light" if "dark" in current else "prefer-dark"
            iface.set_string("color-scheme", opposite)
            GLib.idle_add(lambda: (iface.set_string("color-scheme", current), False)[1])
        except Exception as exc:
            print(f"[wallpaper-theme] GTK reload failed: {exc}", file=sys.stderr, flush=True)
        return False  # do not repeat

    GLib.timeout_add(GTK_RELOAD_DELAY_MS, _reload)


def process_wallpaper(uri: str) -> None:
    if not uri or not uri.startswith("file://"):
        return

    image_path = Path(uri[len("file://"):])
    if not image_path.exists():
        print(f"[wallpaper-theme] wallpaper not found: {image_path}", file=sys.stderr, flush=True)
        return

    print(f"[wallpaper-theme] processing {image_path}", flush=True)
    try:
        colors = extract_palette(image_path)

        # Let Chroma Chameleon's accent override color4 and the cursor so
        # terminal themes stay in sync with the GTK accent. By the time
        # materialyoucolor finishes (~0.5–1 s), CC has already written its CSS.
        cc_accent = chroma_chameleon_accent()
        if cc_accent:
            colors[4] = cc_accent
            print(f"[wallpaper-theme] using CC accent {cc_accent}", flush=True)

        write_wal_cache(image_path, colors)
        run_wal()
        schedule_gtk_reload()
        print(f"[wallpaper-theme] done — bg={colors[0]}  accent={colors[4]}", flush=True)
    except Exception as exc:
        print(f"[wallpaper-theme] error: {exc}", file=sys.stderr, flush=True)


def on_wallpaper_changed(settings: Gio.Settings, key: str) -> None:
    process_wallpaper(settings.get_string(key))


def main() -> None:
    bg = Gio.Settings.new("org.gnome.desktop.background")

    # Apply colors immediately for the current wallpaper on service start.
    startup_uri = bg.get_string("picture-uri-dark") or bg.get_string("picture-uri")
    if startup_uri:
        process_wallpaper(startup_uri)

    bg.connect("changed::picture-uri",      on_wallpaper_changed)
    bg.connect("changed::picture-uri-dark", on_wallpaper_changed)

    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
