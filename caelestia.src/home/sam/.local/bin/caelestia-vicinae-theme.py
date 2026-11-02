#!/usr/bin/env python3
# ~/.local/bin/caelestia-vicinae-theme.py
import json
import pathlib

scheme_path = pathlib.Path.home() / ".local/state/caelestia/scheme.json"
out_path = pathlib.Path.home() / ".local/share/vicinae/themes/caelestia.toml"

scheme = json.loads(scheme_path.read_text())
c = scheme["colours"]  # all hex values without '#'
mode = scheme.get("mode", "dark")

# Map Caelestia Material 3 / Catppuccin aliases → Vicinae keys
core = {
    "background": c.get("surface", c.get("base", "1E1E2E")),
    "foreground": c.get("text", c.get("onSurface", "CDD6F4")),
    "secondary_background": c.get("surfaceContainer", c.get("surface2", "181825")),
    "border": c.get("outlineVariant", c.get("overlay0", "313244")),
    "accent": c.get("primary", "89B4FA"),
}

accents = {
    "blue": c.get("blue", c.get("sky", "89B4FA")),
    "green": c.get("green", c.get("teal", "A6E3A1")),
    "magenta": c.get("magenta", c.get("pink", "F5C2E7")),
    "orange": c.get("orange", c.get("peach", "FAB387")),
    "purple": c.get("purple", c.get("mauve", "CBA6F7")),
    "red": c.get("red", c.get("rosewater", "F38BA8")),
    "yellow": c.get("yellow", c.get("yellow", "F9E2AF")),
    "cyan": c.get("cyan", c.get("sapphire", "94E2D5")),
}


def hx(v):
    return f'"{v}"'


lines = [
    "[meta]",
    "version = 1",
    'name = "Caelestia Dynamic"',
    'description = "Auto-generated from Caelestia wallpaper scheme."',
    f'variant = "{mode}"',
    f'inherits = "vicinae-{"dark" if mode == "dark" else "light"}"',
    "",
    "[colors.core]",
]
lines += [f"{k} = {hx(v)}" for k, v in core.items()]
lines += ["", "[colors.accents]"]
lines += [f"{k} = {hx(v)}" for k, v in accents.items()]

import os
import tempfile

tmp_fd, tmp_path = tempfile.mkstemp(dir=out_path.parent, prefix=out_path.name + ".", suffix=".tmp")
with os.fdopen(tmp_fd, "w") as f:
    f.write("\n".join(lines) + "\n")
os.replace(tmp_path, out_path)
