import QtQuick
import Quickshell

PopupWindow {
    id: popup
    required property Item target
    property var hostWindow: null
    property string title: ""
    property string description: ""
    property color accentColor: Theme.energy
    property color textColor: Theme.text
    property color surfaceColor: Theme.primary
    property int fontSize: Theme.settings ? Theme.settings.popupFontSize : 12
    property int maxWidth: Theme.settings ? Theme.settings.popupMaxWidth : 300
    property int borderWidth: Theme.settings ? Theme.settings.popupBorderWidth : 2
    property bool hovered: target && (target.containsMouse !== undefined ? target.containsMouse : !!target.hovered)
    visible: !!(target && (hostWindow || target.QsWindow.window)
        && hovered
        && description.length > 0)
    anchor.window: hostWindow || (target ? target.QsWindow.window : null)
    grabFocus: false
    implicitWidth: Math.min(popup.maxWidth, Math.max(100, (anchor.window ? anchor.window.width : 300) - 16))
    implicitHeight: Math.min(body.implicitHeight + 24, anchor.window && anchor.window.screen ? anchor.window.screen.height - 100 : 600)
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
    function capture(path) { popupVisual.grabToImage(r => r.saveToFile(path)) }
    Item {
    id: popupVisual
    anchors.fill: parent
    clip: true
    Rectangle {
        id: popupSurface
        anchors.fill: parent
        color: popup.surfaceColor
        radius: Theme.borderRadius
        ThemeBorder {}
    }
    Rectangle {
        id: scanline
        x: 6
        width: parent.width - 12
        height: 1
        color: popup.accentColor
        opacity: 0.18
        SequentialAnimation on y {
            running: popup.visible
            loops: Animation.Infinite
            NumberAnimation { from: 8; to: popup.height - 8; duration: 1700; easing.type: Easing.Linear }
            PauseAnimation { duration: 250 }
        }
    }
    Rectangle { x: -2; y: 6; width: 2; height: parent.height - 12; color: popup.accentColor }
    Rectangle { x: parent.width; y: 6; width: 2; height: parent.height - 12; color: popup.accentColor }
    Rectangle { x: parent.width / 2 - 5; y: 0; width: 10; height: 4; color: popup.accentColor }
    Rectangle { x: parent.width / 2 - 2; y: -4; width: 4; height: 4; color: popup.accentColor }
    Column {
        id: body
        x: 12; y: 12
        width: popup.width - 24
        spacing: 4
        StyledText { width: parent.width; elide: Text.ElideRight; text: popup.title.toUpperCase(); color: popup.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 11 }
        StyledText { width: parent.width; text: popup.description; color: popup.textColor; font.family: "monospace"; font.pixelSize: popup.fontSize; textFormat: Text.PlainText; maximumLineCount: Math.max(1, Math.floor(((popup.anchor.window && popup.anchor.window.screen ? popup.anchor.window.screen.height : 700) - 150) / (popup.fontSize * 1.3))); elide: Text.ElideRight; wrapMode: Text.Wrap }
    }
}
}
