import QtQuick
import QtQml
import "../theme"

Pill{
    property QtObject nord: Nord {}
    Text{
      color: nord.nord6
      font.pointSize: 10
      text: Time.time
    }
}
