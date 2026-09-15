import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: library
    required property var store
    required property string kind
    required property var draft
    property string editing: ""
    property string deleting: ""
    signal editRequested(var preset)
    readonly property var presets: store.items(kind)
    function select(preset) { editing = preset.name; nameField.text = preset.name; deleting = ""; editRequested(preset) }
    function fresh() { editing = ""; nameField.text = ""; deleting = "" }
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        ComboBox {
            id: choices
            Layout.fillWidth: true
            model: library.presets
            textRole: "name"
            displayText: count ? currentText : "No saved presets yet"
            palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.primary
        }
        ExpanderButton { text: "Edit preset"; enabled: choices.currentIndex >= 0; onClicked: library.select(library.presets[choices.currentIndex]) }
    }
    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: "Name this preset"
            maximumLength: 40
            palette.text: Theme.text; palette.base: Theme.secondary
        }
        ExpanderButton {
            text: "Save preset"
            enabled: library.store.ready && nameField.text.trim().length > 0
            onClicked: if (library.store.savePreset(library.kind, nameField.text, library.draft)) {
                library.editing = nameField.text.trim()
                choices.currentIndex = library.presets.findIndex(p => p.name === library.editing)
                library.deleting = ""
            }
        }
        ExpanderButton {
            text: "Rename"
            enabled: library.editing !== "" && nameField.text.trim().length > 0
            onClicked: if (library.store.renamePreset(library.kind, library.editing, nameField.text)) library.editing = nameField.text.trim()
        }
        ExpanderButton {
            text: library.deleting === library.editing && library.editing ? "Confirm delete" : "Delete"
            enabled: library.editing !== ""
            onClicked: {
                if (library.deleting !== library.editing) { library.deleting = library.editing; return }
                library.store.removePreset(library.kind, library.editing)
                library.fresh()
            }
        }
    }
    StyledText {
        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted
        text: library.editing ? "Editing “" + library.editing + "”. Save updates that name; a new name saves a copy." : "Save your draft with a name to use it again."
    }
    StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; visible: library.store.error !== ""; text: library.store.error; color: "#f38ba8" }
}
