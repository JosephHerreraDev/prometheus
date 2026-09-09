import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: style.background
    Style { id: themeStyle }
    readonly property var style: themeStyle
    property bool revealed: false
    property bool busy: false
    property string errorMessage: ""
    property date now: new Date()
    function reveal() {
        revealed = true
        password.forceActiveFocus()
    }
    function login() {
        if (busy || username.text.length === 0) return
        errorMessage = ""
        busy = true
        sddm.login(username.text, password.text, sessions.currentIndex)
    }
    Component.onCompleted: {
        root.forceActiveFocus()
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.errorMessage = "Login failed. Please try again."
            password.clear()
            password.forceActiveFocus()
        }
    }
    Keys.onPressed: event => {
        if (!revealed) {
            reveal()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape && !busy) {
            password.clear()
            revealed = false
            root.forceActiveFocus()
            event.accepted = true
        }
    }
    Image {
        id: wallpaper
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blurMax: 48
        blur: root.revealed ? 0.2 : 1.0
        Behavior on blur { NumberAnimation { duration: 400 } }
    }
    Rectangle { anchors.fill: parent; color: "#20000000" }
    MouseArea {
        anchors.fill: parent
        enabled: !root.revealed
        onClicked: root.reveal()
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 50
        spacing: -5
        opacity: root.revealed ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "hh:mm")
            font.family: root.style.font
            font.pointSize: root.style.clockSize
            font.weight: Font.Black
            color: root.style.foreground
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "dddd, MMMM dd, yyyy")
            font.family: root.style.font
            font.pointSize: root.style.dateSize
            color: root.style.foreground
        }
    }
    component GlassButton: Button {
        id: control
        font.family: root.style.font
        contentItem: Text {
            text: control.text
            font: control.font
            color: root.style.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: root.style.radius
            color: root.style.foreground
            opacity: control.down || control.hovered || control.activeFocus ? 0.3 : root.style.inputOpacity
        }
        padding: 10
    }
    component GlassCombo: ComboBox {
        font.family: root.style.font
        palette.text: root.style.foreground
        palette.buttonText: root.style.foreground
        palette.base: root.style.background
        palette.window: root.style.background
        palette.button: root.style.background
        palette.highlight: "#555960"
        palette.highlightedText: root.style.foreground
        background: Rectangle {
            radius: root.style.radius
            color: root.style.foreground
            opacity: parent.activeFocus ? 0.3 : root.style.inputOpacity
        }
    }
    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(root.style.inputWidth + 50, root.width - 40)
        spacing: 12
        opacity: root.revealed ? 1 : 0
        visible: opacity > 0
        enabled: root.revealed && !root.busy
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 100; height: 100; radius: 50
            color: "#26ffffff"
            Text {
                anchors.centerIn: parent
                text: username.text.slice(0, 1).toUpperCase()
                color: root.style.foreground
                font.family: root.style.font
                font.pointSize: 36
            }
        }
        GlassCombo {
            id: users
            Layout.fillWidth: true
            model: userModel
            textRole: "name"
            currentIndex: userModel.lastIndex
            onActivated: username.text = currentText
        }
        TextField {
            id: username
            Layout.fillWidth: true
            text: users.currentText
            placeholderText: "Username"
            color: root.style.foreground
            font.family: root.style.font
            font.pointSize: root.style.userSize
            horizontalAlignment: Text.AlignHCenter
            background: Rectangle { color: "transparent" }
            KeyNavigation.tab: password
            onAccepted: password.forceActiveFocus()
        }
        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: password
                Layout.fillWidth: true
                Layout.preferredHeight: root.style.inputHeight
                echoMode: TextInput.Password
                placeholderText: "Password"
                color: root.style.foreground
                font.family: root.style.font
                selectByMouse: true
                background: Rectangle {
                    radius: root.style.radius
                    color: root.style.foreground
                    opacity: root.style.inputOpacity
                }
                onAccepted: root.login()
            }
            GlassButton { text: "→"; onClicked: root.login(); Accessible.name: "Log in" }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 + 175
        text: root.busy ? "Logging in…" : root.errorMessage
        color: root.style.foreground
        font.family: root.style.font
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        visible: !root.revealed
        text: "Press any key"
        color: root.style.foreground
        font.family: root.style.font
    }
    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 40
        visible: root.revealed
        Text { text: "Session"; color: root.style.foreground }
        GlassCombo {
            id: sessions
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
        }
    }
    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40
        visible: root.revealed
        GlassButton {
            text: "Restart"
            enabled: sddm.canReboot && !root.busy
            onClicked: sddm.reboot()
        }
        GlassButton {
            text: "Shut down"
            enabled: sddm.canPowerOff && !root.busy
            onClicked: sddm.powerOff()
        }
    }
}
