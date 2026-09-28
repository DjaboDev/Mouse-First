import QtQuick

// A labelled switch row for the settings panel.
Item {
    id: row

    required property var svc
    property string label: ""
    property string sublabel: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 300
    height: Math.max(36, labels.implicitHeight + 10)
    opacity: enabled ? 1 : 0.35
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Column {
        id: labels
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.right: pill.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: row.label
            color: row.svc.fg
            font.family: row.svc.fontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            visible: row.sublabel !== ""
            text: row.sublabel
            color: row.svc.muted
            font.family: row.svc.fontFamily
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }
    }

    Switch {
        id: pill
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        svc: row.svc
        checked: row.checked
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggled()
    }

}
