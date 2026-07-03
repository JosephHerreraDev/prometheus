import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../theme"

Scope {
  id: root

  property QtObject theme: Theme {}

  readonly property int screenGap: 4
  readonly property int barHeight: 30
  readonly property int panelTop: screenGap
  readonly property int panelRight: 10
  readonly property int cardWidth: 360
  readonly property int maxCards: 5
  readonly property var notifications: server.trackedNotifications.values
  readonly property bool hasNotifications: notifications.length > 0

  function screenFocused(screen) {
    const monitor = Hyprland.monitorFor(screen)
    return monitor !== null
      && Hyprland.focusedMonitor !== null
      && monitor.name === Hyprland.focusedMonitor.name
  }

  function cleanText(text) {
    if (!text) {
      return ""
    }

    return text
      .replace(/<br\s*\/?\s*>/gi, "\n")
      .replace(/<[^>]*>/g, "")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&amp;/g, "&")
      .trim()
  }

  function appLabel(notification) {
    return notification.appName && notification.appName.length > 0
      ? notification.appName
      : "Notification"
  }

  function accentFor(notification) {
    if (notification.urgency === NotificationUrgency.Critical) {
      return root.theme.color11
    }

    if (notification.urgency === NotificationUrgency.Low) {
      return root.theme.color3
    }

    return root.theme.color8
  }

  NotificationServer {
    id: server

    keepOnReload: false
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyImagesSupported: true
    actionsSupported: true
    actionIconsSupported: true
    imageSupported: true

    onNotification: function(notification) {
      notification.tracked = true
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData

      screen: modelData
      visible: root.hasNotifications && root.screenFocused(modelData)
      color: "#00000000"
      aboveWindows: true
      focusable: false
      exclusiveZone: 0
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.layer: WlrLayer.Overlay

      anchors {
        top: true
        right: true
      }

      margins {
        top: root.panelTop
        right: root.panelRight
      }

      implicitWidth: root.cardWidth
      implicitHeight: Math.min(list.implicitHeight, Math.max(0, window.screen.height - root.panelTop - 20))

      ColumnLayout {
        id: list

        width: root.cardWidth
        spacing: 8

        Repeater {
          model: root.notifications.slice(0, root.maxCards)

          Rectangle {
            id: card

            required property var modelData

            Layout.preferredWidth: root.cardWidth
            Layout.maximumWidth: root.cardWidth
            Layout.minimumWidth: root.cardWidth
            Layout.preferredHeight: content.implicitHeight + 20

            radius: 8
            color: root.theme.color0
            border.width: 1
            border.color: cardMouse.containsMouse ? root.accentFor(modelData) : root.theme.color2

            Timer {
              interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
              running: card.modelData.urgency !== NotificationUrgency.Critical && !card.modelData.resident
              repeat: false
              onTriggered: card.modelData.expire()
            }

            Rectangle {
              width: 4
              radius: 2
              color: root.accentFor(card.modelData)

              anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: 8
              }
            }

            MouseArea {
              id: cardMouse

              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.RightButton
              onClicked: card.modelData.dismiss()
            }

            ColumnLayout {
              id: content

              z: 1

              anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10
                leftMargin: 18
                rightMargin: 10
              }

              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                  text: root.appLabel(card.modelData)
                  color: root.theme.color8
                  font.pixelSize: 11
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Rectangle {
                  width: 24
                  height: 22
                  radius: 6
                  color: closeArea.containsMouse ? root.theme.color1 : root.theme.color0
                  border.width: 1
                  border.color: closeArea.containsMouse ? root.theme.color8 : root.theme.color2

                  Text {
                    anchors.centerIn: parent
                    text: "x"
                    color: root.theme.color6
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                  }

                  MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.modelData.dismiss()
                  }
                }
              }

              Text {
                text: root.cleanText(card.modelData.summary)
                visible: text.length > 0
                color: root.theme.color6
                font.pixelSize: 14
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: root.cleanText(card.modelData.body)
                visible: text.length > 0
                color: root.theme.color4
                font.pixelSize: 12
                lineHeight: 1.1
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              RowLayout {
                visible: card.modelData.actions.length > 0
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                  model: card.modelData.actions

                  Rectangle {
                    required property var modelData

                    Layout.preferredHeight: 24
                    Layout.preferredWidth: actionText.implicitWidth + 18
                    radius: 6
                    color: actionMouse.containsMouse ? root.theme.color2 : root.theme.color1
                    border.width: 1
                    border.color: actionMouse.containsMouse ? root.theme.color8 : root.theme.color3

                    Text {
                      id: actionText

                      anchors.centerIn: parent
                      text: modelData.text
                      color: root.theme.color6
                      font.pixelSize: 11
                      font.weight: Font.DemiBold
                    }

                    MouseArea {
                      id: actionMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor

                      onClicked: {
                        modelData.invoke()
                        card.modelData.dismiss()
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
