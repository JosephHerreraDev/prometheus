import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml
import "../theme"

Pill {
  id: root

  property QtObject nord: Nord {}

  property var shellScreen
  property var hyprMonitor: shellScreen ? Hyprland.monitorFor(shellScreen) : null

  implicitWidth: row.implicitWidth + 14
  implicitHeight: 28

  function appClass(toplevel) {
    if (toplevel.wayland && toplevel.wayland.appId) {
      return toplevel.wayland.appId.toLowerCase()
    }

    if (toplevel.lastIpcObject && toplevel.lastIpcObject.class) {
      return toplevel.lastIpcObject.class.toLowerCase()
    }

    if (toplevel.lastIpcObject && toplevel.lastIpcObject.initialClass) {
      return toplevel.lastIpcObject.initialClass.toLowerCase()
    }

    if (toplevel.title) {
      return toplevel.title.toLowerCase()
    }

    return ""
  }

  function iconSource(toplevel) {
    const cls = appClass(toplevel)

    const customIcons = {
      "brave-origin": "browser.svg",
      "spotify": "music.svg",
      "obsidian": "pencil.svg",
      "kitty": "terminal.svg",
      "org.pwmt.zathura": "book.svg",
    }

    if (customIcons[cls]) {
      return Qt.resolvedUrl("../icons/" + customIcons[cls])
    }

    return Qt.resolvedUrl("../icons/box.svg")
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 5

    Repeater {
      model: Hyprland.workspaces

      Rectangle {
        id: workspaceButton

        required property var modelData
        property var workspace: modelData

        visible: workspace.id > 0
          && root.hyprMonitor !== null
          && workspace.monitor !== null
          && workspace.monitor.name === root.hyprMonitor.name

        Layout.preferredWidth: content.implicitWidth + 12
        Layout.preferredHeight: 24

        radius: 6

        color: workspace.focused
          ? root.nord.nord2
          : workspace.active
            ? root.nord.nord1
            : root.nord.nord0

        border.width: workspace.focused ? 2 : 1

        border.color: workspace.focused
          ? root.nord.nord8
          : workspace.active
            ? root.nord.nord10
            : root.nord.nord3

        RowLayout {
          id: content

          anchors.centerIn: parent
          spacing: 5

          Text {
            text: workspaceButton.workspace.name

            font.pixelSize: 12
            font.weight: workspaceButton.workspace.focused
              ? Font.DemiBold
              : Font.Medium

            color: workspaceButton.workspace.focused
              ? root.nord.nord6
              : root.nord.nord4
          }

          Repeater {
            model: workspaceButton.workspace.toplevels

            Item {
              required property var modelData

              Layout.preferredWidth: 15
              Layout.preferredHeight: 15

              IconImage {
                id: rawIcon

                anchors.fill: parent
                source: root.iconSource(modelData)

                // Hidden because MultiEffect draws the tinted version.
                visible: false
              }

              MultiEffect {
                anchors.fill: parent
                source: rawIcon

                colorization: 1.0
                colorizationColor: workspaceButton.workspace.focused
                  ? root.nord.nord8
                  : root.nord.nord4
              }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor

          onClicked: workspaceButton.workspace.activate()
        }
      }
    }
  }
}
