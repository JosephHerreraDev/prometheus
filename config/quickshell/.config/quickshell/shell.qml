import Quickshell
import QtQuick

import "bar" as Bar
import "connectivity" as Connectivity
import "clipboard" as Clipboard
import "install-menu" as InstallMenu
import "launcher" as Launcher
import "osd" as Osd
import "powermenu" as PowerMenu
import "screenshot-menu" as ScreenshotMenu
import "system" as System
import "theme-selector" as ThemeSelector
import "theme-wallpaper" as ThemeWallpaper
import "wallpaper" as Wallpaper

ShellRoot {
  QtObject {
    id: menuState

    property string active: ""
  }

  System.SystemState {
    id: systemState
  }

  Bar.Bar {
    systemState: systemState
  }

  Bar.NotificationManager {}

  Connectivity.RadioPanel { menuState: menuState; kind: "wifi" }
  Connectivity.RadioPanel { menuState: menuState; kind: "bluetooth" }

  Osd.ControlOsd {
    systemState: systemState
  }

  Launcher.Launcher {
    menuState: menuState
  }

  Clipboard.ClipboardHistory {
    menuState: menuState
  }

  InstallMenu.InstallMenu {
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
