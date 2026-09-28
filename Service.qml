import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import "src"
import "src/ui"
import "src/js/geometry.js" as G
import "src/js/hypr.js" as Hypr
import "src/js/i18n.js" as I18n

// The Mouse-First service: created once by the Omarchy shell.
//
// Omarchy builds one bar (and one bar widget) per monitor, so everything
// stateful lives here and the bar widget only renders `appsModule.rows`. This
// object owns the Hyprland connection, the window state machine, the drag,
// minimize/restore, the settings, and one overlay per screen.
Item {
    id: root
    width: 0
    height: 0
    visible: false

    // Injected by the shell.
    property var shell: null
    property var manifest: null

    readonly property string pluginId: "io.github.mousefirst.controls"
    readonly property var cfg: config.data

    function tr(key) { return I18n.tr(root.cfg.language, key) }

    // ── Theme ────────────────────────────────────────────────
    readonly property bool themed: root.cfg.colorMode !== "custom"
    readonly property color bg: themed ? Qt.darker(Color.background, 1.4) : root.cfg.customBg
    readonly property color fg: themed ? Color.foreground : root.cfg.customFg
    readonly property color accent: themed ? Color.accent : root.cfg.customAccent
    readonly property color red: themed ? Color.urgent : root.cfg.customRed
    readonly property color muted: Color.muted
    readonly property string fontFamily: Style.font.family

    // ── Bar ──────────────────────────────────────────────────
    readonly property var barConfig: root.shell && root.shell.barConfig ? root.shell.barConfig : ({})
    readonly property string barPosition: String(root.barConfig.position || "top")
    readonly property string barSection: {
        var layout = root.barConfig.layout || {}
        var sections = ["left", "center", "right"]
        for (var i = 0; i < sections.length; i++) {
            var list = layout[sections[i]] || []
            for (var j = 0; j < list.length; j++)
                if (list[j] && list[j].id === root.pluginId) return sections[i]
        }
        return root.cfg.barSection
    }

    function setBarSection(section) {
        if (["left", "center", "right"].indexOf(section) < 0 || section === root.barSection) return
        config.set("barSection", section)
        Quickshell.execDetached(["omarchy-shell", "shell", "moveBarWidget", root.pluginId,
                                 JSON.stringify({ section: section })])
    }

    // ── Dock detection ───────────────────────────────────────
    property bool dockPresent: false
    readonly property bool showAppsInBar: root.cfg.minimizeToBar || !root.dockPresent

    // ── Active window ────────────────────────────────────────
    readonly property var win: trackerModule.active
    readonly property bool hasWindow: !!root.win && root.win.fullscreen !== 2
        && root.win.workspace !== minimizerModule.workspaceName
    // Whether the capsule and drag strip are drawn for the active window: not
    // for windows narrower than the capsule's useful size, picture-in-picture
    // players, or classes the user excluded.
    readonly property bool controlsVisible: {
        if (!root.hasWindow) return false
        var w = root.win
        if (w.w < root.cfg.minControlsWidth || w.h < 120) return false
        if (/picture.in.picture/i.test(w.title)) return false
        var cls = String(w.cls || "").toLowerCase()
        var excluded = root.cfg.excludedClasses || []
        for (var i = 0; i < excluded.length; i++)
            if (String(excluded[i]).toLowerCase() === cls) return false
        return true
    }
    readonly property bool winMaximized: root.hasWindow && statesModule.isMaximized(root.win)
    // Rect the controls follow: the drag's prediction while dragging, so they
    // never trail the pointer, otherwise the compositor's report.
    readonly property var winRect: {
        if (!root.hasWindow) return null
        if (dragModule.active && dragModule.rect && dragModule.address === root.win.address) return dragModule.rect
        return G.rect(root.win.x, root.win.y, root.win.w, root.win.h)
    }
    readonly property string winMonitor: {
        if (!root.hasWindow) return ""
        if (dragModule.active && dragModule.rect) {
            var m = G.monitorAt(trackerModule.monitors, dragModule.rect.x + dragModule.rect.w / 2, dragModule.rect.y + 8)
            if (m) return m.name
        }
        return root.win.monitor
    }

    // ── Window drag (from the top-edge zone or the grip) ─────
    // The screen whose overlay holds the pointer grab for the current drag.
    property string dragScreen: ""

    function pressWindow(screenName, point) {
        if (!root.hasWindow) return
        root.dragScreen = screenName
        dragModule.press(point.x, point.y)
    }
    function moveWindow(point) { dragModule.move(point.x, point.y) }
    function releaseWindow() {
        dragModule.release()
        root.dragScreen = ""
    }

    // ── Settings panel ───────────────────────────────────────
    property bool settingsOpen: false
    property string settingsMonitor: ""
    function toggleSettings() {
        root.settingsMonitor = root.winMonitor || (trackerModule.monitors[0] ? trackerModule.monitors[0].name : "")
        root.settingsOpen = !root.settingsOpen
    }

    // ── Control bar offset (the draggable position of the buttons) ──
    property var sessionOffsets: ({})
    property bool menuDragging: false
    property var liveMenuOffset: null
    readonly property var menuOffset: {
        if (root.liveMenuOffset) return root.liveMenuOffset
        if (!root.cfg.enableMenuDrag || !root.hasWindow) return { x: 0, y: 0 }
        if (root.cfg.rememberMenuGlobal) return { x: root.cfg.globalMenuOffsetX, y: root.cfg.globalMenuOffsetY }
        if (root.cfg.rememberMenuPerWindow) {
            var o = root.cfg.perWindowClassOffsets[root.win.cls]
            return o ? { x: o.x || 0, y: o.y || 0 } : { x: 0, y: 0 }
        }
        return root.sessionOffsets[root.win.address] || { x: 0, y: 0 }
    }

    function setMenuOffset(offset) {
        root.liveMenuOffset = { x: Math.round(offset.x), y: Math.round(offset.y) }
    }

    function commitMenuOffset() {
        var o = root.liveMenuOffset
        root.liveMenuOffset = null
        if (!o || !root.hasWindow) return
        root._storeMenuOffset(o)
    }

    function resetMenuOffset() {
        if (!root.hasWindow) return
        root._storeMenuOffset(null)
    }

    function _storeMenuOffset(o) {
        if (root.cfg.rememberMenuGlobal) {
            config.set("globalMenuOffsetX", o ? o.x : 0)
            config.set("globalMenuOffsetY", o ? o.y : 0)
        } else if (root.cfg.rememberMenuPerWindow) {
            if (!root.win.cls) return
            var map = Object.assign({}, root.cfg.perWindowClassOffsets)
            if (o) map[root.win.cls] = o
            else delete map[root.win.cls]
            config.set("perWindowClassOffsets", map)
        } else {
            var s = Object.assign({}, root.sessionOffsets)
            if (o) s[root.win.address] = o
            else delete s[root.win.address]
            root.sessionOffsets = s
        }
    }

    // ── Actions ──────────────────────────────────────────────

    function trigger(id) {
        if (!root.hasWindow) return
        var w = root.win
        if (id === "float") trackerModule.dispatch(Hypr.toggleFloating(w.address))
        else if (id === "minimize") root.minimize(w.address)
        else if (id === "maximize") statesModule.toggleMaximize(w)
        else if (id === "close") trackerModule.dispatch(Hypr.close(w.address))
    }

    function minimize(address) {
        var origin = ""
        if (root.win && root.win.address === Hypr.normalizeAddress(address)) origin = root.win.workspace
        else origin = root.workspaceOf(address)
        minimizerModule.minimize(address, origin)
    }

    function workspaceOf(address) {
        var a = Hypr.normalizeAddress(address)
        var ts = Hyprland.toplevels.values
        for (var i = 0; i < ts.length; i++)
            if (Hypr.normalizeAddress(ts[i].address) === a)
                return ts[i].workspace ? String(ts[i].workspace.name || "") : ""
        return ""
    }

    function restore(address) { minimizerModule.restore(address) }

    function focus(address) {
        trackerModule.dispatch([Hypr.focus(address), Hypr.bringToTop(address)])
    }

    function close(address) { trackerModule.dispatch(Hypr.close(address)) }

    function launch(appId) { appsModule.launch(appId) }

    // Bar tile click, like a taskbar: launch when nothing is open; with one
    // window, toggle it (minimize when focused, bring back otherwise); with
    // several, cycle through them, starting from the most recently used.
    function activateRow(row) {
        var wins = row.windows || []
        if (wins.length === 0) { root.launch(row.appId); return }
        var active = -1
        for (var i = 0; i < wins.length; i++) if (wins[i].state === "active") active = i
        var target
        if (active >= 0) {
            if (wins.length === 1) { root.minimize(wins[0].address); return }
            target = wins[(active + 1) % wins.length]
        } else {
            target = wins.slice().sort((a, b) => {
                var ra = a.state === "minimized" ? 1 : 0, rb = b.state === "minimized" ? 1 : 0
                return ra !== rb ? ra - rb : a.focus - b.focus
            })[0]
        }
        root.activateWindow(target)
    }

    function activateWindow(w) {
        if (w.state === "minimized") root.restore(w.address)
        else root.focus(w.address)
    }

    function closeRow(row) {
        var wins = row.windows || []
        for (var i = 0; i < wins.length; i++) root.close(wins[i].address)
    }

    function setPinned(appId, pinned) { appsModule.setPinned(appId, pinned) }

    function moveButton(index, delta) {
        var order = root.cfg.buttonOrder.slice()
        var to = index + delta
        if (to < 0 || to >= order.length) return
        var tmp = order[index]; order[index] = order[to]; order[to] = tmp
        config.set("buttonOrder", order)
    }

    function setExcluded(cls, excluded) {
        if (!cls) return
        var list = (root.cfg.excludedClasses || []).filter(c => c !== cls)
        if (excluded) list.push(cls)
        config.set("excludedClasses", list)
        if (excluded) root.settingsOpen = false   // its capsule is about to disappear
    }

    function setButtonVisible(id, visible) {
        var v = Object.assign({}, root.cfg.buttonVisible)
        v[id] = visible
        config.set("buttonVisible", v)
    }

    // Settings that live inside Hyprland (window rule, shortcuts) are pushed
    // on load, on change, and again after a Hyprland config reload.
    function applyCompositorSettings() {
        if (!config.ready) return
        trackerModule.evalLua(Hypr.evalFloatRule(root.cfg.disableTiling, root.cfg.centerNewWindows))
        trackerModule.evalLua(Hypr.evalShortcuts(root.cfg.enableShortcuts))
    }

    function runShortcut(action) {
        if (!root.hasWindow) return
        var w = root.win
        if (action === "left" || action === "right") statesModule.snap(w, action, statesModule.restoreGeometryFor(w))
        else if (action === "up") statesModule.toggleMaximize(w)
        else if (action === "down") {
            if (statesModule.isManaged(w)) statesModule.restore(w)
            else root.minimize(w.address)
        }
    }

    // ── Modules ──────────────────────────────────────────────

    Config { id: config; onReadyChanged: root.applyCompositorSettings() }

    WindowTracker {
        id: trackerModule
        onConfigReloaded: root.applyCompositorSettings()
    }

    WindowStates {
        id: statesModule
        tracker: trackerModule
        gap: Math.max(0, Style.gapsOut)
        ignoreDock: root.cfg.ignoreDock
        dockPresent: root.dockPresent
        barPosition: root.barPosition
        barThickness: Style.bar.sizeHorizontal
    }

    DragController {
        id: dragModule
        tracker: trackerModule
        states: statesModule
        snappingEnabled: !root.cfg.disableSnapping
        topMaximizes: root.cfg.topEdgeMaximizes
    }

    Minimizer { id: minimizerModule; tracker: trackerModule }

    AppsModel {
        id: appsModule
        minimizedWorkspace: minimizerModule.workspaceName
        onMinimizedChanged: addresses => minimizerModule.prune(addresses)
    }

    readonly property alias cfgFile: config
    readonly property alias tracker: trackerModule
    readonly property alias states: statesModule
    readonly property alias drag: dragModule
    readonly property alias apps: appsModule

    Connections {
        target: root.cfg
        function onDisableTilingChanged() { root.applyCompositorSettings() }
        function onCenterNewWindowsChanged() { root.applyCompositorSettings() }
        function onEnableShortcutsChanged() { root.applyCompositorSettings() }
    }

    // Native moves handed over by the Lua module (see DragController).
    Connections {
        target: trackerModule
        function onNativeDragStarted(address, x, y, rect) {
            if (dragModule.pressed) return   // our own drag is moving it
            var w = trackerModule.active
            var win = w && w.address === address
                ? Object.assign({}, w, rect)
                : Object.assign({ address: address, floating: true, fullscreen: 0, monitor: "", workspace: "" }, rect)
            dragModule.takeOver(win, x, y)
        }
        function onShortcut(action) { root.runShortcut(action) }
        function onCursorMoved(x, y) {
            if (dragModule.handedOver) dragModule.move(x, y)
        }
        function onButtonReleased(x, y) {
            if (!dragModule.handedOver) return
            dragModule.move(x, y)
            dragModule.release()
        }
    }

    Connections {
        target: trackerModule
        function onWindowClosed(address) {
            if (root.sessionOffsets[address]) {
                var s = Object.assign({}, root.sessionOffsets)
                delete s[address]
                root.sessionOffsets = s
            }
        }
    }

    // Dock detection: one layer query at start, then re-checked whenever a
    // layer surface opens or closes.
    Process {
        id: layersProc
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var found = false
                    var outputs = JSON.parse(text)
                    for (var o in outputs)
                        for (var lvl in outputs[o].levels)
                            for (var i = 0; i < outputs[o].levels[lvl].length; i++)
                                if (/dock|plank|wbar/i.test(outputs[o].levels[lvl][i].namespace || "")) found = true
                    root.dockPresent = found
                } catch (e) {}
            }
        }
    }
    Timer {
        id: layersDebounce
        interval: 300
        onTriggered: if (!layersProc.running) layersProc.running = true
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "openlayer" || event.name === "closelayer") layersDebounce.restart()
        }
    }

    // One overlay per screen, recreated automatically on hotplug.
    Variants {
        model: Quickshell.screens
        delegate: Overlay {
            required property var modelData
            screen: modelData
            service: root
        }
    }

    // `qs -p /usr/share/omarchy/shell ipc call mousefirst <function>`
    // e.g. o.bind("SUPER + ALT + LEFT", "Snap left", "qs -p /usr/share/omarchy/shell ipc call mousefirst snap left")
    IpcHandler {
        target: "mousefirst"

        function snap(zone: string): void {
            if (root.hasWindow) statesModule.snap(root.win, zone, statesModule.restoreGeometryFor(root.win))
        }
        function toggleMaximize(): void { if (root.hasWindow) statesModule.toggleMaximize(root.win) }
        function restore(): void { if (root.hasWindow) statesModule.restore(root.win) }
        function minimize(): void { if (root.hasWindow) root.minimize(root.win.address) }
        function restoreLast(): void {
            var rows = appsModule.rows
            for (var i = rows.length - 1; i >= 0; i--)
                if (rows[i].state === "minimized") { root.restore(rows[i].address); return }
        }
        function settings(): void { root.toggleSettings() }
        // Diagnostics for bug reports.
        function status(): string {
            return JSON.stringify({
                version: root.manifest ? root.manifest.version : "",
                active: trackerModule.active,
                monitors: trackerModule.monitors,
                buttonKnown: trackerModule.buttonKnown,
                dockPresent: root.dockPresent,
                states: statesModule.entries
            })
        }
    }

    Component.onCompleted: {
        trackerModule.install()
        root.applyCompositorSettings()
        layersProc.running = true
    }
}
