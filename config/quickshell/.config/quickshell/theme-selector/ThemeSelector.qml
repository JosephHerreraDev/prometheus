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
  property string query: ""
  property string currentTheme: "Unknown"
  property string statusText: ""
  property var themes: []
  property var filteredThemes: []
  property int focusRequest: 0
  property int selectedIndex: -1

  readonly property int animationDuration: 140
  readonly property int maxVisibleResults: 12
  readonly property string helper: Quickshell.shellPath("theme-selector/themectl")

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
    menuState.active = "theme"
    query = ""
    refresh()
    Qt.callLater(function() {
      if (menuState.active === "theme") {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    opened = false
    hideTimer.restart()
    if (menuState.active === "theme") {
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

  function requestFocus(): void {
    focusRequest += 1
  }

  function refresh(): void {
    statusText = "Loading themes..."
    currentProcess.exec([helper, "current"])
    listProcess.exec([helper, "list"])
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    const results = []

    for (let i = 0; i < themes.length; i++) {
      const item = themes[i]

      if (needle.length === 0 || item.search.indexOf(needle) !== -1) {
        results.push(item)
      }
    }

    filteredThemes = results
    selectedIndex = filteredThemes.length > 0 ? 0 : -1
  }

  function parseList(text) {
    const lines = text.split("\n")
    const results = []

    for (let i = 0; i < lines.length; i++) {
      const parts = lines[i].split("\t")
      const name = parts.length > 0 ? parts[0].trim() : ""
      const colors = parts.length > 1 && parts[1].trim().length > 0
        ? parts[1].trim().split(",")
        : []

      if (name.length > 0) {
        results.push({
          name: name,
          search: name.toLowerCase(),
          current: name === currentTheme,
          colors: colors
        })
      }
    }

    return results
  }

  function selectedTheme() {
    if (selectedIndex >= 0 && selectedIndex < filteredThemes.length) {
      return filteredThemes[selectedIndex]
    }

    return null
  }

  function applyTheme(item) {
    if (item === null || item.name.length === 0) {
      return
    }

    close()
    Quickshell.execDetached([helper, "set", item.name])
  }

  onQueryChanged: filter()
  onCurrentThemeChanged: {
    themes = themes.map(function(item) {
      return {
        name: item.name,
        search: item.search,
        current: item.name === currentTheme,
        colors: item.colors
      }
    })
    filter()
  }

  IpcHandler {
    target: "theme"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: menuState

    function onActiveChanged(): void {
      if (menuState.active === "theme") {
        hideTimer.stop()
        root.mounted = true
        Qt.callLater(function() {
          if (menuState.active === "theme") {
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
    id: currentProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: root.currentTheme = text.trim()
    }
  }

  Process {
    id: listProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        root.themes = root.parseList(text)
        root.statusText = root.themes.length === 0 ? "No themes found" : ""
        root.filter()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (text.length > 0) {
          console.warn("Theme list failed: " + text)
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.themes = []
        root.filteredThemes = []
        root.statusText = "Could not load themes"
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
      WlrLayershell.namespace: "prometheus-theme-selector"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      onVisibleChanged: {
        if (visible) {
          focusInput()
        }
      }

      function focusInput(): void {
        Qt.callLater(function() {
          input.forceActiveFocus()
          input.selectAll()
        })
      }

      Connections {
        target: root

        function onFocusRequestChanged(): void {
          if (window.visible) {
            window.focusInput()
          }
        }
      }

      Rectangle {
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
        opacity: root.opened ? 1.0 : 0.0
        scale: root.opened ? 1.0 : 0.96
        width: Math.min(620, window.width - 40)
        implicitHeight: content.implicitHeight + 28
        anchors {
          top: parent.top
          topMargin: Math.max(88, Math.round(window.height * 0.18))
          horizontalCenter: parent.horizontalCenter
        }

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
          id: content

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
          }

          spacing: 10

          TextField {
            id: input

            Layout.fillWidth: true
            text: root.query
            placeholderText: "Select theme"
            selectByMouse: true
            color: root.theme.color6
            placeholderTextColor: root.theme.color4
            font.pixelSize: 18
            background: Rectangle {
              radius: 8
              color: root.theme.color1
              border.width: 1
              border.color: input.activeFocus ? root.theme.color8 : root.theme.color3
            }

            onTextChanged: root.query = text
            onAccepted: root.applyTheme(root.selectedTheme())

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down && root.filteredThemes.length > 0) {
                root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredThemes.length - 1)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up && root.filteredThemes.length > 0) {
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }
          }

          Text {
            visible: root.statusText.length > 0 || root.filteredThemes.length === 0
            Layout.fillWidth: true
            text: root.statusText.length > 0 ? root.statusText : "No matches"
            color: root.theme.color4
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
          }

          ListView {
            id: resultsList

            visible: root.statusText.length === 0 && root.filteredThemes.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.filteredThemes.length, root.maxVisibleResults) * 48
            clip: true
            interactive: root.filteredThemes.length > root.maxVisibleResults
            currentIndex: root.selectedIndex
            model: root.filteredThemes
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: {
              if (currentIndex >= 0) {
                positionViewAtIndex(currentIndex, ListView.Contain)
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: root.filteredThemes.length > root.maxVisibleResults
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
              id: row

              required property int index
              required property var modelData

              width: resultsList.width
              height: 48
              radius: 8
              color: ListView.isCurrentItem || rowMouse.containsMouse
                ? root.theme.color2
                : "transparent"
              border.width: ListView.isCurrentItem ? 1 : 0
              border.color: root.theme.color8

              RowLayout {
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  bottom: parent.bottom
                  leftMargin: 12
                  rightMargin: 12
                }

                spacing: 10

                Rectangle {
                  Layout.preferredWidth: 14
                  Layout.preferredHeight: 14
                  Layout.alignment: Qt.AlignVCenter
                  radius: 7
                  color: row.modelData.current ? root.theme.color8 : root.theme.color3
                  border.width: 1
                  border.color: row.modelData.current ? root.theme.color6 : root.theme.color4
                }

                Text {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  text: row.modelData.name
                  color: row.modelData.current || ListView.isCurrentItem ? root.theme.color6 : root.theme.color4
                  font.pixelSize: 14
                  font.weight: row.modelData.current ? Font.DemiBold : Font.Normal
                  elide: Text.ElideRight
                }

                RowLayout {
                  Layout.alignment: Qt.AlignVCenter
                  spacing: -3

                  Repeater {
                    model: row.modelData.colors

                    Rectangle {
                      required property var modelData

                      Layout.preferredWidth: 12
                      Layout.preferredHeight: 12
                      radius: 6
                      color: modelData
                      border.width: 1
                      border.color: root.theme.color3
                    }
                  }
                }

                Text {
                  visible: row.modelData.current
                  Layout.alignment: Qt.AlignVCenter
                  text: "Current"
                  color: root.theme.color8
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                }
              }

              MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.selectedIndex = row.index
                }
                onClicked: root.applyTheme(row.modelData)
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
