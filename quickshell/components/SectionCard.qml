import QtQuick

Rectangle {
    id: card
    default property alias content: host.data
    required property string title
    required property string description
    property real previewHeight: 70
    signal clicked()

    radius: 16
    color: Qt.rgba(0, 0, 0, 0.2)
    border.color: Qt.rgba(1, 1, 1, 0.1)
    border.width: 1
    scale: hover.hovered ? 1.02 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }
    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6
        Item {
            id: host
            width: parent.width
            height: card.previewHeight
        }
        Text {
            width: parent.width
            text: card.title
            color: Theme.text
            font.pixelSize: 18
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: card.description
            color: Theme.muted
            font.pixelSize: 12
            wrapMode: Text.Wrap
            lineHeight: 1.25
        }
    }
    HoverHandler { id: hover }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }
}