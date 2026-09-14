// Workspace occupancy/animated pills adapted from Serpantinum WorkspacesWidget.qml.
// AGPL-3.0; Hyprland-only adaptation, modified 2026-09-12.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Hyprland

Rectangle {
    id: workspaces
    required property var monitorGroups
    required property var actions
    property bool compact: false
    property real panelOpacity: 0.88
    property bool continuousStyle: false
    implicitWidth: groups.implicitWidth + 20
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Row {
        id: groups
        anchors.centerIn: parent
        spacing: 12
        Repeater {
            model: workspaces.monitorGroups
            Column {
                id: group
                required property var modelData
                spacing: 3
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: workspaces.compact ? (group.modelData.monitor === "DP-3" ? "OS" : group.modelData.monitor === "DP-2" ? "Gaming" : "Media") : group.modelData.label
                    font.pixelSize: workspaces.compact ? 16 : 18
                    font.bold: true
                    color: (Theme.unified ? Theme.energy : group.modelData.color)
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Repeater {
                        model: group.modelData.workspaces
                        Rectangle {
                            id: pill
                            required property int modelData
                            objectName: "workspace-" + modelData
                            property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) || null
                            property bool focused: workspace !== null && workspace.focused
                            property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
                            width: workspaces.compact ? 29 : 38
                            height: 30
                            radius: 15
                            color: drop.containsDrag || focused ? (Theme.unified ? Theme.energy : group.modelData.color) : occupied ? Theme.choose("#45475a", "tertiary") : Theme.choose("#313244", "secondary")
                            Behavior on color { ColorAnimation { duration: 160 } }
                            StyledText {
                                anchors.centerIn: parent
                                text: pill.modelData
                                font.pixelSize: 22
                                color: pill.focused || drop.containsDrag ? Theme.choose("#1e1e2e", "primary") : Theme.choose("#cdd6f4", "text")
                            }
                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: workspaces.actions.switchWorkspace(pill.modelData)
                                ToolTip.visible: false
                                ToolTip.text: group.modelData.label + " • Workspace " + pill.modelData
                            }
                            DescriptionPopup {
                                target: workspaceMouse
                                title: group.modelData.label + " workspace " + pill.modelData
                                description: "A place to arrange windows, focus, and roam."
                                accentColor: (Theme.unified ? Theme.energy : group.modelData.color)
                            }
                            DropArea {
                                id: drop
                                anchors.fill: parent
                                keys: ["desktop-window"]
                                onDropped: event => {
                                    if (event.source && event.source.address) {
                                        event.source.workspaceId = pill.modelData
                                        event.acceptProposedAction()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
