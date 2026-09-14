import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: card
    required property var preset
    required property var appSettings
    property bool selected: false
    readonly property var colors: preset.theme || ({})
    readonly property color surface: colors.surfaceColor || "#1e1e2e"
    readonly property color energy: colors.accentColor || "#cba6f7"
    readonly property color edge: colors.detailAccentColor || energy
    readonly property color ink: surface.hslLightness > .55 ? "#15151d" : "#f4f4fa"
    readonly property var swatches: [
        {label:"Primary",color:colors.surfaceColor || "#1e1e2e"},
        {label:"Secondary",color:colors.secondaryColor || "#313244"},
        {label:"Tertiary",color:colors.tertiaryColor || "#45475a"},
        {label:"Energy",color:colors.accentColor || "#cba6f7"},
        {label:"Accent",color:colors.detailAccentColor || "#89b4fa"},
        {label:"Text",color:colors.textColor || "#cdd6f4"},
        {label:"Text outline",color:colors.textOutlineColor || "#11111b"}
    ]
    implicitWidth: 260
    implicitHeight: 184
    padding: 14
    hoverEnabled: true
    Accessible.name: "Edit colorway " + preset.name
    background: Item {
        Rectangle { anchors.fill: parent; anchors.topMargin: 4; anchors.leftMargin: 4; color: "#40000000"; radius: 6 }
        Rectangle {
            anchors.fill: parent; anchors.bottomMargin: 4; anchors.rightMargin: 4
            radius: 6; color: card.surface
            border.color: card.selected || card.hovered || card.activeFocus ? card.edge : Qt.rgba(card.edge.r,card.edge.g,card.edge.b,.5)
            border.width: card.selected || card.activeFocus ? 2 : 1
            Rectangle {
                anchors.fill: parent; anchors.margins: 2; radius: 4
                gradient: Gradient {
                    GradientStop { position: 0; color: card.hovered ? "#30ffffff" : "#18ffffff" }
                    GradientStop { position: .45; color: "#02ffffff" }
                    GradientStop { position: 1; color: "#19000000" }
                }
            }
            Rectangle { x: 12; y: 0; width: 42; height: 3; color: card.edge }
            Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; width: 16; height: 2; color: card.edge; rotation: -45 }
        }
    }
    contentItem: ColumnLayout {
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Text { text: card.preset.name; color: card.ink; font.pixelSize: 17; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: card.selected ? "EDITING" : "EDIT ↗"; color: card.ink; opacity: .65; font.pixelSize: 9; font.letterSpacing: 1 }
        }
        Row {
            spacing: 10; Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: card.appSettings.pinnedApps.slice(0,4)
                Rectangle {
                    required property var modelData
                    width: 40; height: 44; radius: 5
                    color: card.colors.secondaryColor || "#313244"
                    border.color: card.edge; border.width: 1
                    ThemedIcon {
                        anchors.fill: parent; anchors.margins: 5
                        source: card.appSettings.icon(modelData.id)
                        fillMode: Image.PreserveAspectFit
                        tintEnabled: !!card.preset.tint
                        tintColor: card.energy
                    }
                }
            }
        }
        Row {
            id: swatchRow
            Layout.fillWidth: true
            spacing: 3
            Repeater {
                model: card.swatches
                Rectangle {
                    required property var modelData
                    width: (swatchRow.width-18)/7; height: 27
                    color: modelData.color
                    border.color: Qt.rgba(card.ink.r,card.ink.g,card.ink.b,.4)
                    border.width: 1
                    ToolTip.visible: swatchHover.hovered
                    ToolTip.text: modelData.label
                    HoverHandler { id: swatchHover }
                }
            }
        }
        Text { text: "PRIMARY  /  SECONDARY  /  TERTIARY  /  ENERGY  /  ACCENT  /  TEXT  /  OUTLINE"; color: card.ink; opacity: .6; font.pixelSize: 6; Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
}
