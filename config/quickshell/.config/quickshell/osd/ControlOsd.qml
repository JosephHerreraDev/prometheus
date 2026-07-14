import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../theme"

Scope {
  id: root

  property QtObject theme: Theme {}
  property bool visible: false
  property string kind: "volume"
  property string label: "Volume"
  property string icon: "../icons/volume.svg"
  property int value: 0
  property bool muted: false
  property int previousBrightness: -1
  property bool brightnessInitialized: false
  property bool volumeInitialized: false
  property bool startupComplete: false
  property QtObject systemState

  readonly property int brightnessValue: systemState ? systemState.brightness : -1

  readonly property int width: 320
  readonly property int height: 92
  readonly property int hideDelay: 1100
  readonly property bool audioReady: Pipewire.ready
    && Pipewire.defaultAudioSink
    && Pipewire.defaultAudioSink.audio
  readonly property int audioValue: audioReady
    ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100)
    : -1
  readonly property bool audioMuted: audioReady
    ? Pipewire.defaultAudioSink.audio.muted
    : false

  property QtObject audioTracker: PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent))
  }

  function show(newKind, newValue, isMuted) {
    if (!startupComplete) {
      return
    }

    kind = newKind
    label = newKind === "brightness" ? "Brightness" : "Volume"
    icon = newKind === "brightness" ? "../icons/brightness.svg" : "../icons/volume.svg"
    value = clampPercent(newValue)
    muted = isMuted === true
    visible = true
    hideTimer.restart()
  }

  onAudioValueChanged: {
    if (!audioReady || audioValue < 0) {
      return
    }

    if (!volumeInitialized) {
      volumeInitialized = true
      return
    }

    show("volume", audioValue, audioMuted)
  }

  onAudioMutedChanged: {
    if (!audioReady) {
      return
    }

    if (!volumeInitialized) {
      volumeInitialized = true
      return
    }

    show("volume", audioValue, audioMuted)
  }

  onBrightnessValueChanged: {
    if (brightnessValue < 0) {
      return
    }

    if (!brightnessInitialized) {
      previousBrightness = brightnessValue
      brightnessInitialized = true
      return
    }

    if (brightnessValue !== previousBrightness) {
      previousBrightness = brightnessValue
      show("brightness", brightnessValue, false)
    }
  }

  Timer {
    id: hideTimer

    interval: root.hideDelay
    repeat: false
    onTriggered: root.visible = false
  }

  Timer {
    interval: 1500
    running: true
    repeat: false
    onTriggered: root.startupComplete = true
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: root.visible && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: false
      exclusiveZone: 0
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "prometheus-control-osd"

      anchors {
        bottom: true
        left: true
        right: true
      }

      margins {
        bottom: Math.max(48, Math.round(window.screen.height * 0.12))
      }

      implicitWidth: window.screen.width
      implicitHeight: root.height

      Rectangle {
        width: root.width
        height: root.height
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 8
        color: root.theme.color0
        border.width: 1
        border.color: root.theme.color2
        opacity: 0.96

        RowLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 14

          Item {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34

            IconImage {
              id: rawIcon

              anchors.fill: parent
              source: Qt.resolvedUrl(root.icon)
              opacity: 0.0
            }

            MultiEffect {
              anchors.fill: parent
              source: rawIcon
              colorization: 1.0
              colorizationColor: root.muted ? root.theme.color11 : root.theme.color8
              brightness: 1.0
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: root.muted ? "Muted" : root.label
                color: root.theme.color6
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: root.muted ? "0%" : root.value + "%"
                color: root.muted ? root.theme.color11 : root.theme.color8
                font.pixelSize: 14
                font.weight: Font.DemiBold
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 10
              radius: 5
              color: root.theme.color1

              Rectangle {
                anchors {
                  left: parent.left
                  top: parent.top
                  bottom: parent.bottom
                }

                width: parent.width * (root.muted ? 0 : root.value / 100)
                radius: 5
                color: root.muted ? root.theme.color11 : root.theme.color8
              }
            }
          }
        }
      }
    }
  }
}
