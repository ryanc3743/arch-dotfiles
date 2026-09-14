import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: actions
    required property var appSettings
    property string pendingTitle: ""
    property string launchingId: ""
    property string lastError: ""
    signal utilityRequested(string id)
    signal performed(string id)

    // lastIpcObject is the supported source for a Hyprland window's class.
    function windowsFor(id) {
        var app = appSettings.entry(id)
        if (!app || !app.className) return []
        return Hyprland.toplevels.values.filter(w => {
            var cls = w.lastIpcObject.class || (w.wayland ? w.wayland.appId : "")
            return cls === app.className
                || (id === "curseforge" && cls.toLowerCase() === app.className.toLowerCase())
                || (id === "fastfetch" && cls === "kitty" && w.title === "Fastfetch")
        })
    }
    function focusWindow(window) {
        Hyprland.dispatch("hl.dsp.focus({ window = 'address:0x" + window.address.replace(/^0x/, "") + "' })")
    }
    function activate(id) {
        if (id === "reset") { reset(); return }
        if (id === "notifications") {
            Quickshell.execDetached(["makoctl", "restore"])
            performed(id)
            return
        }
        if (id === "wallpaper" || id === "settings" || id === "audio-outputs" || id === "connectivity" || id === "launcher") {
            utilityRequested(id)
            performed(id)
            return
        }
        var app = appSettings.entry(id)
        if (!app || !app.command) return
        var windows = windowsFor(id)
        if (windows.length) {
            var current = windows.findIndex(w => w.activated)
            focusWindow(windows[(current + 1) % windows.length])
        } else if (launchingId !== id) {
            launchingId = id
            launchTimeout.restart()
            Quickshell.execDetached(app.command)
        }
        performed(id)
    }
    function focusWhenMapped(title) {
        pendingTitle = title
        focusTimer.attempts = 0
        focusTimer.restart()
    }
    function switchWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = '" + Number(id) + "' })")
    }
    function moveWindow(address, workspaceId) {
        if (!/^(0x)?[0-9a-f]+$/i.test(address) || workspaceId < 1 || workspaceId > 9) return
        Hyprland.dispatch("hl.dsp.window.move({ window = 'address:0x" + address.replace(/^0x/, "") + "', workspace = '" + Number(workspaceId) + "', follow = false })")
        performed("move-window")
    }
    function reset() {
        if (resetProcess.running) return
        lastError = ""
        resetProcess.running = true
    }
    property var resetProcess: Process {
        command: ["hyprctl", "eval", "resetDesktopLayout()"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ok") actions.lastError = text.trim()
                else actions.performed("reset")
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) actions.lastError = text.trim() }
    }
    property var launchTimeout: Timer { interval: 2500; onTriggered: actions.launchingId = "" }
    property var focusTimer: Timer {
        property int attempts: 0
        interval: 80
        repeat: true
        onTriggered: {
            Hyprland.refreshToplevels()
            var window = Hyprland.toplevels.values.find(w => w.title === actions.pendingTitle)
            if (window) {
                actions.focusWindow(window)
                actions.pendingTitle = ""
                stop()
            } else if (++attempts > 25) {
                actions.lastError = "Could not focus " + actions.pendingTitle
                stop()
            }
        }
    }
}
