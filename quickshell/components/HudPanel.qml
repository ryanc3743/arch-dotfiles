import QtQuick
import QtQuick.Layouts

Rectangle {
    id: hud
    default property alias content: host.data
    required property string number
    required property string title
    required property string description
    property real previewHeight: 64
    signal clicked()

    radius: 3
    color: Qt.rgba(0, 0, 0, 0.32)
    border.color: hover.hovered ? Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.7) : Qt.rgba(1, 1, 1, 0.1)
    border.width: 1

    property color accent: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, hover.hovered ? 1 : 0.72)

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 14
        y: 0
        width: hover.hovered ? parent.width - 28 : 90
        height: 2
        color: hud.accent
        Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: 18
        spacing: 10
        RowLayout {
            width: parent.width
            spacing: 10
            Text {
                text: hud.number
                color: hud.accent
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 2
            }
            Rectangle {
                width: 1
                height: 13
                color: Qt.rgba(hud.accent.r, hud.accent.g, hud.accent.b, 0.4)
            }
            Text {
                Layout.fillWidth: true
                text: hud.title.toUpperCase()
                color: Theme.text
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 1.6
                elide: Text.ElideRight
            }
            Text {
                text: ">"
                color: hud.accent
                font.pixelSize: 14
                font.bold: true
            }
        }
        Item {
            id: host
            width: parent.width
            height: hud.previewHeight
        }
        Text {
            width: parent.width
            text: hud.description.toUpperCase()
            color: Theme.muted
            font.pixelSize: 10
            font.letterSpacing: 0.8
            opacity: 0.85
            elide: Text.ElideRight
        }
    }

    Canvas {
        id: corners
        anchors.fill: parent
        property color frameColor: hud.accent

        Connections {
            target: hud
            function onAccentChanged() { corners.frameColor = hud.accent; corners.requestPaint() }
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

    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: hud.clicked()
    }
}