import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
  id: root

  property QtObject menuState
  property QtObject theme: Theme {}
  property bool opened: false
  property bool mounted: false
  property int selectedIndex: 0
  property int focusRequest: 0
  property var actions: [
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
      command: "prometheus-system-logout"
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

  readonly property int animationDuration: 140

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
    menuState.active = "powermenu"
    selectedIndex = 0
    Qt.callLater(function() {
      if (menuState.active === "powermenu") {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    opened = false
    hideTimer.restart()
    if (menuState.active === "powermenu") {
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

  function run(command) {
    if (!command || command.length === 0) {
      return
    }

    close()
    Quickshell.execDetached(["sh", "-c", command])
  }

  function requestFocus(): void {
    focusRequest += 1
  }

  function moveSelection(delta) {
    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, actions.length - 1))
  }

  function runSelected(): void {
    if (selectedIndex >= 0 && selectedIndex < actions.length) {
      run(actions[selectedIndex].command)
    }
  }

  IpcHandler {
    target: "powermenu"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: menuState

    function onActiveChanged(): void {
      if (menuState.active === "powermenu") {
        hideTimer.stop()
        root.mounted = true
        Qt.callLater(function() {
          if (menuState.active === "powermenu") {
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
      WlrLayershell.namespace: "prometheus-powermenu"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      onVisibleChanged: {
        if (visible) {
          focusPanel()
        }
      }

      function focusPanel(): void {
        Qt.callLater(function() {
          panel.forceActiveFocus()
        })
      }

      Connections {
        target: root

        function onFocusRequestChanged(): void {
          if (window.visible) {
            window.focusPanel()
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
        width: Math.min(500, window.width - 40)
        implicitHeight: content.implicitHeight + 32
        anchors.centerIn: parent

        radius: 8
        color: root.theme.color0
        border.width: 1
        border.color: root.theme.color2
        focus: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Right) {
            root.moveSelection(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.moveSelection(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.moveSelection(window.width < 520 ? 2 : 3)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.moveSelection(window.width < 520 ? -2 : -3)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.runSelected()
            event.accepted = true
          } else if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
          }
        }

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
              model: root.actions

              Rectangle {
                id: actionButton

                required property int index
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 74

                radius: 8
                color: actionButton.index === root.selectedIndex || actionMouse.containsMouse ? root.theme.color1 : root.theme.color2
                border.width: 1
                border.color: actionButton.index === root.selectedIndex || actionMouse.containsMouse
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
                  onEntered: root.selectedIndex = actionButton.index
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
