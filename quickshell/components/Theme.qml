pragma Singleton
import QtQuick
QtObject {
    property var settings: null
    readonly property color primary: settings ? settings.surfaceColor : "#1e1e2e"
    readonly property color secondary: settings ? settings.secondaryColor : "#313244"
    readonly property color energy: settings ? settings.accentColor : "#cba6f7"
    readonly property color text: settings ? settings.textColor : "#cdd6f4"
    readonly property color muted: settings ? settings.mutedColor : "#a6adc8"
    readonly property color tertiary: settings ? settings.tertiaryColor : "#45475a"
    readonly property color accent: settings ? settings.detailAccentColor : "#89b4fa"
    readonly property color textOutline: settings ? settings.textOutlineColor : "#11111b"
    readonly property int textStyle: settings ? settings.textStyle : 0
    readonly property string borderStyle: settings ? settings.borderStyle : "solid"
    readonly property int borderWidth: settings ? settings.borderWidth : 1
    readonly property int borderRadius: settings ? settings.borderRadius : 8
    readonly property bool unified: settings ? settings.unifiedTheme : true
    function choose(original, role) {
        return unified ? ({primary:primary, secondary:secondary, energy:energy, tertiary:tertiary, accent:accent, text:text, muted:muted})[role] : original
    }
}
