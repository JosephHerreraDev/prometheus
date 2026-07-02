import QtQuick

Item {
    id: wrapper

    property real margin: 6
    required default property Item child

    implicitWidth: child.implicitWidth + margin * 2
    implicitHeight: child.implicitHeight + margin * 2

    Rectangle {
        id: bg
        anchors.fill: parent

        color: "#2e3440"
        border.width: 1
        border.color: "white"
        radius: 6

        Item {
            anchors.fill: parent
            anchors.margins: wrapper.margin
            data: [child]
        }
    }
}
