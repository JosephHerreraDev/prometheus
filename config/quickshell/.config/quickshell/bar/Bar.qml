import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      readonly property int screenGap: 4
      readonly property int barHeight: 30
      readonly property int hyprOuterGap: 10
      readonly property int hyprWindowGap: 5

      color: "#00000000"

      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      margins {
        top: screenGap
        left: 10
        right: 10
      }

      implicitHeight: barHeight
      exclusiveZone: screenGap + barHeight - (hyprOuterGap - hyprWindowGap)

      Item {
        anchors.fill: parent

        Workspace {
          id: workspaces

          shellScreen: modelData

          anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
          }
        }

        ClockWidget {
          id: clock

          anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
          }

          z: 10
        }

        System {
          id: system

          anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
