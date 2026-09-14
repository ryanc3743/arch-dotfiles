import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    ThemeBorder { z: 20 }
    id: panel
    signal closeRequested()
    color: Theme.choose("#1e1e2e", "primary")
    implicitWidth: 720
    implicitHeight: 620
    property string query: ""
    readonly property var allApps: DesktopEntries.applications.values.filter(app => !app.noDisplay)
    readonly property var apps: allApps.filter(app => {
        if (!panel.query.trim()) return true
        var needle = panel.query.toLowerCase()
        return (app.name + " " + app.genericName + " " + app.comment + " " + (app.keywords || []).join(" ")).toLowerCase().includes(needle)
    })
    function prepare() { query = ""; search.forceActiveFocus() }
    function iconSource(app) {
        if (!app || !app.icon) return "image://icon/application-x-executable"
        if (app.icon.startsWith("/") || app.icon.startsWith("file:")) return app.icon.startsWith("/") ? "file://" + app.icon : app.icon
        return "image://icon/" + app.icon
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "Applications"; color: Theme.choose("#cdd6f4", "text"); font.pixelSize: 25; font.bold: true; Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.energy; palette.highlightedText: Theme.primary; text: "Done"; onClicked: panel.closeRequested() }
        }
        TextField { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.energy; palette.highlightedText: Theme.primary;
            id: search
            objectName: "launcher-search"
            Layout.fillWidth: true
            placeholderText: "Search applications"
            text: panel.query
            onTextEdited: panel.query = text
            Keys.onEscapePressed: panel.closeRequested()
            Keys.onReturnPressed: if (panel.apps.length) { panel.apps[0].execute(); panel.closeRequested() }
            Component.onCompleted: forceActiveFocus()
        }
        StyledText {
            visible: panel.apps.length === 0
            text: "No matching applications"
            color: Theme.choose("#a6adc8", "muted")
        }
        GridView {
            id: appGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.max(120, (width - 14) / 3)
            cellHeight: 102
            model: panel.apps
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: Button {
                required property var modelData
                objectName: "launcher-app-" + modelData.id
                width: appGrid.cellWidth - 10
                height: 92
                onClicked: { modelData.execute(); panel.closeRequested() }
                contentItem: Column {
                    spacing: 5
                    ThemedIcon { source: panel.iconSource(modelData); sourceSize: Qt.size(36,36); width: 40; height: 40; anchors.horizontalCenter: parent.horizontalCenter; fillMode: Image.PreserveAspectFit }
                    StyledText { width: parent.width; text: modelData.name; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; color: Theme.text }
                }
                background: Rectangle { radius: 10; color: parent.hovered ? Qt.lighter(Theme.secondary,1.2) : Theme.secondary }
            }
        }
    }
}
