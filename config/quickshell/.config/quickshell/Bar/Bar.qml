import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      color: "#00000000"
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
}

margins {
	top: 4
	left: 10
	right: 10
}

      implicitHeight: 30

      RowLayout{
	      anchors.fill: parent
	      spacing: 8
	      
      Workspace {
	      shellScreen: modelData
      }
      Item {
        Layout.fillWidth: true
    }
      ClockWidget {
	}
      Item {
        Layout.fillWidth: true
    }
      Workspace {
      }
	}
    }
  }
}
