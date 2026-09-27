import QtQuick

// On/off pill used by the settings rows.
Rectangle {
    required property var svc
    property bool checked: false

    width: 36
    height: 20
    radius: 10
    color: checked ? svc.accent : Qt.rgba(1, 1, 1, 0.12)
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        x: parent.checked ? 18 : 2
        y: 2
        width: 16
        height: 16
        radius: 8
        color: "white"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
}
