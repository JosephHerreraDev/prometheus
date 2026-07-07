import Quickshell
import QtQuick

import "bar" as Bar
import "launcher" as Launcher
import "osd" as Osd
import "powermenu" as PowerMenu
import "screenshot-menu" as ScreenshotMenu
import "theme-selector" as ThemeSelector
import "theme-wallpaper" as ThemeWallpaper
import "wallpaper" as Wallpaper

ShellRoot {
  QtObject {
    id: menuState

    property string active: ""
  }

  Bar.Bar {}

  Bar.NotificationManager {}

  Osd.ControlOsd {}

  Launcher.Launcher {
    menuState: menuState
  }

  PowerMenu.PowerMenu {
    menuState: menuState
  }

  ScreenshotMenu.ScreenshotMenu {
    menuState: menuState
  }

  ThemeSelector.ThemeSelector {
    menuState: menuState
  }

  ThemeWallpaper.ThemeWallpaperSelector {
    menuState: menuState
  }

  Wallpaper.WallpaperSelector {
    menuState: menuState
  }
}
