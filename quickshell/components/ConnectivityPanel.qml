import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    ThemeBorder { z: 20 }
    id: panel
    required property var connectivity
    signal closeRequested()
    color: Theme.choose("#1e1e2e", "primary")
    implicitWidth: 620
    implicitHeight: 620
    function strength(network) {
        return Math.round(Math.max(0, Math.min(1, network.signalStrength)) * 100) + "%"
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "Network & Bluetooth"; color: Theme.choose("#cdd6f4", "text"); font.pixelSize: 24; font.bold: true; Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Done"; onClicked: panel.closeRequested() }
        }
        RowLayout {
            Layout.fillWidth: true
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                text: "Wi-Fi: " + (panel.connectivity.networking.wifiEnabled ? "On" : "Off")
                checkable: true; checked: panel.connectivity.networking.wifiEnabled
                onClicked: panel.connectivity.toggleWifi()
            }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                text: "Bluetooth: " + (panel.connectivity.adapter && panel.connectivity.adapter.enabled ? "On" : "Off")
                checkable: true; checked: panel.connectivity.adapter && panel.connectivity.adapter.enabled
                onClicked: panel.connectivity.toggleBluetooth()
            }
        }
        StyledText { text: "Wired: " + panel.connectivity.wiredLabel; color: Theme.choose("#a6adc8", "muted"); Layout.fillWidth: true; elide: Text.ElideRight }
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "Saved Wi-Fi"; color: Theme.choose("#cdd6f4", "text"); font.bold: true; Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: panel.connectivity.wifiDevice && panel.connectivity.wifiDevice.scannerEnabled ? "Stop scan" : "Scan"; enabled: !!panel.connectivity.wifiDevice; onClicked: panel.connectivity.scanWifi() }
        }
        ScrollView {
            Layout.fillWidth: true; Layout.preferredHeight: 190; clip: true
            Column { width: parent.width; spacing: 6
                Repeater {
                    model: panel.connectivity.wifiNetworks
                    delegate: Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                        required property var modelData
                        width: parent.width; height: 48
                        text: modelData.name + "  " + panel.strength(modelData) + (modelData.connected ? "  • connected" : "")
                        enabled: modelData.connected || modelData.known
                        onClicked: modelData.connected ? panel.connectivity.disconnectNetwork(modelData) : panel.connectivity.connectNetwork(modelData)
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            StyledText { text: "Bluetooth devices"; color: Theme.choose("#cdd6f4", "text"); font.bold: true; Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: panel.connectivity.adapter && panel.connectivity.adapter.discovering ? "Stop scan" : "Scan"; enabled: !!panel.connectivity.adapter; onClicked: panel.connectivity.scanBluetooth() }
        }
        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            Column { width: parent.width; spacing: 6
                Repeater {
                    model: panel.connectivity.btDevices
                    delegate: Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                        required property var modelData
                        width: parent.width; height: 52
                        text: (modelData.name || modelData.deviceName || modelData.address) + (modelData.connected ? "  • connected" : "")
                        onClicked: modelData.connected ? panel.connectivity.disconnectBluetooth(modelData) : panel.connectivity.connectBluetooth(modelData)
                    }
                }
            }
        }
        StyledText { visible: !!panel.connectivity.error; text: panel.connectivity.error; color: "#f38ba8"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    }
}
