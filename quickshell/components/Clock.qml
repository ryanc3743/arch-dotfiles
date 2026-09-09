import QtQuick

Column {
    id: clock

    spacing: -2

    property date currentTime: new Date()

    Text {
        text: Qt.formatDateTime(clock.currentTime, "HH:mm:ss")
        font.pixelSize: 15
    }

    Text {
        text: Qt.formatDateTime(clock.currentTime, "dddd, MMMM d")
        font.pixelSize: 10
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            clock.currentTime = new Date()
        }
    }
}
