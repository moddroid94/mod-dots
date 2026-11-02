-- DMS Window Rules — managed by Dux Shell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, float = true })

-- DMS-RULE: id=wr_1793578184682246320, name=brave-browse
hl.window_rule({ match = { class = "^brave-browser$", title = "^Picture in picture$" }, float = true, size = { 600, 400 }, move = { 1300, 630 } })

-- DMS-RULE: id=wr_1793621941966540482, name=dev.duxlabs.files
hl.window_rule({ match = { class = "^dev.duxlabs.files$" } })

-- DMS-RULE: id=dms-window-opaque, name=DMS Window Opaque
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, opaque = true })
