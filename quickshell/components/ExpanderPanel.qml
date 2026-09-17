import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Rectangle {
    id: panel
    required property var monitorGroups
    required property var actions
    signal closeRequested()
    signal powerRequested()
    property int tab: 0
    property string query: ""
    property string result: ""
    property bool hintVisible: true
    readonly property string helper: Qt.resolvedUrl("../scripts/actions.sh").toString().replace(/^file:\/\//, "")
    readonly property string overviewHelper: Qt.resolvedUrl("../scripts/overview.sh").toString().replace(/^file:\/\//, "")
    readonly property bool calculating: /^calc(?:\s|$)/.test(query.trim())
    readonly property bool quickAction: ["ss", "ssf", "cl", "ssh", "emoji", "pm"].includes(query.trim())
    readonly property var allApps: DesktopEntries.applications.values.filter(app => !app.noDisplay)
    readonly property var apps: calculating || quickAction ? [] : allApps.filter(app =>
        (app.name + " " + app.genericName + " " + app.comment + " " + (app.keywords || []).join(" ")).toLowerCase().includes(query.trim().toLowerCase()))
    readonly property var windows: Hyprland.toplevels.values.filter(w =>
        !(w.lastIpcObject.class === "org.quickshell" && ["Applications", "Expander Power"].includes(w.title)))
    color: Theme.primary
    implicitWidth: 840
    implicitHeight: 690
    ThemeBorder { z: 20 }
    function prepare() { tab = 0; query = ""; hintVisible = true; hints.restart(); search.forceActiveFocus(); Hyprland.refreshToplevels() }
    function toggleTab() { tab = 1 - tab; if (tab === 0) search.forceActiveFocus(); Hyprland.refreshToplevels() }
    function runAction(action) {
        if (action === "pm") { powerRequested(); return }
        closeRequested()
        delayedAction.action = action
        delayedAction.restart()
    }
    function submit() {
        if (calculating) {
            if (result && !result.startsWith("Error:") && !calculator.running)
                Quickshell.execDetached([helper, "copy", result])
        } else if (quickAction) runAction(query.trim())
        else if (apps.length) { apps[0].execute(); closeRequested() }
    }
    function focusWindow(window) {
        var address = window.address
        closeRequested()
        Quickshell.execDetached([overviewHelper, "focus", address])
    }
    function iconSource(app) {
        if (!app || !app.icon) return "image://icon/application-x-executable"
        if (app.icon.startsWith("/") || app.icon.startsWith("file:")) return app.icon.startsWith("/") ? "file://" + app.icon : app.icon
        return "image://icon/" + app.icon
    }
    onQueryChanged: { result = ""; calculationDelay.restart() }
    Timer { id: hints; interval: 3000; onTriggered: panel.hintVisible = false }
    Timer { id: delayedAction; property string action; interval: 180; onTriggered: Quickshell.execDetached([panel.helper, action]) }
    Timer {
        id: calculationDelay; interval: 120
        onTriggered: {
            if (calculator.running) { restart(); return }
            if (panel.calculating) {
                calculator.requestQuery = panel.query
                calculator.command = [panel.helper, "calc", panel.query.trim().slice(4).trim()]
                calculator.running = true
            }
        }
    }
    Process {
        id: calculator
        property string requestQuery
        stdout: StdioCollector { onStreamFinished: if (calculator.requestQuery === panel.query) panel.result = text.trim() }
    }
    Timer { interval: 800; repeat: true; running: panel.visible && panel.tab === 1; onTriggered: Hyprland.refreshToplevels() }
    focus: true
    Keys.onEscapePressed: closeRequested()
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "Dashboard Center"; color: Theme.text; font.pixelSize: 25; font.bold: true; Layout.fillWidth: true }
            ExpanderButton { text: "Launcher"; highlighted: panel.tab === 0; onClicked: { panel.tab = 0; search.forceActiveFocus() } }
            ExpanderButton { text: "Overview"; highlighted: panel.tab === 1; onClicked: { panel.tab = 1; Hyprland.refreshToplevels() } }
            ExpanderButton { text: "×"; Accessible.name: "Close Expander"; onClicked: panel.closeRequested() }
        }
        TextField {
            id: search
            visible: panel.tab === 0
            Layout.fillWidth: true
            palette.text: Theme.text; palette.base: Theme.secondary; palette.highlight: Theme.energy
            placeholderText: "Search apps · calc 2+2 · ss · ssf · cl · ssh · emoji · pm"
            text: panel.query
            onTextEdited: panel.query = text
            onAccepted: panel.submit()
        }
        StyledText {
            visible: panel.tab === 0 && (panel.calculating || panel.quickAction)
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Theme.text
            text: panel.calculating ? ((panel.result || "Calculating…") + "   ·   Enter copies result") : "Enter to open " + ({ss: "region screenshot", ssf: "full screenshot", cl: "clipboard history", ssh: "SSH host picker", emoji: "emoji picker", pm: "power menu"}[panel.query.trim()] || "")
        }
        GridView {
            id: appGrid
            visible: panel.tab === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: Math.max(120, (width - 14) / 4)
            cellHeight: 102
            model: panel.apps
            ScrollBar.vertical: ScrollBar {}
            delegate: ExpanderButton {
                required property var modelData
                width: appGrid.cellWidth - 10; height: 92
                onClicked: { modelData.execute(); panel.closeRequested() }
                contentItem: Column {
                    spacing: 5
                    ThemedIcon { source: panel.iconSource(modelData); sourceSize: Qt.size(36, 36); width: 40; height: 40; anchors.horizontalCenter: parent.horizontalCenter; fillMode: Image.PreserveAspectFit }
                    StyledText { width: parent.width; text: modelData.name; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; color: Theme.text }
                }
                background: Rectangle { radius: 10; color: parent.hovered ? Qt.lighter(Theme.secondary, 1.2) : Theme.secondary }
            }
            StyledText { anchors.centerIn: parent; visible: panel.apps.length === 0 && !panel.calculating && !panel.quickAction; text: "No matching applications"; color: Theme.text }
        }
        Workspaces {
            visible: panel.tab === 1
            Layout.alignment: Qt.AlignHCenter
            monitorGroups: panel.monitorGroups
            actions: panel.actions
            compact: true
        }
        GridView {
            id: windowGrid
            visible: panel.tab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 3
            cellHeight: 180
            model: panel.windows
            ScrollBar.vertical: ScrollBar {}
            delegate: ExpanderButton {
                id: windowCard
                required property var modelData
                width: windowGrid.cellWidth - 10; height: 170
                onClicked: panel.focusWindow(modelData)
                background: Rectangle { radius: 10; color: windowCard.hovered ? Qt.lighter(Theme.secondary, 1.2) : Theme.secondary; border.color: Theme.energy; border.width: windowCard.modelData.activated ? 1 : 0 }
                contentItem: ColumnLayout {
                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        ScreencopyView {
                            id: preview
                            anchors.fill: parent
                            captureSource: panel.visible && panel.tab === 1 ? windowCard.modelData.wayland : null
                            live: panel.visible && panel.tab === 1
                            paintCursor: false
                        }
                        StyledText { anchors.centerIn: parent; visible: !preview.hasContent; text: windowCard.modelData.lastIpcObject.class || "Window"; color: Theme.text; width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                    }
                    StyledText { Layout.fillWidth: true; text: windowCard.modelData.title; color: Theme.text; elide: Text.ElideRight }
                    StyledText { Layout.fillWidth: true; text: windowCard.modelData.lastIpcObject.workspace?.name === "special:expander-minimized" ? "Minimized · click to restore" : "Workspace " + (windowCard.modelData.lastIpcObject.workspace?.name || ""); color: Theme.energy; font.pixelSize: 12 }
                }
            }
            StyledText { anchors.centerIn: parent; visible: panel.windows.length === 0; text: "No open windows"; color: Theme.text }
        }
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: [{id:"ss", label:"Screenshot"}, {id:"cl", label:"Clipboard"}, {id:"ssh", label:"SSH"}, {id:"emoji", label:"Emoji"}, {id:"pm", label:"Power"}]
                ExpanderButton { required property var modelData; text: modelData.label; onClicked: panel.runAction(modelData.id) }
            }
            Item { Layout.fillWidth: true }
            ExpanderButton { text: "?"; Accessible.name: "Show shortcut hints"; onClicked: { panel.hintVisible = !panel.hintVisible; if (panel.hintVisible) hints.restart() } }
        }
        RowLayout {
            visible: panel.hintVisible
            StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Tap Super: launcher · tap again: overview · hold then release: power · Esc: close"; color: Theme.energy; font.pixelSize: 12 }
            ExpanderButton { text: "×"; Accessible.name: "Dismiss hints"; onClicked: panel.hintVisible = false }
        }
    }
}
