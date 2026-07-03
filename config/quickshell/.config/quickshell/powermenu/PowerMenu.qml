import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
  id: root

  property QtObject theme: Theme {}
  property bool opened: false

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function open(): void {
    opened = true
  }

  function close(): void {
    opened = false
  }

  function toggle(): void {
    opened = !opened
  }

  function run(command) {
    if (!command || command.length === 0) {
      return
    }

    close()
    Quickshell.execDetached(["sh", "-c", command])
  }

  IpcHandler {
    target: "powermenu"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
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
      WlrLayershell.namespace: "prometheus-powermenu"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Rectangle {
        anchors.fill: parent
        color: "#66000000"

        MouseArea {
          anchors.fill: parent
          enabled: root.opened
          onClicked: root.close()
        }
      }

      Rectangle {
        id: panel

        width: Math.min(500, window.width - 40)
        implicitHeight: content.implicitHeight + 32
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
          id: content

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
          }

          spacing: 14

          Text {
            Layout.fillWidth: true
            text: "Power"
            color: root.theme.color6
            font.pixelSize: 16
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }

          GridLayout {
            Layout.fillWidth: true
            columns: window.width < 520 ? 2 : 3
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
              model: [
                {
                  label: "Lock",
                  detail: "Lock session",
                  command: "hyprlock"
                },
                {
                  label: "Suspend",
                  detail: "Sleep",
                  command: "systemctl suspend"
                },
                {
                  label: "Hibernate",
                  detail: "Disk sleep",
                  command: "systemctl hibernate"
                },
                {
                  label: "Logout",
                  detail: "End session",
                  command: "uwsm stop"
                },
                {
                  label: "Restart",
                  detail: "Reboot",
                  command: "systemctl reboot --no-wall"
                },
                {
                  label: "Shutdown",
                  detail: "Power off",
                  command: "systemctl poweroff --no-wall",
                  danger: true
                }
              ]

              Rectangle {
                id: actionButton

                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 74

                radius: 8
                color: actionMouse.containsMouse ? root.theme.color1 : root.theme.color2
                border.width: 1
                border.color: actionMouse.containsMouse
                  ? (modelData.danger === true ? root.theme.color11 : root.theme.color8)
                  : root.theme.color3

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: actionButton.modelData.label
                    color: actionButton.modelData.danger === true
                      ? root.theme.color11
                      : root.theme.color6
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                  }

                  Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: actionButton.modelData.detail
                    color: root.theme.color4
                    font.pixelSize: 11
                  }
                }

                MouseArea {
                  id: actionMouse

                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.run(actionButton.modelData.command)
                }
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
