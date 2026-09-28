import QtQuick
import Quickshell

// Right-click menu for a bar icon: the app's windows, a new window, pin or
// unpin (shared with omadock), and close. A popup with a focus grab, so a
// click anywhere else closes it.
PopupWindow {
    id: menu

    required property var svc
    property var row: null
    property Item anchorItem: null

    readonly property var windows: row && row.windows ? row.windows : []

    function openFor(r, item) {
        menu.row = r
        menu.anchorItem = item
        menu.visible = true
    }

    function run(action) {
        menu.visible = false
        action()
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 260
    implicitHeight: list.implicitHeight + 12

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: menu.svc.bg
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        Column {
            id: list
            x: 6
            y: 6
            width: parent.width - 12

            Repeater {
                model: menu.windows
                MenuRow {
                    required property var modelData
                    label: modelData.title || (menu.row ? menu.row.name : "")
                    dot: modelData.state
                    onClicked: menu.run(() => menu.svc.activateWindow(modelData))
                }
            }

            Rectangle {
                visible: menu.windows.length > 0
                width: parent.width
                height: 9
                color: "transparent"
                Rectangle { anchors.centerIn: parent; width: parent.width - 8; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }
            }

            MenuRow {
                label: menu.svc.tr("newWindow")
                onClicked: menu.run(() => menu.svc.launch(menu.row.appId))
            }
            MenuRow {
                label: menu.svc.tr(menu.row && menu.row.pinned ? "unpin" : "pin")
                onClicked: {
                    var r = menu.row
                    menu.run(() => menu.svc.setPinned(r.pinned ? r.pinId : r.appId, !r.pinned))
                }
            }
            MenuRow {
                visible: menu.windows.length > 0
                label: menu.svc.tr(menu.windows.length > 1 ? "closeAllWindows" : "closeWindow")
                danger: true
                onClicked: {
                    var r = menu.row
                    menu.run(() => menu.svc.closeRow(r))
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: item
        property string label: ""
        property string dot: ""
        property bool danger: false
        signal clicked()

        width: parent ? parent.width : 0
        height: 30
        radius: 6
        color: area.containsMouse ? (danger ? Qt.rgba(0.9, 0.2, 0.2, 0.7) : Qt.rgba(1, 1, 1, 0.08)) : "transparent"

        Rectangle {
            visible: item.dot !== ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: item.dot === "minimized" ? menu.svc.muted : menu.svc.accent
            opacity: item.dot === "active" ? 1 : 0.6
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: item.dot !== "" ? 24 : 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: item.label
            elide: Text.ElideRight
            color: area.containsMouse && item.danger ? "white" : menu.svc.fg
            font.family: menu.svc.fontFamily
            font.pixelSize: 12
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.clicked()
        }
    }
}
