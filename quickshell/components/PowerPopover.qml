import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: panel
    signal closeRequested()
    property string pending: ""
    color: Theme.primary
    ThemeBorder {}
    function prepare() { pending = ""; forceActiveFocus() }
    function run(action) {
        if (action !== "lock" && pending !== action) { pending = action; return }
        closeRequested()
        Quickshell.execDetached([Qt.resolvedUrl("../scripts/actions.sh").toString().replace(/^file:\/\//, ""), action])
    }
    focus: true
    Keys.onEscapePressed: closeRequested()
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 24; spacing: 14
        RowLayout {
            StyledText { text: "Shortcuts & power"; color: Theme.text; font.pixelSize: 24; Layout.fillWidth: true }
            ExpanderButton { text: "×"; Accessible.name: "Close power menu"; onClicked: panel.closeRequested() }
        }
        Repeater {
            model: ["Super + Q   Terminal", "Super + E   Files", "Super + W   Close window", "Super + B   Fullscreen", "Super + 1–0   Workspace", "Super + Shift + D   Launcher", "Super + Shift + V   Clipboard", "Super + mouse drag   Move / resize"]
            StyledText { required property string modelData; text: modelData; color: Theme.text }
        }
        Item { Layout.fillHeight: true }
        StyledText { Layout.fillWidth: true; text: panel.pending ? "Select " + panel.pending + " again to confirm." : "Choose a power action"; color: Theme.energy }
        RowLayout {
            Repeater {
                model: [{id:"lock", label:"Lock"}, {id:"sleep", label:"Sleep"}, {id:"logout", label:"Log out"}, {id:"reboot", label:"Reboot"}]
                ExpanderButton { required property var modelData; text: modelData.label; highlighted: panel.pending === modelData.id; onClicked: panel.run(modelData.id) }
            }
        }
    }
}
