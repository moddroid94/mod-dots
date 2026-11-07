-- DMS Window Rules — managed by Dux Shell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, float = true })

-- DMS-RULE: id=wr_1793578184682246320, name=brave-browse
hl.window_rule({ match = { class = "^brave-browser$", title = "^Picture in picture$" }, float = true, size = { 600, 400 }, move = { 1300, 630 } })

-- DMS-RULE: id=wr_1793683024571230422, name=org.localsend.localsend_app
hl.window_rule({ match = { class = "^org.localsend.localsend_app$" }, float = true, size = { 800, 500 } })

-- DMS-RULE: id=wr_1793741420846864373, name=zen
hl.window_rule({ match = { class = "^zen$", title = "^Picture-in-Picture$" }, float = true, size = { 600, 400 }, move = { 1300, 600 } })

-- DMS-RULE: id=wr_1793803873144526764, name=org.keepassxc.KeePassXC
hl.window_rule({ match = { class = "^org.keepassxc.KeePassXC$", title = "^Generate Password$" }, float = true })

-- DMS-RULE: id=dms-window-opaque, name=DMS Window Opaque
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, opaque = true })
