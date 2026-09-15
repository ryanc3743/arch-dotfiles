import QtQuick
import QtQuick.Layouts

Rectangle {
    id: preview
    required property var theme
    required property var appSettings
    property bool tintIcons: true
    property real barOpacity: 1
    function value(key, fallback) { return theme[key] === undefined ? fallback : theme[key] }
    readonly property color primary: value("surfaceColor","#1e1e2e")
    readonly property color secondary: value("secondaryColor","#313244")
    readonly property color tertiary: value("tertiaryColor","#45475a")
    readonly property color energy: value("accentColor","#cba6f7")
    readonly property color accent: value("detailAccentColor","#89b4fa")
    readonly property color subtitle: value("mutedColor","#a6adc8")
    readonly property color ink: value("textColor","#cdd6f4")
    color: Theme.secondary
    radius: 8
    component PreviewText: Text {
        color: preview.ink
        style: preview.value("textStyle",0)
        styleColor: preview.value("textOutlineColor","#11111b")
        wrapMode: Text.Wrap
    }
    component PreviewBorder: ThemeBorder {
        lineColor: preview.accent
        lineStyle: preview.value("borderStyle","solid")
        lineWidth: preview.value("borderWidth",1)
        cornerRadius: preview.value("borderRadius",8)
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 14; spacing: 14
        Text { text: "Live desktop preview"; color: Theme.text; font.pixelSize: 18; font.bold: true }
        Text { text: "Updates as you edit. Save applies it."; color: Theme.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 410
            color: Qt.darker(preview.primary,1.7)
            radius: 8; clip: true
            Rectangle {
                id: miniBar
                width: parent.width; height: 58
                color: Qt.rgba(preview.primary.r,preview.primary.g,preview.primary.b,preview.barOpacity)
                PreviewBorder { cornerRadius: 0 }
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Repeater {
                        model: ["firefox","dolphin","steam"]
                        Rectangle {
                            required property string modelData
                            width: 36; height: 38
                            color: preview.secondary; radius: preview.value("borderRadius",8)
                            PreviewBorder {}
                            ThemedIcon { anchors.fill: parent; anchors.margins: 4; source: preview.appSettings.icon(modelData); fillMode: Image.PreserveAspectFit; tintEnabled: preview.tintIcons; tintColor: preview.energy }
                        }
                    }
                    PreviewText { anchors.verticalCenter: parent.verticalCenter; text: "12:34"; font.pixelSize: 14 }
                }
            }
            Rectangle {
                x: 12; y: 85; width: parent.width-24; height: 168
                color: preview.primary; radius: preview.value("borderRadius",8)
                PreviewBorder {}
                Column {
                    anchors.fill: parent; anchors.margins: 12; spacing: 10
                    PreviewText { text: "Applications"; font.pixelSize: 18; font.bold: true }
                    Rectangle {
                        width: parent.width; height: 30; color: preview.secondary
                        PreviewText { anchors.centerIn: parent; text: "Search applications"; font.pixelSize: 12 }
                    }
                    Rectangle {
                        width: parent.width; height: 32; color: preview.tertiary
                        PreviewBorder {}
                        PreviewText { anchors.centerIn: parent; text: "Selected / hover state"; font.pixelSize: 12 }
                    }
                    PreviewText { width: parent.width; text: "Text color and outline sample"; font.pixelSize: 13 }
                }
            }
            Rectangle {
                x: 12; y: 280; width: parent.width-24; height: 110
                color: preview.primary; radius: preview.value("borderRadius",8)
                PreviewBorder {}
                Column {
                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                    PreviewText { text: "DESCRIPTION"; color: preview.energy; font.bold: true }
                    PreviewText { width: parent.width; text: "Subtitle color preview"; color: preview.subtitle; font.pixelSize: 13 }
                }
            }
        }
        Text { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted; text: "Primary: surfaces\nSecondary: panels\nTertiary: hover states\nAccent: borders and selection\nEnergy: icons and animation\nText / Outline: readable labels\nSubtitle: secondary labels" }
        Item { Layout.fillHeight: true }
    }
}
