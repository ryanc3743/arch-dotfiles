import QtQuick
import QtQuick.Layouts

Rectangle {
    id: utilities
    required property var appSettings
    required property var actions
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    implicitWidth: utilityRow.implicitWidth + 16
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Row {
        id: utilityRow
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: utilities.appSettings.utilities
            DockButton {
                required property var modelData
                objectName: "utility-" + modelData.id
                width: 42
                label: modelData.label
                description: utilities.appSettings.description(modelData.id)
                accentColor: utilities.appSettings.accentColor
                textColor: utilities.appSettings.textColor
                mutedColor: utilities.appSettings.mutedColor
                popupColor: utilities.appSettings.surfaceColor
                popupFontSize: utilities.appSettings.popupFontSize
                popupMaxWidth: utilities.appSettings.popupMaxWidth
                popupBorderWidth: utilities.appSettings.popupBorderWidth
                iconSource: utilities.appSettings.icon(modelData.id)
                fallbackSource: utilities.appSettings.defaultIcon(modelData.id)
                onClicked: utilities.actions.activate(modelData.id)
            }
        }
    }
}
