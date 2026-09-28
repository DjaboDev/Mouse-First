import QtQuick
import QtQuick.Layouts

// The floating capsule with the window buttons, pinned to the top-right
// corner of the active window (plus the user's custom offset).
Rectangle {
    id: bubble

    required property var svc
    required property var overlay
    property var win: null            // window rect in overlay coordinates

    readonly property var cfg: svc.cfg
    readonly property var buttons: cfg.buttonOrder.filter(b => cfg.buttonVisible[b] !== false)
    readonly property bool revealed: cfg.alwaysVisible || hover.hovered || svc.settingsOpen || svc.menuDragging || grip.pressed

    visible: !!win
    width: 12 + (cfg.showDragHandle ? 26 : 0) + buttons.length * 28 + Math.max(0, buttons.length - 1) * 4
    height: 34
    radius: 10
    color: svc.bg
    border.color: Qt.rgba(1, 1, 1, 0.18)
    border.width: 1

    x: win ? Math.max(0, Math.min(overlay.width - width, win.x + win.w - width + svc.menuOffset.x)) : 0
    y: win ? Math.max(overlay.reservedTop, Math.min(overlay.height - height, win.y + svc.menuOffset.y)) : 0

    opacity: revealed ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    HoverHandler { id: hover }

    // Right-click anywhere on the capsule toggles the settings.
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: bubble.svc.toggleSettings()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        // Optional grip: drags the window like the top-edge zone.
        Item {
            id: gripItem
            visible: bubble.cfg.showDragHandle
            Layout.preferredWidth: 22
            Layout.preferredHeight: 28

            Grid {
                anchors.centerIn: parent
                columns: 2
                spacing: 3
                Repeater {
                    model: 6
                    Rectangle {
                        width: 3; height: 3; radius: 1.5
                        color: bubble.svc.fg
                        opacity: grip.containsMouse || grip.pressed ? 0.75 : 0.3
                    }
                }
            }

            MouseArea {
                id: grip
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeAllCursor
                onPressed: mouse => bubble.svc.pressWindow(bubble.overlay.screen.name, bubble.overlay.toGlobal(grip, mouse.x, mouse.y))
                onPositionChanged: mouse => { if (pressed) bubble.svc.moveWindow(bubble.overlay.toGlobal(grip, mouse.x, mouse.y)) }
                onReleased: bubble.svc.releaseWindow()
                onCanceled: bubble.svc.releaseWindow()
            }
        }

        Repeater {
            model: bubble.buttons
            delegate: Rectangle {
                id: button
                required property string modelData
                readonly property bool isClose: modelData === "close"
                readonly property bool hovered: ma.containsMouse
                readonly property color iconColor: hovered && isClose ? "white"
                    : (modelData === "float" && bubble.svc.win && bubble.svc.win.floating ? bubble.svc.accent : Qt.rgba(1, 1, 1, 0.85))

                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 7
                color: {
                    if (isClose && ma.pressed) return Qt.rgba(0.85, 0.15, 0.15, 0.9)
                    if (isClose && hovered) return Qt.rgba(0.9, 0.2, 0.2, 0.7)
                    if (ma.pressed) return Qt.rgba(1, 1, 1, 0.15)
                    if (hovered) return Qt.rgba(1, 1, 1, 0.09)
                    return "transparent"
                }
                Behavior on color { ColorAnimation { duration: 80 } }

                ButtonIcon {
                    anchors.centerIn: parent
                    kind: button.modelData
                    color: button.iconColor
                    background: button.hovered && button.isClose ? "white" : bubble.svc.bg
                    maximized: bubble.svc.winMaximized
                    floating: !!bubble.svc.win && bubble.svc.win.floating
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) bubble.svc.toggleSettings()
                        else bubble.svc.trigger(button.modelData)
                    }
                }

                // Tooltip below the button: above it would collide with the bar.
                Rectangle {
                    visible: button.hovered && !bubble.svc.settingsOpen
                    anchors.top: parent.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tip.implicitWidth + 14
                    height: tip.implicitHeight + 8
                    radius: 5
                    color: Qt.rgba(0, 0, 0, 0.85)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    border.width: 1
                    Text {
                        id: tip
                        anchors.centerIn: parent
                        color: "white"
                        font.family: bubble.svc.fontFamily
                        font.pixelSize: 11
                        text: {
                            var id = button.modelData
                            var w = bubble.svc.win
                            if (id === "float") return bubble.svc.tr(w && w.floating ? "tile" : "float")
                            if (id === "maximize") return bubble.svc.tr(bubble.svc.winMaximized ? "restore" : "maximize")
                            return bubble.svc.tr(id)
                        }
                    }
                }
            }
        }
    }

    // Thin handle along the bottom edge: drag to move the capsule itself,
    // double-click to put it back in the corner.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 24, 34)
        height: 2
        radius: 1
        color: bubble.svc.accent
        visible: bubble.cfg.enableMenuDrag
        opacity: bubble.cfg.alwaysShowMenuDragZone || handle.containsMouse || handle.pressed ? 0.85 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    MouseArea {
        id: handle
        property point startMouse
        property var startOffset
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 16, 46)
        height: 6
        z: 10
        enabled: bubble.cfg.enableMenuDrag
        hoverEnabled: true
        cursorShape: Qt.SizeAllCursor

        onPressed: mouse => {
            startMouse = bubble.overlay.toGlobal(handle, mouse.x, mouse.y)
            startOffset = bubble.svc.menuOffset
            bubble.svc.menuDragging = true
        }
        onPositionChanged: mouse => {
            if (!pressed || !bubble.win) return
            var p = bubble.overlay.toGlobal(handle, mouse.x, mouse.y)
            // Keep the capsule on screen: offsets are relative to the corner.
            var baseX = bubble.win.x + bubble.win.w - bubble.width
            var baseY = bubble.win.y
            bubble.svc.setMenuOffset({
                x: Math.max(-baseX, Math.min(bubble.overlay.width - bubble.width - baseX, startOffset.x + p.x - startMouse.x)),
                y: Math.max(bubble.overlay.reservedTop - baseY, Math.min(bubble.overlay.height - bubble.height - baseY, startOffset.y + p.y - startMouse.y))
            })
        }
        onReleased: { bubble.svc.menuDragging = false; bubble.svc.commitMenuOffset() }
        onCanceled: { bubble.svc.menuDragging = false; bubble.svc.commitMenuOffset() }
        onDoubleClicked: bubble.svc.resetMenuOffset()
    }
}
