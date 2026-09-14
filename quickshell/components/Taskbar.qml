// Serpantinum Dock.qml adaptation, AGPL-3.0; modified 2026-09-12.
// See ../third-party/SERPANTINUM.md.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: dock
    required property var appSettings
    required property var actions
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    implicitWidth: appRow.implicitWidth + 20
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Row {
        id: appRow
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            model: dock.appSettings.pinnedApps
            DockButton {
                required property var modelData
                property var windows: dock.actions.windowsFor(modelData.id)
                objectName: "app-" + modelData.id
                label: modelData.label + (windows.length ? " • " + windows.length + " open" : "")
                description: dock.appSettings.description(modelData.id)
                accentColor: dock.appSettings.accentColor
                textColor: dock.appSettings.textColor
                mutedColor: dock.appSettings.mutedColor
                popupColor: dock.appSettings.surfaceColor
                popupFontSize: dock.appSettings.popupFontSize
                popupMaxWidth: dock.appSettings.popupMaxWidth
                popupBorderWidth: dock.appSettings.popupBorderWidth
                iconSource: dock.appSettings.icon(modelData.id)
                fallbackSource: dock.appSettings.defaultIcon(modelData.id)
                running: windows.length > 0
                active: windows.some(w => w.activated)
                windowAddress: windows.length ? (windows.find(w => w.activated) || windows[0]).address : ""
                onClicked: dock.actions.activate(modelData.id)
                onWindowDropped: (address, workspaceId) => dock.actions.moveWindow(address, workspaceId)
            }
        }
    }
}
