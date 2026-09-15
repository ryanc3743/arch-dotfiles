import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Slideshow.js" as Slideshow

Rectangle {
    ThemeBorder { z: 20 }
    anchors.fill: parent

    color: Theme.choose("#151515", "primary")
    radius: 12

    property var wallpapers: []
    property bool fitOnly: true
    property int tolerance: 400
    readonly property var monitorScreen: Quickshell.screens.find(s => s.name === selectedOutput)
    readonly property int targetWidth: monitorScreen ? Math.round(monitorScreen.width * monitorScreen.devicePixelRatio) : (selectedOutput === "DP-3" ? 1080 : selectedOutput === "DP-2" ? 2560 : 1920)
    readonly property int targetHeight: monitorScreen ? Math.round(monitorScreen.height * monitorScreen.devicePixelRatio) : (selectedOutput === "DP-3" ? 1920 : selectedOutput === "DP-2" ? 1440 : 1080)
    readonly property var filteredWallpapers: wallpapers.filter(image => !fitOnly ||
        (image.width > 0 && image.height > 0 && Math.abs(image.width-targetWidth) <= tolerance && Math.abs(image.height-targetHeight) <= tolerance))
    onSelectedOutputChanged: wallpaperGrid.positionViewAtBeginning()
    onToleranceChanged: wallpaperGrid.positionViewAtBeginning()
    onFitOnlyChanged: wallpaperGrid.positionViewAtBeginning()

    property string selectedOutput: "DP-2"

    function capture(path) { picker.grabToImage(r => r.saveToFile(path)) }
    id: picker
    property var appSettings
    required property var presetStore
    property bool editingPresets: false
    readonly property var outputs: Quickshell.screens.map(s => s.name)
    property var wallpaperState: ({})
    readonly property bool presetBusy: presetApply.running || setWallpaper.running || restore.running
    property var pendingPreset: null
    property bool matchAfterPreset: true
    property bool previousSlideshow: false
    signal presetApplied(bool success)
    FileView {
        id: wallpaperStateFile
        path: picker.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { picker.wallpaperState = JSON.parse(text()) }
            catch (error) { picker.failure = "Could not read wallpaper settings." }
        }
    }
    function currentSnapshot() {
        var state = wallpaperState
        var images = Object.assign({"DP-3":state.dp3Wallpaper || "", "DP-2":state.dp2Wallpaper || "", "HDMI-A-1":state.hdmiWallpaper || ""}, state.outputImages || {}, state.sourceImages || {})
        return {mode:state.lastMode === "span" ? "span" : "individual", images:images,
            spanImage:Object.values(state.sourceImages || {})[0] || selectedImage,
            slideshow:{enabled:slideshowActive, images:slideshowImages.slice(), index:slideIndex,
                output:slideshowOutput, mode:slideshowMode, order:slideState.order,
                intervalChoice:slideState.intervalChoice, target:slideState.target}}
    }
    function showPresets() {
        presetEditor.prepare()
        editingPresets = true
    }
    function applyPreset(preset, matchPalette) {
        if (presetBusy) { failure = "Wait for the current wallpaper change to finish."; return false }
        pendingPreset = JSON.parse(JSON.stringify(preset))
        matchAfterPreset = matchPalette !== false
        previousSlideshow = slideshowActive
        slideshowActive = false
        failure = ""
        presetApply.command = ["python3", helper, "apply-preset", "--state", statePath, "--preset-json", JSON.stringify(pendingPreset)]
        presetApply.running = true
        return true
    }
    Process {
        id: presetApply
        stderr: StdioCollector { onStreamFinished: if (text.trim()) picker.failure = text.trim() }
        stdout: StdioCollector { onStreamFinished: if (text.trim()) picker.wallpaperState = JSON.parse(text) }
        onExited: (code, status) => {
            if (code === 0) {
                picker.selectedImage = picker.pendingPreset.mode === "span" ? picker.pendingPreset.spanImage : (picker.pendingPreset.images[picker.selectedOutput] || picker.selectedImage)
                var slide = picker.pendingPreset.slideshow || {}
                picker.slideshowImages = slide.images || []
                picker.slideIndex = Math.max(-1, Math.min(picker.slideshowImages.length - 1, slide.index ?? -1))
                picker.slideshowOutput = slide.output || picker.selectedOutput
                picker.slideshowMode = ["selected","all","span"].includes(slide.mode) ? slide.mode : "selected"
                slideState.order = slide.order === 1 ? 1 : 0
                slideState.intervalChoice = Math.max(0, Math.min(5, slide.intervalChoice ?? 3))
                slideState.target = ["selected","all","span"].indexOf(picker.slideshowMode)
                picker.slideshowActive = !!slide.enabled
                slideSave.restart()
                if (picker.matchAfterPreset && picker.appSettings.followWallpaper) picker.appSettings.matchWallpaper()
            } else {
                picker.slideshowActive = picker.previousSlideshow
                if (!picker.failure) picker.failure = "Could not apply wallpaper preset."
            }
            picker.presetApplied(code === 0)
        }
    }
    property bool slideStateReady: false
    property bool wallpaperRestored: false
    property alias slideshowActive: slideState.enabled
    property alias slideshowImages: slideState.images
    property alias slideIndex: slideState.index
    property alias slideshowOutput: slideState.output
    property alias slideshowMode: slideState.mode
    FileView {
        id: slideStorage
        path: Quickshell.statePath("slideshow-settings.json")
        adapter: JsonAdapter {
            id: slideState
            property bool enabled: false
            property var images: []
            property int index: -1
            property string output: "DP-2"
            property string mode: "selected"
            property int order: 0
            property int intervalChoice: 3
            property int target: 0
        }
        onLoaded: Qt.callLater(() => { picker.slideStateReady = true })
        onLoadFailed: picker.slideStateReady = true
        onAdapterUpdated: if (picker.slideStateReady) slideSave.restart()
    }
    Timer { id: slideSave; interval: 200; onTriggered: slideStorage.writeAdapter() }
    function startSlideshow() {
        if (!filteredWallpapers.length || setWallpaper.running || restore.running) return
        slideshowImages = filteredWallpapers.map(image => image.path)
        slideshowOutput = selectedOutput
        slideshowMode = ["selected","all","span"][slideshowTarget.currentIndex]
        slideIndex = slideshowImages.indexOf(selectedImage)
        slideshowActive = true
        advanceSlide()
    }
    function advanceSlide() {
        if (!slideshowActive || !wallpaperRestored || presetApply.running || setWallpaper.running || restore.running || !slideshowImages.length) return
        slideIndex = Slideshow.nextIndex(slideshowImages.length,slideIndex,slideshowOrder.currentIndex === 1,Math.random())
        apply(slideshowImages[slideIndex],slideshowMode,slideshowOutput)
    }
    Timer {
        id: slideTimer
        interval: [10000,30000,60000,300000,900000,1800000][slideshowInterval.currentIndex]
        running: picker.slideshowActive && picker.slideStateReady && picker.wallpaperRestored
        repeat: true
        onTriggered: picker.advanceSlide()
    }
    property string selectedImage: ""
    property string failure: ""
    readonly property string statePath: Quickshell.statePath("wallpaper-settings.json")
    readonly property string helper: Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace("file://", "")
    function apply(image, mode, output) {
        if (setWallpaper.running || presetApply.running) return
        selectedImage = image
        failure = ""
        setWallpaper.command = ["python3", helper, "apply", "--image", image, "--mode", mode,
            "--output", output || selectedOutput, "--state", statePath]
        setWallpaper.running = true
    }
    /*
        Find every supported wallpaper in the wallpaper directory,
        including the iCloud Photos directory.
    */
    Process {
        id: listWallpapers

        command: ["python3", picker.helper, "catalog", "--state", picker.statePath]
        running: true
        stdout: StdioCollector {
            onStreamFinished: { if (text.trim()) picker.wallpapers = JSON.parse(text) }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) picker.failure = text.trim() }
    }

    /*
        Apply a wallpaper to the currently selected monitor.
    */
    Process {
        id: setWallpaper
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                picker.slideshowActive = false
                if (!picker.failure) picker.failure = "Wallpaper could not be applied. Slideshow stopped."
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) picker.failure = text.trim() }
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() && picker.appSettings && picker.appSettings.followWallpaper)
                picker.appSettings.matchWallpaper()
        }
    }
    Process {
        id: restore
        onExited: (code, status) => picker.wallpaperRestored = code === 0
        command: ["python3", picker.helper, "restore", "--state", picker.statePath]
        stderr: StdioCollector { onStreamFinished: if (text.trim()) picker.failure = text.trim() }
    }
    Timer { interval: 2000; running: true; onTriggered: restore.running = true }

    WallpaperPresetEditor {
        id: presetEditor
        anchors.fill: parent
        visible: picker.editingPresets
        picker: picker
        store: picker.presetStore
        onCloseRequested: picker.editingPresets = false
    }
    ColumnLayout {
        visible: !picker.editingPresets
        anchors.fill: parent
        anchors.margins: 24

        spacing: 16

        /*
            Header
        */
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: "Wallpaper Picker"

                color: Theme.choose("white", "text")

                font.pixelSize: 24
                font.bold: true

                Layout.fillWidth: true
            }

            ExpanderButton { text: "Presets"; onClicked: picker.showPresets() }

            StyledText {
                text: selectedOutput

                color: Theme.choose("#d4af37", "energy")

                font.pixelSize: 14
                font.bold: true
            }
        }

        /*
            Monitor tabs
        */
        RowLayout {
            Layout.fillWidth: true

            spacing: 8

            Repeater {
                model: [
                    {
                        name: "DP-3",
                        label: "Left"
                    },
                    {
                        name: "DP-2",
                        label: "Center"
                    },
                    {
                        name: "HDMI-A-1",
                        label: "Right"
                    }
                ]

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 42

                    radius: 8

                    color: selectedOutput === modelData.name
                           ? Theme.choose("#d4af37", "energy")
                           : Theme.choose("#252525", "secondary")

                    border.width: 1

                    border.color: selectedOutput === modelData.name
                                  ? Theme.choose("#f0d878", "energy")
                                  : Theme.choose("#444444", "secondary")

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Column {
                        anchors.centerIn: parent

                        spacing: 1

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: modelData.label

                            color: selectedOutput === modelData.name
                                   ? Theme.choose("#151515", "primary")
                                   : Theme.choose("white", "text")

                            font.pixelSize: 13
                            font.bold: true
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter

                            text: modelData.name

                            color: selectedOutput === modelData.name
                                   ? "#302800"
                                   : Theme.choose("#888888", "muted")

                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            selectedOutput = modelData.name
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Apply to each monitor"; enabled: picker.selectedImage !== "" && !setWallpaper.running; onClicked: picker.apply(picker.selectedImage, "all") }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Span across all monitors"; enabled: picker.selectedImage !== "" && !setWallpaper.running; onClicked: picker.apply(picker.selectedImage, "span") }
        }
        StyledLabel { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Click an image to apply it to the selected monitor. Then use a button above to repeat or span it across all displays."; color: Theme.text }
        StyledLabel { Layout.fillWidth: true; wrapMode: Text.Wrap; visible: picker.failure !== ""; text: picker.failure; color: "#f38ba8" }
        RowLayout {
            Layout.fillWidth: true
            ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                model: ["Fits this monitor", "All images"]
                onActivated: picker.fitOnly = currentIndex === 0
            }
            StyledLabel { text: "Tolerance"; color: Theme.text }
            ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                model: ["±200 px", "±300 px", "±400 px"]
                currentIndex: 2
                onActivated: picker.tolerance = 200 + currentIndex * 100
            }
            Item { Layout.fillWidth: true }
            StyledLabel { text: picker.targetWidth + " × " + picker.targetHeight + "  ·  " + picker.filteredWallpapers.length + " images"; color: Theme.muted }
        }
        StyledLabel {
            visible: listWallpapers.running || picker.filteredWallpapers.length === 0
            text: listWallpapers.running ? "Checking image dimensions…" : "No matching images. Choose All images to browse wallpapers for cropping or spanning."
            color: Theme.muted; Layout.fillWidth: true; wrapMode: Text.Wrap
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            radius: 8; color: Theme.secondary
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 6
                RowLayout {
                    StyledLabel { text: "Slideshow"; font.bold: true; color: Theme.text }
                    ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; id: slideshowOrder; currentIndex: slideState.order; onActivated: slideState.order = currentIndex; model: ["In picker order","Random"] }
                    ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; id: slideshowInterval; model: ["10 seconds","30 seconds","1 minute","5 minutes","15 minutes","30 minutes"]; currentIndex: slideState.intervalChoice; onActivated: slideState.intervalChoice = currentIndex }
                    ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; id: slideshowTarget; currentIndex: slideState.target; onActivated: slideState.target = currentIndex; model: ["Selected monitor","Each monitor","Span all monitors"]; enabled: !picker.slideshowActive }
                    Item { Layout.fillWidth: true }
                    Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                        text: picker.slideshowActive ? "Stop" : "Start"
                        enabled: picker.slideshowActive || (picker.filteredWallpapers.length > 0 && !setWallpaper.running && !restore.running)
                        onClicked: {
                            if (picker.slideshowActive) picker.slideshowActive = false
                            else picker.startSlideshow()
                        }
                    }
                    Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Next"; enabled: picker.slideshowActive && !setWallpaper.running; onClicked: { picker.advanceSlide(); slideTimer.restart() } }
                }
                StyledLabel {
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted
                    text: picker.slideshowActive
                        ? "Playing " + picker.slideshowImages.length + " images · " + (picker.slideshowMode === "selected" ? picker.slideshowOutput : picker.slideshowMode === "all" ? "each monitor" : "spanning all monitors") + " · keeps playing when this window closes."
                        : "Start uses the images currently shown below. Stop and restart to use a different filter or monitor."
                }
            }
        }
        /*
            Wallpaper gallery
        */
        GridView {
            id: wallpaperGrid

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            model: picker.filteredWallpapers

            cellWidth: (width - 18) / Math.max(1, Math.floor((width - 18) / 220))
            cellHeight: 180
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: 12
                contentItem: Rectangle { implicitWidth: 10; radius: 5; color: parent.pressed ? Theme.text : Theme.energy }
            }

            /*
                Allow free scrolling rather than snapping between rows.
            */
            snapMode: GridView.NoSnap

            /*
                More aggressive scrolling/momentum.
            */
            maximumFlickVelocity: 5000
            flickDeceleration: 700

            boundsBehavior: Flickable.StopAtBounds

            cacheBuffer: 1000

            delegate: Rectangle {
                id: wallpaperTile

                required property var modelData

                width: wallpaperGrid.cellWidth - 12
                height: wallpaperGrid.cellHeight - 12

                radius: 8

                color: mouseArea.containsMouse
                       ? Theme.choose("#d4af37", "energy")
                       : Theme.choose("#252525", "secondary")

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Image {
                    anchors.fill: parent

                    anchors.margins: 4

                    source: "file://" + wallpaperTile.modelData.path

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true
                    cache: true

                    opacity: mouseArea.containsMouse
                             ? 0.45
                             : 1.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 4
                    width: dimensions.implicitWidth + 12; height: 23; color: "#cc101018"; radius: 3
                    StyledText { id: dimensions; anchors.centerIn: parent; text: wallpaperTile.modelData.width + " × " + wallpaperTile.modelData.height; color: "#ffffff"; font.pixelSize: 11 }
                }
                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: { picker.slideshowActive = false; picker.apply(wallpaperTile.modelData.path, "selected") }
                }
            }

            /*
                Custom wheel handling.

                Normal mouse wheels usually send 120 angleDelta units
                per click. We translate that into a much larger pixel
                movement and also give the GridView a flick velocity.
            */
        }
    }
}
