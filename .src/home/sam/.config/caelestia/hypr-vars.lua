

return {
  -- Changing default apps:
  browser          = "brave",
  editor           = "vscodium",

  singleWindowGapsOut        = 15,

  

  hl.on("hyprland.start", function ()
    hl.timer(function()
      hl.exec_cmd("localsend --hidden")
      hl.exec_cmd("keepassxc")
      hl.exec_cmd("/home/sam/.local/bin/dpms-guard.sh")
      hl.exec_cmd("flatpak run com.cassidyjames.butler", { workspace = "special:special silent" })
      hl.exec_cmd("/home/sam/.local/bin/Music.Assistant_0.6.8_amd64.AppImage", { workspace = "special:music silent" })
      hl.exec_cmd("/home/sam/.local/bin/Easy_Effects-8.3.0-anylinux-x86_64.AppImage", { workspace = "2 silent" })
      hl.exec_cmd("sh -c 'touch /run/user/$(id -u)/caelestia-ready'")
    end, { timeout = 4000, type = "oneshot" })
  end)

}