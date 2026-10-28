require("/home/sam/.config/hypr/hyprland-gui.lua")

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })


hl.bind("SUPER + ALT + F12", hl.dsp.exec_cmd("/home/sam/.local/bin/reload_caelestia.sh"))   