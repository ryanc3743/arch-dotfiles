import QtQuick
import QtQuick.Controls

Button {
    id: control
    palette.text: Theme.text
    palette.buttonText: Theme.text
    palette.button: Theme.secondary
    palette.highlight: Theme.energy
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.highlighted ? Theme.primary : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        implicitWidth: 84; implicitHeight: 32; radius: 6
        color: control.highlighted ? Theme.energy : (control.hovered ? Qt.lighter(Theme.secondary, 1.25) : Theme.secondary)
        border.color: Theme.energy
        border.width: control.activeFocus ? 1 : 0
    }
}
