import QtQuick
import QtQml
import "../theme"

Pill {
  id: root

  implicitWidth: clockButton.implicitWidth + root.margin * 2
  implicitHeight: clockButton.implicitHeight + root.margin * 2

  BarButton {
    id: clockButton

    implicitWidth: timeText.implicitWidth + 14
    implicitHeight: 22

    buttonColor: hovered
      ? root.theme.color1
      : root.theme.color0

    buttonBorderWidth: 1

    buttonBorderColor: hovered
      ? root.theme.color8
      : root.theme.color0

    Text {
      id: timeText

      anchors.centerIn: parent

      text: Time.time
      color: root.theme.color6

      font.pixelSize: 12
      font.weight: Font.DemiBold
    }
  }
}
