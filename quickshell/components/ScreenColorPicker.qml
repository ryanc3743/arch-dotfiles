import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/* Full-screen surface color picker.

   While active it freezes the composited desktop of one output into a PNG via
   grim, shows that frame full-bleed, and magnifies the pixels around the cursor
   through a Canvas lens with a live hex/RGB readout.  A click commits the
   center pixel (wl-copy + picked(hex)); Esc / right-click cancels.

   Everything is 1:1 because grim captures the output at its native pixels and
   every monitor on this setup is scale 1 — the local mouse position indexes
   straight into the captured frame. */
Rectangle {
    id: picker

    required property string outputName
    property bool live: false
    property bool busy: false
    property real zoom: 14
    property string pickedHex: "#000000"
    property real cursorX: 0
    property real cursorY: 0
    property bool hasCursor: false
    readonly property real lensX: (hasCursor ? cursorX : width / 2)
    readonly property real lensY: (hasCursor ? cursorY : height / 2)
    signal picked(string hex)
    signal canceled()
    signal armed()
    onWidthChanged: lens.requestPaint()
    onHeightChanged: lens.requestPaint()
    onLensXChanged: lens.requestPaint()
    onLensYChanged: lens.requestPaint()

    color: "black"

    function arm() {
        if (busy || live) return
        busy = true
        grimProcess.command = ["grim", "-o", picker.outputName, "-t", "png", frostPath]
        grimProcess.running = true
    }
    function disarm() { live = false; busy = false }

    function wlCopy(hex) {
        wlCopyProcess.command = ["bash", "-c", "printf %s " + hex + " | wl-copy"]
        wlCopyProcess.running = true
    }

    readonly property string frostPath: "/tmp/qs-screenpick-" + outputName + ".png"

    Process {
        id: grimProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) { busy = false; return }
            busy = false
            live = true
            backdrop.source = "file://" + picker.frostPath
            picker.armed()
            refresh.restart()
            Qt.callLater(() => lens.requestPaint())
        }
    }
    Process {
        id: wlCopyProcess
    }

    /* The frozen frame's status reaches Ready slightly before its texture is
       sampleable by the Canvas, so repaint once shortly after arming. */
    Timer {
        id: refresh
        interval: 90
        repeat: false
        onTriggered: lens.requestPaint()
    }

    Image {
        id: backdrop
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: false
        sourceSize: Qt.size(picker.width, picker.height)
        smooth: false
        onStatusChanged: if (status === Image.Ready && picker.live) { lens.requestPaint(); refresh.restart() }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: picker.live
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: m => { picker.cursorX = m.x; picker.cursorY = m.y; picker.hasCursor = true }
        onPressed: m => {
            if (!picker.live) return
            if (m.button === Qt.RightButton) { picker.canceled(); return }
            picker.cursorX = m.x; picker.cursorY = m.y; picker.hasCursor = true
            lens.requestPaint()
            var hex = picker.pickedHex
            picker.wlCopy(hex)
            picker.picked(hex)
        }
        cursorShape: Qt.CrossCursor
    }

    /* Magnifier lens: a fixed-size square drawn by Canvas, anchored so the
       crosshair cell sits exactly on the cursor's pixel. */
    Canvas {
        id: lens
        width: 224
        height: 224
        z: 10
        visible: picker.live
        antialiasing: false
        renderTarget: Canvas.Image

        x: Math.max(0, Math.min(picker.width - width, picker.lensX - width / 2))
        y: Math.max(0, Math.min(picker.height - height, picker.lensY - height / 2))

        property int cells: 15
        property int cellPx: Math.floor((lens.width - 24) / lens.cells)
        property real srcX: Math.max(0, Math.min(picker.width - 1, picker.lensX))
        property real srcY: Math.max(0, Math.min(picker.height - 1, picker.lensY))
        property var hoverCell: ({r:0,g:0,b:0})

        onPaint: {
            var ctx = getContext("2d")
            try { ctx.reset() } catch (e) {}
            if (!picker.live || backdrop.status !== Image.Ready) return
            try { ctx.imageSmoothingEnabled = false } catch (e) {}

            var cell = lens.cellPx
            var cells = lens.cells
            var off = (lens.width - cell * cells) / 2
            var center = Math.floor(cells / 2)
            var sx0 = Math.max(0, Math.min(picker.width - cells, Math.round(lens.srcX) - center))
            var sy0 = Math.max(0, Math.min(picker.height - cells, Math.round(lens.srcY) - center))

            for (var j = 0; j < cells; ++j) {
                for (var i = 0; i < cells; ++i) {
                    var dx = off + i * cell
                    var dy = off + j * cell
                    ctx.drawImage(backdrop, sx0 + i, sy0 + j, 1, 1, dx, dy, cell, cell)
                }
            }

            var cdx = off + center * cell
            var cdy = off + center * cell
            var data = ctx.getImageData(cdx, cdy, 1, 1).data
            lens.hoverCell = {r: data[0], g: data[1], b: data[2]}
            var ch = "0123456789ABCDEF"
            picker.pickedHex = "#" + ch[data[0] >> 4] + ch[data[0] & 15] +
                                         ch[data[1] >> 4] + ch[data[1] & 15] +
                                         ch[data[2] >> 4] + ch[data[2] & 15]

            /* subtle backdrop under lens + crosshair + corner brackets */
            ctx.strokeStyle = "rgba(0,0,0,0.55)"
            ctx.lineWidth = 1
            ctx.strokeRect(0.5, 0.5, lens.width - 1, lens.height - 1)
            ctx.strokeStyle = "rgba(255,255,255,0.85)"
            ctx.strokeRect(cdx + 0.5, cdy + 0.5, cell - 1, cell - 1)
            ctx.beginPath()
            ctx.moveTo(cdx + cell / 2, cdy - 5); ctx.lineTo(cdx + cell / 2, cdy)
            ctx.moveTo(cdx + cell / 2, cdy + cell); ctx.lineTo(cdx + cell / 2, cdy + cell + 5)
            ctx.moveTo(cdx - 5, cdy + cell / 2); ctx.lineTo(cdx, cdy + cell / 2)
            ctx.moveTo(cdx + cell, cdy + cell / 2); ctx.lineTo(cdx + cell + 5, cdy + cell / 2)
            ctx.stroke()
        }
    }

    /* HUD readout — bottom center pill, HUD style. */
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        width: readoutRow.implicitWidth + 40
        height: 58
        radius: 3
        color: Qt.rgba(0, 0, 0, 0.72)
        border.color: Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.55)
        border.width: 1
        visible: picker.live
        RowLayout {
            id: readoutRow
            anchors.centerIn: parent
            spacing: 14
            Rectangle {
                id: swatch
                width: 34; height: 34; radius: 2
                color: picker.pickedHex
                border.color: "white"; border.width: 1
            }
            ColumnLayout {
                spacing: 0
                Text {
                    text: picker.pickedHex
                    color: "white"
                    font.family: "monospace"; font.bold: true; font.pixelSize: 16; font.letterSpacing: 1
                }
                Text {
                    text: (lens.hoverCell.r).toString().padStart(3, " ") + "  " +
                          (lens.hoverCell.g).toString().padStart(3, " ") + "  " +
                          (lens.hoverCell.b).toString().padStart(3, " ")
                    color: Qt.rgba(1,1,1,0.7)
                    font.family: "monospace"; font.pixelSize: 11; font.letterSpacing: 1
                }
            }
            Rectangle { width: 1; height: 34; color: Qt.rgba(1,1,1,0.25) }
            ColumnLayout {
                spacing: 0
                Text {
                    text: Math.round(picker.zoom * 100) + "%"
                    color: Qt.rgba(1,1,1,0.9)
                    font.family: "monospace"; font.bold: true; font.pixelSize: 13
                }
                Text {
                    text: "CLICK PICK · ESC CANCEL"
                    color: Qt.rgba(1,1,1,0.55)
                    font.family: "monospace"; font.pixelSize: 9; font.letterSpacing: 1
                }
            }
        }
    }

    Text {
        anchors.top: parent.top; anchors.topMargin: 26
        anchors.horizontalCenter: parent.horizontalCenter
        text: "SCREEN COLOR PICKER — " + picker.outputName.toUpperCase()
        color: Qt.rgba(1,1,1,0.85)
        font.family: "monospace"; font.bold: true; font.pixelSize: 13; font.letterSpacing: 2.5
        visible: picker.live
    }

    Text {
        anchors.centerIn: parent
        text: "Capturing screen…"
        color: Qt.rgba(1,1,1,0.7)
        font.family: "monospace"; font.pixelSize: 14
        visible: picker.visible && picker.busy
    }

    DesktopEscapeShortcut {
        enabled: picker.visible
        onClosing: {
            picker.canceled()
        }
    }
}