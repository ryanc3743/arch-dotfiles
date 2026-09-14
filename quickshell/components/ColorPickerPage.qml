import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "ColorHistory.js" as History

Rectangle {
    id: page
    required property var appSettings
    property string roleLabel: "Primary"
    property color selectedColor: "#1e1e2e"
    property real hue: 0.6
    property var previewTheme: ({surfaceColor:"#1e1e2e",secondaryColor:"#313244",accentColor:"#cba6f7"})
    property bool leaveIconsDefault: false
    signal iconModeChanged(bool leaveDefault)
    property string roleKey: "surfaceColor"
    property var history: ({entries:[],index:-1})
    property bool historyReady: false
    property bool restoringHistory: false
    property string historyRole: ""
    function snapshot() { return {color:selectedColor.toString(),leaveDefault:leaveIconsDefault} }
    function persistHistory() { if (historyReady) appSettings.saveColorHistory(historyRole, history) }
    function flushHistory() {
        historyTimer.stop()
        if (!historyReady || restoringHistory) return
        history = History.record(history,snapshot())
        persistHistory()
    }
    function restoreEntry() {
        var value = history.entries[history.index]
        if (!value) return
        restoringHistory = true
        selectedColor = value.color
        hue = Math.max(0,selectedColor.hsvHue)
        iconModeChanged(value.leaveDefault)
        restoringHistory = false
    }
    function startHistory() {
        historyReady = false
        historyRole = roleKey
        var previous = appSettings.colorHistory[roleKey]
        history = previous && previous.entries && previous.entries.length ? JSON.parse(JSON.stringify(previous)) : History.record({entries:[],index:-1},snapshot())
        restoreEntry()
        historyReady = true
        persistHistory()
    }
    function undo() {
        flushHistory()
        if (history.index <= 0) return
        history = History.move(history,-1)
        restoreEntry()
        persistHistory()
    }
    function redo() {
        if (historyTimer.running) flushHistory()
        if (history.index >= history.entries.length-1) return
        history = History.move(history,1)
        restoreEntry()
        persistHistory()
    }
    onVisibleChanged: {
        if (visible) startHistory()
        else { flushHistory(); historyReady = false }
    }
    onSelectedColorChanged: if (visible && historyReady && !restoringHistory) historyTimer.restart()
    onLeaveIconsDefaultChanged: if (visible && historyReady && !restoringHistory) historyTimer.restart()
    Timer { id: historyTimer; interval: 200; onTriggered: page.flushHistory() }
    Shortcut { sequence: "Ctrl+Z"; enabled: page.visible && !!page.QsWindow.window && page.QsWindow.window.visible; onActivated: page.undo() }
    Shortcut { sequences: ["Ctrl+Shift+Z","Ctrl+Y"]; enabled: page.visible && !!page.QsWindow.window && page.QsWindow.window.visible; onActivated: page.redo() }
    signal accepted(color value)
    signal canceled()
    color: Theme.primary
    function preview(key) { return key === roleKey ? selectedColor : (previewTheme[key] || "#313244") }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Button { palette.button: Theme.secondary; palette.buttonText: Theme.text; text: "Undo"; enabled: page.history.index > 0 || historyTimer.running; onClicked: page.undo() }
            Button { palette.button: Theme.secondary; palette.buttonText: Theme.text; text: "Redo"; enabled: page.history.index < page.history.entries.length-1; onClicked: page.redo() }
            StyledLabel { text: "History saved for this color"; color: Theme.muted }
        }
        StyledLabel { text: page.roleLabel + " color"; font.pixelSize: 24; color: Theme.text }
        StyledLabel { text: "Choose a palette tile, or adjust the color square below."; color: Theme.muted }
        Grid {
            columns: 12; spacing: 3; Layout.alignment: Qt.AlignHCenter
            Repeater {
                model: 72
                Rectangle {
                    required property int index
                    width: 34; height: 20
                    color: index < 12 ? Qt.hsla(0,0,index/11,1) : Qt.hsla((index%12)/12,0.7,0.16+Math.floor(index/12)*0.13,1)
                    border.width: page.selectedColor === color ? 3 : 0
                    border.color: "#ffffff"
                    MouseArea { anchors.fill: parent; onClicked: { page.selectedColor = parent.color; page.hue = parent.color.hsvHue < 0 ? 0 : parent.color.hsvHue } }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Rectangle {
                id: square
                Layout.preferredWidth: 180; Layout.preferredHeight: 180
                color: Qt.hsva(page.hue,1,1,1)

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } }
                }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } }
                }
                Rectangle {
                    x: page.selectedColor.hsvSaturation * square.width - 5
                    y: (1-page.selectedColor.hsvValue)*square.height - 5
                    width: 10; height: 10; radius: 5; color: "transparent"; border.color: "white"; border.width: 2
                }
                MouseArea {
                    anchors.fill: parent
                    function pick(mouse) { page.selectedColor = Qt.hsva(page.hue,Math.max(0,Math.min(1,mouse.x/width)),1-Math.max(0,Math.min(1,mouse.y/height)),1) }
                    onPressed: mouse => pick(mouse)
                    onPositionChanged: mouse => { if (pressed) pick(mouse) }
                }
            }
            Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                orientation: Qt.Vertical; Layout.preferredHeight: 180
                from: 0; to: 1; value: page.hue
                onMoved: { page.hue = value; page.selectedColor = Qt.hsva(value,Math.max(.1,page.selectedColor.hsvSaturation),Math.max(.1,page.selectedColor.hsvValue),1) }
            }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 88
            color: page.preview("surfaceColor")
            ThemeBorder {
                lineColor: page.preview("detailAccentColor")
                lineStyle: page.previewTheme.borderStyle || "solid"
                lineWidth: page.previewTheme.borderWidth === undefined ? 1 : page.previewTheme.borderWidth
                cornerRadius: page.previewTheme.borderRadius === undefined ? 8 : page.previewTheme.borderRadius
            }
            Row {
                anchors.centerIn: parent; spacing: 16
                Rectangle { width: 44; height: 44; radius: 8; color: page.preview("secondaryColor"); border.color: page.preview("accentColor"); border.width: 2
                    ThemedIcon { anchors.fill: parent; anchors.margins: 5; source: page.appSettings.icon("firefox"); fillMode: Image.PreserveAspectFit; tintEnabled: !page.leaveIconsDefault; tintColor: page.preview("accentColor") }
                }
                Column {
                    StyledText { text: "DESKTOP PREVIEW"; color: page.preview("accentColor"); font.bold: true }
                    StyledText { text: "Panels, icons and menus"; color: page.preview("textColor")
                        style: page.roleKey === "textOutlineColor" ? Text.Outline : (page.previewTheme.textStyle || Text.Normal)
                        styleColor: page.preview("textOutlineColor") }
                }
            }
        }
        CheckBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
            text: "Leave icons default"
            checked: page.leaveIconsDefault
            onToggled: page.iconModeChanged(checked)
        }
        RowLayout {
            Rectangle { width: 44; height: 32; color: page.selectedColor; border.color: Theme.text }
            StyledLabel { text: page.selectedColor.toString().toUpperCase(); color: Theme.text }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Save color"; onClicked: page.appSettings.saveColor(page.selectedColor.toString()) }
        }
        Flow {
            Layout.fillWidth: true; Layout.preferredHeight: page.appSettings.savedColors.length ? Math.max(32,implicitHeight) : 0; spacing: 4
            Repeater {
                model: page.appSettings.savedColors
                Rectangle {
                    required property string modelData
                    width: 28; height: 28; color: modelData; border.width: 1; border.color: Theme.muted
                    MouseArea { anchors.fill: parent; onClicked: { page.selectedColor = parent.color; page.hue = Math.max(0,parent.color.hsvHue) } }
                }
            }
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Back"; onClicked: { page.flushHistory(); page.canceled() } }
            Item { Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Use color"; onClicked: { page.flushHistory(); page.accepted(page.selectedColor) } }
        }
    }
}
