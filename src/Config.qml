import QtQuick
import Quickshell
import Quickshell.Io

// User preferences in ~/.config/omarchy/mouse-first.json (same keys as v0.1).
// Edits made in the file by hand are picked up live; changes made from the
// settings panel are written back atomically.
FileView {
    id: file

    readonly property alias data: adapter
    property bool ready: false

    path: Quickshell.env("HOME") + "/.config/omarchy/mouse-first.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false

    onFileChanged: reload()
    onLoaded: ready = true
    onLoadFailed: error => {
        // First run: write the defaults so the file documents every option.
        if (error === FileViewError.FileNotFound) writeAdapter()
        ready = true
    }
    onAdapterUpdated: writeAdapter()

    // Assign a property and persist it. Objects and arrays must be replaced,
    // not mutated, for the change to be seen.
    function set(key, value) {
        adapter[key] = value
    }

    function toggle(key) {
        adapter[key] = !adapter[key]
    }

    JsonAdapter {
        id: adapter

        property string language: String(Quickshell.env("LANG") || "").indexOf("pt") === 0 ? "pt" : "en"
        property bool disableTiling: true
        property bool alwaysVisible: true
        property bool dragFullWidth: true
        property bool showDragHandle: false
        property bool ignoreDock: false
        property bool disableSnapping: false
        property bool minimizeToBar: true
        property string barSection: "left"

        property bool enableMenuDrag: true
        property bool rememberMenuPerWindow: false
        property bool rememberMenuGlobal: false
        property bool alwaysShowMenuDragZone: false
        property real globalMenuOffsetX: 0
        property real globalMenuOffsetY: 0
        property var perWindowClassOffsets: ({})

        property var buttonOrder: ["float", "minimize", "maximize", "close"]
        property var buttonVisible: ({ float: false, minimize: true, maximize: true, close: true })

        property string colorMode: "theme"
        property string customBg: "#0e0e14"
        property string customFg: "#a9b1d6"
        property string customAccent: "#7aa2f7"
        property string customRed: "#f7768e"
    }
}
