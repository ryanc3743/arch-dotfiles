import QtQuick

Rectangle {
    id: clock
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    property date currentTime: new Date()
    implicitWidth: 164
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Column {
        id: clockFace
        anchors.centerIn: parent
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.currentTime, "HH:mm:ss")
            font.pixelSize: 30
            color: Theme.choose("#cdd6f4", "text")
        }
        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.currentTime, "ddd, MMM d")
            font.pixelSize: 20
            color: Theme.choose("#bac2de", "text")
        }
    }
    MouseArea { id: clockMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
    DescriptionPopup {
        target: clockMouse
        title: "Clock"
        description: "The present moment, rendered with unnecessary drama."
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.currentTime = new Date()
    }
}
