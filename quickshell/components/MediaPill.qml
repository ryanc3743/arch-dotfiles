import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris

Rectangle {
    id: pill
    property real panelOpacity: 0.34
    property bool continuousStyle: false
    property var player: Mpris.players.values.length ? Mpris.players.values[0] : null
    readonly property bool playing: player && player.playbackState === MprisPlaybackState.Playing
    implicitWidth: 220
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    component MediaButton: Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
        opacity: enabled ? 1 : 0.45
        width: 28
        height: 32
        padding: 0
        contentItem: StyledText {
            text: parent.text
            color: Theme.choose("#cdd6f4", "energy")
            font.pixelSize: 17
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 8
            color: parent.down ? Theme.choose("#45475a", "tertiary") : parent.hovered ? Theme.choose("#313244", "secondary") : "transparent"
        }
        ToolTip.visible: hovered
        ToolTip.text: Accessible.name
    }
    Row {
        objectName: "media-controls"
        anchors.centerIn: parent
        spacing: 6
        StyledText {
            width: 100
            anchors.verticalCenter: parent.verticalCenter
            text: pill.player ? (pill.player.trackTitle || (pill.playing ? "Playing" : "Paused")) : "No media"
            elide: Text.ElideRight
            color: Theme.choose("#cdd6f4", "text")
            font.pixelSize: 15
        }
        MediaButton {
            text: "‹"
            Accessible.name: "Previous track"
            enabled: pill.player && pill.player.canGoPrevious
            onClicked: pill.player.previous()
        }
        MediaButton {
            objectName: "media-play-pause"
            text: pill.playing ? "Ⅱ" : "▶"
            Accessible.name: pill.playing ? "Pause" : "Play"
            enabled: pill.player && pill.player.canTogglePlaying
            onClicked: pill.player.togglePlaying()
        }
        MediaButton {
            text: "›"
            Accessible.name: "Next track"
            enabled: pill.player && pill.player.canGoNext
            onClicked: pill.player.next()
        }
    }
    ToolTip.visible: false
    ToolTip.text: "Media controls"
    MouseArea { id: hoverArea; anchors.fill: parent; z: -1; hoverEnabled: true }
    DescriptionPopup {
        target: hoverArea
        title: "Media"
        description: "Your currently playing track, with tiny remote-control powers."
    }
}
