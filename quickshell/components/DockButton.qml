// Adapted from Serpantinum Dock.qml (ilyamiro), AGPL-3.0.
// Modified 2026-09-12: reusable horizontal button, tooltip, fallback, window drag.
// See ../third-party/SERPANTINUM.md.
import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: button
    property string label: ""
    property string description: ""
    property color accentColor: "#cba6f7"
    property color textColor: "#cdd6f4"
    property color mutedColor: "#a6adc8"
    property color popupColor: "#171827"
    property int popupFontSize: 12
    property int popupMaxWidth: 300
    property int popupBorderWidth: 2
    property url iconSource
    property url fallbackSource
    property bool running: false
    property bool active: false
    property string windowAddress: ""
    readonly property int imageStatus: iconImage.status
    signal clicked()
    signal windowDropped(string address, int workspaceId)
    implicitWidth: 46
    implicitHeight: 48
    Accessible.role: Accessible.Button
    Accessible.name: label

    Rectangle {
        anchors.fill: parent
        border.width: 0
        ThemeBorder { lineColor: Theme.accent; cornerRadius: Theme.borderRadius }
        border.color: mouse.containsMouse || button.active ? button.accentColor : Qt.rgba(button.accentColor.r,button.accentColor.g,button.accentColor.b,0.4)
        radius: Theme.borderRadius
        color: mouse.containsMouse ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25) : (Theme.unified ? Theme.secondary : "transparent")
        Behavior on color { ColorAnimation { duration: 180 } }
    }
    Item {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        scale: mouse.pressed ? 0.92 : mouse.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        ThemedIcon {
            id: iconImage
            anchors.fill: parent
            source: button.iconSource
            sourceSize: Qt.size(64, 64)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }
        ThemedIcon {
            anchors.fill: parent
            visible: iconImage.status === Image.Error
            source: visible ? button.fallbackSource : ""
            sourceSize: Qt.size(64, 64)
            fillMode: Image.PreserveAspectFit
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: button.active ? 20 : 5
        height: 3
        radius: 2
        visible: button.running
        color: button.active ? accentColor : mutedColor
        Behavior on width { NumberAnimation { duration: 180 } }
    }
    // A separate drag item leaves the dock button in its layout slot.
    Item {
        id: ghost
        width: button.width
        height: button.height
        property string address: ""
        Drag.active: mouse.drag.active && address !== ""
        Drag.source: ghost
        Drag.keys: ["desktop-window"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        property int workspaceId: 0
        ThemedIcon {
            anchors.fill: parent
            visible: ghost.Drag.active
            source: button.iconSource
            opacity: 0.7
            fillMode: Image.PreserveAspectFit
        }
    }
    MouseArea {
        id: mouse
        objectName: "dock-mouse-" + button.objectName
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag.target: button.windowAddress !== "" ? ghost : null
        drag.threshold: 10
        property bool wasDragged: false
        onPressed: {
            ghost.address = button.windowAddress
            ghost.workspaceId = 0
            wasDragged = false
        }
        onPositionChanged: if (drag.active) wasDragged = true
        onReleased: {
            if (ghost.Drag.active) ghost.Drag.drop()
            if (ghost.workspaceId > 0) button.windowDropped(ghost.address, ghost.workspaceId)
            ghost.x = 0
            ghost.y = 0
        }
        onCanceled: { ghost.Drag.cancel(); ghost.x = 0; ghost.y = 0 }
        onClicked: if (!wasDragged) button.clicked()
    }
    property bool previewDescription: false
    function descriptionStatus() {
        return JSON.stringify({visible: popout.visible, anchored: popout.anchor.window === button.QsWindow.window,
            x: popout.anchor.rect.x, y: popout.anchor.rect.y, width: popout.width, height: popout.height})
    }
    function captureDescription(path) { popout.capture(path) }
    DescriptionPopup {
        id: popout
        target: mouse
        hovered: button.previewDescription || (mouse.containsMouse && !mouse.pressed && !mouse.drag.active)
        title: button.label
        description: button.description
        accentColor: button.accentColor
        textColor: button.textColor
        surfaceColor: button.popupColor
        fontSize: button.popupFontSize
        maxWidth: button.popupMaxWidth
        borderWidth: button.popupBorderWidth
    }
}
