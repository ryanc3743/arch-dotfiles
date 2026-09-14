import QtQuick
import QtQuick.Controls

Rectangle {
    id: pill
    property real panelOpacity: 0.34
    property bool continuousStyle: false
    signal outputsRequested()
    AudioState { id: audio }
    implicitWidth: 132
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        text: (audio.muted ? "󰖁" : "󰕾") + " " + (audio.volume < 0 ? "—" : audio.volume + "%")
        color: audio.muted ? "#f38ba8" : Theme.choose("#cdd6f4", "text")
        font.pixelSize: 16
    }
    MouseArea {
        id: audioMouse
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: outputChoice.left }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.RightButton) pill.outputsRequested()
            else audio.toggleMute()
        }
        onWheel: event => {
            if (event.angleDelta.y !== 0) audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        }
        ToolTip.visible: false
        ToolTip.text: audio.label(audio.sink) + "\nClick to mute · scroll for volume · right-click for outputs"
    }
    DescriptionPopup {
        target: audioMouse
        title: "Audio"
        description: "Volume control, mute, and a shortcut to output choices."
    }
    ToolButton { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
        id: outputChoice
        objectName: "audio-output-picker"
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 24
        height: 48
        text: "⌄"
        Accessible.name: "Choose audio output"
        contentItem: StyledText { text: outputChoice.text; color: Theme.choose("#cdd6f4", "text"); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 8; color: outputChoice.hovered ? Theme.choose("#45475a", "tertiary") : "transparent" }
        onClicked: pill.outputsRequested()
        ToolTip.visible: hovered
        ToolTip.text: "Choose audio output"
    }
}
