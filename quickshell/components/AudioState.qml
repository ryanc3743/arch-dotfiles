import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: audio
    property var backend: Pipewire
    readonly property var outputs: backend.nodes.values.filter(node => node.isSink && !node.isStream && node.audio)
    readonly property var sink: backend.defaultAudioSink
    readonly property bool available: backend.ready && sink && sink.ready && sink.audio
    readonly property int volume: available ? Math.round(sink.audio.volume * 100) : -1
    readonly property bool muted: available && sink.audio.muted
    property string pendingName: ""
    property string error: ""

    // Node audio properties are populated and kept current only while tracked.
    property var tracker: PwObjectTracker {
        objects: audio.backend === Pipewire ? audio.outputs : []
    }
    function label(node) { return node ? node.description || node.nickname || node.name : "No output" }
    function toggleMute() { if (available) sink.audio.muted = !sink.audio.muted }
    function adjustVolume(delta) {
        if (available) sink.audio.volume = Math.max(0, Math.min(1.5, sink.audio.volume + delta))
    }
    function selectOutput(node) {
        error = ""
        if (!backend.ready || !outputs.includes(node) || !node.ready) {
            error = "That output is no longer available."
            return false
        }
        if (node === sink) return true
        pendingName = node.name
        switchTimeout.restart()
        backend.preferredDefaultAudioSink = node
        return true
    }
    onSinkChanged: {
        if (sink && sink.name === pendingName) {
            pendingName = ""
            switchTimeout.stop()
        }
    }
    property var switchTimeout: Timer {
        interval: 4000
        onTriggered: {
            if (!audio.sink || audio.sink.name !== audio.pendingName)
                audio.error = "The output did not switch. Try selecting it again."
            audio.pendingName = ""
        }
    }
}
