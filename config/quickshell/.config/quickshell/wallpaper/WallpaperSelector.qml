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

  property QtObject theme: Theme {}
  property bool opened: false
  property var wallpapers: []
  property string statusText: ""

  readonly property string helper: Quickshell.shellPath("wallpaper/wallpaperctl")

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    opened = true
    refresh()
  }

  function close(): void {
    opened = false
  }

  function toggle(): void {
    if (opened) {
      close()
    } else {
      open()
    }
  }

  function refresh(): void {
    statusText = "Loading wallpapers..."
    listProcess.exec([helper, "list"])
  }

  function applyWallpaper(path) {
    if (!path || path.length === 0) {
      return
    }

    Quickshell.execDetached([helper, "apply", path])
    close()
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
    target: "wallpaper"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Process {
    id: listProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        root.wallpapers = root.parseList(text)
        root.statusText = root.wallpapers.length === 0
          ? "No wallpapers found in ~/Pictures/wallpapers/general"
          : ""
      }
    }

    stderr: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (text.length > 0) {
          console.warn("Wallpaper list failed: " + text)
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.wallpapers = []
        root.statusText = "Could not load wallpapers"
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: root.opened && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: true
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.opened
        onClicked: root.close()
      }

      Rectangle {
        id: panel

        width: Math.min(760, window.width - 40)
        height: Math.min(560, window.height - 80)
        anchors.centerIn: parent

        radius: 8
        color: root.theme.color0
        border.width: 1
        border.color: root.theme.color2

        MouseArea {
          anchors.fill: parent
          onClicked: function(mouse) { mouse.accepted = true }
          onWheel: function(wheel) { wheel.accepted = true }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 12

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
              text: "Wallpapers"
              color: root.theme.color6
              font.pixelSize: 16
              font.weight: Font.DemiBold
              Layout.fillWidth: true
            }
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

            visible: root.statusText.length === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            model: root.wallpapers
            cellWidth: 178
            cellHeight: 148
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              required property var modelData

              width: grid.cellWidth - 10
              height: grid.cellHeight - 10
              radius: 8
              color: tileMouse.containsMouse ? root.theme.color1 : root.theme.color2
              border.width: 1
              border.color: tileMouse.containsMouse ? root.theme.color8 : root.theme.color3

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Image {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  source: "file://" + encodeURI(modelData.path)
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  cache: false

                  Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: root.theme.color3
                  }
                }

                Text {
                  Layout.fillWidth: true
                  text: modelData.name
                  color: root.theme.color6
                  font.pixelSize: 11
                  elide: Text.ElideMiddle
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
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
