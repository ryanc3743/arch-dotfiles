import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ShellRoot {
    id: shell
    AppSettings { id: barSettings }
    PresetStore { id: presetStore }
    Binding { target: Theme; property: "settings"; value: barSettings }
    WorkspaceLayout { id: workspaceLayout }
    AudioState { id: audioState }
    ConnectivityState { id: connectivity }
    DesktopActions {
        id: desktop
        appSettings: barSettings
        onUtilityRequested: actionId => {
            if (actionId === "wallpaper") {
                wallpaperWindow.visible = true
                desktop.focusWhenMapped(wallpaperWindow.title)
            } else if (actionId === "settings") {
                settingsWindow.visible = true
                desktop.focusWhenMapped(settingsWindow.title)
            } else if (actionId === "audio-outputs") {
                audioWindow.visible = true
                desktop.focusWhenMapped(audioWindow.title)
            } else if (actionId === "connectivity") {
                connectivityWindow.visible = true
                desktop.focusWhenMapped(connectivityWindow.title)
            } else if (actionId === "launcher") {
                launcherWindow.visible = true
                launcherView.prepare()
                desktop.focusWhenMapped(launcherWindow.title)
            }
        }
        onLastErrorChanged: if (lastError) console.error(lastError)
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            // Keep the 1080p side displays compact; the 1440p center display
            // has room for media, tray, metrics, and remote controls.
            property bool wideBar: panel.width >= 1800
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 64
            margins { top: 0; bottom: 0; left: 0; right: 0 }
            color: "transparent"
            IpcHandler {
                target: "bar-" + panel.screen.name
                function description(open: bool): string {
                    var dock = barContent.children.find(c => c.objectName === "main-taskbar")
                    var row = dock.children[0]
                    var button = row.children.find(c => c.objectName === "app-firefox")
                    button.previewDescription = open
                    return button.descriptionStatus()
                }
                function captureDescription(path: string): void {
                    var dock = barContent.children.find(c => c.objectName === "main-taskbar")
                    dock.children[0].children.find(c => c.objectName === "app-firefox").captureDescription(path)
                }
                function menu(open: bool): void { panel.contextMenuOpen = open }
                function status(): string {
                    return JSON.stringify({width: panel.width, height: panel.height, menu: contextMenu.visible,
                        menuAnchor: contextMenu.anchor.window === panel,
                        items: barContent.children.filter(c => c.visible && c.width > 0).map(c => ({x:c.x, width:c.width})),
                        minimumWidth: barContent.implicitWidth,
                        network: {centerY:connectivityButton.y+connectivityButton.height/2, iconSize:connectivityButton.contentItem.iconSize, color:connectivityButton.contentItem.color.toString()},
                        launcher: {centerY:launcherButton.y+launcherButton.height/2, iconSize:launcherButton.contentItem.iconSize, color:launcherButton.contentItem.color.toString()}})
                }
                function captureMenu(path: string): void { menuSurface.grabToImage(r => r.saveToFile(path)) }
                function capture(path: string): void {
                    barContent.grabToImage(result => result.saveToFile(path))
                }
            }
            Rectangle {
                anchors.fill: parent
                z: -1
                color: Qt.rgba(Qt.color(barSettings.surfaceColor).r, Qt.color(barSettings.surfaceColor).g, Qt.color(barSettings.surfaceColor).b, barSettings.panelOpacity)
                ThemeBorder { visible: Theme.unified && barSettings.panelOpacity > 0; cornerRadius: 0 }
            }
            function dockButtonAt(x, y) {
                var hosts = [barContent.children.find(c => c.objectName === "main-taskbar"),
                             barContent.children.find(c => c.objectName === "launcher-bar")]
                for (var h = 0; h < hosts.length; ++h) {
                    var host = hosts[h]
                    if (!host) continue
                    var row = host.children[0]
                    if (!row) continue
                    for (var i = 0; i < row.children.length; ++i) {
                        var child = row.children[i]
                        if (!child.objectName || child.objectName === "") continue
                        if (!(child.objectName.startsWith("app-") || child.objectName.startsWith("utility-"))) continue
                        var p = child.mapFromItem(barContextMouse, x, y)
                        if (p.x >= 0 && p.x <= child.width && p.y >= 0 && p.y <= child.height) return child
                    }
                }
                return null
            }
            MouseArea {
                id: barContextMouse
                anchors.fill: parent
                z: 100
                acceptedButtons: Qt.RightButton
                onClicked: event => {
                    var button = panel.dockButtonAt(event.x, event.y)
                    if (button) {
                        panel.contextMenuOpen = false
                        elementInspector.open(button)
                    } else {
                        panel.contextMenuX = event.x
                        panel.contextMenuOpen = !panel.contextMenuOpen
                    }
                }
            }
            PopupWindow {
                id: contextMenu
                visible: panel.contextMenuOpen
                anchor.window: panel
                grabFocus: true
                implicitWidth: 250
                implicitHeight: 164
                anchor.rect.x: Math.max(8, Math.min(panel.width - width - 8, panel.contextMenuX))
                anchor.rect.y: panel.height + 6
                anchor.edges: Edges.Top | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                Rectangle {
                    id: menuSurface
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: panel.contextMenuOpen = false
                    color: barSettings.surfaceColor
                    ThemeBorder {}
                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6
                        StyledText { text: "BAR ACTIONS"; color: barSettings.accentColor; font.family: "monospace"; font.bold: true; font.pixelSize: 12 }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Reload bar"; width: parent.width; onClicked: { panel.contextMenuOpen = false; reloadBar.running = true } }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Customization Center"; width: parent.width; onClicked: { panel.contextMenuOpen = false; desktop.activate("settings") } }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Reset desktop layout"; width: parent.width; onClicked: { panel.contextMenuOpen = false; desktop.activate("reset") } }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Close"; width: parent.width; onClicked: panel.contextMenuOpen = false }
                    }
                }
            }
            HyprlandFocusGrab {
                active: contextMenu.visible
                windows: [contextMenu]
                onCleared: panel.contextMenuOpen = false
            }
            ElementInspector {
                id: elementInspector
                appSettings: barSettings
            }
            Process {
                id: reloadBar
                command: ["systemctl", "--user", "--no-block", "restart", "desktop-bar.service"]
                running: false
            }
            RowLayout {
                id: barContent
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8
                Workspaces {
                    monitorGroups: workspaceLayout.monitorGroups
                    actions: desktop
                    compact: !panel.wideBar
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                Item { Layout.fillWidth: true }
                Taskbar {
                    objectName: "main-taskbar"
                    appSettings: barSettings
                    actions: desktop
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                MediaPill {
                    visible: panel.wideBar
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                Item { Layout.fillWidth: true }
                LauncherBar {
                    objectName: "launcher-bar"
                    appSettings: barSettings
                    actions: desktop
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                AudioPill {
                    visible: panel.wideBar
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                    onOutputsRequested: desktop.activate("audio-outputs")
                }
                ServiceStatus {
                    visible: panel.wideBar
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                TrayPill {
                    id: filteredTray
                    visible: panel.wideBar && itemCount > 0
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                SystemPill {
                    visible: panel.wideBar
                    panelOpacity: barSettings.panelOpacity
                    continuousStyle: true
                }
                ToolButton { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                    id: connectivityButton
                    visible: panel.wideBar
                    text: "⌁"
                    Layout.preferredWidth: 88
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignVCenter
                    padding: 0
                    font.pixelSize: 84
                    contentItem: FluentIcon {
                        name: connectivity.networkIcon
                        iconSize: 56
                        color: Theme.choose("#cdd6f4", "energy")
                    }
                    background: Rectangle {
                        radius: 8
                        color: connectivityButton.hovered ? Theme.secondary : "transparent"
                        border.width: connectivityButton.hovered ? 1 : 0
                        border.color: Theme.energy
                    }
                    Accessible.name: barSettings.description("connectivity")
                    onClicked: desktop.activate("connectivity")
                    ToolTip.visible: false
                    ToolTip.text: barSettings.description("connectivity")
                    DescriptionPopup {
                        target: connectivityButton
                        title: connectivity.networkStatus
                        description: barSettings.description("connectivity")
                        accentColor: barSettings.accentColor
                        textColor: barSettings.textColor
                        surfaceColor: barSettings.surfaceColor
                        fontSize: barSettings.popupFontSize
                        maxWidth: barSettings.popupMaxWidth
                        borderWidth: barSettings.popupBorderWidth
                    }
                }
                ToolButton { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                    id: launcherButton
                    visible: panel.wideBar
                    text: "⌕"
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 64
                    Layout.alignment: Qt.AlignVCenter
                    padding: 0
                    font.pixelSize: 56
                    contentItem: FluentIcon {
                        name: "apps"
                        iconSize: 48
                        color: Theme.choose("#cdd6f4", "energy")
                    }
                    background: Rectangle {
                        radius: 8
                        color: launcherButton.hovered ? Theme.secondary : "transparent"
                        border.width: launcherButton.hovered ? 1 : 0
                        border.color: Theme.energy
                    }
                    Accessible.name: barSettings.description("launcher")
                    onClicked: desktop.activate("launcher")
                    ToolTip.visible: false
                    ToolTip.text: barSettings.description("launcher")
                    DescriptionPopup {
                        target: launcherButton
                        title: "Launcher"
                        description: barSettings.description("launcher")
                        accentColor: barSettings.accentColor
                        textColor: barSettings.textColor
                        surfaceColor: barSettings.surfaceColor
                        fontSize: barSettings.popupFontSize
                        maxWidth: barSettings.popupMaxWidth
                        borderWidth: barSettings.popupBorderWidth
                    }
                }
                Clock { panelOpacity: barSettings.panelOpacity; continuousStyle: true }
            }
            property bool contextMenuOpen: false
            property real contextMenuX: 12
        }
    }
    FloatingWindow {
        DesktopEscapeShortcut {}
        id: wallpaperWindow
        title: "Wallpaper Picker"
        width: 1000
        height: 750
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, barSettings.centerOpacity)
        visible: false
        WallpaperPicker { id: wallpaperView; appSettings: barSettings; presetStore: presetStore }
    }
    FloatingWindow {
        DesktopEscapeShortcut {}
        id: connectivityWindow
        title: "Network & Bluetooth"
        implicitWidth: 620
        implicitHeight: 620
        color: Theme.primary
        visible: false
        ConnectivityPanel { id: connectivityView; anchors.fill: parent; connectivity: connectivity; onCloseRequested: connectivityWindow.visible = false }
    }
    FloatingWindow {
        DesktopEscapeShortcut {}
        id: launcherWindow
        title: "Dashboard Center"
        implicitWidth: 840
        implicitHeight: 690
        color: Theme.primary
        visible: false
        ExpanderPanel { id: launcherView; anchors.fill: parent; monitorGroups: workspaceLayout.monitorGroups; actions: desktop; onCloseRequested: launcherWindow.visible = false; onPowerRequested: shell.openPower() }
    }
    function openPower() {
        launcherWindow.visible = false
        powerWindow.visible = true
        powerView.prepare()
        desktop.focusWhenMapped(powerWindow.title)
    }
    FloatingWindow {
        DesktopEscapeShortcut {}
        id: powerWindow
        title: "Dashboard Center · Power"
        implicitWidth: 550
        implicitHeight: 530
        color: Theme.primary
        visible: false
        PowerPopover { id: powerView; anchors.fill: parent; onCloseRequested: powerWindow.visible = false }
    }
    Variants {
        model: Quickshell.screens
        DesktopMenu {
            appSettings: barSettings
            onCustomizeRequested: desktop.activate("settings")
            onInspectRequested: {
                settingsWindow.visible = true
                Qt.callLater(() => settingsWindow.showElementInspector())
                desktop.focusWhenMapped(settingsWindow.title)
            }
            onReloadRequested: Quickshell.execDetached(["systemctl", "--user", "--no-block", "restart", "desktop-bar.service"])
            onResetRequested: desktop.activate("reset")
        }
    }
    // Share one refresh across every window; moving/resizing has no per-frame IPC event.
    Timer {
        interval: 100
        repeat: true
        running: Hyprland.toplevels.values.length > 0
        onTriggered: Hyprland.refreshToplevels()
    }
    IpcHandler {
        target: "expander"
        function open(): void {
            powerWindow.visible = false
            if (launcherWindow.visible) launcherView.toggleTab()
            else { launcherWindow.visible = true; launcherView.prepare() }
            desktop.focusWhenMapped(launcherWindow.title)
        }
        function toggle(): void {
            if (launcherWindow.visible) { launcherWindow.visible = false; return }
            open()
        }
        function power(): void { shell.openPower() }
        function hide(): void { launcherWindow.visible = false; powerWindow.visible = false }
        function status(): string { return JSON.stringify({visible: launcherWindow.visible, tab: launcherView.tab, power: powerWindow.visible, query: launcherView.query, result: launcherView.result, windows: launcherView.windows.length}) }
        function search(query: string): void { launcherView.query = query }
        function capture(path: string): void { launcherView.grabToImage(r => r.saveToFile(path)) }
    }
    IpcHandler {
        target: "shell"
        function reload(): void { Quickshell.execDetached(["systemctl", "--user", "--no-block", "restart", "desktop-bar.service"]) }
    }
    IconSettings {
        id: settingsWindow
        appSettings: barSettings
        presetStore: presetStore
        wallpaperController: wallpaperView
        onScreenPickRequested: {
            pickerWindow.arm()
            settingsWindow.visible = false
        }
    }
    // Fullscreen surface color picker. Captures the output via grim while this
    // window is NOT yet mapped (so the frozen frame never contains our overlay),
    // then shows the frame once the capture lands (armed()).
    PanelWindow {
        DesktopEscapeShortcut { onClosing: pickerWindow.cancelPick() }
        id: pickerWindow
        visible: false
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "screen-color-picker"
        // Freeze the monitor the Customization Center actually lives on (its
        // `screen` property is static and can name the wrong output).
        function targetScreen() {
            var w = Hyprland.toplevels.values.find(t => t.title === settingsWindow.title)
            var at = w && w.lastIpcObject ? w.lastIpcObject.at : null
            if (at) {
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var s = Quickshell.screens[i]
                    if (at[0] >= s.x && at[0] < s.x + s.width && at[1] >= s.y && at[1] < s.y + s.height) return s
                }
            }
            return settingsWindow.screen || Quickshell.screens[0]
        }
        function reset() { pickerView.disarm(); pickerView.pickedHex = "#000000" }
        // Call while the CC is still mapped so its toplevel can be located.
        function arm() {
            pickerWindow.screen = targetScreen()
            reset()
            pickerView.outputName = pickerWindow.screen ? pickerWindow.screen.name : "DP-2"
            armDelay.restart()
        }
        Timer {
            id: armDelay
            interval: 150
            repeat: false
            onTriggered: pickerView.arm()
        }
        function cancelPick() {
            if (!pickerWindow.visible && !pickerView.busy) return
            pickerWindow.visible = false
            pickerView.disarm()
            settingsWindow.visible = true
            desktop.focusWhenMapped(settingsWindow.title)
        }
        ScreenColorPicker {
            id: pickerView
            anchors.fill: parent
            outputName: "DP-2"
            onArmed: pickerWindow.visible = true
            onCanceled: pickerWindow.cancelPick()
            onPicked: hex => {
                pickerWindow.visible = false
                pickerView.disarm()
                settingsWindow.visible = true
                settingsWindow.acceptScreenPick(hex)
                desktop.focusWhenMapped(settingsWindow.title)
            }
        }
    }
    FloatingWindow {
        DesktopEscapeShortcut {}
        id: audioWindow
        title: "Audio outputs"
        implicitWidth: 520
        implicitHeight: 380
        color: Theme.primary
        visible: false
        AudioOutputs { id: audioView; anchors.fill: parent; audio: audioState; onCloseRequested: audioWindow.visible = false }
    }
    IpcHandler {
        target: "audio"
        function status(): string {
            return JSON.stringify({visible: audioWindow.visible, volume: audioState.volume,
                muted: audioState.muted, current: audioState.sink ? audioState.sink.name : null,
                outputs: audioState.outputs.map(node => ({name: node.name, label: audioState.label(node), ready: node.ready})),
                error: audioState.error})
        }
        function hide(): void { audioWindow.visible = false }
        function capture(path: string): void { audioView.grabToImage(result => result.saveToFile(path)) }
    }
    IpcHandler {
        target: "connectivity"
        function status(): string {
            return JSON.stringify({icon: connectivity.networkIcon, status: connectivity.networkStatus, wifi: connectivity.networking.wifiEnabled,
                wifiHardware: connectivity.networking.wifiHardwareEnabled,
                wired: connectivity.wiredLabel, wifiLabel: connectivity.wifiLabel,
                bluetooth: connectivity.adapter ? connectivity.adapter.enabled : false,
                bluetoothLabel: connectivity.bluetoothLabel,
                wifiNetworks: connectivity.wifiNetworks.length,
                bluetoothDevices: connectivity.btDevices.length, error: connectivity.error})
        }
        function open(): void { connectivityWindow.visible = true }
        function hide(): void { connectivityWindow.visible = false }
        function capture(path: string): void { connectivityView.grabToImage(result => result.saveToFile(path)) }
    }
    IpcHandler {
        target: "launcher"
        function open(): void { launcherWindow.visible = true; launcherView.prepare(); desktop.focusWhenMapped(launcherWindow.title) }
        function hide(): void { launcherWindow.visible = false }
        function capture(path: string): void { launcherView.grabToImage(result => result.saveToFile(path)) }
    }
    // Also permits testing the same actions used by the buttons without key injection.
    IpcHandler {
        target: "colorpicker"
        function open() {
            pickerWindow.arm()
            settingsWindow.visible = false
        }
        function capture(path: string): void {
            if (pickerWindow.visible) pickerView.grabToImage(r => r.saveToFile(path))
        }
        function hide(): void { pickerWindow.cancelPick() }
        function status(): string { return JSON.stringify({visible: pickerWindow.visible, live: pickerView.live, busy: pickerView.busy, output: pickerView.outputName, hex: pickerView.pickedHex}) }
    }
    IpcHandler {
        target: "appearance"
        function colorways(): void { settingsWindow.showColorways() }
        function wallpaperCapture(path: string): void { wallpaperView.capture(path) }
        function wallpaperPresets(): void { wallpaperWindow.visible = true; wallpaperView.showPresets(); desktop.focusWhenMapped(wallpaperWindow.title) }
        function open(): void { desktop.activate("settings") }
        function picker(): void { settingsWindow.previewPicker() }
        function capture(path: string): void { settingsWindow.capture(path) }
        function hide(): void { settingsWindow.visible = false }
    }
    IpcHandler {
        target: "desktop"
        function activate(id: string): void { desktop.activate(id) }
        function reset(): void { desktop.reset() }
        function hideUtilities(): void { powerWindow.visible = false; wallpaperWindow.visible = false; settingsWindow.visible = false; audioWindow.visible = false; connectivityWindow.visible = false; launcherWindow.visible = false }
        function status(): string {
            return JSON.stringify({
                wallpaper: wallpaperWindow.visible, settings: settingsWindow.visible,
                opacity: barSettings.panelOpacity, error: desktop.lastError,
                pinned: barSettings.pinnedApps.map(e => e.id),
                windows: barSettings.pinnedApps.map(e => ({id: e.id, count: desktop.windowsFor(e.id).length}))
            })
        }
    }
}
