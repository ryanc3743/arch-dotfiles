import QtQuick
import QtQuick.Layouts

/* HUD gold chip used by the full-bleed gallery screen (and the wallpaper
   picker once the gallery pill lands there too). *

 * API: `text`, `colorWay` (HudTag.Gold), `onClicked`. Renders as an
   uppercase gold-accented tag pill with hover energy. */
Rectangle {
    id: tag

    enum ColorWay { Gold }

    property string text: ""
    property int colorWay: HudTag.Gold
    signal clicked()

    implicitWidth: label.implicitWidth + 34
    implicitHeight: 34

    radius: 3
    color: Qt.rgba(0, 0, 0, 0.4)
    border.color: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, tagTap.hovered ? 0.85 : 0.35)
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: 110 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: tag.text.toUpperCase()
        color: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, tagTap.hovered ? 1 : 0.85)
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1.4
    }

    MouseArea {
        id: tagTap
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tag.clicked()
    }
}