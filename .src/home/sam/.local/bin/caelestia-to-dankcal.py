#!/usr/bin/env python3
"""Convert Caelestia scheme.json → Dux Calendar (dankcal) matugen theme."""

import json
import os
from pathlib import Path

SCHEME_PATH = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "caelestia" / "scheme.json"

OUTPUT_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "dankcal" / "matugen-theme.json"

# Caelestia M3 key → Dux Calendar theme role
ROLE_MAP = {
    "primary": "primary",
    "onPrimary": "primaryText",
    "primaryContainer": "primaryContainer",
    "secondary": "secondary",
    "surface": "surface",
    "onSurface": "surfaceText",
    "surfaceVariant": "surfaceVariant",
    "onSurfaceVariant": "surfaceVariantText",
    "background": "background",
    "onBackground": "backgroundText",
    "outline": "outline",
    "surfaceContainerLowest": "surfaceContainerLowest",
    "surfaceContainerLow": "surfaceContainerLow",
    "surfaceContainer": "surfaceContainer",
    "surfaceContainerHigh": "surfaceContainerHigh",
    "surfaceContainerHighest": "surfaceContainerHighest",
    "error": "error",
}


def to_hex(value: str) -> str:
    """Ensure the value is a #RRGGBB string (caelestia omits the #)."""
    v = value.strip()
    if not v.startswith("#"):
        v = "#" + v
    return v


def main():
    if not SCHEME_PATH.exists():
        raise SystemExit(f"Scheme file not found: {SCHEME_PATH}")

    with open(SCHEME_PATH) as f:
        scheme = json.load(f)

    colours = scheme.get("colours", {})
    mode = scheme.get("mode", "dark")

    theme = {}
    for cae_key, dux_role in ROLE_MAP.items():
        if cae_key in colours:
            theme[dux_role] = to_hex(colours[cae_key])

    # surfaceTint is conventionally the primary colour in Material 3
    if "primary" in colours:
        theme["surfaceTint"] = to_hex(colours["primary"])

    # Write as a flat palette for the current mode.
    # Dux Calendar's light/dark/automatic setting picks the palette;
    # a flat object applies to whichever mode is active.
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_PATH, "w") as f:
        json.dump(theme, f, indent=2)
        f.write("\n")

    print(f"Wrote {len(theme)} roles → {OUTPUT_PATH}  (mode: {mode})")


if __name__ == "__main__":
    main()
