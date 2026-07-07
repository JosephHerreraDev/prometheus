import Quickshell
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

  function volumeText() {
    if (!Pipewire.ready || !Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) {
      return "--%"
    }

    if (Pipewire.defaultAudioSink.audio.muted) {
      return "MUT"
    }

    return Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%"
  }

  RowLayout {
    id: row

    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: [
        {
          icon: "../icons/bluetooth.svg",
          command: "prometheus-launch-or-focus-tui bluetui"
        },
        {
          icon: "../icons/wifi.svg",
          command: "prometheus-launch-or-focus-tui impala"
        },
        {
          icon: "../icons/brightness.svg",
          command: "brightnessctl --min-value=5% set 100%",
          scrollUp: "brightnessctl --min-value=5% set 5%+",
          scrollDown: "brightnessctl --min-value=5% set 5%-"
        },
        {
          icon: "../icons/volume.svg",
          command: "prometheus-launch-or-focus-tui wiremix",
          scrollUp: "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+",
          scrollDown: "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-",
          middleClick: "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
          volume: true
        },
        {
          icon: "../icons/battery.svg",
          command: "",
          battery: true
        },
        {
          icon: "../icons/cpu.svg",
          command: "prometheus-launch-or-focus-tui btop"
        },
        {
          icon: "../icons/arch.svg",
          command: "prometheus-launch-or-focus-tui --hold fastfetch"
        }
      ]

      BarButton {
        id: systemButton

        required property var modelData

        readonly property bool isBattery: systemButton.modelData.battery === true
        readonly property bool isVolume: systemButton.modelData.volume === true
        readonly property bool hasText: systemButton.isBattery || systemButton.isVolume

        Layout.preferredWidth: systemButton.hasText
          ? buttonContent.implicitWidth + 10
          : root.buttonWidth

        Layout.preferredHeight: root.buttonHeight

        buttonColor: systemButton.hovered
          ? root.theme.color1
          : root.theme.color0

        buttonBorderWidth: 1

        buttonBorderColor: systemButton.hovered
          ? root.theme.color8
          : root.theme.color0

        onClicked: root.run(systemButton.modelData.command)

        onMiddleClicked: root.run(systemButton.modelData.middleClick)

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
              colorizationColor: root.theme.color8
              brightness: 1.0
            }
          }

          Text {
            visible: systemButton.hasText

            text: systemButton.isBattery
              ? root.batteryText()
              : root.volumeText()

            color: root.theme.color6

            font.pixelSize: 11
            font.weight: Font.DemiBold
          }
        }
      }
    }
  }
}
