import QtQuick
import Quickshell
import Quickshell.Io
import "js/hypr.js" as Hypr

// Minimize and restore. Windows are parked on special:minimized, the same
// workspace omadock uses, so both show and restore them. The workspace each
// window came from is remembered on disk so a shell restart does not send
// restored windows to the wrong place.
Item {
    id: root
    visible: false

    required property var tracker

    readonly property string workspaceName: "special:minimized"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/mouse-first"

    function minimize(address, originWorkspace) {
        var a = Hypr.normalizeAddress(address)
        if (!a) return
        if (originWorkspace && originWorkspace.indexOf("special:") !== 0) {
            var next = Object.assign({}, store.adapter.origins)
            next[a] = originWorkspace
            store.adapter.origins = next
        }
        root.tracker.evalLua(Hypr.evalMinimize(a))
    }

    function restore(address) {
        var a = Hypr.normalizeAddress(address)
        if (!a) return
        var origin = store.adapter.origins[a] || ""
        root.forget(a)
        root.tracker.evalLua(Hypr.evalRestore(a, origin))
    }

    function forget(address) {
        if (store.adapter.origins[address] === undefined) return
        var next = Object.assign({}, store.adapter.origins)
        delete next[address]
        store.adapter.origins = next
    }

    // Drop entries for windows that no longer exist or were restored by
    // something else (omadock, a keybind).
    function prune(minimizedAddresses) {
        var keep = {}
        for (var i = 0; i < minimizedAddresses.length; i++) keep[minimizedAddresses[i]] = true
        var changed = false
        var next = {}
        for (var a in store.adapter.origins) {
            if (keep[a]) next[a] = store.adapter.origins[a]
            else changed = true
        }
        if (changed) store.adapter.origins = next
    }

    FileView {
        id: store
        path: root.stateDir + "/minimized.json"
        atomicWrites: true
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property var origins: ({})
        }
    }

    Connections {
        target: root.tracker
        function onWindowClosed(address) { root.forget(address) }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", root.stateDir])
    }
}
