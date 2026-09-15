import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
ShellRoot {
    PresetStore { id: store; settingsPath: Quickshell.env("PRESET_TEST_STATE") }
    PresetStore { id: reader; settingsPath: Quickshell.env("PRESET_TEST_STATE") }
    function fail(message) {
        console.error("FAIL: " + message)
        Qt.quit()
    }
    Connections {
        target: store
        function onSaved() { reader.storage.reload() }
    }
    Timer {
        property int step: 0
        interval: 200; running: true; repeat: true
        onTriggered: {
            if (!store.ready) return
            try {
                if (step === 0) {
                    if (store.error !== "") fail("stray store error: " + store.error)
                    store.savePreset("wallpaper", "Ocean", {mode:"individual",images:{"DP-2":"/tmp/ocean.png"},slideshow:{enabled:true,images:["/tmp/a.png","/tmp/b.png"],intervalChoice:4}})
                } else if (step === 1) {
                    store.savePreset("wallpaper", "ocean", {mode:"span",spanImage:"/tmp/ocean.png",images:{},slideshow:{enabled:false,images:[]}})
                    if (store.wallpaperPresets.length !== 1) fail("duplicate name")
                    store.renamePreset("wallpaper", "ocean", "Sea")
                } else if (step === 2) {
                    store.savePreset("desktop", "Studio", {theme:{surfaceColor:"#123456"},opacity:0.7,icons:{firefox:"fox"},wallpaper:store.wallpaperPresets[0]})
                } else if (step === 3) {
                    store.savePreset("wallpaper", "Other", {mode:"individual",images:{}})
                    if (store.renamePreset("wallpaper", "Other", "sea")) fail("rename collision")
                    if (store.savePreset("desktop", "  ", {})) fail("empty name")
                    store.removePreset("wallpaper", "Other")
                } else if (step === 4) {
                    reader.storage.reload()
                } else {
                    if (!reader.ready) fail("reader never loaded the saved file")
                    if (reader.wallpaperPresets.length !== 1 || reader.wallpaperPresets[0].name !== "Sea") fail("wallpaper persistence")
                    var p = reader.desktopPresets[0]
                    if (!p || p.name !== "Studio" || p.theme.surfaceColor !== "#123456" || p.wallpaper.spanImage !== "/tmp/ocean.png" || p.icons.firefox !== "fox") fail("desktop persistence")
                    console.log("PASS preset save/update/rename/delete, validation and wallpaper+desktop reload")
                    Qt.quit()
                }
            } catch (error) {
                fail(error.message || String(error))
            }
            step++
        }
    }
}