import QtQuick

// One app on the bar (all of its windows). Left click: launch, toggle, or
// cycle through the windows. Middle click: close the focused window.
// Right click: the app menu.
Rectangle {
    id: tile

    required property var row
    required property var svc
    property var bar: null
    property var menu: null

    readonly property int windowCount: row.windows ? row.windows.length : 0

    readonly property string state_: row.state
    readonly property string tooltip: windowCount > 1 ? row.name + " (" + windowCount + ")"
        : (row.title ? row.name + " — " + row.title : (row.name || svc.tr("untitled")))

    width: 26
    height: 26
    radius: 6
    color: {
        var hover = area.containsMouse
        if (state_ === "active") return Qt.rgba(1, 1, 1, hover ? 0.22 : 0.14)
        if (state_ === "running") return Qt.rgba(1, 1, 1, hover ? 0.16 : 0.06)
        if (state_ === "minimized") return Qt.rgba(1, 1, 1, hover ? 0.14 : 0.04)
        return hover ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
    }
    border.color: state_ === "active" ? Qt.rgba(svc.accent.r, svc.accent.g, svc.accent.b, 0.5)
                : (area.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : "transparent")
    border.width: 1
    Behavior on color { ColorAnimation { duration: 80 } }

    Image {
        id: icon
        anchors.centerIn: parent
        width: 16
        height: 16
        sourceSize: Qt.size(32, 32)
        smooth: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: tile.row.icon || ""
        opacity: tile.state_ === "minimized" ? 0.55 : (tile.state_ === "closed" ? 0.8 : 1)
        visible: status === Image.Ready
    }

    // Letter fallback when no icon can be found.
    Text {
        anchors.centerIn: parent
        visible: !icon.visible
        text: String(tile.row.name || tile.row.appId || "?").charAt(0).toUpperCase()
        color: tile.svc.accent
        font.family: tile.svc.fontFamily
        font.pixelSize: 11
        font.bold: true
    }

    // State dot: long for the focused window, short for running/minimized.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1.5
        anchors.horizontalCenter: parent.horizontalCenter
        visible: tile.state_ !== "closed"
        width: tile.state_ === "active" ? 10 : 4
        height: tile.state_ === "active" ? 2.5 : 2
        radius: 1.25
        color: tile.state_ === "minimized" ? tile.svc.muted : tile.svc.accent
        opacity: tile.state_ === "active" ? 1 : (tile.state_ === "running" ? 0.85 : 0.65)
    }

    // Window count when the app has more than one.
    Rectangle {
        visible: tile.windowCount > 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -3
        anchors.topMargin: 0
        width: Math.max(12, countText.implicitWidth + 4)
        height: 12
        radius: 6
        color: tile.svc.accent
        Text {
            id: countText
            anchors.centerIn: parent
            text: tile.windowCount > 9 ? "9+" : String(tile.windowCount)
            color: tile.svc.bg
            font.family: tile.svc.fontFamily
            font.pixelSize: 8
            font.bold: true
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: if (tile.bar && tile.bar.showTooltip) tile.bar.showTooltip(tile, tile.tooltip)
        onExited: if (tile.bar && tile.bar.hideTooltip) tile.bar.hideTooltip(tile)
        onClicked: mouse => {
            if (tile.bar && tile.bar.hideTooltip) tile.bar.hideTooltip(tile)
            if (mouse.button === Qt.LeftButton) tile.svc.activateRow(tile.row)
            else if (mouse.button === Qt.RightButton) { if (tile.menu) tile.menu.openFor(tile.row, tile) }
            else if (tile.row.address) tile.svc.close(tile.row.address)
        }
    }
}
