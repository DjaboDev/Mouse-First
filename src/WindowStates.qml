import QtQuick
import "js/geometry.js" as G
import "js/hypr.js" as Hypr

// Per-window placement state: free, snapped to a zone, or maximized, plus the
// geometry to restore to. This replaces v0.1's pile of size caches and
// browser-specific magic numbers with one explicit model.
//
// Maximize is done with geometry (float + usable area), like snapping, so a
// maximized window and a snapped one behave the same when dragged away.
// Windows maximized by Hyprland itself (fullscreen state 1, e.g. via a
// keybind) are recognised and handed back to Hyprland to un-maximize.
Item {
    id: root
    visible: false

    required property var tracker
    property bool dragging: false          // set by DragController
    property int gap: 6
    property bool ignoreDock: false
    property bool dockPresent: false
    property string barPosition: "top"
    property int barThickness: 26

    // address -> { mode: "snapped"|"maximized", zone, target, restore, since, confirmed }
    property var entries: ({})
    // address -> last geometry seen while the window was free and floating
    property var lastFree: ({})
    // address -> true once oversized-window protection has run
    property var fitted: ({})
    // Native (SUPER + drag) move of a snapped window waiting for the drop.
    property var pendingDrop: null

    readonly property int settleMs: 700

    // ── Queries ──────────────────────────────────────────────

    function entry(address) {
        return root.entries[address] || null
    }

    function isMaximized(win) {
        if (!win) return false
        var e = root.entry(win.address)
        return win.fullscreen === 1 || !!(e && e.mode === "maximized")
    }

    function isManaged(win) {
        return !!win && (win.fullscreen === 1 || !!root.entry(win.address))
    }

    // Monitor object for a window (by name) or for a point.
    function monitorOf(win) {
        return (win && root.tracker.monitorByName(win.monitor)) || root.tracker.monitors[0] || null
    }

    function monitorAt(x, y) {
        return G.monitorAt(root.tracker.monitors, x, y)
    }

    function areaFor(monitor, gapOverride) {
        if (!monitor) return G.rect(0, 0, 1920, 1080)
        var r = monitor.reserved
        if (root.ignoreDock && root.dockPresent) {
            // Keep the bar's own reservation, drop the dock's.
            r = {
                left: r.left, top: r.top, right: r.right,
                bottom: root.barPosition === "bottom" ? root.barThickness : 0
            }
        }
        return G.usableArea(monitor, r, gapOverride === undefined ? root.gap : gapOverride)
    }

    // What "restore" should return this window to.
    function restoreGeometryFor(win) {
        var e = root.entry(win.address)
        if (e && e.restore) return e.restore
        if (win.floating && win.fullscreen === 0) return G.rect(win.x, win.y, win.w, win.h)
        return root.lastFree[win.address] || null
    }

    // ── Mutations ────────────────────────────────────────────

    function _set(address, value) {
        var next = Object.assign({}, root.entries)
        if (value) next[address] = value
        else delete next[address]
        root.entries = next
    }

    function clear(address) {
        if (root.entries[address]) root._set(address, null)
    }

    function forget(address) {
        root.clear(address)
        delete root.lastFree[address]
        delete root.fitted[address]
        if (root.pendingDrop && root.pendingDrop.address === address) root.pendingDrop = null
    }

    function apply(address, r) {
        root.tracker.dispatch(Hypr.geometry(address, r))
    }

    function _place(win, mode, zone, target, restore) {
        if (!win.floating) root.tracker.dispatch(Hypr.setFloating(win.address, true))
        root._set(win.address, {
            mode: mode, zone: zone, target: target, restore: restore,
            since: Date.now(), confirmed: false
        })
        root.apply(win.address, target)
    }

    function snap(win, zone, restore) {
        var area = root.areaFor(root.monitorOf(win))
        var target = G.zoneRect(zone, area, root.gap)
        if (!target) return
        root._place(win, zone === "maximize" ? "maximized" : "snapped", zone, target, restore)
    }

    // Snap into a zone of the monitor the cursor is on (used by the drag).
    function snapTo(win, zone, target, restore) {
        root._place(win, zone === "maximize" ? "maximized" : "snapped", zone, target, restore)
    }

    function maximize(win) {
        if (!win || win.fullscreen === 1) return
        root.snap(win, "maximize", root.restoreGeometryFor(win))
    }

    function restore(win) {
        if (!win) return
        if (win.fullscreen === 1) {
            root.tracker.dispatch(Hypr.setMaximizedState(win.address, false))
            root.clear(win.address)
            return
        }
        var e = root.entry(win.address)
        if (!e) return
        var area = root.areaFor(root.monitorOf(win))
        var size = G.restoreSize(e.restore, area)
        var r = e.restore && e.restore.w > 0
            ? G.clampInto(G.rect(e.restore.x, e.restore.y, size.w, size.h), area)
            : G.centered(size, area)
        root.clear(win.address)
        root.apply(win.address, r)
    }

    function toggleMaximize(win) {
        if (root.isMaximized(win)) root.restore(win)
        else root.maximize(win)
    }

    // ── Observation ──────────────────────────────────────────
    // Called for every geometry report of the active window.

    function observe(win) {
        if (!win || root.dragging) return
        var e = root.entry(win.address)

        if (e) {
            if (G.rectsMatch(win, e.target)) {
                if (!e.confirmed) e.confirmed = true
            } else if (root.tracker.buttonDown) {
                // A drag may be starting; the drag controller takes it over
                // and restores the window itself. Decide once it is released.
            } else if (e.confirmed || Date.now() - e.since > root.settleMs) {
                if (G.sizesMatch(win, e.target) && win.fullscreen === 0) root._beginNativeDrop(win, e)
                else root.clear(win.address)   // resized by the user: now free
            }
        } else if (win.floating && win.fullscreen === 0) {
            root.lastFree[win.address] = G.rect(win.x, win.y, win.w, win.h)
            root._fitOnce(win)
        }

        if (root.pendingDrop && root.pendingDrop.address === win.address && !root.tracker.buttonDown)
            dropTimer.restart()
    }

    // Windows that open larger than the usable area or under the bar are
    // pulled into view once.
    function _fitOnce(win) {
        if (root.fitted[win.address]) return
        root.fitted[win.address] = true
        // Measured without gaps: a window flush against the bar is fine.
        var r = G.fitInside(win, root.areaFor(root.monitorOf(win), 0))
        if (r) root.apply(win.address, r)
    }

    // A snapped or maximized window is being moved by Hyprland itself
    // (SUPER + drag). Resizing it mid-drag would detach it from the cursor,
    // because Hyprland keeps the grab offset it started with; wait for the
    // drop, then restore the size around the cursor.
    function _beginNativeDrop(win, e) {
        root.clear(win.address)
        root.pendingDrop = { address: win.address, restore: e.restore }
        if (!root.tracker.buttonDown) dropTimer.restart()
    }

    function _finishNativeDrop(cursor) {
        var p = root.pendingDrop
        root.pendingDrop = null
        var win = root.tracker.active
        if (!p || !win || win.address !== p.address) return
        var monitor = cursor ? root.monitorAt(cursor.x, cursor.y) : root.monitorOf(win)
        var area = root.areaFor(monitor)
        var size = G.restoreSize(p.restore, area)
        var r
        if (cursor && G.contains(win, cursor.x, cursor.y)) {
            r = G.restoreUnderCursor(size, cursor, (cursor.x - win.x) / win.w, cursor.y - win.y, area)
        } else {
            var cx = win.x + win.w / 2
            r = G.clampInto(G.rect(cx - size.w / 2, win.y, size.w, size.h), area)
        }
        root.apply(win.address, r)
    }

    // Fallback when the compositor cannot report the button: the move is
    // over once the window stops moving for a moment.
    Timer {
        id: dropTimer
        interval: 250
        onTriggered: if (!root.tracker.buttonDown) root._finishNativeDrop(null)
    }

    Connections {
        target: root.tracker
        function onWindowUpdated(win) { root.observe(win) }
        function onWindowClosed(address) { root.forget(address) }
        function onButtonReleased(x, y) {
            if (root.pendingDrop) {
                dropTimer.stop()
                root._finishNativeDrop({ x: x, y: y })
            }
        }
    }
}
