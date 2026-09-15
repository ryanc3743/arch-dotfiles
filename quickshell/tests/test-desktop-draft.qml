import QtQuick
import Quickshell
import "../components"
ShellRoot {
    AppSettings { id: settings; settingsPath: Quickshell.env("PRESET_TEST_STATE") + "-bar" }
    PresetStore { id: presets; settingsPath: Quickshell.env("PRESET_TEST_STATE") + "-library" }
    QtObject {
        id: wallpaper
        property string failure: ""
        property var lastApplied: null
        signal presetApplied(bool success)
        function currentSnapshot() { return {mode:"individual", images:{"DP-2":"/tmp/example.png"},slideshow:{enabled:false}} }
        function applyPreset(value, match) { lastApplied = value; finish.restart(); return true }
        property var finish: Timer { interval: 20; onTriggered: wallpaper.presetApplied(true) }
    }
    IconSettings { id: editor; appSettings: settings; presetStore: presets; wallpaperController: wallpaper }
    Timer {
        property int step: 0
        interval: 200; running: true; repeat: true
        onTriggered: {
            if (!presets.ready) return
            if (step === 0) {
                editor.editDesktopPreset({name:"Test", theme:{surfaceColor:"#112233", mutedColor:"#22aa77"},opacity:0.6,icons:{firefox:"custom"},wallpaper:wallpaper.currentSnapshot()})
                if (settings.surfaceColor === "#112233" || wallpaper.lastApplied) throw new Error("Editing applied the draft")
                editor.applyDraft()
            } else if (step === 1) {
                if (settings.surfaceColor !== "#112233" || settings.mutedColor !== "#22aa77" || settings.panelOpacity !== 0.6 || !wallpaper.lastApplied) throw new Error("Combined apply/subtitle failed")
                settings.storage.reload()
            } else {
                if (settings.mutedColor !== "#22aa77") throw new Error("Subtitle was not persisted")
                console.log("PASS desktop draft stays separate; combined Apply and custom subtitle persist")
                Qt.quit()
            }
            step++
        }
    }
}
