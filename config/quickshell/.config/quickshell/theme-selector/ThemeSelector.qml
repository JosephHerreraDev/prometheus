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
  readonly property int maxVisibleRows: 3
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

  function currentThemeColors() {
    for (let i = 0; i < themes.length; i++) {
      if (themes[i].current) {
        return themes[i].colors
      }
    }

    return []
  }

  function moveSelection(delta) {
    if (filteredThemes.length === 0) {
      selectedIndex = -1
      return
    }

    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, filteredThemes.length - 1))
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
        width: Math.min(700, window.width - 32)
        height: Math.min(window.height - 48, content.implicitHeight + 32)
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
          id: content

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 14
          }

          spacing: 12

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
              text: "Themes"
              color: root.theme.color6
              font.pixelSize: 18
              font.weight: Font.DemiBold
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "Current theme"
                color: root.theme.color4
                font.pixelSize: 12
                Layout.alignment: Qt.AlignVCenter
              }

              Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.currentTheme
                color: root.theme.color6
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
              }

              RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Repeater {
                  model: root.currentThemeColors().slice(0, 4)

                  Rectangle {
                    required property var modelData

                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: 3
                    color: modelData
                    border.width: 1
                    border.color: root.theme.color0
                  }
                }
              }
            }
          }

          TextField {
            id: input

            Layout.fillWidth: true
            Layout.preferredHeight: 42
            text: root.query
            placeholderText: "Search themes"
            selectByMouse: true
            color: root.theme.color6
            placeholderTextColor: root.theme.color4
            font.pixelSize: 15
            leftPadding: 12
            rightPadding: 12
            background: Rectangle {
              radius: 6
              color: root.theme.color1
              border.width: 1
              border.color: input.activeFocus ? root.theme.color8 : root.theme.color3
            }

            onTextChanged: root.query = text
            onAccepted: root.applyTheme(root.selectedTheme())

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right && root.filteredThemes.length > 0) {
                root.moveSelection(1)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Left && root.filteredThemes.length > 0) {
                root.moveSelection(-1)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Down && root.filteredThemes.length > 0) {
                root.moveSelection(resultsGrid.columns)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up && root.filteredThemes.length > 0) {
                root.moveSelection(-resultsGrid.columns)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
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
            Layout.preferredHeight: 48
            text: root.statusText.length > 0 ? root.statusText : "No matching themes"
            color: root.theme.color4
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          GridView {
            id: resultsGrid

            visible: root.statusText.length === 0 && root.filteredThemes.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Math.ceil(root.filteredThemes.length / columns), root.maxVisibleRows) * cellHeight
            clip: true
            interactive: Math.ceil(root.filteredThemes.length / columns) > root.maxVisibleRows
            currentIndex: root.selectedIndex
            model: root.filteredThemes
            boundsBehavior: Flickable.StopAtBounds
            readonly property int columns: width >= 520 ? 2 : 1
            cellWidth: width / columns
            cellHeight: 100

            onCurrentIndexChanged: {
              if (currentIndex >= 0) {
                positionViewAtIndex(currentIndex, GridView.Contain)
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: Math.ceil(root.filteredThemes.length / resultsGrid.columns) > root.maxVisibleRows
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
              id: themeCard

              required property int index
              required property var modelData

              width: resultsGrid.cellWidth - 8
              height: resultsGrid.cellHeight - 8
              radius: 6
              color: GridView.isCurrentItem || cardMouse.containsMouse
                ? root.theme.color1
                : root.theme.color0
              border.width: GridView.isCurrentItem || cardMouse.containsMouse ? 1 : 0
              border.color: GridView.isCurrentItem ? root.theme.color8 : root.theme.color3

              ColumnLayout {
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  bottom: parent.bottom
                  margins: 12
                }

                spacing: 6

                Text {
                  Layout.fillWidth: true
                  text: themeCard.modelData.name
                  color: themeCard.modelData.current || GridView.isCurrentItem ? root.theme.color6 : root.theme.color4
                  font.pixelSize: 15
                  font.weight: themeCard.modelData.current ? Font.DemiBold : Font.Medium
                  elide: Text.ElideRight
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 5

                  Repeater {
                    model: themeCard.modelData.colors

                    Rectangle {
                      required property var modelData

                      Layout.preferredWidth: 18
                      Layout.preferredHeight: 18
                      radius: 4
                      color: modelData
                      border.width: 1
                      border.color: root.theme.color0
                    }
                  }

                  Item {
                    Layout.fillWidth: true
                  }

                  Text {
                    visible: themeCard.modelData.current
                    text: "Current"
                    color: root.theme.color8
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                  }
                }
              }

              MouseArea {
                id: cardMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.selectedIndex = themeCard.index
                }
                onClicked: root.applyTheme(themeCard.modelData)
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
