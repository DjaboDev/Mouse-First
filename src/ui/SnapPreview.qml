import QtQuick

// Outline of where the window will land if released now. Each overlay draws
// the part of the target that falls on its own screen.
Rectangle {
    id: preview

    required property var svc
    property real originX: 0
    property real originY: 0
    property real screenW: 0
    property real screenH: 0

    readonly property var target: svc.drag.active ? svc.drag.zoneRect : null
    readonly property bool onThisScreen: !!target &&
        target.x < originX + screenW && target.x + target.w > originX &&
        target.y < originY + screenH && target.y + target.h > originY

    property var shown: null
    onTargetChanged: if (target) shown = target

    visible: opacity > 0.01
    opacity: onThisScreen ? 1 : 0
    x: shown ? shown.x - originX : 0
    y: shown ? shown.y - originY : 0
    width: shown ? shown.w : 0
    height: shown ? shown.h : 0
    radius: 12
    color: Qt.rgba(svc.accent.r, svc.accent.g, svc.accent.b, 0.16)
    border.color: svc.accent
    border.width: 2

    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 140 } }
}
