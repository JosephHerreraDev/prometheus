pragma Singleton

import Quickshell
import QtQuick

Singleton {
  id: root

  readonly property string time: {
    Qt.formatDateTime(clock.date, "dddd hh:mm")
  }

  SystemClock {
    id: clock
  }
}
