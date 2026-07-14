import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell.Widgets
import QtQuick.Effects
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "../theme"

Pill {
  id: root

  readonly property int buttonWidth: 24
  readonly property int buttonHeight: 22
  readonly property int iconSize: 14

  implicitWidth: row.implicitWidth + 14
  implicitHeight: 28

  property QtObject systemState

  readonly property int brightness: systemState ? systemState.brightness : -1
  property bool wifiAvailable: false
  property bool wifiEnabled: false
  property bool wifiHardwareBlocked: false
  property bool bluetoothAvailable: false
  property bool bluetoothEnabled: false
  property bool bluetoothHardwareBlocked: false

  readonly property bool audioReady: Pipewire.ready
    && Pipewire.defaultAudioSink
    && Pipewire.defaultAudioSink.audio
  readonly property bool audioMuted: audioReady
    ? Pipewire.defaultAudioSink.audio.muted
    : false

  property QtObject audioTracker: PwObjectTracker {
    objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
  }

  function run(command) {
    if (command && command.length > 0) {
      Quickshell.execDetached(["sh", "-c", command])
    }
  }

  function batteryText() {
    if (!UPower.displayDevice.ready) {
      return "--%"
    }

    return Math.round(UPower.displayDevice.percentage * 100) + "%"
  }

  function brightnessText() {
    return brightness < 0 ? "--%" : brightness + "%"
  }

  function volumeText() {
    if (!Pipewire.ready || !Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) {
      return "--%"
    }

    if (Pipewire.defaultAudioSink.audio.muted) {
      return "MUT"
    }

    return Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%"
  }

  function updateRadioState(text) {
    let devices

    try {
      devices = JSON.parse(text).rfkilldevices
    } catch (error) {
      return
    }

    const wifi = { available: false, enabled: false, hardwareBlocked: false }
    const bluetooth = { available: false, enabled: false, hardwareBlocked: false }

    for (let i = 0; i < devices.length; i++) {
      const device = devices[i]
      const state = device.type === "bluetooth" ? bluetooth
        : device.type === "wlan" || device.type === "wifi" ? wifi
          : null

      if (state === null) {
        continue
      }

      state.available = true
      state.hardwareBlocked = state.hardwareBlocked || device.hard === "blocked"
      state.enabled = state.enabled || (device.soft !== "blocked" && device.hard !== "blocked")
    }

    wifiAvailable = wifi.available
    wifiEnabled = wifi.enabled
    wifiHardwareBlocked = wifi.hardwareBlocked
    bluetoothAvailable = bluetooth.available
    bluetoothEnabled = bluetooth.enabled
    bluetoothHardwareBlocked = bluetooth.hardwareBlocked
  }

  function refreshRadios() {
    if (!radioProcess.running) {
      radioProcess.exec(["rfkill", "--json"])
    }
  }

  function toggleRadio(kind) {
    const enabled = kind === "wifi" ? wifiEnabled : bluetoothEnabled
    const target = kind === "wifi" ? "wifi" : "bluetooth"

    run("rfkill " + (enabled ? "block " : "unblock ") + target)
    radioRefreshTimer.restart()
  }

  function controlIconColor(kind) {
    if (kind === "wifi") {
      return !wifiAvailable || !wifiEnabled ? theme.color3 : theme.color8
    }

    if (kind === "bluetooth") {
      return !bluetoothAvailable || !bluetoothEnabled ? theme.color3 : theme.color8
    }

    if (kind === "brightness") {
      return brightness >= 0 && brightness <= 20 ? theme.color13 : theme.color8
    }

    if (kind === "volume") {
      return !audioReady ? theme.color3 : audioMuted ? theme.color11 : theme.color8
    }

    if (kind === "battery") {
      if (!UPower.displayDevice.ready) {
        return theme.color3
      }

      if (UPower.onBattery && UPower.displayDevice.percentage <= 0.2) {
        return theme.color11
      }

      return UPower.onBattery ? theme.color8 : theme.color14
    }

    return theme.color8
  }

  property QtObject radioPollTimer: Timer {

    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshRadios()
  }

  property QtObject radioRefreshTimer: Timer {

    interval: 500
    repeat: false
    onTriggered: root.refreshRadios()
  }

  property QtObject radioProcess: Process {

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateRadioState(text)
    }
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: [
        {
          kind: "bluetooth",
          icon: "../icons/bluetooth.svg",
          command: "prometheus-launch-bluetooth"
        },
        {
          kind: "wifi",
          icon: "../icons/wifi.svg",
          command: "prometheus-launch-wifi"
        },
        {
          kind: "brightness",
          icon: "../icons/brightness.svg",
          command: "brightnessctl --min-value=5% set 100%",
          scrollUp: "brightnessctl --min-value=5% set 5%+",
          scrollDown: "brightnessctl --min-value=5% set 5%-",
          brightness: true
        },
        {
          kind: "volume",
          icon: "../icons/volume.svg",
          command: "prometheus-launch-audio",
          scrollUp: "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+",
          scrollDown: "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-",
          middleClick: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
          volume: true
        },
        {
          kind: "battery",
          icon: "../icons/battery.svg",
          command: "",
          battery: true
        },
        {
          kind: "cpu",
          icon: "../icons/cpu.svg",
          command: "prometheus-launch-or-focus-tui btop"
        },
        {
          kind: "about",
          icon: "../icons/arch.svg",
          command: "prometheus-launch-about"
        }
      ]

      BarButton {
        id: systemButton

        required property var modelData

        readonly property bool isBattery: systemButton.modelData.battery === true
        readonly property bool isVolume: systemButton.modelData.volume === true
        readonly property bool isBrightness: systemButton.modelData.brightness === true
        readonly property bool hasText: systemButton.isBattery || systemButton.isBrightness || systemButton.isVolume

        Layout.preferredWidth: systemButton.hasText
          ? buttonContent.implicitWidth + 10
          : root.buttonWidth

        Layout.preferredHeight: root.buttonHeight

        buttonColor: systemButton.hovered
          ? root.theme.color1
          : root.theme.color0

        buttonBorderWidth: 1

        buttonBorderColor: systemButton.hovered
          ? root.controlIconColor(systemButton.modelData.kind)
          : root.theme.color0

        onClicked: root.run(systemButton.modelData.command)

        onMiddleClicked: {
          if (systemButton.modelData.kind === "wifi" || systemButton.modelData.kind === "bluetooth") {
            root.toggleRadio(systemButton.modelData.kind)
          } else {
            root.run(systemButton.modelData.middleClick)
          }
        }

        onWheelMoved: function(up) {
          if (!systemButton.modelData.scrollUp || !systemButton.modelData.scrollDown) {
            return
          }

          if (up) {
            root.run(systemButton.modelData.scrollUp)
          } else {
            root.run(systemButton.modelData.scrollDown)
          }
        }

        RowLayout {
          id: buttonContent

          anchors.centerIn: parent
          spacing: systemButton.hasText ? 4 : 0

          Item {
            Layout.preferredWidth: root.iconSize
            Layout.preferredHeight: root.iconSize

            IconImage {
              id: rawIcon

              anchors.fill: parent
              source: Qt.resolvedUrl(systemButton.modelData.icon)

              visible: true
              opacity: 0.0
            }

            MultiEffect {
              anchors.fill: parent
              source: rawIcon

              colorization: 1.0
              colorizationColor: root.controlIconColor(systemButton.modelData.kind)
              brightness: 1.0
            }
          }

          Text {
            visible: systemButton.hasText

            text: systemButton.isBattery
              ? root.batteryText()
              : systemButton.isBrightness
                ? root.brightnessText()
                : root.volumeText()

            color: root.controlIconColor(systemButton.modelData.kind)

            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }
}
