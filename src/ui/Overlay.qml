import QtQuick
import Quickshell
import Quickshell.Wayland

// Transparent layer covering one screen. Only the controls, the drag strip
// and the settings panel take input (see `mask`); everything else clicks
// through to the windows underneath.
PanelWindow {
    id: overlay

    required property var service
    readonly property var svc: service

    // Monitor geometry as Hyprland reports it (global layout coordinates).
    readonly property var monitor: svc.tracker.monitorByName(screen ? screen.name : "")
    readonly property real originX: monitor ? monitor.x : (screen ? screen.x : 0)
    readonly property real originY: monitor ? monitor.y : (screen ? screen.y : 0)
    readonly property real reservedTop: monitor ? monitor.reserved.top : 0

    // This overlay draws the controls when the active window is on its
    // monitor. During a drag it keeps them (and the pointer grab) until the
    // button is released, even if the window crosses to another screen.
    readonly property bool hosting: {
        if (!svc.hasWindow || !screen) return false
        if (svc.dragScreen !== "") return svc.dragScreen === screen.name
        return svc.winMonitor === screen.name
    }
    // Active window rect in this overlay's local coordinates.
    readonly property var winLocal: hosting && svc.winRect
        ? { x: svc.winRect.x - originX, y: svc.winRect.y - originY, w: svc.winRect.w, h: svc.winRect.h }
        : null
    readonly property bool settingsHere: svc.settingsOpen && screen && svc.settingsMonitor === screen.name

    WlrLayershell.namespace: "mouse-first-controls"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    mask: Region {
        Region { item: overlay.hosting && overlay.svc.drag.pressed ? content : null }
        Region { item: overlay.settingsHere ? content : null }
        Region { item: dragZone.enabled ? dragZone : null }
        Region { item: bubble.visible ? bubble : null }
    }

    Item {
        id: content
        anchors.fill: parent

        SnapPreview {
            svc: overlay.svc
            originX: overlay.originX
            originY: overlay.originY
            screenW: overlay.width
            screenH: overlay.height
        }

        DragZone {
            id: dragZone
            svc: overlay.svc
            overlay: overlay
            win: overlay.winLocal
            rightInset: bubble.width + 12
        }

        ControlBubble {
            id: bubble
            svc: overlay.svc
            overlay: overlay
            win: overlay.winLocal
        }

        // Clicking anywhere outside the panel closes it.
        MouseArea {
            anchors.fill: parent
            visible: overlay.settingsHere
            acceptedButtons: Qt.AllButtons
            onPressed: overlay.svc.settingsOpen = false
        }

        SettingsPanel {
            svc: overlay.svc
            visible: overlay.settingsHere
            anchorItem: bubble.visible ? bubble : null
            maxHeight: overlay.height - overlay.reservedTop - 24
            topLimit: overlay.reservedTop + 8
        }
    }

    // Converts an item-local mouse position to global layout coordinates.
    function toGlobal(item, x, y) {
        var p = item.mapToItem(content, x, y)
        return { x: p.x + overlay.originX, y: p.y + overlay.originY }
    }
}
