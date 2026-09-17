import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/*
    Full-bleed gallery screen.

    Replaces the whole picker root column (picker.editingGallery === true) with
    nothing but the catalogue — the widest possible grid, no monitor pills, no
    title chrome. Opened by the gold GALLERY → pill inside the Picker HudSection
    title row; closed with ← / Escape (DesktopEscapeShortcut) via backRequested.
*/
Rectangle {
    id: gallery
    required property var picker
    property bool editingGallery: picker.editingGallery
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 0
    color: Theme.primary
    border.color: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.1 * (gallery.editingGallery ? 1 : 1))
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            HudTag { text: "←  BACK"; colorWay: HudTag.Gold; onClicked: gallery.picker.editingGallery = false }
            StyledText {
                text: "GALLERY — FULL LIBRARY  ·  " + picker.filteredWallpapers.length + " IMGS"
                color: Theme.text; font.pixelSize: 20; font.bold: true
                font.letterSpacing: 2.4
            }
            StyledText {
                Layout.alignment: Qt.AlignRight
                text: "SPAN " + picker.spanMode
                color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1.2
            }
        }

        GridView {
            id: galleryGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: picker.wallpapers
            cellWidth: (width - 12) / Math.max(1, Math.floor((width - 12) / 240))
            cellHeight: Math.max(196, (height - 12) * 0.18)
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn; width: 12
                contentItem: Rectangle { implicitWidth: 10; radius: 5; color: Theme.energy }
            }
            cacheBuffer: 2000
            delegate: Rectangle {
                id: tile
                required property var modelData
                width: galleryGrid.cellWidth - 10
                height: galleryGrid.cellHeight - 10
                radius: 4
                color: Qt.rgba(0, 0, 0, 0.26)
                border.width: hoverArea.containsMouse ? 1 : 1
                border.color: hoverArea.containsMouse
                              ? Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.6)
                              : Qt.rgba(1, 1, 1, 0.06)
                Behavior on border.color { ColorAnimation { duration: 110 } }
                Image {
                    anchors.fill: parent; anchors.margins: 5
                    source: "file://" + tile.modelData.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true; cache: true
                    opacity: hoverArea.containsMouse ? 0.55 : 1
                    Behavior on opacity { NumberAnimation { duration: 110 } }
                }
                StyledLabel {
                    anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 6
                    text: tile.modelData.width + " × " + tile.modelData.height
                    color: Theme.energy; font.pixelSize: 9; font.letterSpacing: 1.1
                }
                MouseArea { id: hoverArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: { picker.apply(tile.modelData.path, "selected") }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            HudTag { text: "← BACK TO PICKER"; colorWay: HudTag.Gold; onClicked: gallery.picker.editingGallery = false }
            HudTag { text: "MATCHES MONITOR SIZE ONLY" ; colorWay: HudTag.Gold; visible: picker.fitOnly
                onClicked: { picker.fitOnly = false } }
            HudTag { text: "ALL IMAGES"; colorWay: HudTag.Gold; visible: !picker.fitOnly
                onClicked: { picker.fitOnly = true } }
        }
    }
}
