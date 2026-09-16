import QtQuick
import QtQuick.Layouts

Item {
    id: canvas
    required property var theme
    required property var appSettings
    property bool tintIcons: true
    property real barOpacity: 1
    property var swatchRoles: []
    property int selectedSwatch: -1
    signal rolePicked(string key, string label)

    function value(key, fallback) { return theme[key] === undefined ? fallback : theme[key] }
    readonly property color primary: value("surfaceColor", "#1e1e2e")
    readonly property color secondary: value("secondaryColor", "#313244")
    readonly property color tertiary: value("tertiaryColor", "#45475a")
    readonly property color energy: value("accentColor", "#cba6f7")
    readonly property color accentCol: value("detailAccentColor", "#89b4fa")
    readonly property color subtitle: value("mutedColor", "#a6adc8")
    readonly property color ink: value("textColor", "#cdd6f4")
    readonly property color outline: value("textOutlineColor", "#11111b")
    readonly property int textStyle: value("textStyle", 0)
    readonly property int borderRadius: value("borderRadius", 8)

    Rectangle {
        anchors.fill: parent
        radius: 12
        clip: true
        color: "transparent"
        border.color: Qt.rgba(0, 0, 0, 0.3)
        border.width: 1

        Rectangle {
            color: Qt.rgba(canvas.tertiary.r, canvas.tertiary.g, canvas.tertiary.b, 0.28)
            width: parent.width * 0.55
            height: parent.height * 0.75
            x: parent.width * 0.42
            y: -parent.height * 0.2
            radius: parent.width * 0.35
            rotation: -16
        }
        Rectangle {
            color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.14)
            width: parent.width * 0.5
            height: parent.height * 0.55
            x: -parent.width * 0.15
            y: parent.height * 0.42
            radius: parent.width * 0.4
            rotation: 22
        }

        Rectangle {
            width: parent.width
            height: 58
            color: Qt.rgba(canvas.primary.r, canvas.primary.g, canvas.primary.b, canvas.barOpacity)
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.7)
                border.width: canvas.value("borderWidth", 1)
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: ["firefox", "dolphin", "steam"]
                    Rectangle {
                        required property string modelData
                        width: 36
                        height: 38
                        radius: 7
                        color: canvas.secondary
                        border.color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.6)
                        border.width: canvas.value("borderWidth", 1)
                        ThemedIcon {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: canvas.appSettings.icon(modelData)
                            fillMode: Image.PreserveAspectFit
                            tintEnabled: canvas.tintIcons
                            tintColor: canvas.energy
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "12:34"
                    color: canvas.ink
                    font.pixelSize: 14
                    style: canvas.textStyle
                    styleColor: canvas.outline
                }
            }
        }

        Rectangle {
            x: 12
            y: 82
            width: parent.width - 24
            height: Math.max(60, parent.height - 82 - 92 - 30)
            radius: canvas.borderRadius
            color: canvas.primary
            border.color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.7)
            border.width: canvas.value("borderWidth", 1)
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 9
                Text {
                    text: "Applications"
                    color: canvas.ink
                    font.pixelSize: 17
                    font.bold: true
                    style: canvas.textStyle
                    styleColor: canvas.outline
                }
                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 5
                    color: canvas.secondary
                    Text {
                        anchors.centerIn: parent
                        text: "Search applications"
                        color: canvas.ink
                        font.pixelSize: 12
                        style: canvas.textStyle
                        styleColor: canvas.outline
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 30
                    radius: canvas.borderRadius
                    color: canvas.tertiary
                    border.color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.7)
                    border.width: canvas.value("borderWidth", 1)
                    Text {
                        anchors.centerIn: parent
                        text: "Selected / hover state"
                        color: canvas.ink
                        font.pixelSize: 12
                        style: canvas.textStyle
                        styleColor: canvas.outline
                    }
                }
                Text {
                    width: parent.width
                    text: "Text color and outline sample"
                    color: canvas.ink
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    style: canvas.textStyle
                    styleColor: canvas.outline
                }
            }
        }

        Rectangle {
            x: 12
            height: 84
            anchors.bottom: parent.bottom
            anchors.bottomMargin: canvas.swatchRoles.length > 0 ? 34 : 8
            width: parent.width - 24
            radius: canvas.borderRadius
            color: canvas.primary
            border.color: Qt.rgba(canvas.accentCol.r, canvas.accentCol.g, canvas.accentCol.b, 0.7)
            border.width: canvas.value("borderWidth", 1)
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7
                Text {
                    text: "DESCRIPTION"
                    color: canvas.energy
                    font.bold: true
                    font.pixelSize: 12
                    style: canvas.textStyle
                    styleColor: canvas.outline
                }
                Text {
                    width: parent.width
                    text: "Subtitle color preview · hover hint"
                    color: canvas.subtitle
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 30
            visible: canvas.swatchRoles.length > 0
            color: Qt.rgba(0, 0, 0, 0.4)
            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                Repeater {
                    model: canvas.swatchRoles
                    Rectangle {
                        id: sw
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 5
                        color: canvas.value(sw.modelData.key, "#313244")
                        border.color: canvas.selectedSwatch === canvas.swatchRoles.indexOf(sw.modelData) ? "white" : Qt.rgba(0, 0, 0, 0.6)
                        border.width: canvas.selectedSwatch === canvas.swatchRoles.indexOf(sw.modelData) ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: sw.modelData.label
                            color: "white"
                            font.pixelSize: 9
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.8)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: canvas.rolePicked(sw.modelData.key, sw.modelData.label)
                        }
                    }
                }
            }
        }
    }
}