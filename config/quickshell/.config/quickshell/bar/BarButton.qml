import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
  id: root

  property QtObject theme: Theme {}

  property color buttonColor: root.hovered
    ? theme.color1
    : theme.color0

  property color buttonBorderColor: root.hovered
    ? theme.color8
    : theme.color0

  property int buttonBorderWidth: 1

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  default property alias content: contentHost.data

  signal clicked()
  signal middleClicked()
  signal wheelMoved(bool up)

  radius: 6

  color: buttonColor
  border.width: buttonBorderWidth
  border.color: buttonBorderColor

  scale: root.pressed ? 0.94 : 1.0
  opacity: root.pressed ? 0.75 : 1.0
  transformOrigin: Item.Center

  Behavior on scale {
    NumberAnimation {
      duration: 90
      easing.type: Easing.OutQuad
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: 90
      easing.type: Easing.OutQuad
    }
  }

  Behavior on color {
    ColorAnimation {
      duration: 90
      easing.type: Easing.OutQuad
    }
  }

  Behavior on border.color {
    ColorAnimation {
      duration: 90
      easing.type: Easing.OutQuad
    }
  }

  Behavior on border.width {
    NumberAnimation {
      duration: 90
      easing.type: Easing.OutQuad
    }
  }

  Item {
    id: contentHost

    anchors.fill: parent
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) {
        root.middleClicked()
        return
      }

      root.clicked()
    }

    onWheel: function(wheel) {
      root.wheelMoved(wheel.angleDelta.y > 0)
      wheel.accepted = true
    }
  }
}
