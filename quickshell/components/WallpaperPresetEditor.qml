import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    id: editor
    required property var picker
    required property var store
    property var draft: ({mode:"individual", images:{}, spanImage:"", slideshow:{enabled:false,images:[]}})
    signal closeRequested()
    color: Qt.rgba(0, 0, 0, 0.62)
    ThemeBorder { z: 20 }
    function snapshot() {
        var value = JSON.parse(JSON.stringify(draft))
        if (value.slideshow) value.slideshow.images = (value.slideshow.images || []).map(p => p.trim()).filter(p => p)
        return value
    }
    function prepare() { draft = picker.currentSnapshot(); library.fresh() }
    function setImage(output, path) {
        if (output === "span") draft = Object.assign({}, draft, {spanImage:path})
        else {
            var images = Object.assign({}, draft.images)
            images[output] = path
            draft = Object.assign({}, draft, {images:images})
        }
    }
    function setSlide(key, value) {
        var slide = Object.assign({}, draft.slideshow || {})
        slide[key] = value
        draft = Object.assign({}, draft, {slideshow:slide})
    }
    FileDialog {
        id: imageDialog
        property string output
        title: "Choose a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif)"]
        onAccepted: editor.setImage(output, decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")))
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 24; spacing: 14
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle { width: 46; height: 2; color: Theme.energy }
            StyledText { text: "WALLPAPER PRESETS"; color: Theme.text; font.pixelSize: 21; font.bold: true; font.letterSpacing: 2 }
            Rectangle { Layout.fillWidth: true; height: 2; color: Theme.energy; opacity: 0.5 }
            ExpanderButton { text: "Use current setup"; onClicked: editor.prepare() }
            ExpanderButton { text: "Back"; onClicked: editor.closeRequested() }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            ColumnLayout {
                width: scroll.availableWidth; spacing: 14
                HudSection {
                    Layout.fillWidth: true
                    number: "01"
                    title: "Saved presets"
                    description: "Save your draft with a name to reuse it. Reusing a name updates that entry."
                    PresetLibrary {
                        id: library
                        Layout.fillWidth: true
                        store: editor.store; kind: "wallpaper"; draft: editor.snapshot()
                        onEditRequested: preset => editor.draft = JSON.parse(JSON.stringify(preset))
                    }
                }
                HudSection {
                    Layout.fillWidth: true
                    number: "02"
                    title: "Monitor wallpapers"
                    description: "Empty rows leave a monitor unchanged. Disconnected monitors stay saved for later."
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ComboBox {
                            Layout.fillWidth: true
                            model: ["INDIVIDUAL IMAGES", "SPAN ONE IMAGE ACROSS ALL MONITORS"]
                            currentIndex: editor.draft.mode === "span" ? 1 : 0
                            onActivated: editor.draft = Object.assign({}, editor.draft, {mode: currentIndex === 1 ? "span" : "individual"})
                            palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.secondary
                        }
                        Repeater {
                            model: editor.draft.mode === "span" ? ["span"] : Array.from(new Set(editor.picker.outputs.concat(Object.keys(editor.draft.images || {}))))
                            RowLayout {
                                required property string modelData
                                readonly property string imagePath: modelData === "span" ? editor.draft.spanImage || "" : editor.draft.images[modelData] || ""
                                Layout.fillWidth: true
                                Image { source: imagePath ? "file://" + imagePath : ""; Layout.preferredWidth: 88; Layout.preferredHeight: 56; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(176,112) }
                                StyledText { text: modelData === "span" ? "ALL MONITORS" : modelData.toUpperCase(); color: Theme.text; font.letterSpacing: 1; Layout.preferredWidth: 110 }
                                TextField { text: imagePath; Layout.fillWidth: true; placeholderText: "Image path (empty leaves monitor unchanged)"; palette.text: Theme.text; palette.base: Theme.secondary }
                                ExpanderButton { text: "Browse"; onClicked: { imageDialog.output = modelData; imageDialog.open() } }
                            }
                        }
                    }
                }
                HudSection {
                    Layout.fillWidth: true
                    number: "03"
                    title: "Slideshow"
                    description: "Only enabled when the draft is applied. Image paths, one per line."
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        CheckBox { text: "Enable slideshow when applied"; checked: !!editor.draft.slideshow?.enabled; palette.windowText: Theme.text; onToggled: editor.setSlide("enabled", checked) }
                        ColumnLayout {
                            visible: !!editor.draft.slideshow?.enabled
                            Layout.fillWidth: true
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                ComboBox { model: ["IN ORDER", "RANDOM"]; currentIndex: editor.draft.slideshow?.order || 0; onActivated: editor.setSlide("order", currentIndex); palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.secondary }
                                ComboBox { model: ["10 SEC", "30 SEC", "1 MIN", "5 MIN", "15 MIN", "30 MIN"]; currentIndex: editor.draft.slideshow?.intervalChoice ?? 3; onActivated: editor.setSlide("intervalChoice", currentIndex); palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.secondary }
                                ComboBox {
                                    model: ["SELECTED MONITOR", "EACH MONITOR", "SPAN ALL"]
                                    currentIndex: ["selected","all","span"].indexOf(editor.draft.slideshow?.mode || "selected")
                                    onActivated: {
                                        editor.setSlide("mode", ["selected","all","span"][currentIndex])
                                        editor.setSlide("target", currentIndex)
                                    }
                                    palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.secondary
                                }
                                ComboBox { model: editor.picker.outputs; currentIndex: Math.max(0, model.indexOf(editor.draft.slideshow?.output || editor.picker.selectedOutput)); onActivated: editor.setSlide("output", currentText); palette.button: Theme.secondary; palette.buttonText: Theme.text; palette.text: Theme.text; palette.base: Theme.secondary }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                StyledText { text: "IMAGES — ONE PATH PER LINE"; color: Theme.text; font.letterSpacing: 1; Layout.fillWidth: true }
                                ExpanderButton { text: "Use gallery images"; onClicked: editor.setSlide("images", editor.picker.filteredWallpapers.map(image => image.path)) }
                            }
                            TextArea {
                                Layout.fillWidth: true; Layout.preferredHeight: 96
                                text: (editor.draft.slideshow?.images || []).join("\n")
                                wrapMode: TextEdit.NoWrap
                                palette.text: Theme.text; palette.base: Theme.secondary
                                onTextChanged: if (activeFocus) editor.setSlide("images", text.split("\n"))
                            }
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted
                    text: "Editing and saving do not change your desktop. Apply draft uses these images and slide settings now."
                }
            }
        }
        StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: editor.picker.failure; visible: text !== ""; color: "#f38ba8" }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            ExpanderButton { text: editor.picker.presetBusy ? "Applying…" : "Apply draft"; enabled: !editor.picker.presetBusy; onClicked: editor.picker.applyPreset(editor.snapshot()) }
        }
    }
}