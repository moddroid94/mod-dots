-- Machine-specific greeter settings, loaded by hyprland.lua.
-- install.sh creates /etc/caelestia-greeter/local.lua from this file (or from ./local.lua
-- if present) and keeps it across reinstalls.

-- Monitors: copy the hl.monitor blocks from your own Hyprland config.
hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080", position = "1920x0", scale = 1 })


-- User preselected until someone has logged in; after that the last user is remembered.
-- install.sh fills this in with the user who ran sudo.
hl.env("CAELESTIA_GREETER_USER", "sam")

-- Monitor that shows the login card (others show the wallpaper). Defaults to the first one.
hl.env("CAELESTIA_GREETER_MONITOR", "DP-1")

-- Session to start after login.
hl.env("CAELESTIA_GREETER_SESSION", "start-hyprland -c /home/sam/.config/hypr/hyprland.lua &> /dev/null")

-- Avatar shape: a MaterialShape name, or several separated by commas to pick one at random
-- on each start (default Cookie9Sided). E.g. Square, Cookie7Sided, Cookie12Sided, Sunny, Gem.
-- hl.env("CAELESTIA_GREETER_AVATAR_SHAPE", "Cookie7Sided,Cookie9Sided,Cookie12Sided")
