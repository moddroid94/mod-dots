"""Expose theme color scheme accent to Home Assistant"""

import logging
from pathlib import Path

# Built-in in Python 3.11+, fallback to tomli for older versions if available
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        tomllib = None

logger = logging.getLogger("lnxlink")

# Path to the scheme file (adjust the filename if needed)
SCHEME_PATH = Path.home() / ".local/share/basetemplate/themes/matugen.toml"


class Addon:
    """Addon module"""

    def __init__(self, lnxlink=None):
        """Setup addon"""
        self.name = "hypr_color"
        self.lnxlink = lnxlink
        self.theme = {}

    def _parse_file(self, path: Path) -> dict:
        """Parse colors from TOML or space-separated key-value file"""
        # Try standard TOML parser first
        if tomllib is not None:
            try:
                with open(path, "rb") as file:
                    return tomllib.load(file)
            except Exception:
                pass

        # Fallback line-by-line parser (handles files formatted without '=')
        colors = {}
        with open(path, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if not line or line.startswith(("#", ";", "[")):
                    continue
                # Split by '=' or whitespace
                if "=" in line:
                    parts = line.split("=", 1)
                else:
                    parts = line.split(None, 1)

                if len(parts) == 2:
                    key = parts[0].strip()
                    val = parts[1].strip().strip("\"'")
                    colors[key] = val
        return colors

    def get_info(self):
        """Gather information from the system"""
        path = SCHEME_PATH
        if not path.exists():
            # Check relative path as fallback
            path = Path(".local/state/caelestia/scheme.toml")

        try:
            self.theme = self._parse_file(path)
        except FileNotFoundError:
            logger.error("Can't read scheme file: %s", path)
            return "Unknown"
        except Exception as err:
            logger.error("Error loading scheme file: %s", err)
            return "Unknown"

        # Look for 'accent' key
        accent = self.theme.get("accent")

        # Fallback if the file is structured as nested TOML [colors.primary.default]
        if not accent and "colors" in self.theme:
            try:
                accent = self.theme["colors"]["primary"]["default"]["hex"]
            except (KeyError, TypeError):
                pass

        if accent:
            accent = str(accent).strip().strip("\"'")
            if not accent.startswith("#"):
                accent = f"#{accent}"
            return accent

        return "Unknown"

    def exposed_controls(self):
        """Exposes to home assistant"""
        return {
            "Theme Accent": {
                "type": "text",
                "icon": "mdi:palette",
            },
        }
