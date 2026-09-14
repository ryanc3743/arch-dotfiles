import QtQuick
import Qt5Compat.GraphicalEffects

Image {
    id: icon
    property bool tintEnabled: Theme.settings ? Theme.settings.tintIcons : true
    property color tintColor: Theme.energy
    layer.enabled: tintEnabled && status === Image.Ready
    layer.effect: Colorize {
        hue: Math.max(0, icon.tintColor.hslHue)
        saturation: icon.tintColor.hslSaturation
        lightness: (icon.tintColor.hslLightness - 0.5) * 0.6
    }
}
