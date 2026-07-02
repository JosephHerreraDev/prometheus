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

  property var shellScreen
  property var hyprMonitor: shellScreen ? Hyprland.monitorFor(shellScreen) : null

  implicitWidth: row.implicitWidth + root.margin * 2
  implicitHeight: row.implicitHeight + root.margin * 2

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
    spacing: 1

    Repeater {
      model: Hyprland.workspaces

      BarButton {
        id: workspaceButton

        required property var modelData
        property var workspace: modelData

        visible: workspace.id > 0
          && root.hyprMonitor !== null
          && workspace.monitor !== null
          && workspace.monitor.name === root.hyprMonitor.name

        Layout.preferredWidth: content.implicitWidth + 12
        Layout.preferredHeight: 24

        buttonColor: workspace.focused
          ? root.theme.color2
          : workspace.active
            ? root.theme.color1
            : root.theme.color0

        buttonBorderWidth: workspace.focused ? 2 : 1

        buttonBorderColor: workspace.focused
          ? root.theme.color8
          : workspace.active
            ? root.theme.color10
            : root.theme.color3

        onClicked: workspaceButton.workspace.activate()

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
              ? root.theme.color6
              : root.theme.color4
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

                visible: true
                opacity: 0.0
              }

              MultiEffect {
                anchors.fill: rawIcon
                source: rawIcon

                colorization: 1.0
                colorizationColor: workspaceButton.workspace.focused
                  ? root.theme.color8
                  : root.theme.color4

                brightness: 1.0
              }
            }
          }
        }
      }
    }
  }
}
