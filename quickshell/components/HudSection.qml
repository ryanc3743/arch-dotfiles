import QtQuick
import QtQuick.Layouts

Rectangle {
    id: section
    default property alias content: host.data
    required property string number
    required property string title
    property string description: ""
    property string status: ""
    property bool fills: false

    radius: 3
    color: Qt.rgba(0, 0, 0, 0.32)
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    property color accent: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.8)

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 14
        y: 0
        width: 90
        height: 2
        color: section.accent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: 18
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: section.number
                color: section.accent
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 2
            }
            Rectangle {
                width: 1
                height: 13
                color: Qt.rgba(section.accent.r, section.accent.g, section.accent.b, 0.4)
            }
            Text {
                Layout.fillWidth: true
                text: section.title.toUpperCase()
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.6
                elide: Text.ElideRight
            }
            Text {
                visible: section.status !== ""
                text: section.status.toUpperCase()
                color: Theme.energy
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        }
        ColumnLayout {
            id: host
            Layout.fillWidth: true
            Layout.fillHeight: section.fills
            spacing: 8
        }
        Text {
            Layout.fillWidth: true
            visible: section.description !== ""
            text: section.description.toUpperCase()
            color: Theme.muted
            font.pixelSize: 10
            font.letterSpacing: 0.8
            opacity: 0.85
            wrapMode: Text.WordWrap
        }
    }

    Canvas {
        id: corners
        anchors.fill: parent
        property color frameColor: section.accent
        Connections {
            target: section
            function onAccentChanged() { corners.frameColor = section.accent; corners.requestPaint() }
        }
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = corners.frameColor.toString()
            ctx.lineWidth = 2
            ctx.lineCap = "square"
            var m = 7
            var l = 9
            ctx.beginPath()
            ctx.moveTo(m, m + l); ctx.lineTo(m, m); ctx.lineTo(m + l, m)
            ctx.moveTo(width - m - l, m); ctx.lineTo(width - m, m); ctx.lineTo(width - m, m + l)
            ctx.moveTo(m, height - m - l); ctx.lineTo(m, height - m); ctx.lineTo(m + l, height - m)
            ctx.moveTo(width - m - l, height - m); ctx.lineTo(width - m, height - m); ctx.lineTo(width - m, height - m - l)
            ctx.stroke()
        }
        antialiasing: true
    }
}