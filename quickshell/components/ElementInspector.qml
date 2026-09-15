import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: inspector
    required property Item target
    required property var appSettings
    property string entryId: ""
    property string entryLabel: ""
    property color accentBacking: "transparent"
    visible: false
    grabFocus: true
    implicitWidth: 320
    implicitHeight: body.implicitHeight + 24
    anchor.window: target ? target.QsWindow.window : null
    anchor.rect.x: {
        if (!target || !target.QsWindow.window) return 0
        var scene = target.mapToItem(null, target.width / 2, 0).x
        var monitorWidth = target.QsWindow.window.width
        return Math.max(0, Math.min(Math.max(0, monitorWidth - width), scene - width / 2))
    }
    anchor.rect.y: anchor.window ? anchor.window.height + 6 : 86
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    color: "transparent"

    function entryIdFrom(objectName) {
        var prefix = objectName.indexOf("app-") === 0 ? "app-" : (objectName.indexOf("utility-") === 0 ? "utility-" : "")
        return objectName.substring(prefix.length)
    }
    function entryLabelFor(id) {
        var entry = appSettings.entry(id)
        return entry ? entry.label : id
    }
    function open(button) {
        target = button
        entryId = entryIdFrom(button.objectName)
        entryLabel = entryLabelFor(entryId)
        descriptionInput.text = appSettings.description(entryId)
        iconInput.text = appSettings.overrides[entryId] || ""
        if (!appSettings.overrides[entryId])
            iconInput.placeholderText = appSettings.entry(entryId).icon
        visible = true
    }
    function save() {
        var overrides = Object.assign({}, appSettings.overrides)
        if (iconInput.text.trim()) overrides[entryId] = iconInput.text.trim()
        else delete overrides[entryId]
        var descriptions = Object.assign({}, appSettings.descriptions)
        if (descriptionInput.text.trim()) descriptions[entryId] = descriptionInput.text.trim()
        else descriptions[entryId] = ""
        appSettings.save(overrides, appSettings.panelOpacity, descriptions, null, null)
        visible = false
    }

    Item {
        id: popupVisual
        anchors.fill: parent
        clip: true
        Rectangle {
            anchors.fill: parent
            color: inspector.appSettings.surfaceColor
            radius: Theme.borderRadius
            ThemeBorder {}
        }
        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            StyledText { text: "INSPECT ELEMENT — " + inspector.entryLabel.toUpperCase(); color: inspector.appSettings.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 12 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                StyledText { text: "Description"; color: inspector.appSettings.textColor; Layout.preferredWidth: 90 }
                TextField {
                    id: descriptionInput
                    Layout.fillWidth: true
                    selectByMouse: true
                    palette.base: Theme.secondary
                    palette.text: Theme.text
                    palette.placeholderText: Theme.muted
                    placeholderText: inspector.appSettings.defaultDescriptions[inspector.entryId] || ""
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                StyledText { text: "Icon"; color: inspector.appSettings.textColor; Layout.preferredWidth: 90 }
                TextField {
                    id: iconInput
                    Layout.fillWidth: true
                    selectByMouse: true
                    palette.base: Theme.secondary
                    palette.text: Theme.text
                    palette.placeholderText: Theme.muted
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Save"; onClicked: inspector.save() }
            }
        }
        StyledText {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            horizontalAlignment: Text.AlignRight
            color: inspector.appSettings.mutedColor
            font.pixelSize: 10
            text: "bar-settings.json"
        }
    }
    HyprlandFocusGrab {
        active: inspector.visible
        windows: [inspector]
        onCleared: inspector.visible = false
    }
}