import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "js/hypr.js" as Hypr

// Live view of the active window and the monitor layout.
//
// src/lua/mousefirst.lua runs inside Hyprland and reports changes as custom
// IPC events, so this object never polls. It also owns the channel for
// commands: plain dispatches go through Quickshell's Hyprland socket, and
// calls into the Lua module go through a small `hyprctl eval` queue.
Item {
    id: root
    visible: false

    // Active window, or null. { address, x, y, w, h, floating, fullscreen,
    // pinned, monitor, workspace, cls, title }
    property var active: null
    // [{ name, x, y, w, h, reserved: { left, top, right, bottom } }]
    property var monitors: []
    // Left button state as reported by the compositor; `buttonKnown` stays
    // false if this Hyprland build cannot report it.
    property bool buttonDown: false
    property bool buttonKnown: false
    property bool installed: false

    signal windowUpdated(var win)
    signal windowClosed(string address)
    signal windowOpened(string address)
    signal buttonReleased(real x, real y)
    signal configReloaded()

    readonly property string moduleSource: luaFile.text()

    function dispatch(commands) {
        var list = Array.isArray(commands) ? commands : [commands]
        for (var i = 0; i < list.length; i++)
            if (list[i]) Hyprland.dispatch(list[i])
    }

    property var _evalQueue: []
    function evalLua(code) {
        if (!code) return
        root._evalQueue = root._evalQueue.concat([code])
        root._pumpEval()
    }
    function _pumpEval() {
        if (evalProc.running || root._evalQueue.length === 0) return
        var code = root._evalQueue[0]
        root._evalQueue = root._evalQueue.slice(1)
        // A leading newline keeps hyprctl from reading a `--` comment as a flag.
        evalProc.command = ["hyprctl", "eval", "\n" + code]
        evalProc.running = true
    }

    // Identifies this shell instance's copy of the module, so a plugin reload
    // that tears down the old service cannot stop the new one's timer.
    readonly property string generation: Date.now().toString(36) + Math.floor(Math.random() * 1e6).toString(36)

    function install() {
        if (root.moduleSource === "") return
        root.evalLua('MOUSE_FIRST_GENERATION = "' + root.generation + '"\n' + root.moduleSource)
        root.installed = true
        resendTimer.restart()
    }

    // Events emitted while the shell is still connecting to Hyprland's event
    // socket are lost; ask the module to report its current state again.
    Timer {
        id: resendTimer
        interval: 600
        onTriggered: root.evalLua("if MOUSE_FIRST then MOUSE_FIRST.resend() end")
    }

    function uninstall() {
        // The object is going away; the process has to outlive it.
        Quickshell.execDetached(["hyprctl", "eval",
            'if MOUSE_FIRST then MOUSE_FIRST.stop("' + root.generation + '") end'])
    }

    function monitorByName(name) {
        for (var i = 0; i < root.monitors.length; i++)
            if (root.monitors[i].name === name) return root.monitors[i]
        return null
    }

    function _parseWindow(payload) {
        if (payload === "none") return null
        var f = payload.split("\u001f")
        if (f.length < 12) return null
        return {
            address: Hypr.normalizeAddress(f[0]),
            x: Number(f[1]), y: Number(f[2]), w: Number(f[3]), h: Number(f[4]),
            floating: f[5] === "1",
            fullscreen: Number(f[6]),
            pinned: f[7] === "1",
            monitor: f[8],
            workspace: f[9],
            cls: f[10],
            title: f.slice(11).join(" ")
        }
    }

    function _parseMonitors(payload) {
        var out = []
        var parts = payload.split(";")
        for (var i = 0; i < parts.length; i++) {
            var f = parts[i].split(",")
            if (f.length < 9) continue
            out.push({
                name: f[0],
                x: Number(f[1]), y: Number(f[2]), w: Number(f[3]), h: Number(f[4]),
                reserved: { left: Number(f[5]), top: Number(f[6]), right: Number(f[7]), bottom: Number(f[8]) }
            })
        }
        return out
    }

    function _handleCustom(data) {
        var prefix = "mousefirst>>"
        if (data.indexOf(prefix) !== 0) return
        var rest = data.slice(prefix.length)
        var sep = rest.indexOf(">>")
        if (sep < 0) return
        var kind = rest.slice(0, sep)
        var payload = rest.slice(sep + 2)

        if (kind === "window") {
            root.active = root._parseWindow(payload)
            root.windowUpdated(root.active)
        } else if (kind === "monitors") {
            root.monitors = root._parseMonitors(payload)
        } else if (kind === "button") {
            var b = payload.split(",")
            var down = b[0] === "1"
            if (down) root.buttonKnown = true
            var wasDown = root.buttonDown
            root.buttonDown = down
            if (wasDown && !down) root.buttonReleased(Number(b[1]), Number(b[2]))
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var name = event.name
            if (name === "custom") {
                root._handleCustom(String(event.data || ""))
            } else if (name === "closewindow") {
                root.windowClosed(Hypr.normalizeAddress(event.data))
            } else if (name === "openwindow") {
                root.windowOpened(Hypr.normalizeAddress(String(event.data || "").split(",")[0]))
            } else if (name === "configreloaded") {
                // A config reload rebuilds Hyprland's Lua state, dropping the
                // module, its timer and the float rule.
                root.install()
                root.configReloaded()
            }
        }
    }

    FileView {
        id: luaFile
        path: decodeURIComponent(Qt.resolvedUrl("lua/mousefirst.lua").toString().replace(/^file:\/\//, ""))
        blockLoading: true
        printErrors: true
    }

    Process {
        id: evalProc
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") console.warn("mouse-first: hyprctl eval:", text.trim()) }
        stdout: StdioCollector {
            onStreamFinished: {
                var out = text.trim()
                if (out !== "" && out !== "ok") console.warn("mouse-first: hyprctl eval:", out)
            }
        }
        onExited: root._pumpEval()
    }

    Component.onDestruction: uninstall()
}
