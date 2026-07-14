-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
--  hl.exec_cmd(terminal)
  hl.exec_cmd("quickshell")
  hl.exec_cmd("hyprpaper")
  hl.exec_cmd(os.getenv("HOME") .. "/.local/share/prometheus/bin/prometheus-clipboard-watch restart")
--  hl.exec_cmd("nm-applet")
--  hl.exec_cmd("waybar & hyprpaper & firefox")
end)
