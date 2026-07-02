import QtQuick
import "../theme"

Item {
  id: wrapper

  property QtObject theme: Theme {}
  property real margin: 2
  required default property Item child

  implicitWidth: child.implicitWidth + margin * 2
  implicitHeight: child.implicitHeight + margin * 2

  Rectangle {
    id: bg

    anchors.fill: parent

    color: theme.color0
    radius: 6

    Item {
      anchors.fill: parent
      anchors.margins: wrapper.margin
      data: [child]
    }
  }
}
