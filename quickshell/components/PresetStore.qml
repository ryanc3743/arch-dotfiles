import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store
    property string settingsPath: Quickshell.statePath("desktop-presets.json")
    property alias wallpaperPresets: data.wallpaper
    property alias desktopPresets: data.desktop
    property bool ready: false
    property string error: ""
    signal saved()
    function items(kind) { return kind === "wallpaper" ? data.wallpaper : data.desktop }
    function setItems(kind, items) {
        if (kind === "wallpaper") data.wallpaper = items
        else data.desktop = items
    }
    function validName(name) {
        if (!name || name.length > 40) { error = "Use a name from 1 to 40 characters."; return false }
        return true
    }
    function savePreset(kind, name, values) {
        if (!ready) { error = "Presets are still loading."; return false }
        name = name.trim()
        if (!validName(name)) return false
        var presets = items(kind).slice()
        var index = presets.findIndex(p => p.name.toLowerCase() === name.toLowerCase())
        var preset = JSON.parse(JSON.stringify(values))
        preset.name = name
        if (index < 0) presets.push(preset)
        else presets[index] = preset
        setItems(kind, presets)
        error = ""
        storage.writeAdapter()
        return true
    }
    function renamePreset(kind, oldName, newName) {
        if (!ready) return false
        newName = newName.trim()
        if (!validName(newName)) return false
        var presets = items(kind)
        if (presets.some(p => p.name !== oldName && p.name.toLowerCase() === newName.toLowerCase())) {
            error = "That name is already used."; return false
        }
        setItems(kind, presets.map(p => p.name === oldName ? Object.assign({}, p, {name:newName}) : p))
        error = ""
        storage.writeAdapter()
        return true
    }
    function removePreset(kind, name) {
        if (!ready) return
        setItems(kind, items(kind).filter(p => p.name !== name))
        error = ""
        storage.writeAdapter()
    }
    property var storage: FileView {
        path: store.settingsPath
        printErrors: false
        adapter: JsonAdapter {
            id: data
            property int version: 1
            property var wallpaper: []
            property var desktop: []
        }
        onLoaded: store.ready = true
        onLoadFailed: error => {
            store.ready = error === FileViewError.FileNotFound
            if (!store.ready) store.error = "Could not read saved presets."
        }
        onSaved: store.saved()
        onSaveFailed: store.error = "Could not save presets. Check write permissions."
    }
}
