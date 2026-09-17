import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "Slideshow.js" as Slideshow

Rectangle {
    ThemeBorder { z: 20 }
    anchors.fill: parent

    id: picker

    property var wallpapers: []
    property bool fitOnly: false
    property int tolerance: 400
    readonly property var monitorScreen: Quickshell.screens.find(s => s.name === selectedOutput)
    readonly property int targetWidth: monitorScreen ? Math.round(monitorScreen.width * monitorScreen.devicePixelRatio) : (selectedOutput === "DP-3" ? 1080 : selectedOutput === "DP-2" ? 2560 : 1920)
    readonly property int targetHeight: monitorScreen ? Math.round(monitorScreen.height * monitorScreen.devicePixelRatio) : (selectedOutput === "DP-3" ? 1920 : selectedOutput === "DP-2" ? 1440 : 1080)
    readonly property var filteredWallpapers: wallpapers.filter(image => !fitOnly ||
        (image.width > 0 && image.height > 0 && Math.abs(image.width - targetWidth) <= tolerance && Math.abs(image.height - targetHeight) <= tolerance))

    property string selectedOutput: "DP-2"

    function capture(path) { picker.grabToImage(r => r.saveToFile(path)) }
    property var appSettings
    required property var presetStore
    property bool editingPresets: false
    property bool editingGallery: false
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
        onLoaded: Qt.callLater(() => { slideStateReady = true })
        onLoadFailed: slideStateReady = true
        onAdapterUpdated: if (slideStateReady) slideSave.restart()
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
        running: picker.slideshowActive && slideStateReady && picker.wallpaperRestored
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
    readonly property bool catalogRunning: listWallpapers.running

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

    WallpaperGallery {
        picker: picker
        visible: picker.editingGallery
    }

    WallpaperPresetEditor {
        id: presetEditor
        anchors.fill: parent
        visible: picker.editingPresets
        picker: picker
        store: picker.presetStore
        onCloseRequested: picker.editingPresets = false
    }

    ColumnLayout {
        visible: !picker.editingPresets && !picker.editingGallery
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        /*
            Title bar
        */
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle { width: 46; height: 2; color: Theme.energy }
            StyledText {
                text: "WALLPAPER PICKER"
                color: Theme.text
                font.pixelSize: 21
                font.bold: true
                font.letterSpacing: 2
            }
            Rectangle { Layout.fillWidth: true; height: 2; color: Theme.energy; opacity: 0.5 }
            ExpanderButton { text: "Presets"; onClicked: picker.showPresets() }
        }

        /*
            Subline + readouts
        */
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            StyledText {
                Layout.fillWidth: true
                text: "> " + (listWallpapers.running ? "WALLPAPER CATALOGUE"
                    : picker.selectedImage ? picker.selectedOutput + " SET FROM CURRENT GALLERY"
                    : "PICK OR SPAN A WALLPAPER PER MONITOR").toString()
                color: Theme.muted
                font.pixelSize: 11
                font.letterSpacing: 1.2
                elide: Text.ElideRight
            }
            Text { text: "OUTPUTS " + picker.outputs.length; color: Theme.energy; font.pixelSize: 11; font.letterSpacing: 1.2 }
            Text { text: "IMG " + picker.filteredWallpapers.length; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
            Text { text: "QUAL " + picker.tolerance + "PX"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
        }

        /*
            Monitor selection
        */
        HudSection {
            Layout.fillWidth: true
            number: "01"
            title: "Monitors"
            description: "The tab selects the target output. Apply repeats it, Span stretches it across every surface."
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: picker.outputs
                    Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 3
                        color: picker.selectedOutput === modelData
                               ? Qt.rgba(0, 0, 0, 0.44)
                               : Qt.rgba(0, 0, 0, 0.2)
                        border.width: 1
                        border.color: picker.selectedOutput === modelData
                                      ? Qt.rgba(Theme.energy.r, Theme.energy.g, Theme.energy.b, 0.6)
                                      : Qt.rgba(1, 1, 1, 0.08)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            y: 0
                            width: picker.selectedOutput === modelData ? parent.width - 28 : 0
                            height: 2
                            color: Theme.energy
                            opacity: 0.9
                            Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.toUpperCase()
                                color: picker.selectedOutput === modelData ? Theme.energy : Theme.text
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 1.6
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: picker.selectedOutput === modelData ? "TARGET" : "OUTPUT"
                                color: picker.selectedOutput === modelData ? Theme.text : Theme.muted
                                font.pixelSize: 8
                                font.letterSpacing: 1.2
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: picker.selectedOutput = modelData
                        }
                    }
                }
            }
        }

        /*
            Apply + filter
        */
        HudSection {
            Layout.fillWidth: true
            number: "02"
            title: "Apply"
            description: picker.selectedImage ? (picker.selectedImage.split("/").pop() + " armed.") : "Open the gallery (04) and click a tile to arm it, then repeat or span."
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ExpanderButton {
                        text: "Apply to each monitor"
                        enabled: picker.selectedImage !== "" && !setWallpaper.running
                        onClicked: picker.apply(picker.selectedImage, "all")
                    }
                    ExpanderButton {
                        text: "Span across monitors"
                        enabled: picker.selectedImage !== "" && !setWallpaper.running
                        onClicked: picker.apply(picker.selectedImage, "span")
                    }
                    Item { Layout.fillWidth: true }
                    ComboBox {
                        model: ["FITS THIS MONITOR", "ALL IMAGES"]
                        currentIndex: picker.fitOnly ? 0 : 1
                        onActivated: picker.fitOnly = currentIndex === 0
                        palette.window: Theme.primary; palette.base: Theme.secondary
                        palette.button: Theme.secondary; palette.text: Theme.text
                        palette.buttonText: Theme.text; palette.windowText: Theme.text
                        palette.highlight: Theme.energy; palette.highlightedText: Theme.primary
                    }
                    StyledLabel { text: "Tolerance"; color: Theme.muted }
                    ComboBox {
                        model: ["±200", "±300", "±400"]
                        currentIndex: Math.floor((picker.tolerance - 200) / 100)
                        onActivated: picker.tolerance = 200 + currentIndex * 100
                        palette.window: Theme.primary; palette.base: Theme.secondary
                        palette.button: Theme.secondary; palette.text: Theme.text
                        palette.buttonText: Theme.text; palette.windowText: Theme.text
                        palette.highlight: Theme.energy; palette.highlightedText: Theme.primary
                    }
                    Item { width: 4 }
                    StyledText {
                        text: picker.targetWidth + "×" + picker.targetHeight
                        color: Theme.muted
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                }
                StyledLabel {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    visible: picker.failure !== ""
                    text: picker.failure
                    color: "#f38ba8"
                }
            }
        }

        /*
            Slideshow
        */
        HudSection {
            Layout.fillWidth: true
            number: "03"
            title: "Slideshow"
            description: picker.slideshowActive
                ? "Playing " + picker.slideshowImages.length + " images · keeps playing when this window closes."
                : "Start plays the filtered library on the selected target. Stop and restart to use a different filter or monitor."
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ComboBox {
                        id: slideshowOrder
                        currentIndex: slideState.order
                        onActivated: slideState.order = currentIndex
                        model: ["IN PICKER ORDER", "RANDOM"]
                        palette.window: Theme.primary; palette.base: Theme.secondary
                        palette.button: Theme.secondary; palette.text: Theme.text
                        palette.buttonText: Theme.text; palette.windowText: Theme.text
                        palette.highlight: Theme.energy; palette.highlightedText: Theme.primary
                    }
                    ComboBox {
                        id: slideshowInterval
                        model: ["10 SEC", "30 SEC", "1 MIN", "5 MIN", "15 MIN", "30 MIN"]
                        currentIndex: slideState.intervalChoice
                        onActivated: slideState.intervalChoice = currentIndex
                        palette.window: Theme.primary; palette.base: Theme.secondary
                        palette.button: Theme.secondary; palette.text: Theme.text
                        palette.buttonText: Theme.text; palette.windowText: Theme.text
                        palette.highlight: Theme.energy; palette.highlightedText: Theme.primary
                    }
                    ComboBox {
                        id: slideshowTarget
                        currentIndex: slideState.target
                        onActivated: slideState.target = currentIndex
                        model: ["SELECTED MONITOR", "EACH MONITOR", "SPAN ALL"]
                        enabled: !picker.slideshowActive
                        palette.window: Theme.primary; palette.base: Theme.secondary
                        palette.button: Theme.secondary; palette.text: Theme.text
                        palette.buttonText: Theme.text; palette.windowText: Theme.text
                        palette.highlight: Theme.energy; palette.highlightedText: Theme.primary
                    }
                    Item { Layout.fillWidth: true }
                    ExpanderButton {
                        text: picker.slideshowActive ? "Stop" : "Start"
                        enabled: picker.slideshowActive || (picker.filteredWallpapers.length > 0 && !setWallpaper.running && !restore.running)
                        onClicked: {
                            if (picker.slideshowActive) picker.slideshowActive = false
                            else picker.startSlideshow()
                        }
                    }
                    ExpanderButton {
                        text: "Next"
                        enabled: picker.slideshowActive && !setWallpaper.running
                        onClicked: { picker.advanceSlide(); slideTimer.restart() }
                    }
                }
            }
        }

        /*
            Library entry — full grid lives in the separate gallery screen
        */
        HudSection {
            Layout.fillWidth: true
            number: "04"
            title: "Library"
            description: picker.selectedImage
                ? (picker.selectedImage.split("/").pop() + " armed · apply to " + picker.selectedOutput + " below.")
                : "Open the full library (GALLERY →) and click a tile to apply it to the selected monitor."
            status: (picker.targetWidth + "×" + picker.targetHeight) + " · " + picker.filteredWallpapers.length + "/" + picker.wallpapers.length
            headerAction: HudTag { text: "GALLERY →"; colorWay: HudTag.Gold; onClicked: picker.editingGallery = true }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 48
                    radius: 3
                    color: Qt.rgba(0, 0, 0, 0.24)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: picker.selectedImage ? "file://" + picker.selectedImage : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    StyledText {
                        anchors.centerIn: parent
                        visible: picker.selectedImage === ""
                        text: "NO IMAGE ARMED"
                        color: Theme.muted
                        font.pixelSize: 9
                        font.letterSpacing: 1.1
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: picker.selectedImage
                            ? (picker.selectedImage.split("/").pop() + " → " + picker.selectedOutput)
                            : "NO WALLPAPER ARMED"
                        color: picker.selectedImage ? Theme.energy : Theme.text
                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "CLICK A TILE IN THE GALLERY TO SET THE SELECTED MONITOR"
                        color: Theme.muted
                        font.pixelSize: 9
                        font.letterSpacing: 1.1
                    }
                }
            }
        }
    }
}