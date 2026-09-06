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
  required property QtObject menuState
  required property string kind
  property QtObject theme: Theme {}
  readonly property bool opened: menuState.active === kind
  property var adapters: []
  property var devices: []
  property var prompt: null
  property string error: ""
  property bool busy: false

  function send(action, details) {
    if (backend.running) backend.write(JSON.stringify(Object.assign({action: action}, details || {})) + "\n")
  }
  function close() { menuState.active = "" }
  function toggle() { menuState.active = opened ? "" : kind }

  IpcHandler {
    target: root.kind
    function toggle(): void { root.toggle() }
    function open(): void { root.menuState.active = root.kind }
    function close(): void { root.close() }
  }

  onOpenedChanged: {
    if (!opened) {
      prompt = null
      error = ""
      busy = false
      adapters = []
      devices = []
    }
  }

  Process {
    id: backend
    command: ["python3", Qt.resolvedUrl("radioctl").toString().replace("file://", ""), root.kind]
    running: root.opened
    stdinEnabled: true
    stdout: SplitParser {
      onRead: data => {
        try {
          const state = JSON.parse(data)
          if (state.adapters !== undefined) root.adapters = state.adapters
          if (state.items !== undefined) root.devices = state.items
          if (state.error !== undefined) root.error = state.error
          if (state.busy !== undefined) root.busy = state.busy
          if (state.prompt !== undefined) root.prompt = state.prompt
        } catch (e) { root.error = "Invalid response from radio service" }
      }
    }
    stderr: StdioCollector { onStreamFinished: { if (text.trim()) root.error = text.trim() } }
    onExited: (exitCode, exitStatus) => {
      if (root.opened) {
        root.busy = false
        root.error = "Radio service stopped. Close and reopen to retry."
      }
    }
  }

  component Action: Button {
    id: control
    contentItem: Text {
      text: control.text
      color: control.enabled ? root.theme.color6 : root.theme.color3
      font.pixelSize: 12
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
      radius: 6
      color: control.hovered || control.visualFocus ? root.theme.color1 : root.theme.color2
      border.color: root.theme.color8
      border.width: control.visualFocus ? 1 : 0
    }
    padding: 9
  }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.opened && Hyprland.focusedMonitor !== null
        && Hyprland.monitorFor(modelData)?.name === Hyprland.focusedMonitor.name
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
      WlrLayershell.namespace: "prometheus-" + root.kind
      // The bar sits 4 px from the top and is 30 px high.
      anchors { top: true; right: true }
      margins { top: 40; right: 10 }
      implicitWidth: Math.min(460, modelData.width - 20)
      implicitHeight: Math.min(content.implicitHeight + 24, modelData.height - 60)
      onVisibleChanged: { if (visible) panel.forceActiveFocus() }

      HyprlandFocusGrab {
        windows: [window]
        active: window.visible
        onCleared: root.close()
      }
      Rectangle {
        id: panel
        anchors.fill: parent
        radius: 8
        color: root.theme.color0
        border.color: root.theme.color2
        border.width: 1
        focus: true
        Keys.onEscapePressed: root.close()
        MouseArea { anchors.fill: parent }
        ColumnLayout {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12
          RowLayout {
            Layout.fillWidth: true
            Text {
              Layout.fillWidth: true
              text: root.kind === "wifi" ? "Wi-Fi" : "Bluetooth"
              color: root.theme.color6
              font.pixelSize: 16
              font.bold: true
            }
            Action { text: "Close"; onClicked: root.close() }
          }
          Repeater {
            model: root.adapters
            RowLayout {
              required property var modelData
              Layout.fillWidth: true
              Text {
                Layout.fillWidth: true
                text: modelData.name + (modelData.powered ? " · On" : " · Off")
                color: root.theme.color6
                elide: Text.ElideRight
              }
              Action {
                text: modelData.powered ? "Turn off" : "Turn on"
                enabled: !root.busy
                onClicked: root.send("power", {path: modelData.path, enabled: !modelData.powered})
              }
              Action {
                text: "Scan"
                enabled: modelData.powered && !root.busy
                onClicked: root.send("scan", {path: modelData.path})
              }
            }
          }
          Text {
            Layout.fillWidth: true
            visible: root.error !== "" || root.busy || root.adapters.length === 0
            text: root.error || (root.busy ? "Working…" : "No adapter available. Check the radio service and hardware switch.")
            color: root.error ? root.theme.color11 : root.theme.color4
            wrapMode: Text.Wrap
            font.pixelSize: 12
          }
          ColumnLayout {
            visible: root.prompt !== null
            Layout.fillWidth: true
            Text {
              text: root.prompt?.label || ""
              color: root.theme.color6
              Layout.fillWidth: true
              wrapMode: Text.Wrap
            }
            TextField {
              id: username
              visible: root.prompt?.signature === "ss"
              placeholderText: "Username"
              Layout.fillWidth: true
            }
            TextField {
              id: secret
              visible: !!root.prompt && ["s", "ss", "u"].indexOf(root.prompt.signature) >= 0
              placeholderText: "Password / PIN"
              echoMode: TextInput.Password
              Layout.fillWidth: true
              onAccepted: submit.clicked()
            }
            RowLayout {
              Action {
                id: submit
                text: "Confirm"
                visible: root.prompt?.signature !== "display"
                onClicked: {
                  root.send("reply", {value: secret.text, username: username.text})
                  secret.clear()
                  username.clear()
                }
              }
              Action { text: "Cancel"; onClicked: root.send("cancel") }
            }
            Connections {
              target: root
              function onPromptChanged() {
                secret.clear()
                username.clear()
                if (root.prompt) Qt.callLater(() => secret.visible ? secret.forceActiveFocus() : submit.forceActiveFocus())
              }
            }
          }
          ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Math.min(360, entries.implicitHeight)
            clip: true
            contentWidth: availableWidth
            ColumnLayout {
              id: entries
              width: parent.width
              spacing: 8
              Repeater {
                model: root.devices
                RowLayout {
                  required property var modelData
                  Layout.fillWidth: true
                  Text {
                    Layout.fillWidth: true
                    text: modelData.name + (modelData.connected ? " · Connected" : modelData.paired ? " · Paired" : "")
                      + (modelData.security ? " · " + modelData.security : "")
                    elide: Text.ElideRight
                    color: modelData.connected ? root.theme.color8 : root.theme.color6
                    font.pixelSize: 13
                    textFormat: Text.PlainText
                  }
                  Action {
                    text: modelData.connected ? "Disconnect" : root.kind === "bluetooth" && !modelData.paired ? "Pair" : "Connect"
                    enabled: !root.busy
                    onClicked: root.send(modelData.connected ? "disconnect" : root.kind === "bluetooth" && !modelData.paired ? "pair" : "connect",
                      {path: modelData.connected && root.kind === "wifi" ? modelData.station : modelData.path})
                  }
                  Action {
                    text: "Forget"
                    visible: !!modelData.known || modelData.paired
                    enabled: !root.busy
                    onClicked: root.send("forget", {path: root.kind === "wifi" ? modelData.known : modelData.path, adapter: modelData.adapter})
                  }
                }
              }
              Text {
                visible: root.devices.length === 0
                text: "No results. Turn the radio on and scan."
                color: root.theme.color4
              }
            }
          }
        }
      }
    }
  }
}
