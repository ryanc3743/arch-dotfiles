import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Rectangle {
    id: status
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    property string sshState: "unknown"
    property string sunshineState: "unknown"
    implicitWidth: 118
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    function mark(state) { return state === "active" ? "●" : "○" }
    Column {
        anchors.centerIn: parent
        spacing: 2
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            StyledText { text: mark(status.sshState) + " SSH"; color: status.sshState === "active" ? "#a6e3a1" : "#f38ba8"; font.pixelSize: 12; font.bold: true }
            StyledText { text: mark(status.sunshineState) + " SUN"; color: status.sunshineState === "active" ? "#a6e3a1" : "#f38ba8"; font.pixelSize: 12; font.bold: true }
        }
        StyledText { text: status.sshState === "active" && status.sunshineState === "active" ? "remote access ready" : "remote service down"; color: Theme.muted; font.family: "monospace"; font.pixelSize: 10 }
    }
    MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    ToolTip.visible: false
    ToolTip.text: "OpenSSH: " + status.sshState + "\nSunshine: " + status.sunshineState
    DescriptionPopup {
        target: hover
        title: "Remote services"
        description: "OpenSSH: " + status.sshState + "\nSunshine: " + status.sunshineState
    }
    Process {
        id: ssh
        command: ["systemctl", "is-active", "sshd.service"]
        stdout: StdioCollector { onStreamFinished: status.sshState = text.trim() }
    }
    Process {
        id: sunshine
        command: ["systemctl", "--user", "is-active", "app-dev.lizardbyte.app.Sunshine.service"]
        stdout: StdioCollector { onStreamFinished: status.sunshineState = text.trim() }
    }
    Timer {
        interval: 10000
        repeat: true
        running: status.visible
        triggeredOnStart: true
        onTriggered: { if (!ssh.running) ssh.running = true; if (!sunshine.running) sunshine.running = true }
    }
}
