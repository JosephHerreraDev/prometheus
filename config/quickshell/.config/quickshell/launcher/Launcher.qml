import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
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
  property var apps: []
  property var filteredApps: []
  property bool appsLoaded: false
  property bool appsLoading: false
  property int selectedIndex: -1
  property int focusRequest: 0

  readonly property int animationDuration: 140
  readonly property int maxVisibleRows: 3
  readonly property string helper: Quickshell.shellPath("launcher/launcherctl")

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
    menuState.active = "launcher"
    query = ""
    if (!appsLoaded) {
      refresh()
    }
    filter()
    Qt.callLater(function() {
      if (menuState.active === "launcher") {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    opened = false
    hideTimer.restart()
    if (menuState.active === "launcher") {
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
    if (appsLoading) {
      return
    }

    appsLoaded = false
    appsLoading = true
    listProcess.exec([helper, "list"])
  }

  function safeString(value) {
    return value === undefined || value === null ? "" : String(value)
  }

  function parseList(text) {
    const lines = text.split("\n")
    const results = []

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]

      if (line.length === 0) {
        continue
      }

      const parts = line.split("\t")
      const id = safeString(parts[0])
      const name = safeString(parts[1])
      const genericName = safeString(parts[2])
      const comment = safeString(parts[3])
      const icon = safeString(parts[4])
      const keywords = safeString(parts[5])

      if (id.length === 0 || name.length === 0) {
        continue
      }

      results.push({
        id: id,
        name: name,
        genericName: genericName,
        comment: comment,
        icon: icon,
        search: [
          name,
          genericName,
          comment,
          id,
          keywords.replace(/;/g, " ")
        ].join(" ").toLowerCase()
      })
    }

    return results
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    const results = []

    if (needle.length === 0) {
      filteredApps = apps
      resetSelection()
      return
    }

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i]

      if (app.search.indexOf(needle) !== -1) {
        results.push(app)
      }
    }

    filteredApps = results
    resetSelection()
  }

  function resetSelection() {
    selectedIndex = filteredApps.length > 0 ? 0 : -1
  }

  function selectedApp() {
    if (selectedIndex >= 0 && selectedIndex < filteredApps.length) {
      return filteredApps[selectedIndex]
    }

    return null
  }

  function moveSelection(delta) {
    if (filteredApps.length === 0) {
      selectedIndex = -1
      return
    }

    selectedIndex = Math.max(0, Math.min(selectedIndex + delta, filteredApps.length - 1))
  }

  function launch(app) {
    if (app === null || app.id.length === 0) {
      return
    }

    close()
    Quickshell.execDetached([helper, "launch", app.id])
  }

  function iconSource(icon) {
    if (icon.length === 0) {
      return ""
    }

    if (icon.indexOf("/") === 0) {
      return "file://" + icon
    }

    return icon
  }

  Component.onCompleted: refresh()

  onQueryChanged: filter()

  IpcHandler {
    target: "launcher"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: menuState

    function onActiveChanged(): void {
      if (menuState.active === "launcher") {
        hideTimer.stop()
        root.mounted = true
        Qt.callLater(function() {
          if (menuState.active === "launcher") {
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
        root.apps = root.parseList(text)
        root.appsLoaded = true
        root.appsLoading = false
        root.filter()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (text.length > 0) {
          console.warn("Launcher list failed: " + text)
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.apps = []
        root.filteredApps = []
        root.appsLoaded = true
        root.appsLoading = false
        root.selectedIndex = -1
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
      WlrLayershell.namespace: "prometheus-launcher"

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
        width: Math.min(700, window.width - 32)
        implicitHeight: content.implicitHeight + 32
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

          RowLayout {
            Layout.fillWidth: true

            Text {
              Layout.fillWidth: true
              text: "Applications"
              color: root.theme.color6
              font.pixelSize: 18
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }

            Text {
              text: root.appsLoaded ? root.apps.length + " available" : "Loading"
              color: root.theme.color4
              font.pixelSize: 12
            }
          }

          TextField {
            id: input

            Layout.fillWidth: true
            Layout.preferredHeight: 42
            text: root.query
            placeholderText: "Search applications"
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
            onAccepted: root.launch(root.selectedApp())

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Right && root.filteredApps.length > 0) {
                root.moveSelection(1)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Left && root.filteredApps.length > 0) {
                root.moveSelection(-1)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Down && root.filteredApps.length > 0) {
                root.moveSelection(resultsGrid.columns)
                resultsGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up && root.filteredApps.length > 0) {
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
            visible: root.filteredApps.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            text: !root.appsLoaded ? "Loading apps..." : root.apps.length === 0 ? "No apps found" : "No matches"
            color: root.theme.color4
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }

          GridView {
            id: resultsGrid

            visible: root.filteredApps.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(Math.ceil(root.filteredApps.length / columns), root.maxVisibleRows) * cellHeight
            clip: true
            interactive: Math.ceil(root.filteredApps.length / columns) > root.maxVisibleRows
            currentIndex: root.selectedIndex
            model: root.filteredApps
            boundsBehavior: Flickable.StopAtBounds
            readonly property int columns: width >= 520 ? 2 : 1
            cellWidth: width / columns
            cellHeight: 92

            onCurrentIndexChanged: {
              if (currentIndex >= 0) {
                positionViewAtIndex(currentIndex, GridView.Contain)
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: Math.ceil(root.filteredApps.length / resultsGrid.columns) > root.maxVisibleRows
                ? ScrollBar.AsNeeded
                : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
              id: appCard

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

              RowLayout {
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  bottom: parent.bottom
                  margins: 12
                }

                spacing: 10

                IconImage {
                  id: appIcon

                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  Layout.alignment: Qt.AlignVCenter
                  source: root.iconSource(appCard.modelData.icon)
                  asynchronous: true
                  mipmap: true
                  visible: status === Image.Ready
                }

                Rectangle {
                  Layout.preferredWidth: 32
                  Layout.preferredHeight: 32
                  Layout.alignment: Qt.AlignVCenter
                  visible: !appIcon.visible
                  radius: 6
                  color: root.theme.color2
                  border.width: 1
                  border.color: root.theme.color3

                  Text {
                    anchors.centerIn: parent
                    text: appCard.modelData.name.length > 0 ? appCard.modelData.name[0].toUpperCase() : "?"
                    color: root.theme.color6
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    text: appCard.modelData.name
                    color: GridView.isCurrentItem ? root.theme.color6 : root.theme.color4
                    font.pixelSize: 15
                    font.weight: GridView.isCurrentItem ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                  }

                  Text {
                    Layout.fillWidth: true
                    visible: appCard.modelData.comment.length > 0 || appCard.modelData.genericName.length > 0
                    text: appCard.modelData.comment.length > 0 ? appCard.modelData.comment : appCard.modelData.genericName
                    color: root.theme.color4
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                id: cardMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.selectedIndex = appCard.index
                }
                onClicked: root.launch(appCard.modelData)
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
