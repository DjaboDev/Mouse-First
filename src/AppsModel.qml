import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "js/hypr.js" as Hypr

// Apps shown on the system bar: pinned apps from omadock's dock.json first,
// then every other running app. Windows of the same app share one tile.
// Built from Quickshell's live toplevel list and desktop entries, and
// rebuilt only when Hyprland reports a change.
//
// rows: [{ key, appId, pinId, name, icon, state, title, address, pinned,
//          windows: [{ address, title, state, focus }] }]
//   state: "active" | "running" | "minimized" | "closed"
Item {
    id: root
    visible: false

    required property string minimizedWorkspace
    property var rows: []
    property var pinned: []
    property var iconIndex: ({})
    property var _pendingIcons: ({})

    signal minimizedChanged(var addresses)

    function appIdOf(toplevel) {
        var appId = toplevel.wayland ? String(toplevel.wayland.appId || "") : ""
        if (appId === "" && toplevel.lastIpcObject)
            appId = String(toplevel.lastIpcObject["class"] || toplevel.lastIpcObject["initialClass"] || "")
        return appId
    }

    function entryFor(appId) {
        if (!appId) return null
        return DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId)
    }

    function iconSource(icon) {
        var value = String(icon || "")
        if (value === "") return ""
        if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
        if (value.charAt(0) === "/") return "file://" + value
        var found = root.iconIndex[value] || root.iconIndex[value.toLowerCase()]
        if (found) return "file://" + found
        var themed = ""
        try { themed = Quickshell.iconPath(value, true) } catch (e) {}
        return themed || ""
    }

    function _groupKey(appId, entry) {
        return entry && entry.id ? String(entry.id).toLowerCase() : String(appId || "").toLowerCase()
    }

    readonly property var _rank: ({ active: 0, running: 1, minimized: 2, closed: 3 })

    function rebuild() {
        var toplevels = Hyprland.toplevels.values
        var groups = {}
        var order = []
        var minimized = []
        for (var i = 0; i < toplevels.length; i++) {
            var t = toplevels[i]
            var address = Hypr.normalizeAddress(t.address)
            if (!address) continue
            var appId = root.appIdOf(t)
            var ws = t.workspace ? String(t.workspace.name || "") : ""
            var isMin = ws === root.minimizedWorkspace
            if (isMin) minimized.push(address)
            var entry = root.entryFor(appId)
            var key = root._groupKey(appId, entry)
            if (!groups[key]) {
                groups[key] = { appId: appId, entry: entry, windows: [] }
                order.push(key)
            }
            var ipc = t.lastIpcObject || {}
            groups[key].windows.push({
                address: address,
                title: String(t.title || ""),
                state: isMin ? "minimized" : (t.activated ? "active" : "running"),
                focus: ipc.focusHistoryID !== undefined ? Number(ipc.focusHistoryID) : 999
            })
        }

        var out = []
        var used = {}
        for (var p = 0; p < root.pinned.length; p++) {
            var pin = String(root.pinned[p] || "")
            if (pin === "") continue
            var pinEntry = root.entryFor(pin)
            var pinKey = root._groupKey(pin, pinEntry)
            var g = groups[pinKey] || groups[pin.toLowerCase()]
            if (g) used[root._groupKey(g.appId, g.entry)] = true
            out.push(root._row(g, pinEntry || (g ? g.entry : null), pin, pin))
        }
        for (var k = 0; k < order.length; k++) {
            if (used[order[k]]) continue
            var group = groups[order[k]]
            out.push(root._row(group, group.entry, group.appId, ""))
        }
        root.rows = out
        root.minimizedChanged(minimized)
    }

    function _row(group, entry, appId, pinId) {
        var windows = group ? group.windows : []
        var best = null
        for (var i = 0; i < windows.length; i++)
            if (!best || root._rank[windows[i].state] < root._rank[best.state]
                    || (windows[i].state === best.state && windows[i].focus < best.focus))
                best = windows[i]
        var name = entry && entry.name ? String(entry.name) : (appId || "App")
        var icon = root.iconSource(entry ? entry.icon : appId) || root.iconSource(appId)
        if (!icon && !root._rescanned) root._requestRescan()
        return {
            key: pinId !== "" ? "pin:" + pinId : "app:" + root._groupKey(appId, entry),
            appId: entry && entry.id ? String(entry.id) : appId,
            pinId: pinId,
            name: name,
            icon: icon,
            title: best ? best.title : "",
            state: best ? best.state : "closed",
            address: best ? best.address : "",
            pinned: pinId !== "",
            windows: windows
        }
    }

    // ── Pinning (shared with omadock through dock.json) ──────

    function setPinned(appId, pinned) {
        if (!appId) return
        var data = {}
        try { data = JSON.parse(dockFile.text() || "{}") } catch (e) { data = {} }
        var list = Array.isArray(data.pinned) ? data.pinned.slice() : []
        var lower = String(appId).toLowerCase()
        list = list.filter(p => String(p).toLowerCase() !== lower)
        if (pinned) list.push(appId)
        data.pinned = list
        root.pinned = list
        dockFile.setText(JSON.stringify(data, null, 2) + "\n")
        root.scheduleRebuild()
    }

    function launch(appId) {
        var entry = root.entryFor(appId)
        if (entry) entry.execute()
        else if (appId) Quickshell.execDetached(["gtk-launch", appId])
    }

    // ── Change sources ───────────────────────────────────────

    Timer {
        id: rebuildTimer
        interval: 60
        onTriggered: root.rebuild()
    }
    function scheduleRebuild() { rebuildTimer.restart() }

    Timer {
        id: refreshTimer
        interval: 120
        onTriggered: {
            Hyprland.refreshToplevels()
            root.scheduleRebuild()
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            switch (event.name) {
            case "openwindow":
            case "closewindow":
            case "movewindowv2":
            case "windowtitlev2":
            case "activewindowv2":
            case "changefloatingmode":
                refreshTimer.restart()
            }
        }
    }
    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.scheduleRebuild() }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            // A newly installed app may bring an icon the index lacks.
            root._rescanned = false
            root.scheduleRebuild()
        }
    }

    FileView {
        id: dockFile
        path: Quickshell.env("HOME") + "/.config/omarchy/dock.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                root.pinned = Array.isArray(d.pinned) ? d.pinned : []
            } catch (e) {
                root.pinned = []
            }
            root.scheduleRebuild()
        }
        onLoadFailed: { root.pinned = []; root.scheduleRebuild() }
    }

    // Absolute-path icon index, the same approach as Omarchy's AppLibrary:
    // Qt's themed lookup returns nothing when the configured icon theme is
    // not installed, which would leave every tile blank. The index is cached
    // on disk and only rebuilt (at low priority) when an icon is missing.
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/mouse-first"
    property bool _cacheReady: false
    property bool _rescanned: false

    function _requestRescan() {
        if (!root._cacheReady || root._rescanned) return
        root._rescanned = true
        iconScanDebounce.restart()
    }

    FileView {
        id: iconCache
        path: root.cacheDir + "/icons.json"
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try { root.iconIndex = JSON.parse(text()) || {} } catch (e) { root.iconIndex = {} }
            root._cacheReady = true
            root.scheduleRebuild()
        }
        onLoadFailed: {
            root._cacheReady = true
            root._requestRescan()
        }
    }

    Timer {
        id: iconScanDebounce
        interval: 2000
        onTriggered: if (!iconScan.running) iconScan.running = true
    }
    Process {
        id: iconScan
        command: ["nice", "-n", "19", "bash", "-c", [
            'dirs="$HOME/.icons $HOME/.local/share/icons";',
            'IFS=":"; for d in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do dirs="$dirs $d/icons"; done; unset IFS;',
            'for ext in svg png; do',
            '  for base in $dirs; do [[ -d $base ]] && find "$base" -path "*/apps/*" -name "*.$ext" 2>/dev/null; done;',
            '  find /usr/share/pixmaps -maxdepth 1 -name "*.$ext" 2>/dev/null;',
            'done'
        ].join(" ")]
        stdout: SplitParser {
            onRead: line => {
                var path = String(line).trim()
                var file = path.slice(path.lastIndexOf("/") + 1)
                var dot = file.lastIndexOf(".")
                var name = dot > 0 ? file.slice(0, dot) : file
                if (name && root._pendingIcons[name] === undefined) {
                    root._pendingIcons[name] = path
                    if (root._pendingIcons[name.toLowerCase()] === undefined) root._pendingIcons[name.toLowerCase()] = path
                }
            }
        }
        onStarted: root._pendingIcons = ({})
        onExited: {
            root.iconIndex = root._pendingIcons
            iconCache.setText(JSON.stringify(root.iconIndex))
            root.scheduleRebuild()
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.cacheDir])
        Hyprland.refreshToplevels()
        root.scheduleRebuild()
    }
}
