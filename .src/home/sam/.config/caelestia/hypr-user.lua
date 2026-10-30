require("/home/sam/.config/hypr/hyprland-gui.lua")

hl.env("QS_ICON_THEME", "Papirus")

hl.workspace_rule({ workspace = "1", monitor = "DP-1" })


hl.bind("SUPER + ALT + F12", hl.dsp.exec_cmd("/home/sam/.local/bin/reload_caelestia.sh"))

hl.unbind("SUPER + SHIFT + S")
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"))

hl.bind("SUPER + Space", hl.dsp.exec_cmd("vicinae toggle"))

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
-- blur
hl.layer_rule({
  match = { namespace = "vicinae" },
  name = "vicinae-blur",
  blur = false,
  ignore_alpha = 0,
})
