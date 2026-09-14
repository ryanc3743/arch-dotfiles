import QtQuick

QtObject {
    readonly property var monitorGroups: [
        {
            monitor: "DP-3",
            label: "OS Management",
            color: "#33ccff",
            workspaces: [1, 2, 3]
        },
        {
            monitor: "DP-2",
            label: "Gaming Center",
            color: "#d4af37",
            workspaces: [4, 5, 6]
        },
        {
            monitor: "HDMI-A-1",
            label: "Media Center",
            color: "#bd93f9",
            workspaces: [7, 8, 9]
        }
    ]
}
