"""Adjust display luminance for External and Laptop monitors"""

import json
import logging
from pathlib import Path

logger = logging.getLogger("lnxlink")


class Addon:
    """Addon module"""

    def __init__(self, lnxlink=None):
        """Setup addon"""
        self.name = "hypr_color"
        self.lnxlink = lnxlink
        self.theme = None

    def get_info(self):
        """Gather information from the system"""
        abs_path = Path(".local/state/caelestia/scheme.json").resolve(strict=True)
        try:
            with open(abs_path, encoding="utf-8") as file:
                self.theme = json.load(file)

        except FileNotFoundError:
            logger.error("Can't read scheme.json file")
        if self.theme["colours"]["primary"]:
            return "#" + self.theme["colours"]["primary"]
        else:
            return "Unknown"

    def exposed_controls(self):
        """Exposes to home assistant"""
        return {
            "Theme Accent": {
                "type": "text",
                "icon": "mdi:palette",
            },
        }
