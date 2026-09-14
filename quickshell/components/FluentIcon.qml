import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: icon
    property string name: "apps"
    property int iconSize: 48
    property color color: Theme.choose("#cdd6f4", "energy")
    Image {
        id: artwork
        anchors.centerIn: parent
        width: icon.iconSize; height: icon.iconSize
        sourceSize: Qt.size(icon.iconSize * 2, icon.iconSize * 2)
        source: Qt.resolvedUrl("../assets/fluent/" + icon.name + ".svg")
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    ColorOverlay { anchors.fill: artwork; source: artwork; color: icon.color }
}
