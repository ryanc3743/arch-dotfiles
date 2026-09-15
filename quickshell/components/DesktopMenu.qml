import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Full-screen transparent surface at the Background layer: it sits below
// windows, so only the empty desktop falls through to it. Right-clicking the
// empty desktop opens the context menu; the menu itself is a nested PanelWindow
// at the Overlay layer so it renders above normal windows.
PanelWindow {
    id: desktopSurface
    required property var modelData
    required property var appSettings
    property bool menuOpen: false
    property real menuX: 0
    property real menuY: 0
    signal customizeRequested()
    signal inspectRequested()
    signal reloadRequested()
    signal resetRequested()

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "desktop-context"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (desktopSurface.menuOpen) {
                desktopSurface.menuOpen = false
                return
            }
            if (event.button === Qt.RightButton) {
                desktopSurface.menuX = event.x
                desktopSurface.menuY = event.y
                desktopSurface.menuOpen = true
            }
        }
    }

    PanelWindow {
        id: menuPanel
        visible: desktopSurface.menuOpen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "desktop-context-menu"
        anchors { top: true; left: true }
        margins {
            top: Math.max(8, Math.min(desktopSurface.height - height - 8, desktopSurface.menuY))
            left: Math.max(8, Math.min(desktopSurface.width - width - 8, desktopSurface.menuX))
        }
        implicitWidth: 240
        implicitHeight: menuColumn.implicitHeight + 20
        Rectangle {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: desktopSurface.menuOpen = false
            color: desktopSurface.appSettings.surfaceColor
            radius: Theme.borderRadius
            ThemeBorder {}
            Column {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6
                StyledText { text: "DESKTOP"; color: desktopSurface.appSettings.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 12 }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Customization Center"; width: parent.width; onClicked: { desktopSurface.menuOpen = false; desktopSurface.customizeRequested() } }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Inspect element"; width: parent.width; onClicked: { desktopSurface.menuOpen = false; desktopSurface.inspectRequested() } }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Reload bar"; width: parent.width; onClicked: { desktopSurface.menuOpen = false; desktopSurface.reloadRequested() } }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Reset desktop layout"; width: parent.width; onClicked: { desktopSurface.menuOpen = false; desktopSurface.resetRequested() } }
                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Close"; width: parent.width; onClicked: desktopSurface.menuOpen = false }
            }
        }
    }
    HyprlandFocusGrab {
        active: menuPanel.visible
        windows: [menuPanel]
        onCleared: desktopSurface.menuOpen = false
    }
}