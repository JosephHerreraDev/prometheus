import Quickshell
import QtQuick

import "bar" as Bar
import "powermenu" as PowerMenu
import "wallpaper" as Wallpaper

ShellRoot {
  Bar.Bar {}

  Bar.NotificationManager {}

  PowerMenu.PowerMenu {}

  Wallpaper.WallpaperSelector {}
}
