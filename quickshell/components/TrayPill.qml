import QtQuick
import QtQuick.Controls
import Quickshell.Services.SystemTray

Rectangle {
    id: pill
    property real panelOpacity: 0.34
    property bool continuousStyle: false
    readonly property var displayedItems: SystemTray.items.values.filter(item => !/steam|sunshine/i.test(
        String(item.id || "") + " " + String(item.title || "") + " " + String(item.tooltipTitle || "")))
    readonly property int itemCount: displayedItems.length
    implicitWidth: Math.max(64, 30 + itemCount * 26)
    implicitHeight: 64
    function iconSource(value) {
        if (!value) return ""
        if (value.startsWith("image://") || value.startsWith("file:")) return value
        return value.startsWith("/") ? "file://" + value : "image://icon/" + value
    }
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Row {
        anchors.centerIn: parent
        spacing: 7
        Repeater {
            model: pill.displayedItems
            delegate: Item {
                required property var modelData
                width: 24
                height: 28
                ThemedIcon {
                    id: trayIcon
                    anchors.fill: parent
                    source: pill.iconSource(modelData.icon)
                    sourceSize: Qt.size(24, 24)
                    fillMode: Image.PreserveAspectFit
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: trayIcon.status === Image.Error || trayIcon.status === Image.Null
                    text: "•"
                    color: Theme.choose("#a6adc8", "muted")
                    font.pixelSize: 24
                }
                ToolTip.visible: trayMouse.containsMouse
                ToolTip.text: modelData.tooltipTitle || modelData.title || "Tray item"
                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (modelData) modelData.activate()
                }
            }
        }
        StyledText { visible: pill.itemCount === 0; text: "󰀻"; color: Theme.choose("#a6adc8", "muted"); font.pixelSize: 20 }
    }
}
