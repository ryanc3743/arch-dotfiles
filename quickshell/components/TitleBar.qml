import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: bar
    required property var appSettings
    required property var targetWindow
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    readonly property var geometry: targetWindow ? targetWindow.lastIpcObject : ({})
    readonly property var monitor: targetWindow ? targetWindow.monitor : null
    readonly property var targetScreen: monitor ? Quickshell.screens.find(s => s.name === monitor.name) || null : null
    screen: targetScreen
    readonly property bool fullscreen: geometry.fullscreen === 2
    readonly property bool workspaceVisible: !!targetWindow && (geometry.pinned || (targetWindow.workspace && targetWindow.workspace.active))
    readonly property bool coveredByFullscreen: Hyprland.toplevels.values.some(w =>
        w !== targetWindow && w.monitor === monitor && w.workspace && w.workspace.active
        && w.lastIpcObject.fullscreen > 0) && !geometry.fullscreen && !targetWindow?.activated
    visible: targetWindow !== null && targetScreen !== null && workspaceVisible
        && geometry.mapped !== false && geometry.visible !== false && !geometry.hidden
        && !coveredByFullscreen && placement.fits
    implicitWidth: fullscreen ? 180 : Math.max(90, Math.min(180, geometry.size ? geometry.size[0] : 180))
    implicitHeight: 32
    anchors { top: true; left: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "expander-window-actions-" + (targetWindow ? targetWindow.address : "")
    readonly property var placement: locate()
    margins.top: placement.y
    margins.left: placement.x
    function locate() {
        var sw = targetScreen ? targetScreen.width : 180
        var sh = targetScreen ? targetScreen.height : 32
        var wx = (geometry.at ? geometry.at[0] : 0) - (monitor ? monitor.x : 0)
        var wy = (geometry.at ? geometry.at[1] : 0) - (monitor ? monitor.y : 0)
        var ww = geometry.size ? geometry.size[0] : 180
        var wh = geometry.size ? geometry.size[1] : 32
        var bw = implicitWidth
        var reserved = monitor && monitor.lastIpcObject.reserved ? monitor.lastIpcObject.reserved : [0,0,0,0]
        // Fullscreen covers normal panels, and the bar must never overlap window
        // geometry, so there is no usable placement for it there: hide instead.
        if (fullscreen) return {x:0, y:0, above:false, fits:false}
        var left = Math.max(reserved[0], wx), top = reserved[1], right = Math.min(sw - reserved[2], wx + ww)
        var x = Math.max(left, Math.min(right - bw, wx + ww - bw))
        var aboveY = wy - 36
        var clearAbove = aboveY >= top && aboveY + 32 <= sh - reserved[3]
        if (clearAbove) {
            clearAbove = !Hyprland.toplevels.values.some(w => {
                if (w === targetWindow || w.monitor !== monitor) return false
                var g = w.lastIpcObject
                if (g.hidden || g.mapped === false || g.visible === false
                    || !(g.pinned || (w.workspace && w.workspace.active)) || !g.at || !g.size) return false
                var ox = g.at[0] - monitor.x, oy = g.at[1] - monitor.y
                return x < ox + g.size[0] && x + bw > ox && aboveY < oy + g.size[1] && aboveY + 32 > oy
            })
        }
        // Tiled windows can be flush to the reserved edge with no clear strip above;
        // a fallback that overlays the window's top 32px would cover content, so hide.
        if (!clearAbove) return {x:0, y:0, above:false, fits:false}
        return {x:x, y:aboveY, above:true, fits:right - left >= bw}
    }
    color: "transparent"
    function perform(action) {
        if (!targetWindow) return
        Quickshell.execDetached([Qt.resolvedUrl("../scripts/overview.sh").toString().replace(/^file:\/\//, ""), action, targetWindow.address])
    }
    Rectangle {
        anchors.fill: parent
        color: bar.fullscreen ? "transparent" : Qt.rgba(
            Qt.color(bar.appSettings.surfaceColor).r,
            Qt.color(bar.appSettings.surfaceColor).g,
            Qt.color(bar.appSettings.surfaceColor).b,
            bar.panelOpacity)
        radius: bar.continuousStyle ? 0 : 6
        Row {
            anchors.fill: parent
            spacing: 2
            Repeater {
                model: [{id:"minimize", label:"—", name:"Minimize"}, {id:"maximize", label:bar.geometry.fullscreen === 1 ? "◇" : "□", name:"Toggle maximize"}, {id:"close", label:"×", name:"Close"}]
                Button {
                    id: control
                    required property var modelData
                    width: (bar.width - 4) / 3; height: 32
                    padding: 0
                    readonly property color accent: modelData.id === "close" ? "#e81123" : modelData.id === "maximize" ? bar.appSettings.detailAccentColor : bar.appSettings.accentColor
                    readonly property color symbolColor: modelData.id === "close" ? "#e81123" : bar.appSettings.textColor
                    focusPolicy: Qt.NoFocus
                    Accessible.name: modelData.name
                    onClicked: bar.perform(modelData.id)
                    contentItem: Text {
                        width: control.width
                        height: control.height
                        text: control.modelData.label
                        color: control.symbolColor
                        style: bar.fullscreen ? Text.Outline : Text.Normal
                        styleColor: "#90000000"
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 5
                        border.width: control.hovered || control.down ? 2 : 1
                        border.color: control.hovered || control.down ? control.accent : bar.appSettings.mutedColor
                        color: bar.fullscreen ? "transparent" : control.hovered || control.down
                            ? Qt.rgba(control.accent.r, control.accent.g, control.accent.b, control.down ? 0.45 : 0.25)
                            : "transparent"
                    }
                }
            }
        }
    }
    function status() {
        return {visible: bar.visible, address: bar.targetWindow ? bar.targetWindow.address : "",
            screen: bar.targetScreen ? bar.targetScreen.name : "", x: bar.margins.left, y: bar.margins.top,
            fullscreen: bar.geometry.fullscreen, transparent: bar.fullscreen, above: bar.placement.above,
            focused: !!bar.targetWindow && bar.targetWindow.activated}
    }
}
