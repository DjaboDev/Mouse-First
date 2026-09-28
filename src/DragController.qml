import QtQuick
import "js/geometry.js" as G
import "js/hypr.js" as Hypr

// Moves the active window while the user drags the top-edge zone or the
// grip. All coordinates are global. The overlay keeps the pointer grab for
// the whole drag, so motion keeps arriving even across monitors.
//
//   press ─(moved ≥ threshold)→ active ─(release)→ snap or final move
//
// A maximized or snapped window is restored the moment the drag starts and
// placed so the point the user grabbed stays under the cursor.
//
// Native moves (SUPER + drag, app title bars) are handed over by the Lua
// module through takeOver(); the cursor then arrives as tracker reports
// instead of overlay mouse events, and everything else is shared.
Item {
    id: root
    visible: false

    required property var tracker
    required property var states
    property bool snappingEnabled: true
    property bool topMaximizes: false     // top edge maximizes instead of the top half

    readonly property bool pressed: _win !== null
    property bool active: false
    property bool handedOver: false
    property string address: ""
    // Where the window is being drawn right now (updated on every motion,
    // ahead of the compositor), and the snap target if one is armed.
    property var rect: null
    property string zone: ""
    property var zoneRect: null

    property var _win: null
    property var _press: null
    property var _start: null
    property var _restore: null
    property bool _dirty: false

    function press(gx, gy) {
        var win = root.tracker.active
        if (!win || root._win) return
        root._win = win
        root._press = { x: gx, y: gy }
    }

    // Continue a drag Hyprland started. The threshold has already been passed,
    // so the drag begins immediately.
    function takeOver(win, gx, gy) {
        if (root._win || !win) return
        root._win = win
        root._press = { x: gx, y: gy }
        root.handedOver = true
        root._begin(gx, gy)
    }

    function move(gx, gy) {
        if (!root._win) return
        if (!root.active) {
            if (Math.hypot(gx - root._press.x, gy - root._press.y) < G.DRAG_THRESHOLD) return
            root._begin(gx, gy)
        }

        var cursor = { x: gx, y: gy }
        var monitor = root.states.monitorAt(gx, gy)
        if (!monitor) return
        var area = root.states.areaFor(monitor)
        var raw = G.rect(root._start.x + gx - root._press.x, root._start.y + gy - root._press.y,
                         root._start.w, root._start.h)

        root.rect = G.dragTarget(raw, area, monitor, cursor)
        var z = root.snappingEnabled ? G.snapZone(raw, area, monitor, cursor) : ""
        if (z === "top" && root.topMaximizes) z = "maximize"
        root.zoneRect = z ? G.zoneRect(z, area, root.states.gap) : null
        root.zone = z
        root._dirty = true
        if (!flushTimer.running) flushTimer.start()
    }

    function release() {
        if (root.active) root._finish()
        root._reset()
    }

    function cancel() {
        root.release()
    }

    function _begin(gx, gy) {
        var win = root._win
        var a = win.address
        root.address = a
        root.active = true
        root.states.dragging = true
        restoreAnimTimer.stop()

        // Remember what a later "restore" should return to before touching
        // anything: the pre-snap geometry, or the window as it is now.
        root._restore = root.states.restoreGeometryFor(win)

        var cmds = [Hypr.setNoAnim(a, true), Hypr.bringToTop(a)]
        if (win.fullscreen === 1) cmds.push(Hypr.setMaximizedState(a, false))
        if (!win.floating) cmds.push(Hypr.setFloating(a, true))
        root.tracker.dispatch(cmds)

        if (root.states.isManaged(win)) {
            var cursor = { x: gx, y: gy }
            var area = root.states.areaFor(root.states.monitorAt(gx, gy))
            var size = G.restoreSize(root._restore, area)
            root._start = G.restoreUnderCursor(size, cursor,
                (root._press.x - win.x) / Math.max(1, win.w), root._press.y - win.y, area)
            root.states.clear(a)
            root.tracker.dispatch(Hypr.geometry(a, root._start))
        } else {
            root._start = G.rect(win.x, win.y, win.w, win.h)
        }
        root._press = { x: gx, y: gy }
        root.rect = root._start
    }

    function _flush() {
        if (!root._dirty || !root.rect) return
        root._dirty = false
        root.tracker.dispatch(Hypr.move(root.address, root.rect.x, root.rect.y))
    }

    function _finish() {
        flushTimer.stop()
        var win = Object.assign({}, root._win, { floating: true, fullscreen: 0 })
        if (root.zone !== "" && root.zoneRect) {
            root.states.snapTo(win, root.zone, root.zoneRect, root._restore)
            root.rect = root.zoneRect
        } else if (root.rect) {
            root.tracker.dispatch(Hypr.move(root.address, root.rect.x, root.rect.y))
        }
        restoreAnimTimer.pendingAddress = root.address
        restoreAnimTimer.restart()
    }

    function _reset() {
        root.states.dragging = false
        root.active = false
        root.handedOver = false
        root._win = null
        root._press = null
        root._start = null
        root.zone = ""
        root.zoneRect = null
        root.rect = null
        root.address = ""
    }

    // Coalesces motion into at most one move dispatch per frame.
    Timer {
        id: flushTimer
        interval: 16
        repeat: true
        onTriggered: {
            if (!root.active) { stop(); return }
            root._flush()
        }
    }

    // Animations come back once the final geometry has been applied.
    Timer {
        id: restoreAnimTimer
        property string pendingAddress: ""
        interval: 200
        onTriggered: root.tracker.dispatch(Hypr.setNoAnim(pendingAddress, false))
    }
}
