import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    ThemeBorder { z: 20 }
    id: view
    required property var audio
    signal closeRequested()
    color: Theme.choose("#1e1e2e", "primary")
    implicitWidth: 520
    implicitHeight: 380
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14
        StyledText { text: "Audio output"; color: Theme.choose("#cdd6f4", "text"); font.pixelSize: 25; font.bold: true }
        StyledText {
            Layout.fillWidth: true
            text: "Choose where to play sound."
            color: Theme.choose("#bac2de", "muted")
            font.pixelSize: 15
        }
        StyledText {
            visible: view.audio.outputs.length === 0
            text: "No audio outputs are available."
            color: Theme.choose("#bac2de", "muted")
        }
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            Column {
                width: parent.width
                spacing: 8
                Repeater {
                    model: view.audio.outputs
                    Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                        id: outputButton
                        required property var modelData
                        objectName: "audio-output-" + modelData.name
                        readonly property bool selected: modelData === view.audio.sink
                        width: parent.width
                        height: 62
                        enabled: modelData.ready && !view.audio.pendingName
                        Accessible.name: view.audio.label(modelData) + (selected ? ", active" : "")
                        onClicked: view.audio.selectOutput(modelData)
                        contentItem: Column {
                            spacing: 3
                            StyledText {
                                width: parent.width
                                text: view.audio.label(outputButton.modelData)
                                elide: Text.ElideRight
                                color: Theme.choose("#cdd6f4", "text")
                                font.pixelSize: 16
                            }
                            StyledText {
                                text: outputButton.selected ? "Active output"
                                    : view.audio.pendingName === outputButton.modelData.name ? "Switching…" : "Select output"
                                color: outputButton.selected ? Theme.choose("#a6e3a1", "energy") : Theme.choose("#a6adc8", "muted")
                                font.pixelSize: 12
                            }
                        }
                        background: Rectangle {
                            color: outputButton.hovered ? Theme.choose("#45475a", "tertiary") : Theme.choose("#313244", "secondary")
                            border.color: outputButton.selected ? Theme.choose("#89b4fa", "energy") : "transparent"
                            radius: 10
                        }
                    }
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: !!view.audio.error
            text: view.audio.error
            color: "#f38ba8"
            wrapMode: Text.WordWrap
        }
        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Done"; Layout.alignment: Qt.AlignRight; onClicked: view.closeRequested() }
    }
}
