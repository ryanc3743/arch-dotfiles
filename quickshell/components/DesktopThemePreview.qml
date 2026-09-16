import QtQuick
import QtQuick.Layouts

Rectangle {
    id: preview
    required property var theme
    required property var appSettings
    property bool tintIcons: true
    property real barOpacity: 1
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        Text {
            text: "Live desktop preview"
            color: Theme.text
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            text: "Updates as you edit. Save applies it."
            color: Theme.muted
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        ThemePreviewCanvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 280
            theme: preview.theme
            appSettings: preview.appSettings
            tintIcons: preview.tintIcons
            barOpacity: preview.barOpacity
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Theme.muted
            text: "Primary: surfaces\nSecondary: panels\nTertiary: hover states\nAccent: borders and selection\nEnergy: icons and animation\nText / Outline: readable labels\nSubtitle: secondary labels"
        }
        Item { Layout.fillHeight: true }
    }
}