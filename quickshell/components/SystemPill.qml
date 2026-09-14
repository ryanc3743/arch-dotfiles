import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "SystemMetrics.js" as Metrics

Rectangle {
    id: pill
    property real panelOpacity: 0.34
    property bool continuousStyle: false
    property var sample: null
    property int cpuPercent: -1
    readonly property int memoryPercent: sample ? Math.round(100 * sample.memoryUsed / sample.memoryTotal) : -1
    readonly property string details: sample
        ? "CPU: " + (cpuPercent < 0 ? "sampling…" : cpuPercent + "%")
          + "\nMemory: " + (sample.memoryUsed / 1048576).toFixed(1) + " / "
          + (sample.memoryTotal / 1048576).toFixed(1) + " GiB"
          + "\nUptime: " + Metrics.uptimeText(sample.uptime)
        : "System information unavailable"
    implicitWidth: 104
    implicitHeight: 64
    radius: continuousStyle ? 0 : 18
    color: continuousStyle ? "transparent" : Qt.rgba(0.15, 0.17, 0.21, panelOpacity)
    border.color: continuousStyle ? "transparent" : Qt.rgba(0.8, 0.83, 0.9, 0.12)
    Column {
        anchors.centerIn: parent
        spacing: 3
        StyledText {
            text: "CPU  " + (pill.cpuPercent < 0 ? "—" : pill.cpuPercent + "%")
            color: Theme.choose("#cdd6f4", "text")
            font.pixelSize: 14
        }
        StyledText {
            text: "RAM  " + (pill.memoryPercent < 0 ? "—" : pill.memoryPercent + "%")
            color: Theme.choose("#a6adc8", "muted")
            font.pixelSize: 14
        }
    }
    Timer {
        interval: 3000
        repeat: true
        running: pill.visible
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }
    Process {
        id: sampler
        command: ["cat", "/proc/stat", "/proc/meminfo", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                var next = Metrics.parse(text)
                pill.cpuPercent = Metrics.cpuPercent(pill.sample, next)
                pill.sample = next
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || exitStatus !== 0) {
                pill.sample = null
                pill.cpuPercent = -1
            }
        }
    }
    MouseArea {
        id: systemMouse
        anchors.fill: parent
        hoverEnabled: true
        ToolTip.visible: false
        ToolTip.text: pill.details
    }
    DescriptionPopup {
        target: systemMouse
        title: "System"
        description: "CPU, memory, and uptime: the bar's tiny status report."
    }
}
