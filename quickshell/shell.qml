import Quickshell
import QtQuick
import "components"

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 40

Workspaces {
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter

    workspaceList: {
        if (modelData.name === "DP-3")
            return [4, 5, 6]

        if (modelData.name === "DP-2")
            return [1, 2, 3]

        if (modelData.name === "HDMI-A-1")
            return [7, 8, 9]

        return []
    }
}
Clock {
    anchors.centerIn: parent
}            }
        }
    }

