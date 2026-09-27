import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "js/hypr.js" as Hypr

// Apps shown on the system bar: pinned apps from omadock's dock.json first,
// then every other open window. Built from Quickshell's live toplevel list
// and desktop entries; rebuilt only when Hyprland reports a change.
//
// rows: [{ key, appId, name, icon, title, state, address, pinned }]
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

    function _matchesPin(pin, appId, entry) {
        var p = pin.toLowerCase()
        if (appId.toLowerCase() === p) return true
        if (entry && String(entry.id).toLowerCase() === p) return true
        return false
    }

    function rebuild() {
        var toplevels = Hyprland.toplevels.values
        var wins = []
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
            wins.push({
                address: address,
                appId: appId,
                entry: entry,
                title: String(t.title || ""),
                state: isMin ? "minimized" : (t.activated ? "active" : "running")
            })
        }

        var out = []
        var used = {}
        var rank = { active: 0, running: 1, minimized: 2 }
        for (var p = 0; p < root.pinned.length; p++) {
            var pin = String(root.pinned[p] || "")
            if (pin === "") continue
            var pinEntry = root.entryFor(pin)
            var best = null
            for (var w = 0; w < wins.length; w++) {
                if (used[wins[w].address] || !root._matchesPin(pin, wins[w].appId, wins[w].entry)) continue
                used[wins[w].address] = true
                if (!best || rank[wins[w].state] < rank[best.state]) best = wins[w]
            }
            out.push(root._row(best, pinEntry, pin, true))
        }
        for (var k = 0; k < wins.length; k++) {
            if (used[wins[k].address]) continue
            out.push(root._row(wins[k], wins[k].entry, wins[k].appId, false))
        }
        root.rows = out
        root.minimizedChanged(minimized)
    }

    function _row(win, entry, appId, pinned) {
        var name = entry && entry.name ? String(entry.name) : (appId || "App")
        return {
            key: win ? win.address : "pin:" + appId,
            appId: entry && entry.id ? String(entry.id) : appId,
            name: name,
            icon: root.iconSource(entry ? entry.icon : appId) || root.iconSource(appId),
            title: win ? win.title : "",
            state: win ? win.state : "closed",
            address: win ? win.address : "",
            pinned: pinned
        }
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
            root.scheduleRebuild()
            iconScanDebounce.restart()
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
    // not installed, which would leave every tile blank.
    Timer {
        id: iconScanDebounce
        interval: 1500
        onTriggered: if (!iconScan.running) iconScan.running = true
    }
    Process {
        id: iconScan
        command: ["bash", "-c", [
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
            root.scheduleRebuild()
        }
    }

    Component.onCompleted: {
        iconScan.running = true
        Hyprland.refreshToplevels()
        root.scheduleRebuild()
    }
}
