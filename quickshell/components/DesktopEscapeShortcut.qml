import QtQuick
import Quickshell

Item {
    id: shortcutRoot
    signal closing()
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: !!shortcutRoot.QsWindow.window && shortcutRoot.QsWindow.window.visible
        onActivated: {
            shortcutRoot.closing()
            shortcutRoot.QsWindow.window.visible = false
        }
    }
}
