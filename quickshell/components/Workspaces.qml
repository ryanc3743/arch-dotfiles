import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: workspaces

    property var workspaceList: []

    spacing: 6

    Repeater {
        model: workspaces.workspaceList

        Rectangle {
            required property var modelData

            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            radius: 6

            color: Hyprland.focusedWorkspace
                   && Hyprland.focusedWorkspace.id === modelData
                   ? "#33ccff"
                   : "transparent"

            border.width: 1
            border.color: "#595959"

            Text {
                anchors.centerIn: parent
                text: modelData
                color: Hyprland.focusedWorkspace
                       && Hyprland.focusedWorkspace.id === modelData
                       ? "black"
                       : "white"
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    Hyprland.dispatch(
                        'hl.dsp.focus({ workspace = "' + modelData + '" })'
                    )
                }
            }
        }
    }
}
