import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Scope {
  id: root

  property QtObject menuState
  property QtObject theme: Theme {}
  property bool opened: false
  property bool mounted: false
  property var wallpapers: []
  property string statusText: ""
  property int selectedIndex: -1
  property int focusRequest: 0

  readonly property int animationDuration: 140
  readonly property string helper: Quickshell.shellPath("theme-wallpaper/theme-wallpaperctl")

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    hideTimer.stop()
    mounted = true
    opened = false
    menuState.active = "theme-wallpaper"
    refresh()
    Qt.callLater(function() {
      if (menuState.active === "theme-wallpaper") {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    opened = false
    hideTimer.restart()
    if (menuState.active === "theme-wallpaper") {
      menuState.active = ""
    }
  }

  function toggle(): void {
    if (opened) {
      close()
    } else {
      open()
    }
  }

  function refresh(): void {
    statusText = "Loading theme wallpapers..."
    listProcess.exec([helper, "list"])
  }

  function requestFocus(): void {
    focusRequest += 1
  }

  function applyWallpaper(path) {
    if (!path || path.length === 0) {
      return
    }

    Quickshell.execDetached([helper, "apply", path])
    close()
  }

  function selectedWallpaper() {
    if (selectedIndex >= 0 && selectedIndex < wallpapers.length) {
      return wallpapers[selectedIndex]
    }

    return null
  }

  function applySelected(): void {
    const item = selectedWallpaper()

    if (item !== null) {
      applyWallpaper(item.path)
    }
  }

  function moveSelection(delta) {
    if (wallpapers.length === 0) {
      selectedIndex = -1
      return
    }

    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, wallpapers.length - 1))
  }

  function fileName(path) {
    const parts = path.split("/")
    return parts.length === 0 ? path : parts[parts.length - 1]
  }

  function parseList(text) {
    const lines = text.split("\n")
    const results = []

    for (let i = 0; i < lines.length; i++) {
      const path = lines[i]

      if (path.length > 0) {
        results.push({
          path: path,
          name: fileName(path)
        })
      }
    }

    return results
  }

  IpcHandler {
    target: "themewallpaper"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: menuState

    function onActiveChanged(): void {
      if (menuState.active === "theme-wallpaper") {
        hideTimer.stop()
        root.mounted = true
        Qt.callLater(function() {
          if (menuState.active === "theme-wallpaper") {
            root.opened = true
            root.requestFocus()
          }
        })
      } else if (root.opened) {
        root.opened = false
        hideTimer.restart()
      }
    }
  }

  Timer {
    id: hideTimer

    interval: root.animationDuration
    repeat: false
    onTriggered: {
      if (!root.opened) {
        root.mounted = false
      }
    }
  }

  Process {
    id: listProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        root.wallpapers = root.parseList(text)
        root.selectedIndex = root.wallpapers.length > 0 ? 0 : -1
        root.statusText = root.wallpapers.length === 0
          ? "No wallpapers found for the current theme"
          : ""
      }
    }

    stderr: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (text.length > 0) {
          console.warn("Theme wallpaper list failed: " + text)
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.wallpapers = []
        root.selectedIndex = -1
        root.statusText = "Could not load theme wallpapers"
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: root.mounted && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "prometheus-theme-wallpaper"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      onVisibleChanged: {
        if (visible) {
          focusGrid()
        }
      }

      function focusGrid(): void {
        Qt.callLater(function() {
          grid.forceActiveFocus()
        })
      }

      Connections {
        target: root

        function onFocusRequestChanged(): void {
          if (window.visible) {
            window.focusGrid()
          }
        }
      }

      Rectangle {
        id: scrim

        anchors.fill: parent
        color: "#66000000"
        opacity: root.opened ? 1.0 : 0.0

        Behavior on opacity {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.opened
          onClicked: root.close()
        }
      }

      Rectangle {
        id: panel

        opacity: root.opened ? 1.0 : 0.0
        scale: root.opened ? 1.0 : 0.96
        width: Math.min(780, window.width - 40)
        height: Math.min(600, window.height - 80)
        anchors.centerIn: parent

        radius: 8
        color: root.theme.color0
        border.width: 1
        border.color: root.theme.color2

        Behavior on opacity {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        Behavior on scale {
          NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
          onWheel: function(wheel) { wheel.accepted = true }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 12

          Text {
            text: "Theme Wallpapers"
            color: root.theme.color6
            font.pixelSize: 16
            font.weight: Font.DemiBold
            Layout.fillWidth: true
          }

          Text {
            visible: root.statusText.length > 0
            text: root.statusText
            color: root.theme.color4
            font.pixelSize: 13
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillHeight: true
          }

          GridView {
            id: grid

            property int columnCount: Math.max(1, Math.floor(width / 190))

            visible: root.statusText.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: root.wallpapers
            cellWidth: Math.floor(width / columnCount)
            cellHeight: 132
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right) {
                root.moveSelection(1)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Left) {
                root.moveSelection(-1)
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                root.moveSelection(Math.max(1, Math.floor(grid.width / grid.cellWidth)))
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up) {
                root.moveSelection(-Math.max(1, Math.floor(grid.width / grid.cellWidth)))
                grid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.applySelected()
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: grid.contentHeight > grid.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
              id: tile

              required property int index
              required property var modelData

              width: grid.cellWidth - 12
              height: grid.cellHeight - 12
              radius: 8
              color: root.theme.color1
              border.width: 1
              border.color: GridView.isCurrentItem || tileMouse.containsMouse ? root.theme.color8 : root.theme.color3

              Rectangle {
                id: preview

                anchors.fill: parent
                anchors.margins: 5
                radius: 6
                clip: true
                color: root.theme.color0

                Image {
                  anchors.fill: parent
                  source: "file://" + encodeURI(modelData.path)
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  cache: false
                  smooth: true
                  mipmap: true
                }

                Rectangle {
                  anchors.fill: parent
                  color: "#00000000"
                  border.width: 1
                  border.color: tile.GridView.isCurrentItem || tileMouse.containsMouse ? root.theme.color6 : "#00000000"
                }

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  height: 28
                  visible: tile.GridView.isCurrentItem || tileMouse.containsMouse
                  gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#99000000" }
                  }
                }
              }

              MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = tile.index
                onClicked: root.applyWallpaper(modelData.path)
              }
            }
          }
        }
      }

      Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: root.close()
      }
    }
  }
}
