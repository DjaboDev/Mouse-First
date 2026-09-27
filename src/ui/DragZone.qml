import QtQuick

// Invisible strip along the top edge of the active window. Press and drag it
// to move the window; double-click to maximize/restore; right-click opens
// the settings. A thin accent line fades in on hover.
Item {
    id: zone

    required property var svc
    required property var overlay
    property var win: null          // window rect in overlay coordinates
    property real rightInset: 120   // keeps clear of the control bubble

    readonly property bool managed: zone.svc.winMaximized || !!(zone.svc.win && zone.svc.states.entry(zone.svc.win.address))
    // Leave room for back/refresh buttons at the left of floating apps; a
    // snapped or maximized window gets the full width so it can be pulled
    // out from anywhere along the top.
    readonly property real leftInset: managed ? 6 : 72

    enabled: !!win && zone.svc.cfg.dragFullWidth
    visible: enabled
    x: win ? win.x + leftInset : 0
    y: win ? win.y : 0
    width: win ? Math.max(0, win.w - leftInset - rightInset) : 0
    height: 8

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(80, Math.min(parent.width - 40, Math.round(parent.width * 0.45)))
        height: 3
        radius: 1.5
        color: zone.svc.accent
        opacity: (area.containsMouse || zone.svc.drag.active) ? 0.65 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: zone.svc.drag.active ? Qt.ClosedHandCursor : Qt.SizeAllCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                zone.svc.toggleSettings()
                return
            }
            zone.svc.pressWindow(zone.overlay.screen.name, zone.overlay.toGlobal(area, mouse.x, mouse.y))
        }
        onPositionChanged: mouse => {
            if (pressed) zone.svc.moveWindow(zone.overlay.toGlobal(area, mouse.x, mouse.y))
        }
        onReleased: zone.svc.releaseWindow()
        onCanceled: zone.svc.releaseWindow()
        onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) zone.svc.trigger("maximize")
        }
    }
}
