import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: settings
    property string settingsPath: Quickshell.statePath("bar-settings.json")
    property alias overrides: data.icons
    property alias panelOpacity: data.panelOpacity
    property alias descriptions: data.descriptions
    property alias surfaceColor: data.surfaceColor
    property alias accentColor: data.accentColor
    property alias textColor: data.textColor
    property alias mutedColor: data.mutedColor
    property alias popupFontSize: data.popupFontSize
    property alias popupMaxWidth: data.popupMaxWidth
    property alias popupBorderWidth: data.popupBorderWidth
    property alias secondaryColor: data.secondaryColor
    property alias tertiaryColor: data.tertiaryColor
    property alias detailAccentColor: data.detailAccentColor
    property alias textOutlineColor: data.textOutlineColor
    property alias textStyle: data.textStyle
    property alias borderStyle: data.borderStyle
    property alias borderWidth: data.borderWidth
    property alias borderRadius: data.borderRadius
    property alias colorPresets: data.colorPresets
    property alias colorHistory: data.colorHistory
    property alias tintIcons: data.tintIcons
    property alias unifiedTheme: data.unifiedTheme
    property alias savedColors: data.savedColors
    property alias followWallpaper: data.followWallpaper
    property alias wallpaperColorOutput: data.wallpaperColorOutput
    function saveNamedPreset(name, values) {
        name = name.trim()
        if (!name || name.length > 40) { errorMessage = "Use a preset name from 1 to 40 characters."; return }
        var presets = data.colorPresets.slice()
        var index = presets.findIndex(p => p.name.toLowerCase() === name.toLowerCase())
        var preset = Object.assign({}, values, {name:name})
        if (index >= 0) presets[index] = preset
        else presets.push(preset)
        data.colorPresets = presets
        errorMessage = ""
        storage.writeAdapter()
    }
    function renamePreset(oldName, newName) {
        newName = newName.trim()
        if (!newName || newName.length > 40) { errorMessage = "Use a preset name from 1 to 40 characters."; return }
        if (data.colorPresets.some(p => p.name !== oldName && p.name.toLowerCase() === newName.toLowerCase())) {
            errorMessage = "That preset name is already used."; return
        }
        data.colorPresets = data.colorPresets.map(p => p.name === oldName ? Object.assign({},p,{name:newName}) : p)
        errorMessage = ""
        storage.writeAdapter()
    }
    function saveColorHistory(role, history) {
        var next = Object.assign({}, data.colorHistory)
        next[role] = history
        if (JSON.stringify(next) !== JSON.stringify(data.colorHistory)) {
            data.colorHistory = next
            storage.writeAdapter()
        }
    }
    function saveColor(value) {
        if (data.savedColors.indexOf(value) < 0) {
            data.savedColors = data.savedColors.concat([value]).slice(-24)
            storage.writeAdapter()
        }
    }
    function matchWallpaper() {
        if (!paletteProcess.running) paletteProcess.running = true
    }
    property var paletteProcess: Process {
        command: ["python3", Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace("file://", ""),
            "palette", "--state", Quickshell.statePath("wallpaper-settings.json"), "--output", settings.wallpaperColorOutput]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim()) return
                var theme = JSON.parse(text)
                data.surfaceColor = theme.surfaceColor
                data.secondaryColor = theme.secondaryColor
                data.accentColor = theme.accentColor
                data.textColor = theme.textColor
                data.mutedColor = theme.mutedColor
                storage.writeAdapter()
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) settings.errorMessage = text.trim() }
    }
    property string errorMessage: ""
    signal saved()

    readonly property var entries: [
        { id: "vscode", label: "VS Code", className: "code", icon: "vscode", command: ["code"] },
        { id: "firefox", label: "Firefox", className: "firefox", icon: "firefox", command: ["firefox"] },
        { id: "dolphin", label: "Dolphin", className: "org.kde.dolphin", icon: "org.kde.dolphin", command: ["dolphin"] },
        { id: "steam", label: "Steam", className: "steam", icon: "steam", command: ["steam"] },
        { id: "fastfetch", label: "Fastfetch", className: "desktop-fastfetch", icon: "/usr/share/icons/breeze/apps/48/utilities-terminal.svg",
          command: ["kitty", "--hold", "--class", "desktop-fastfetch", "--title", "Fastfetch", "fastfetch"] },
        { id: "curseforge", label: "CurseForge", className: "CurseForge", icon: "/usr/share/icons/breeze/categories/32/applications-games.svg",
          command: ["/home/ry/Downloads/curseforge-latest-linux.AppImage"] },
        { id: "wallpaper", label: "Wallpaper picker", icon: "/usr/share/icons/breeze/preferences/32/preferences-desktop-wallpaper.svg" },
        { id: "notifications", label: "Notification history", icon: "/usr/share/icons/breeze/actions/24/notifications.svg" },
        { id: "settings", label: "Customization Center", icon: "/usr/share/icons/breeze/apps/48/systemsettings.svg" },
        { id: "reset", label: "Reset desktop layout", icon: "/usr/share/icons/breeze-dark/actions/32/view-refresh.svg" },
        { id: "connectivity", label: "Network and Bluetooth", icon: "/usr/share/icons/breeze/status/32/network-wired.svg" },
        { id: "launcher", label: "Application launcher", icon: "/usr/share/icons/breeze/apps/48/system-run.svg" }
    ]
    readonly property var defaultDescriptions: ({
        vscode: "VS Code, where the bugs become features",
        firefox: "Firefox, a mid browser with main-character energy",
        dolphin: "Dolphin, keeper of the files",
        steam: "Steam, press play and lose an afternoon",
        fastfetch: "Fastfetch, instant machine bragging",
        curseforge: "CurseForge, mod management with a little magic",
        wallpaper: "Wallpaper picker, repaint the universe",
        notifications: "Notification history, what did I miss?",
        settings: "Customization Center, make this place yours",
        reset: "Reset layout, the emergency tidy-up",
        connectivity: "Network and Bluetooth, wires and waves",
        launcher: "Application launcher, choose your next adventure"
    })
    readonly property var pinnedApps: entries.slice(0, 6)
    readonly property var utilities: entries.slice(6).filter(e => !["connectivity", "launcher", "settings", "reset"].includes(e.id))
    function entry(id) { return entries.find(e => e.id === id) || null }
    function source(value) {
        if (!value) return ""
        if (value.startsWith("file:") || value.startsWith("image://")) return value
        if (value.startsWith("/")) return "file://" + value
        return "image://icon/" + value
    }
    function icon(id) { return source(overrides[id] || entry(id).icon) }
    function defaultIcon(id) { return source(entry(id).icon) }
    function description(id) { return descriptions[id] || defaultDescriptions[id] || entry(id).label }
    function snapshot() {
        return JSON.stringify([data.icons, data.descriptions, data.panelOpacity, data.surfaceColor,
            data.secondaryColor, data.accentColor, data.textColor, data.mutedColor, data.unifiedTheme,
            data.tintIcons, data.followWallpaper, data.wallpaperColorOutput,
            data.popupFontSize, data.popupMaxWidth, data.popupBorderWidth, data.tertiaryColor, data.detailAccentColor, data.textOutlineColor, data.textStyle, data.borderStyle, data.borderWidth, data.borderRadius])
    }
    function save(icons, opacity, nextDescriptions, nextTheme, nextDisplay) {
        var before = snapshot()
        errorMessage = ""
        data.icons = Object.assign({}, icons)
        data.descriptions = Object.assign({}, nextDescriptions)
        data.panelOpacity = Math.max(0, Math.min(1, opacity))
        if (nextTheme) {
            if (nextTheme.borderRadius !== undefined) data.borderRadius = nextTheme.borderRadius
            if (nextTheme.borderWidth !== undefined) data.borderWidth = nextTheme.borderWidth
            if (nextTheme.borderStyle !== undefined) data.borderStyle = nextTheme.borderStyle
            if (nextTheme.textStyle !== undefined) data.textStyle = nextTheme.textStyle
            if (nextTheme.textOutlineColor !== undefined) data.textOutlineColor = nextTheme.textOutlineColor
            if (nextTheme.detailAccentColor !== undefined) data.detailAccentColor = nextTheme.detailAccentColor
            if (nextTheme.tertiaryColor !== undefined) data.tertiaryColor = nextTheme.tertiaryColor
            if (nextTheme.secondaryColor !== undefined) data.secondaryColor = nextTheme.secondaryColor
            if (nextTheme.tintIcons !== undefined) data.tintIcons = nextTheme.tintIcons
            if (nextTheme.unifiedTheme !== undefined) data.unifiedTheme = nextTheme.unifiedTheme
            if (nextTheme.followWallpaper !== undefined) data.followWallpaper = nextTheme.followWallpaper
            if (nextTheme.wallpaperColorOutput !== undefined) data.wallpaperColorOutput = nextTheme.wallpaperColorOutput
            data.surfaceColor = nextTheme.surfaceColor
            data.accentColor = nextTheme.accentColor
            data.textColor = nextTheme.textColor
            data.mutedColor = nextTheme.mutedColor
        }
        if (nextDisplay) {
            data.popupFontSize = Math.max(10, Math.min(24, nextDisplay.popupFontSize))
            data.popupMaxWidth = Math.max(180, Math.min(520, nextDisplay.popupMaxWidth))
            data.popupBorderWidth = Math.max(1, Math.min(6, nextDisplay.popupBorderWidth))
        }
        if (before === snapshot()) settings.saved()
        else storage.writeAdapter()
    }
    property var storage: FileView {
        path: settings.settingsPath
        printErrors: false
        adapter: JsonAdapter {
            id: data
            property string secondaryColor: "#313244"
            property string tertiaryColor: "#45475a"
            property string detailAccentColor: "#89b4fa"
            property string textOutlineColor: "#11111b"
            property int textStyle: 0
            property string borderStyle: "solid"
            property int borderWidth: 1
            property int borderRadius: 8
            property var colorPresets: []
            property var colorHistory: ({})
            property bool tintIcons: true
            property bool unifiedTheme: true
            property var savedColors: []
            property bool followWallpaper: false
            property string wallpaperColorOutput: "DP-2"
            property var icons: ({})
            property var descriptions: ({})
            property real panelOpacity: 0.88
            property string surfaceColor: "#1e1e2e"
            property string accentColor: "#cba6f7"
            property string textColor: "#cdd6f4"
            property string mutedColor: "#a6adc8"
            property int popupFontSize: 12
            property int popupMaxWidth: 300
            property int popupBorderWidth: 2
        }
        onSaved: settings.saved()
        onSaveFailed: settings.errorMessage = "Could not save bar settings. Check write permissions."
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                settings.errorMessage = "Could not read bar settings."
        }
    }
}
