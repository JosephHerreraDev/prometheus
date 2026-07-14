import Quickshell
import Quickshell.Io
import QtQml

Scope {
  id: root

  property int brightness: -1

  function clampPercent(percent) {
    return Math.max(0, Math.min(100, percent))
  }

  function parseBrightness(text) {
    const parts = text.trim().split(",")

    for (let i = 0; i < parts.length; i++) {
      const match = parts[i].trim().match(/^([0-9]+(?:\.[0-9]+)?)%$/)

      if (match) {
        return clampPercent(Math.round(parseFloat(match[1])))
      }
    }

    const match = text.match(/([0-9]+(?:\.[0-9]+)?)%/)
    return match ? clampPercent(Math.round(parseFloat(match[1]))) : -1
  }

  Timer {
    interval: 450
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: {
      if (!brightnessProcess.running) {
        brightnessProcess.exec(["brightnessctl", "-m", "info"])
      }
    }
  }

  Process {
    id: brightnessProcess

    stdout: StdioCollector {
      waitForEnd: true

      onStreamFinished: {
        const value = root.parseBrightness(text)

        if (value >= 0) {
          root.brightness = value
        }
      }
    }
  }
}
