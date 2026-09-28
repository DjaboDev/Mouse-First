import QtQuick
import Quickshell.Hyprland
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

    // address -> { mode: "snapped"|"maximized", zone, target, restore, monitor,
    //              workspace, since, confirmed }
    property var entries: ({})
    // address -> last geometry seen while the window was free and floating
    property var lastFree: ({})
    // address -> true once oversized-window protection has run
    property var fitted: ({})

    // Border resize of a snapped window in progress: its rect when the
    // resize started and the snapped neighbours that follow its edges.
    property var resizeSession: null

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
    }

    function apply(address, r) {
        root.tracker.dispatch(Hypr.geometry(address, r))
    }

    function _place(win, mode, zone, target, restore) {
        if (!win.floating) root.tracker.dispatch(Hypr.setFloating(win.address, true))
        root._set(win.address, {
            mode: mode, zone: zone, target: target, restore: restore,
            monitor: win.monitor, workspace: win.workspace,
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
                // A drag is handed to the drag controller, which restores the
                // window itself. A border resize drags the neighbours along.
                if (e.mode === "snapped" && e.confirmed && !G.sizesMatch(win, e.target))
                    root._resizeNeighbours(win, e)
            } else if (root.resizeSession && root.resizeSession.address === win.address) {
                root._finishResize(win)
            } else if (e.confirmed || Date.now() - e.since > root.settleMs) {
                // Moved or resized by something else (a border resize, a
                // keybind): the window is free again.
                root.clear(win.address)
            }
        } else if (win.floating && win.fullscreen === 0) {
            root.lastFree[win.address] = G.rect(win.x, win.y, win.w, win.h)
            root._fitOnce(win)
        }
    }

    // ── Resizing snapped neighbours together ─────────────────

    function _workspaceOf(address) {
        var ts = Hyprland.toplevels.values
        for (var i = 0; i < ts.length; i++)
            if (Hypr.normalizeAddress(ts[i].address) === address)
                return ts[i].workspace ? String(ts[i].workspace.name || "") : ""
        return ""
    }

    function _resizeNeighbours(win, e) {
        var session = root.resizeSession
        if (!session || session.address !== win.address) {
            var neighbours = []
            for (var a in root.entries) {
                var n = root.entries[a]
                if (a === win.address || n.mode !== "snapped" || n.monitor !== e.monitor) continue
                if (n.workspace !== e.workspace || root._workspaceOf(a) !== e.workspace) continue
                neighbours.push({ address: a, start: n.target })
            }
            session = { address: win.address, start: e.target, neighbours: neighbours, latest: {} }
            root.resizeSession = session
        }
        var now = G.rect(win.x, win.y, win.w, win.h)
        for (var i = 0; i < session.neighbours.length; i++) {
            var nb = session.neighbours[i]
            var r = G.followEdge(session.start, now, nb.start, root.gap)
            if (r) session.latest[nb.address] = r
        }
        if (!neighbourTimer.running) neighbourTimer.start()
    }

    // The resize ended: the window stays snapped at its new size, and so do
    // the neighbours that followed it.
    function _finishResize(win) {
        neighbourTimer.stop()
        root._flushNeighbours()
        var session = root.resizeSession
        root.resizeSession = null
        var next = Object.assign({}, root.entries)
        var own = next[win.address]
        if (own) next[win.address] = Object.assign({}, own, { target: G.rect(win.x, win.y, win.w, win.h), since: Date.now() })
        for (var a in session.latest)
            if (next[a]) next[a] = Object.assign({}, next[a], { target: session.latest[a], since: Date.now(), confirmed: true })
        root.entries = next
    }

    function _flushNeighbours() {
        var session = root.resizeSession
        if (!session) return
        for (var a in session.latest) root.apply(a, session.latest[a])
    }

    // Neighbour geometry is sent at most ~30 times a second.
    Timer {
        id: neighbourTimer
        interval: 33
        onTriggered: root._flushNeighbours()
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

    Connections {
        target: root.tracker
        function onWindowUpdated(win) { root.observe(win) }
        function onWindowClosed(address) { root.forget(address) }
        // The last geometry report may come before the release; look again.
        function onButtonReleased(x, y) { Qt.callLater(() => root.observe(root.tracker.active)) }
    }
}
