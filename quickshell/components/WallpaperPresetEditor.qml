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
    color: Theme.primary
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
        anchors.fill: parent; anchors.margins: 24; spacing: 12
        RowLayout {
            StyledText { text: "Wallpaper presets"; color: Theme.text; font.pixelSize: 24; font.bold: true; Layout.fillWidth: true }
            ExpanderButton { text: "Use current setup"; onClicked: editor.prepare() }
            ExpanderButton { text: "Back"; onClicked: editor.closeRequested() }
        }
        ScrollView {
            id: scroll
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            ColumnLayout {
                width: scroll.availableWidth; spacing: 12
                PresetLibrary {
                    id: library
                    Layout.fillWidth: true
                    store: editor.store; kind: "wallpaper"; draft: editor.snapshot()
                    onEditRequested: preset => editor.draft = JSON.parse(JSON.stringify(preset))
                }
                StyledText { text: "Monitor wallpapers"; color: Theme.energy; font.pixelSize: 18; font.bold: true }
                ComboBox {
                    model: ["Individual images", "Span one image across all monitors"]
                    currentIndex: editor.draft.mode === "span" ? 1 : 0
                    onActivated: editor.draft = Object.assign({}, editor.draft, {mode: currentIndex === 1 ? "span" : "individual"})
                    palette.button: Theme.secondary; palette.buttonText: Theme.text
                }
                Repeater {
                    model: editor.draft.mode === "span" ? ["span"] : Array.from(new Set(editor.picker.outputs.concat(Object.keys(editor.draft.images || {}))))
                    RowLayout {
                        required property string modelData
                        readonly property string imagePath: modelData === "span" ? editor.draft.spanImage || "" : editor.draft.images[modelData] || ""
                        Layout.fillWidth: true
                        Image { source: imagePath ? "file://" + imagePath : ""; Layout.preferredWidth: 88; Layout.preferredHeight: 56; fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(176,112) }
                        StyledText { text: modelData === "span" ? "All monitors" : modelData; color: Theme.text; Layout.preferredWidth: 100 }
                        TextField { text: imagePath; Layout.fillWidth: true; placeholderText: "Image path (empty leaves monitor unchanged)"; palette.text: Theme.text; palette.base: Theme.secondary; onTextEdited: editor.setImage(modelData, text) }
                        ExpanderButton { text: "Browse"; onClicked: { imageDialog.output = modelData; imageDialog.open() } }
                    }
                }
                CheckBox { text: "Enable slideshow when applied"; checked: !!editor.draft.slideshow?.enabled; palette.windowText: Theme.text; onToggled: editor.setSlide("enabled", checked) }
                ColumnLayout {
                    visible: !!editor.draft.slideshow?.enabled
                    Layout.fillWidth: true
                    RowLayout {
                        ComboBox { model: ["In order", "Random"]; currentIndex: editor.draft.slideshow?.order || 0; onActivated: editor.setSlide("order", currentIndex) }
                        ComboBox { model: ["10 seconds", "30 seconds", "1 minute", "5 minutes", "15 minutes", "30 minutes"]; currentIndex: editor.draft.slideshow?.intervalChoice ?? 3; onActivated: editor.setSlide("intervalChoice", currentIndex) }
                        ComboBox { model: ["Selected monitor", "Each monitor", "Span all monitors"]; currentIndex: ["selected","all","span"].indexOf(editor.draft.slideshow?.mode || "selected"); onActivated: { editor.setSlide("mode", ["selected","all","span"][currentIndex]); editor.setSlide("target", currentIndex) } }
                        ComboBox { model: editor.picker.outputs; currentIndex: Math.max(0, model.indexOf(editor.draft.slideshow?.output || editor.picker.selectedOutput)); onActivated: editor.setSlide("output", currentText) }
                    }
                    RowLayout {
                        StyledText { text: "Slideshow images — one path per line"; color: Theme.text; Layout.fillWidth: true }
                        ExpanderButton { text: "Use gallery images"; onClicked: editor.setSlide("images", editor.picker.filteredWallpapers.map(image => image.path)) }
                    }
                    TextArea {
                        Layout.fillWidth: true; Layout.preferredHeight: 100
                        text: (editor.draft.slideshow?.images || []).join("\n")
                        wrapMode: TextEdit.NoWrap
                        palette.text: Theme.text; palette.base: Theme.secondary
                        onTextChanged: if (activeFocus) editor.setSlide("images", text.split("\n"))
                    }
                }
                StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; color: Theme.muted; text: "Edit and save without changing your desktop. Apply draft uses these images and slideshow settings now." }
            }
        }
        StyledText { Layout.fillWidth: true; wrapMode: Text.Wrap; text: editor.picker.failure; visible: text !== ""; color: "#f38ba8" }
        RowLayout {
            Item { Layout.fillWidth: true }
            ExpanderButton { text: editor.picker.presetBusy ? "Applying…" : "Apply draft"; enabled: !editor.picker.presetBusy; onClicked: editor.picker.applyPreset(editor.snapshot()) }
        }
    }
}
