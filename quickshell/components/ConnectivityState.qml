import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth
import "NetworkIcon.js" as NetworkIcons

QtObject {
    id: state
    readonly property var networking: Networking
    readonly property var bluetooth: Bluetooth
    readonly property var wifiDevice: networking.devices.values.find(device => device.type === DeviceType.Wifi) || null
    readonly property var wiredDevices: networking.devices.values.filter(device => device.type === DeviceType.Wired)
    readonly property var wifiNetworks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var adapter: bluetooth.defaultAdapter
    readonly property var btDevices: adapter ? adapter.devices.values : []
    readonly property var connectedNetwork: wifiNetworks.find(network => network.connected) || null
    readonly property var connectedWired: wiredDevices.find(device => device.connected) || null
    readonly property var connectedBluetooth: btDevices.find(device => device.connected) || null
    readonly property string wifiLabel: connectedNetwork ? connectedNetwork.name : (networking.wifiEnabled ? "No Wi-Fi connection" : "Wi-Fi off")
    readonly property string wiredLabel: connectedWired ? connectedWired.name : "Ethernet disconnected"
    readonly property string bluetoothLabel: connectedBluetooth ? (connectedBluetooth.name || connectedBluetooth.deviceName) : (adapter && adapter.enabled ? "No Bluetooth device" : "Bluetooth off")
    readonly property bool networkProblem: networking.connectivity === NetworkConnectivity.Portal
        || networking.connectivity === NetworkConnectivity.Limited
        || ((connectedWired || connectedNetwork) && networking.connectivityCheckEnabled
            && networking.connectivity === NetworkConnectivity.None)
    readonly property string networkIcon: NetworkIcons.icon(!!connectedWired, !!connectedNetwork, networkProblem)
    readonly property string networkStatus: !connectedWired && !connectedNetwork ? "No connection"
        : (connectedWired ? "Ethernet connected" : "Wi-Fi: " + connectedNetwork.name)
          + (networking.connectivity === NetworkConnectivity.Portal ? " · Sign in required"
             : networkProblem ? " · Internet connection issue"
             : networking.connectivity === NetworkConnectivity.Full ? " · Internet available" : " · Internet status unverified")
    property string error: ""

    function toggleWifi() { error = ""; networking.wifiEnabled = !networking.wifiEnabled }
    function toggleBluetooth() {
        error = ""
        if (adapter) adapter.enabled = !adapter.enabled
        else error = "No Bluetooth adapter is available."
    }
    function scanWifi() { if (wifiDevice) wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled }
    function scanBluetooth() { if (adapter) adapter.discovering = !adapter.discovering }
    function connectNetwork(network) {
        error = ""
        if (!network || !network.known) { error = "Only saved Wi-Fi networks can be connected here."; return }
        network.connect()
    }
    function disconnectNetwork(network) { if (network) network.disconnect() }
    function connectBluetooth(device) { if (device) device.connect() }
    function disconnectBluetooth(device) { if (device) device.disconnect() }
}
