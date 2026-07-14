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
  property string statusText: ""
  property var entries: []
  property var filteredEntries: []
  property int selectedIndex: -1
  property int focusRequest: 0

  readonly property int animationDuration: 140
  readonly property int maxVisibleResults: 12
  readonly property string helper: Quickshell.shellPath("clipboard/clipboardctl")

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
    menuState.active = "clipboard"
    query = ""
    refresh()
    Qt.callLater(function() {
      if (menuState.active === "clipboard") {
        opened = true
        requestFocus()
      }
    })
  }

  function close(): void {
    opened = false
    hideTimer.restart()
    if (menuState.active === "clipboard") {
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
    statusText = "Loading clipboard..."
    listProcess.exec([helper, "list"])
  }

  function normalizeWhitespace(text) {
    let result = ""
    let spacing = false

    for (let i = 0; i < text.length; i++) {
      const ch = text[i]
      const whitespace = ch === " " || ch === "\n" || ch === "\r" || ch === "\t"

      if (whitespace) {
        spacing = result.length > 0
      } else {
        if (spacing) {
          result += " "
        }
        result += ch
        spacing = false
      }
    }

    return result
  }

  function displayPreview(preview) {
    const value = normalizeWhitespace(preview)

    if (value.length === 0) {
      return "Clipboard item"
    }

    return value
  }

  function sortEntries(items) {
    const sorted = items.slice()

    sorted.sort(function(a, b) {
      if (a.pinned !== b.pinned) {
        return a.pinned ? -1 : 1
      }

      return a.order - b.order
    })

    return sorted
  }

  function parseList(text) {
    const lines = text.split("\n")
    const results = []

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]

      if (line.length === 0) {
        continue
      }

      const firstTab = line.indexOf("\t")
      const secondTab = firstTab >= 0 ? line.indexOf("\t", firstTab + 1) : -1
      const id = firstTab >= 0 ? line.substring(0, firstTab).trim() : line.trim()
      const pinned = secondTab >= 0 && line.substring(firstTab + 1, secondTab) === "1"
      const preview = secondTab >= 0
        ? line.substring(secondTab + 1)
        : firstTab >= 0 ? line.substring(firstTab + 1) : ""

      if (id.length === 0) {
        continue
      }

      const label = displayPreview(preview)

      results.push({
        id: id,
        pinned: pinned,
        preview: label,
        search: [id, label].join(" ").toLowerCase(),
        order: i
      })
    }

    return sortEntries(results)
  }

  function filter(): void {
    const needle = query.trim().toLowerCase()
    const results = []

    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i]

      if (needle.length === 0 || entry.search.indexOf(needle) !== -1) {
        results.push(entry)
      }
    }

    filteredEntries = results
    selectedIndex = filteredEntries.length > 0 ? 0 : -1
  }

  function selectedEntry() {
    if (selectedIndex >= 0 && selectedIndex < filteredEntries.length) {
      return filteredEntries[selectedIndex]
    }

    return null
  }

  function copyEntry(entry) {
    if (entry === null || entry.id.length === 0) {
      return
    }

    close()
    Quickshell.execDetached([helper, "copy", entry.id])
  }

  function deleteEntry(entry) {
    if (entry === null || entry.id.length === 0) {
      return
    }

    Quickshell.execDetached([helper, "delete", entry.id])
    entries = entries.filter(function(item) {
      return item.id !== entry.id
    })
    filter()
  }

  function togglePin(entry) {
    if (entry === null || entry.id.length === 0) {
      return
    }

    Quickshell.execDetached([helper, "toggle-pin", entry.id])

    const updated = []
    for (let i = 0; i < entries.length; i++) {
      const item = entries[i]

      updated.push({
        id: item.id,
        pinned: item.id === entry.id ? !item.pinned : item.pinned,
        preview: item.preview,
        search: item.search,
        order: item.order
      })
    }

    entries = sortEntries(updated)
    filter()
  }

  onQueryChanged: filter()

  IpcHandler {
    target: "clipboard"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  Connections {
    target: menuState

    function onActiveChanged(): void {
      if (menuState.active === "clipboard") {
        hideTimer.stop()
        root.mounted = true
        Qt.callLater(function() {
          if (menuState.active === "clipboard") {
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
        root.entries = root.parseList(text)
        root.statusText = root.entries.length === 0 ? "No clipboard history" : ""
        root.filter()
      }
    }

    stderr: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        if (text.length > 0) {
          console.warn("Clipboard list failed: " + text)
          root.statusText = text.trim()
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.entries = []
        root.filteredEntries = []
        root.selectedIndex = -1
        if (root.statusText.length === 0 || root.statusText === "No clipboard history") {
          root.statusText = "Could not load clipboard"
        }
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
      WlrLayershell.namespace: "prometheus-clipboard"

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
        width: Math.min(680, window.width - 40)
        implicitHeight: content.implicitHeight + 28
        anchors {
          top: parent.top
          horizontalCenter: parent.horizontalCenter
          topMargin: 44
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
            placeholderText: "Clipboard history"
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
            onAccepted: root.copyEntry(root.selectedEntry())

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Down && root.filteredEntries.length > 0) {
                root.selectedIndex = Math.min(root.selectedIndex + 1, root.filteredEntries.length - 1)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Up && root.filteredEntries.length > 0) {
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0)
                resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                event.accepted = true
              } else if (event.key === Qt.Key_Delete) {
                root.deleteEntry(root.selectedEntry())
                event.accepted = true
              } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
                root.togglePin(root.selectedEntry())
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true
              }
            }
          }

          Text {
            visible: root.statusText.length > 0 || root.filteredEntries.length === 0
            Layout.fillWidth: true
            text: root.statusText.length > 0 ? root.statusText : "No matches"
            color: root.theme.color4
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
          }

          ListView {
            id: resultsList

            visible: root.statusText.length === 0 && root.filteredEntries.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(root.filteredEntries.length, root.maxVisibleResults) * 48
            clip: true
            interactive: root.filteredEntries.length > root.maxVisibleResults
            currentIndex: root.selectedIndex
            model: root.filteredEntries
            boundsBehavior: Flickable.StopAtBounds

            onCurrentIndexChanged: {
              if (currentIndex >= 0) {
                positionViewAtIndex(currentIndex, ListView.Contain)
              }
            }

            ScrollBar.vertical: ScrollBar {
              policy: root.filteredEntries.length > root.maxVisibleResults
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

              MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                  root.selectedIndex = row.index
                }
                onClicked: root.copyEntry(row.modelData)
              }

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

                Image {
                  source: Qt.resolvedUrl("../icons/pin.svg")
                  sourceSize.width: 16
                  sourceSize.height: 16
                  Layout.preferredWidth: 16
                  Layout.preferredHeight: 16
                  opacity: row.modelData.pinned ? 0.95 : 0.0
                }

                Text {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  text: row.modelData.preview
                  color: ListView.isCurrentItem ? root.theme.color6 : root.theme.color4
                  font.pixelSize: 14
                  elide: Text.ElideRight
                }

                Rectangle {
                  Layout.preferredWidth: 30
                  Layout.preferredHeight: 30
                  radius: 6
                  color: pinMouse.containsMouse ? root.theme.color3 : "transparent"

                  Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: Qt.resolvedUrl("../icons/pin.svg")
                    opacity: row.modelData.pinned ? 1.0 : 0.48
                  }

                  MouseArea {
                    id: pinMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = row.index
                    onClicked: function(mouse) {
                      mouse.accepted = true
                      root.togglePin(row.modelData)
                    }
                  }

                  ToolTip.visible: pinMouse.containsMouse
                  ToolTip.text: row.modelData.pinned ? "Unpin" : "Pin"
                }

                Rectangle {
                  Layout.preferredWidth: 30
                  Layout.preferredHeight: 30
                  radius: 6
                  color: deleteMouse.containsMouse ? root.theme.color3 : "transparent"

                  Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: Qt.resolvedUrl("../icons/trash.svg")
                    opacity: deleteMouse.containsMouse ? 1.0 : 0.62
                  }

                  MouseArea {
                    id: deleteMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = row.index
                    onClicked: function(mouse) {
                      mouse.accepted = true
                      root.deleteEntry(row.modelData)
                    }
                  }

                  ToolTip.visible: deleteMouse.containsMouse
                  ToolTip.text: "Delete"
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
