import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: settingsWindow
    DesktopEscapeShortcut { onClosing: colorPage.flushHistory() }
    title: "Customization Center"
    width: 1000
    height: 850
    visible: false
    required property var appSettings
    required property var presetStore
    required property var wallpaperController
    property var draftDesktopWallpaper: null
    property bool includeDesktopWallpaper: true
    property bool waitingForWallpaper: false
    property string view: "overview"
    property string subtitle: sectionSubtitle()

    property color windowBase: draftTheme.surfaceColor || "#1e1e2e"
    function surfaceRgba(alpha) { return Qt.rgba(windowBase.r, windowBase.g, windowBase.b, alpha) }
    color: Qt.rgba(windowBase.r, windowBase.g, windowBase.b, settingsWindow.draftCenterOpacity)

    signal screenPickRequested()
    function acceptScreenPick(hex) {
        if (!settingsWindow.pickingColor) return
        colorPage.flushHistory()
        colorPage.selectedColor = hex
        colorPage.hue = Math.max(0, colorPage.selectedColor.hsvHue)
        var next = Object.assign({}, settingsWindow.draftTheme)
        next[settingsWindow.selectedRole] = hex
        settingsWindow.draftTheme = next
    }
    function sectionSubtitle() {
        if (view === "overview") return "Pick a module to customize."
        if (view === "colors") return settingsWindow.editingColorway ? "Editing colorway: " + settingsWindow.editingColorway + " · Save colorway to keep your edits." : "Surfaces, Energy accents, text and borders — previewed live."
        if (view === "icons") return "Override any button's icon."
        if (view === "descriptions") return "The little descriptions shown when you hover, and how they look."
        if (view === "presets") return "Save colors, borders, icons, descriptions and opacity together."
        if (view === "opacity") return "How translucent panels and this window are."
        return ""
    }
    function go(viewId) { view = viewId }
    function goBack() { view = "overview" }
    function showDesktopPresets() { view = "presets"; Qt.callLater(() => presetsScroll.contentItem.contentY = desktopPresetTitle.y) }
    function showColorways() { view = "presets"; Qt.callLater(() => presetsScroll.contentItem.contentY = colorwayTitle.y) }
    function showElementInspector() { view = "descriptions" }

    function desktopSnapshot() {
        return {theme:draftTheme, opacity:draftOpacity, display:draftDisplay, tint:draftTint,
            unified:draftUnified, follow:draftFollow, wallpaperOutput:draftWallpaperOutput,
            icons:draftIcons, descriptions:draftDescriptions, wallpaper:includeDesktopWallpaper ? (draftDesktopWallpaper || wallpaperController.currentSnapshot()) : null}
    }
    function editDesktopPreset(preset) {
        editColorway(preset)
        editingColorway = ""
        presetName.text = ""
        draftIcons = Object.assign({}, preset.icons || {})
        draftDescriptions = Object.assign({}, preset.descriptions || {})
        includeDesktopWallpaper = !!preset.wallpaper
        draftDesktopWallpaper = preset.wallpaper ? JSON.parse(JSON.stringify(preset.wallpaper)) : null
    }
    function applyDraft() {
        if (waitingForWallpaper || savingTheme) return
        if (draftDesktopWallpaper) {
            waitingForWallpaper = true
            if (!wallpaperController.applyPreset(draftDesktopWallpaper, false)) {
                waitingForWallpaper = false
                paletteError = wallpaperController.failure
            }
        } else commitStyle()
    }
    function commitStyle() {
        savingTheme = true
        var theme = Object.assign({}, draftTheme, {unifiedTheme:draftUnified, tintIcons:draftTint,
            followWallpaper:draftFollow, wallpaperColorOutput:draftWallpaperOutput})
        appSettings.save(draftIcons, draftOpacity, draftDescriptions, theme, draftDisplay, draftCenterOpacity)
    }
    Connections {
        target: settingsWindow.wallpaperController
        function onPresetApplied(success) {
            if (!settingsWindow.waitingForWallpaper) return
            settingsWindow.waitingForWallpaper = false
            if (success) settingsWindow.commitStyle()
            else settingsWindow.paletteError = settingsWindow.wallpaperController.failure
        }
    }
    function capture(path) { (pickingColor ? colorPage : settingsContent).grabToImage(r => r.saveToFile(path)) }
    function previewPicker() { selectedRole = "accentColor"; selectedRoleLabel = "Energy"; colorPage.selectedColor = draftTheme.accentColor; pickingColor = true }
    function pickRole(key, label) {
        settingsWindow.selectedRole = key
        settingsWindow.selectedRoleLabel = label
        colorPage.selectedColor = settingsWindow.draftTheme[key] || "#313244"
        colorPage.hue = Math.max(0,colorPage.selectedColor.hsvHue)
        settingsWindow.pickingColor = true
    }
    property bool pickingColor: false
    property bool savingTheme: false
    property string selectedRole: "surfaceColor"
    property string selectedRoleLabel: "Primary"
    property string editingColorway: ""
    property real draftCenterOpacity: 1
    function editColorway(preset) {
        editingColorway = preset.name
        presetName.text = preset.name
        draftTheme = Object.assign({},draftTheme,preset.theme)
        draftOpacity = preset.opacity === undefined ? 0.88 : preset.opacity
        draftDisplay = Object.assign({},draftDisplay,preset.display || {})
        draftTint = !!preset.tint
        draftUnified = preset.unified !== false
        draftFollow = !!preset.follow
        draftWallpaperOutput = preset.wallpaperOutput || "DP-2"
        view = "colors"
        Qt.callLater(() => colorsScroll.contentItem.contentY = 0)
    }
    property bool draftTint: true
    property bool draftUnified: true
    property bool draftFollow: false
    property string draftWallpaperOutput: "DP-2"
    property string paletteError: ""
    property var draftIcons: ({})
    property var draftDescriptions: ({})
    property var draftTheme: ({ surfaceColor: "#1e1e2e", accentColor: "#cba6f7", textColor: "#cdd6f4", mutedColor: "#a6adc8" })
    onDraftThemeChanged: {
        var defaults = {tertiaryColor:"#45475a",detailAccentColor:"#89b4fa",textOutlineColor:"#11111b",
            textStyle:0,borderStyle:"solid",borderWidth:1,borderRadius:8}
        var missing = Object.keys(defaults).some(key => draftTheme[key] === undefined)
        if (missing) draftTheme = Object.assign({},defaults,draftTheme)
    }
    property real draftOpacity: 0.88
    property var draftDisplay: ({ popupFontSize: 12, popupMaxWidth: 300, popupBorderWidth: 2 })

    onVisibleChanged: if (visible) {
        pickingColor = false
        savingTheme = false
        editingColorway = ""
        draftDesktopWallpaper = null
        includeDesktopWallpaper = true
        desktopLibrary.fresh()
        draftTint = appSettings.tintIcons
        draftUnified = appSettings.unifiedTheme
        draftFollow = appSettings.followWallpaper
        draftWallpaperOutput = appSettings.wallpaperColorOutput
        draftCenterOpacity = appSettings.centerOpacity
        draftIcons = Object.assign({}, appSettings.overrides)
        draftDescriptions = Object.assign({}, appSettings.descriptions)
        draftTheme = { tertiaryColor: appSettings.tertiaryColor, detailAccentColor: appSettings.detailAccentColor, textOutlineColor: appSettings.textOutlineColor, textStyle: appSettings.textStyle, borderStyle: appSettings.borderStyle, borderWidth: appSettings.borderWidth, borderRadius: appSettings.borderRadius, secondaryColor: appSettings.secondaryColor, surfaceColor: appSettings.surfaceColor, accentColor: appSettings.accentColor, textColor: appSettings.textColor, mutedColor: appSettings.mutedColor }
        draftOpacity = appSettings.panelOpacity
        draftDisplay = { popupFontSize: appSettings.popupFontSize, popupMaxWidth: appSettings.popupMaxWidth, popupBorderWidth: appSettings.popupBorderWidth }
    }
    onClosed: colorPage.flushHistory()
    Connections {
        target: settingsWindow.appSettings
        function onSaved() { if (settingsWindow.savingTheme) { settingsWindow.savingTheme = false; settingsWindow.visible = false } }
    }

    ColumnLayout {
        id: settingsContent
        visible: !settingsWindow.pickingColor
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle { width: 46; height: 2; color: settingsWindow.draftTheme.accentColor || "#cba6f7" }
            StyledText { text: "CUSTOMIZATION CENTER"; color: settingsWindow.appSettings.textColor; font.pixelSize: 21; font.bold: true; font.letterSpacing: 2 }
            Rectangle { Layout.fillWidth: true; height: 2; color: settingsWindow.draftTheme.accentColor || "#cba6f7"; opacity: 0.5 }
            ExpanderButton {
                text: "All sections"
                visible: settingsWindow.view !== "overview"
                onClicked: settingsWindow.goBack()
            }
            ExpanderButton {
                text: "Desktop presets"
                visible: settingsWindow.view !== "presets"
                onClicked: settingsWindow.showDesktopPresets()
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            Text {
                Layout.fillWidth: true
                text: "> " + settingsWindow.subtitle.toUpperCase()
                color: settingsWindow.appSettings.mutedColor
                font.pixelSize: 11
                font.letterSpacing: 1.2
                elide: Text.ElideRight
            }
            Text { text: "MODULES 06"; color: settingsWindow.draftTheme.accentColor || "#cba6f7"; font.pixelSize: 11; font.letterSpacing: 1.2 }
            Text { text: "BAR A" + Math.round(settingsWindow.draftOpacity * 100) + "%"; color: settingsWindow.appSettings.mutedColor; font.pixelSize: 11; font.letterSpacing: 1.2 }
            Text { text: "WIN A" + Math.round(settingsWindow.draftCenterOpacity * 100) + "%"; color: settingsWindow.appSettings.mutedColor; font.pixelSize: 11; font.letterSpacing: 1.2 }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ScrollView {
                id: overviewScroll
                anchors.fill: parent
                clip: true
                visible: settingsWindow.view === "overview"
                GridLayout {
                    width: overviewScroll.availableWidth
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 14

                    HudPanel {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: 242
                        number: "00"
                        title: "Live desktop preview"
                        description: "Whole look on one screen — translucent bar, windows and popouts · open to edit live"
                        previewHeight: 180
                        onClicked: settingsWindow.go("colors")
                        ThemePreviewCanvas {
                            anchors.fill: parent
                            anchors.margins: 6
                            theme: settingsWindow.draftTheme
                            appSettings: settingsWindow.appSettings
                            tintIcons: settingsWindow.draftTint
                            barOpacity: settingsWindow.draftOpacity
                        }
                    }
                    HudPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 152
                        number: "01"
                        title: "Colors & Theme"
                        description: "Surfaces, Energy accents, text, borders and corners"
                        onClicked: settingsWindow.go("colors")
                        Row {
                            anchors.centerIn: parent
                            spacing: 10
                            Rectangle { width: 44; height: 44; radius: 3; color: settingsWindow.draftTheme.surfaceColor || "#1e1e2e"; border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                            Rectangle { width: 44; height: 44; radius: 3; color: settingsWindow.draftTheme.secondaryColor || "#313244"; border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                            Rectangle { width: 44; height: 44; radius: 3; color: settingsWindow.draftTheme.accentColor || "#cba6f7"; border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                            Rectangle { width: 44; height: 44; radius: 3; color: settingsWindow.draftTheme.textColor || "#cdd6f4"; border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                        }
                    }
                    HudPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 152
                        number: "02"
                        title: "Icons"
                        description: "Override any button icon"
                        onClicked: settingsWindow.go("icons")
                        ThemedIcon {
                            anchors.centerIn: parent
                            width: 44; height: 44
                            source: settingsWindow.appSettings.icon("firefox")
                            fillMode: Image.PreserveAspectFit
                            tintEnabled: settingsWindow.draftTint
                            tintColor: settingsWindow.draftTheme.accentColor || "#cba6f7"
                        }
                    }
                    HudPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 152
                        number: "03"
                        title: "Descriptions & Popouts"
                        description: "Hover descriptions, box size and border"
                        onClicked: settingsWindow.go("descriptions")
                        Rectangle {
                            anchors.centerIn: parent
                            width: 150; height: 44; radius: 3
                            color: settingsWindow.draftTheme.surfaceColor || "#1e1e2e"
                            border.color: settingsWindow.draftTheme.detailAccentColor || "#89b4fa"
                            border.width: 1
                            Column {
                                anchors.centerIn: parent
                                spacing: 3
                                StyledText { text: "DESCRIPTION"; color: settingsWindow.draftTheme.accentColor || "#cba6f7"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1; anchors.horizontalCenter: parent.horizontalCenter }
                                StyledText { text: "hover hint text sample"; color: settingsWindow.draftTheme.mutedColor || "#a6adc8"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                    HudPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 152
                        number: "04"
                        title: "Presets & Colorways"
                        description: "Saved whole-look presets"
                        onClicked: settingsWindow.go("presets")
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Repeater {
                                model: settingsWindow.appSettings.colorPresets.slice(0, 3)
                                Rectangle {
                                    required property var modelData
                                    width: 36; height: 46; radius: 3
                                    color: modelData.theme.surfaceColor || "#1e1e2e"
                                    border.color: Qt.rgba(1,1,1,.2); border.width: 1
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 8; width: 22; height: 22; radius: 2
                                        color: modelData.theme.accentColor || "#cba6f7"
                                    }
                                }
                            }
                        }
                    }
                    HudPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 152
                        number: "05"
                        title: "Opacity & Layers"
                        description: "Bar panels and this window translucency"
                        onClicked: settingsWindow.go("opacity")
                        Row {
                            anchors.centerIn: parent
                            spacing: 10
                            Rectangle { width: 66; height: 18; radius: 2; color: settingsWindow.surfaceRgba(0.88); border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                            Rectangle { width: 66; height: 18; radius: 2; color: settingsWindow.surfaceRgba(0.55); border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                            Rectangle { width: 66; height: 18; radius: 2; color: settingsWindow.surfaceRgba(0.3); border.color: Qt.rgba(1,1,1,.2); border.width: 1 }
                        }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 18
                visible: settingsWindow.view === "colors"
                ScrollView {
                    id: colorsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ColumnLayout {
                        width: colorsScroll.availableWidth
                        spacing: 8
                        StyledText { text: "Desktop GUI colors"; color: Theme.energy; font.bold: true; font.pixelSize: 18 }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: settingsWindow.draftUnified ? "Apply to all ✓" : "Apply to all"; onClicked: settingsWindow.draftUnified = true }
                        CheckBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Match bar contents and GUI menus"; checked: settingsWindow.draftUnified; onToggled: settingsWindow.draftUnified = checked }
                        CheckBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Tint icons with Energy color"; checked: settingsWindow.draftTint; onToggled: settingsWindow.draftTint = checked }
                        Repeater {
                            model: [{key:"surfaceColor",label:"Primary",hint:"Main surfaces"},
                                    {key:"secondaryColor",label:"Secondary",hint:"Panels and icon backgrounds"},
                                    {key:"accentColor",label:"Energy",hint:"Icons and animation"},
                                    {key:"tertiaryColor",label:"Tertiary",hint:"Hover and raised surfaces"},
                                    {key:"detailAccentColor",label:"Accent",hint:"Borders and selected controls"},
                                    {key:"textColor",label:"Text",hint:"Labels and readable content"},
                                    {key:"mutedColor",label:"Subtitle",hint:"Secondary labels and help text"},
                                    {key:"textOutlineColor",label:"Text Outline",hint:"Outline, raised and sunken text"}]
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Column {
                                    Layout.preferredWidth: 210
                                    StyledLabel { text: modelData.label; color: Theme.text; font.pixelSize: 17 }
                                    StyledLabel { text: modelData.hint; color: Theme.muted; font.pixelSize: 12 }
                                }
                                Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                                    Layout.preferredWidth: 116; Layout.preferredHeight: 48
                                    Accessible.name: "Choose " + modelData.label + " color"
                                    background: Rectangle { color: settingsWindow.draftTheme[modelData.key] || "#313244"; radius: 4; border.color: Theme.text; border.width: 2 }
                                    onClicked: settingsWindow.pickRole(modelData.key, modelData.label)
                                }
                            }
                        }
                        RowLayout {
                            StyledLabel { text: "Text effect"; color: Theme.text }
                            ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent;
                                model: ["None","Outline","Raised","Sunken"]
                                currentIndex: settingsWindow.draftTheme.textStyle || 0
                                onActivated: settingsWindow.draftTheme = Object.assign({},settingsWindow.draftTheme,{textStyle:currentIndex})
                            }
                        }
                        RowLayout {
                            StyledLabel { text: "Borders"; color: Theme.text }
                            ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent;
                                model: ["none","solid","dashed","dotted"]
                                currentIndex: model.indexOf(settingsWindow.draftTheme.borderStyle || "solid")
                                onActivated: settingsWindow.draftTheme = Object.assign({},settingsWindow.draftTheme,{borderStyle:currentText})
                            }
                            StyledLabel { text: "Width"; color: Theme.text }
                            SpinBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; from: 0; to: 6; value: settingsWindow.draftTheme.borderWidth === undefined ? 1 : settingsWindow.draftTheme.borderWidth; onValueModified: settingsWindow.draftTheme = Object.assign({},settingsWindow.draftTheme,{borderWidth:value}) }
                            StyledLabel { text: "Corners"; color: Theme.text }
                            SpinBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; from: 0; to: 24; value: settingsWindow.draftTheme.borderRadius === undefined ? 8 : settingsWindow.draftTheme.borderRadius; onValueModified: settingsWindow.draftTheme = Object.assign({},settingsWindow.draftTheme,{borderRadius:value}) }
                        }
                        RowLayout {
                            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: paletteProcess.running ? "Extracting…" : "Match wallpaper"; enabled: !paletteProcess.running; onClicked: { settingsWindow.paletteError = ""; paletteProcess.running = true } }
                            ComboBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; model: ["DP-2","DP-3","HDMI-A-1"]; currentIndex: model.indexOf(settingsWindow.draftWallpaperOutput); onActivated: settingsWindow.draftWallpaperOutput = currentText }
                        }
                        CheckBox { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Follow wallpaper changes"; checked: settingsWindow.draftFollow; onToggled: settingsWindow.draftFollow = checked }
                        StyledLabel { text: "Preview the selected monitor’s palette, then Save to apply."; color: Theme.muted }
                        StyledLabel { visible: settingsWindow.paletteError !== ""; text: settingsWindow.paletteError; color: "#f38ba8"; Layout.fillWidth: true; wrapMode: Text.Wrap }
                        ThemePreviewCanvas {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 170
                            theme: settingsWindow.draftTheme
                            appSettings: settingsWindow.appSettings
                            tintIcons: settingsWindow.draftTint
                            barOpacity: settingsWindow.draftOpacity
                            swatchRoles: [
                                {key:"surfaceColor",label:"Primary"},
                                {key:"secondaryColor",label:"Secondary"},
                                {key:"tertiaryColor",label:"Tertiary"},
                                {key:"accentColor",label:"Energy"},
                                {key:"detailAccentColor",label:"Accent"},
                                {key:"textColor",label:"Text"},
                                {key:"mutedColor",label:"Subtitle"},
                                {key:"textOutlineColor",label:"Text Outline"}]
                            selectedSwatch: swatchRoles.findIndex(r => r.key === settingsWindow.selectedRole)
                            onRolePicked: (key,label) => settingsWindow.pickRole(key,label)
                        }
                        RowLayout {
                            StyledLabel { text: "Presets"; color: settingsWindow.appSettings.textColor }
                            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Moon"; onClicked: settingsWindow.draftTheme = {secondaryColor: "#313244", surfaceColor: "#1e1e2e", accentColor: "#cba6f7", textColor: "#cdd6f4", mutedColor: "#a6adc8"} }
                            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Game Boy"; onClicked: settingsWindow.draftTheme = {secondaryColor: "#34472b", surfaceColor: "#1b281b", accentColor: "#9bbc0f", textColor: "#d8e8a8", mutedColor: "#6f8f3d"} }
                            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Charmander"; onClicked: settingsWindow.draftTheme = {secondaryColor: "#643426", surfaceColor: "#351b1b", accentColor: "#ff9f43", textColor: "#ffe0b2", mutedColor: "#d27d5f"} }
                        }
                    }
                }
                DesktopThemePreview {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    theme: settingsWindow.draftTheme
                    appSettings: settingsWindow.appSettings
                    tintIcons: settingsWindow.draftTint
                    barOpacity: settingsWindow.draftOpacity
                }
            }

            ScrollView {
                id: iconsScroll
                anchors.fill: parent
                clip: true
                visible: settingsWindow.view === "icons"
                ColumnLayout {
                    width: iconsScroll.availableWidth
                    spacing: 8
                    StyledText { text: "Inspect element properties"; color: settingsWindow.appSettings.accentColor; font.bold: true; font.pixelSize: 18 }
                    StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Change a button's icon."; color: settingsWindow.appSettings.mutedColor }
                    Repeater {
                        model: settingsWindow.appSettings.entries
                        RowLayout {
                            id: elementRow
                            required property var modelData
                            ThemedIcon { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: settingsWindow.appSettings.source(settingsWindow.draftIcons[elementRow.modelData.id] || elementRow.modelData.icon); fillMode: Image.PreserveAspectFit }
                            StyledLabel { text: elementRow.modelData.label; color: settingsWindow.appSettings.textColor; Layout.preferredWidth: 145 }
                            TextField { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                                objectName: "icon-input-" + elementRow.modelData.id
                                Layout.preferredWidth: 200
                                placeholderText: elementRow.modelData.icon
                                text: settingsWindow.draftIcons[elementRow.modelData.id] || ""
                                onTextEdited: { var icons = Object.assign({}, settingsWindow.draftIcons); if (!text.trim()) delete icons[elementRow.modelData.id]; else icons[elementRow.modelData.id] = text.trim(); settingsWindow.draftIcons = icons }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            ScrollView {
                id: descriptionsScroll
                anchors.fill: parent
                clip: true
                visible: settingsWindow.view === "descriptions"
                ColumnLayout {
                    width: descriptionsScroll.availableWidth
                    spacing: 8
                    StyledText { text: "Descriptions & popouts"; color: settingsWindow.appSettings.accentColor; font.bold: true; font.pixelSize: 18 }
                    StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "The little line shown under a button when you hover."; color: settingsWindow.appSettings.mutedColor }
                    Repeater {
                        model: settingsWindow.appSettings.entries
                        RowLayout {
                            id: iconRow
                            required property var modelData
                            ThemedIcon { Layout.preferredWidth: 28; Layout.preferredHeight: 28; source: settingsWindow.appSettings.source(settingsWindow.draftIcons[iconRow.modelData.id] || iconRow.modelData.icon); fillMode: Image.PreserveAspectFit }
                            StyledLabel { text: iconRow.modelData.label; color: settingsWindow.appSettings.textColor; Layout.preferredWidth: 145 }
                            TextField { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                                objectName: "description-input-" + iconRow.modelData.id
                                Layout.fillWidth: true
                                placeholderText: settingsWindow.appSettings.defaultDescriptions[iconRow.modelData.id]
                                text: settingsWindow.draftDescriptions[iconRow.modelData.id] || ""
                                onTextEdited: { var descriptions = Object.assign({}, settingsWindow.draftDescriptions); descriptions[iconRow.modelData.id] = text; settingsWindow.draftDescriptions = descriptions }
                            }
                        }
                    }
                    StyledText { text: "Description display"; color: settingsWindow.appSettings.accentColor; font.bold: true; font.pixelSize: 18 }
                    RowLayout {
                        StyledLabel { text: "Text size"; color: settingsWindow.appSettings.textColor }
                        Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; Layout.fillWidth: true; from: 10; to: 24; value: settingsWindow.draftDisplay.popupFontSize; onMoved: settingsWindow.draftDisplay = Object.assign({}, settingsWindow.draftDisplay, {popupFontSize: value}) }
                        StyledLabel { text: Math.round(settingsWindow.draftDisplay.popupFontSize) + " px"; color: settingsWindow.appSettings.textColor }
                    }
                    RowLayout {
                        StyledLabel { text: "Box width"; color: settingsWindow.appSettings.textColor }
                        Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; Layout.fillWidth: true; from: 180; to: 520; value: settingsWindow.draftDisplay.popupMaxWidth; onMoved: settingsWindow.draftDisplay = Object.assign({}, settingsWindow.draftDisplay, {popupMaxWidth: value}) }
                        StyledLabel { text: Math.round(settingsWindow.draftDisplay.popupMaxWidth) + " px"; color: settingsWindow.appSettings.textColor }
                    }
                    RowLayout {
                        StyledLabel { text: "Pixel border"; color: settingsWindow.appSettings.textColor }
                        Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; Layout.fillWidth: true; from: 1; to: 6; value: settingsWindow.draftDisplay.popupBorderWidth; onMoved: settingsWindow.draftDisplay = Object.assign({}, settingsWindow.draftDisplay, {popupBorderWidth: value}) }
                        StyledLabel { text: Math.round(settingsWindow.draftDisplay.popupBorderWidth) + " px"; color: settingsWindow.appSettings.textColor }
                    }
                }
            }

            ScrollView {
                id: presetsScroll
                anchors.fill: parent
                clip: true
                visible: settingsWindow.view === "presets"
                ColumnLayout {
                    width: presetsScroll.availableWidth
                    spacing: 8
                    StyledText { id: desktopPresetTitle; text: "My desktop presets"; color: Theme.text; font.bold: true; font.pixelSize: 20 }
                    StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Save colors, borders, icons, descriptions and opacity together. Attach wallpaper settings if you want the whole look."; color: Theme.muted }
                    PresetLibrary {
                        id: desktopLibrary
                        Layout.fillWidth: true
                        store: settingsWindow.presetStore
                        kind: "desktop"
                        draft: settingsWindow.desktopSnapshot()
                        onEditRequested: preset => settingsWindow.editDesktopPreset(preset)
                    }
                    CheckBox {
                        text: "Include wallpaper setup"
                        checked: settingsWindow.includeDesktopWallpaper
                        palette.windowText: Theme.text
                        onToggled: { settingsWindow.includeDesktopWallpaper = checked; settingsWindow.draftDesktopWallpaper = checked ? settingsWindow.wallpaperController.currentSnapshot() : null }
                    }
                    RowLayout {
                        visible: settingsWindow.includeDesktopWallpaper
                        Layout.fillWidth: true
                        ComboBox {
                            Layout.fillWidth: true
                            model: settingsWindow.presetStore.wallpaperPresets
                            textRole: "name"
                            displayText: currentIndex >= 0 ? currentText : "Save wallpaper presets in Wallpaper Picker"
                            palette.button: Theme.secondary; palette.buttonText: Theme.text
                            onActivated: settingsWindow.draftDesktopWallpaper = JSON.parse(JSON.stringify(model[currentIndex]))
                        }
                        ExpanderButton { text: "Use current wallpaper"; onClicked: settingsWindow.draftDesktopWallpaper = settingsWindow.wallpaperController.currentSnapshot() }
                    }
                    StyledText {
                        Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted
                        text: settingsWindow.includeDesktopWallpaper ? "Included: " + (settingsWindow.draftDesktopWallpaper?.name || "current wallpaper snapshot") + ". Main Save applies the desktop draft." : "Main Save applies your desktop draft. Preset edits stay separate until then."
                    }
                    StyledText { id: colorwayTitle; text: "My Colorways"; color: Theme.text; font.bold: true; font.pixelSize: 20 }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(184,colorwayGrid.implicitHeight)
                        Grid {
                            id: colorwayGrid
                            width: parent.width
                            columns: width >= 540 ? 2 : 1
                            spacing: 12
                            Repeater {
                                model: settingsWindow.appSettings.colorPresets
                                ColorwayCard {
                                    required property var modelData
                                    width: (colorwayGrid.width-(colorwayGrid.columns-1)*colorwayGrid.spacing)/colorwayGrid.columns
                                    height: 184
                                    preset: modelData
                                    appSettings: settingsWindow.appSettings
                                    selected: settingsWindow.editingColorway === modelData.name
                                    onClicked: settingsWindow.editColorway(modelData)
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        TextField { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; id: presetName; Layout.fillWidth: true; placeholderText: "Name this colorway"; maximumLength: 40 }
                        Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                            text: "Save colorway"
                            enabled: presetName.text.trim().length > 0
                            onClicked: settingsWindow.appSettings.saveNamedPreset(presetName.text, {
                                theme:settingsWindow.draftTheme, opacity:settingsWindow.draftOpacity,
                                display:settingsWindow.draftDisplay, tint:settingsWindow.draftTint,
                                unified:settingsWindow.draftUnified, follow:settingsWindow.draftFollow,
                                wallpaperOutput:settingsWindow.draftWallpaperOutput})
                        }
                    }
                    Button {
                        text: "Rename selected colorway"
                        visible: settingsWindow.editingColorway !== ""
                        enabled: presetName.text.trim().length > 0
                        onClicked: {
                            settingsWindow.appSettings.renamePreset(settingsWindow.editingColorway,presetName.text)
                            if (!settingsWindow.appSettings.errorMessage) settingsWindow.editingColorway = presetName.text.trim()
                        }
                    }
                }
            }

            ScrollView {
                id: opacityScroll
                anchors.fill: parent
                clip: true
                visible: settingsWindow.view === "opacity"
                ColumnLayout {
                    width: opacityScroll.availableWidth
                    spacing: 12
                    StyledText { text: "Panels & layers"; color: settingsWindow.appSettings.accentColor; font.bold: true; font.pixelSize: 18 }
                    StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Bar panels, menus and this Customization Center window render over the wallpaper."; color: settingsWindow.appSettings.mutedColor }
                    RowLayout {
                        StyledLabel { text: "Panel opacity"; color: settingsWindow.appSettings.textColor }
                        Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; Layout.fillWidth: true; from: 0; to: 1; value: settingsWindow.draftOpacity; onMoved: settingsWindow.draftOpacity = value }
                        StyledLabel { text: Math.round(settingsWindow.draftOpacity * 100) + "%"; color: settingsWindow.appSettings.textColor }
                    }
                    RowLayout {
                        StyledLabel { text: "Customization Center opacity"; color: settingsWindow.appSettings.textColor }
                        Slider { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; Layout.fillWidth: true; from: 0; to: 1; value: settingsWindow.draftCenterOpacity; onMoved: settingsWindow.draftCenterOpacity = value }
                        StyledLabel { text: Math.round(settingsWindow.draftCenterOpacity * 100) + "%"; color: settingsWindow.appSettings.textColor }
                    }
                    ThemePreviewCanvas {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        theme: settingsWindow.draftTheme
                        appSettings: settingsWindow.appSettings
                        tintIcons: settingsWindow.draftTint
                        barOpacity: settingsWindow.draftOpacity
                    }
                }
            }
        }

        StyledText { text: settingsWindow.appSettings.errorMessage; color: "#f38ba8"; visible: text.length > 0 }
        RowLayout {
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Restore original colors"; onClicked: {
                settingsWindow.draftUnified = false
                settingsWindow.draftTint = false
                settingsWindow.draftFollow = false
                settingsWindow.draftTheme = {secondaryColor:"#313244",surfaceColor:"#1e1e2e",accentColor:"#cba6f7",textColor:"#cdd6f4",mutedColor:"#a6adc8"}
                settingsWindow.draftOpacity = 0.88
                settingsWindow.draftCenterOpacity = 0.55
            } }
            Item { Layout.fillWidth: true }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary; text: "Cancel"; onClicked: settingsWindow.visible = false }
            Button { palette.window: Theme.primary; palette.base: Theme.secondary; palette.placeholderText: Theme.muted; palette.button: Theme.secondary; palette.text: Theme.text; palette.buttonText: Theme.text; palette.windowText: Theme.text; palette.highlight: Theme.accent; palette.highlightedText: Theme.primary;
                objectName: "save-settings"
                text: settingsWindow.waitingForWallpaper || settingsWindow.savingTheme ? "Applying…" : "Save"
                enabled: !settingsWindow.waitingForWallpaper && !settingsWindow.savingTheme
                onClicked: settingsWindow.applyDraft()
            }
        }
    }
    ColorPickerPage {
        id: colorPage
        anchors.fill: parent
        visible: settingsWindow.pickingColor
        appSettings: settingsWindow.appSettings
        roleKey: settingsWindow.selectedRole
        roleLabel: settingsWindow.selectedRoleLabel
        previewTheme: settingsWindow.draftTheme
        leaveIconsDefault: !settingsWindow.draftTint
        onIconModeChanged: leaveDefault => settingsWindow.draftTint = !leaveDefault
        onRoleRequested: (key,label) => {
            settingsWindow.selectedRole = key
            settingsWindow.selectedRoleLabel = label
            colorPage.selectedColor = settingsWindow.draftTheme[key] || "#313244"
            colorPage.hue = Math.max(0,colorPage.selectedColor.hsvHue)
        }
        onCanceled: settingsWindow.pickingColor = false
        onScreenPickRequested: settingsWindow.screenPickRequested()
        onAccepted: value => {
            var next = Object.assign({}, settingsWindow.draftTheme)
            next[settingsWindow.selectedRole] = value.toString()
            settingsWindow.draftTheme = next
            settingsWindow.pickingColor = false
        }
    }
    Process {
        id: paletteProcess
        command: ["python3", Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace("file://", ""),
            "palette", "--state", Quickshell.statePath("wallpaper-settings.json"), "--output", settingsWindow.draftWallpaperOutput]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) settingsWindow.draftTheme = Object.assign({},settingsWindow.draftTheme,JSON.parse(text)) }
        stderr: StdioCollector { onStreamFinished: settingsWindow.paletteError = text.trim() }
    }
}