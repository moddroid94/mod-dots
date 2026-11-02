#!/usr/bin/env python3
import json
import shutil
import subprocess
from pathlib import Path

"""
dms-brave-theme.py — Sync Brave's theme to DankMaterialShell's dynamic palette.

Usage:
  ./dms-brave-theme.py              # generate once (uses "mode" field from json)
  ./dms-brave-theme.py --watch      # keep watching for changes
  ./dms-brave-theme.py --mode light # force light palette
  ./dms-brave-theme.py --mode dark  # force dark palette

Output: writes manifest.json into ~/dms-brave-theme/
Load it in Brave via brave://extensions → Developer mode → Load unpacked.
"""

import hashlib
import json
import sys
import time
from pathlib import Path

DMS_COLORS = Path.home() / ".cache" / "dms" / "dms-colors.json"
THEME_DIR = Path.home() / "dms-brave-theme"
MANIFEST = THEME_DIR / "manifest.json"

# matugen key → Brave theme slot
MAPPING = {
    "frame": "surface",
    "frame_inactive": "surface_container",
    "toolbar": "surface",
    "toolbar_text": "on_surface",
    "toolbar_separator": "outline",
    "toolbar_button_hover": "surface_container_high",
    "toolbar_button_selected": "surface_container_highest",
    "tab_strip": "surface_container_low",
    "tab_background": "surface_container",
    "tab_background_text": "on_surface_variant",
    "tab_selected": "surface_container_high",
    "tab_selected_text": "on_surface",
    "tab_unselected": "surface_container_low",
    "tab_unselected_text": "on_surface_variant",
    "tab_urgent": "error",
    "ntp_background": "background",
    "ntp_text": "on_background",
    "ntp_link": "primary",
    "bookmark_text": "on_surface_variant",
    "button_background": "primary_container",
    "button_text": "on_primary",
    "selected_button": "primary",
    "selected_button_text": "on_primary",
    "omnibox_background": "surface_container",
    "omnibox_text": "on_surface",
    "popup": "surface_container",
    "popup_text": "on_surface_variant",
    "sidebar": "surface_container_low",
    "sidebar_text": "on_surface_variant",
}


def hex_to_rgb(hex_str: str) -> list[int]:
    """'#aabbcc' → [170, 187, 204]"""
    h = hex_str.lstrip("#")
    return [int(h[i : i + 2], 16) for i in (0, 2, 4)]


def get_color(colors: dict, key: str, mode: str) -> list[int]:
    """Fetch a matugen color: colors[mode][key] → hex string → [R,G,B]."""
    palette = colors.get(mode, {})
    hex_val = palette.get(key, "#000000")
    return hex_to_rgb(hex_val)


def build_manifest(colors: dict, mode: str) -> dict:
    """Build the Brave/Chromium theme manifest dict."""
    theme_colors = {}
    for slot, matugen_key in MAPPING.items():
        theme_colors[slot] = get_color(colors, matugen_key, mode)

    return {
        "manifest_version": 3,
        "name": "DMS Dynamic Theme",
        "version": "1.0",
        "description": "Auto-generated from DankMaterialShell palette",
        "theme": {
            "colors": theme_colors,
            "images": {},
            "properties": {
                "theme_colors": {
                    "primary": colors.get(mode, {}).get("primary", "#000000"),
                    "surface": colors.get(mode, {}).get("surface", "#000000"),
                }
            },
        },
    }


def write_theme(mode: str | None = None) -> bool:
    """Read dms-colors.json, write manifest.json. Returns True if changed."""
    if not DMS_COLORS.exists():
        print(f"✗ {DMS_COLORS} not found. Is DMS running?")
        return False

    data = json.loads(DMS_COLORS.read_text())
    colors = data.get("colors", {})

    # Use explicit --mode, or fall back to the "mode" field in the JSON
    if mode is None:
        mode = data.get("mode", "dark")

    manifest = build_manifest(colors, mode)
    THEME_DIR.mkdir(parents=True, exist_ok=True)

    new_content = json.dumps(manifest, indent=2)
    old_content = MANIFEST.read_text() if MANIFEST.exists() else ""

    if new_content != old_content:
        MANIFEST.write_text(new_content)
        print(f"✓ Theme updated ({mode}) → {MANIFEST}")
        return True
    return False


def watch(interval: float = 2.0):
    """Poll dms-colors.json and regenerate on change."""
    print(f"Watching {DMS_COLORS} every {interval}s …")
    last_hash = None
    try:
        while True:
            if DMS_COLORS.exists():
                h = hashlib.md5(DMS_COLORS.read_bytes()).hexdigest()
                if h != last_hash:
                    write_theme()
                    last_hash = h
            time.sleep(interval)
    except KeyboardInterrupt:
        print("\nStopped.")


def apply_chromium() -> None:
    """Set BrowserThemeColor on all installed Chromium-based browsers via policy."""
    if not DMS_COLORS.exists():
        print(f"✗ {DMS_COLORS} not found")
        return

    data = json.loads(DMS_COLORS.read_text())
    mode = data.get("mode", "dark")
    surface_hex = data["colors"][mode]["surface"].lstrip("#")

    browsers = [
        ("chromium", Path("/etc/chromium/policies/managed")),
        ("brave", Path("/etc/brave/policies/managed")),
        ("google-chrome-stable", Path("/etc/opt/chrome/policies/managed")),
    ]

    for cmd, policy_dir in browsers:
        if shutil.which(cmd) is None:
            continue
        if not policy_dir.is_dir():
            subprocess.run(["sudo", "-n", "mkdir", "-p", str(policy_dir)], stderr=subprocess.DEVNULL)
        if not policy_dir.is_dir():
            print(f"⚠ Unable to create {policy_dir}")
            continue

        subprocess.run(
            ["sudo", "-n", "tee", str(policy_dir / "dms-theme.json")],
            input=json.dumps(
                {
                    "BrowserThemeColor": f"#{surface_hex}",
                    "BrowserColorScheme": "device",
                }
            ),
            text=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        subprocess.run(
            [cmd, "--refresh-platform-policy", "--no-startup-window"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        print(f"✓ {cmd} → #{surface_hex} ({mode})")


def main():
    mode = None
    watch_mode = False

    args = sys.argv[1:]
    if "--watch" in args:
        watch_mode = True
        args.remove("--watch")
    if "--mode" in args:
        i = args.index("--mode")
        if i + 1 < len(args):
            mode = args[i + 1]
            args[i : i + 2] = []

    if watch_mode:
        watch()
    else:
        if not apply_chromium():
            sys.exit(0)


if __name__ == "__main__":
    main()
DMS_COLORS = Path.home() / ".cache" / "dms" / "dms-colors.json"
