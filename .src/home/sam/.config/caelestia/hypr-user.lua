require("/home/sam/.config/hypr/hyprland-gui.lua")

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })


hl.bind("SUPER + ALT + F12", hl.dsp.exec_cmd("/home/sam/.local/bin/reload_caelestia.sh"))

hl.unbind("SUPER + SHIFT + S")
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"))

hl.window_rule({
    match = { class = "^(org.gnome.Loupe)$" },
    float = true,
    center = true,
})
hl.window_rule({
    match = { class = "^(com.gabm.satty)$" },
    float = true,
    center = true,
})