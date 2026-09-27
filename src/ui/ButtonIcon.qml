import QtQuick

// Vector glyphs for the window buttons, drawn with rectangles so they stay
// crisp at any scale and follow the theme colour.
Item {
    id: icon

    required property string kind      // float | minimize | maximize | close
    property color color: "white"
    property color background: "transparent"
    property bool maximized: false
    property bool floating: true

    width: 14
    height: 14

    Rectangle {
        visible: icon.kind === "minimize"
        anchors.centerIn: parent
        width: 10; height: 2; radius: 1
        color: icon.color
    }

    Rectangle {
        visible: icon.kind === "maximize" && !icon.maximized
        anchors.centerIn: parent
        width: 10; height: 10; radius: 1.5
        color: "transparent"
        border.color: icon.color
        border.width: 1.5
    }

    Item {
        visible: icon.kind === "maximize" && icon.maximized
        anchors.centerIn: parent
        width: 11; height: 11
        Rectangle {
            x: 2; y: 0; width: 8; height: 8; radius: 1
            color: "transparent"
            border.color: icon.color
            border.width: 1.2
        }
        Rectangle {
            x: 0; y: 3; width: 8; height: 8; radius: 1
            color: icon.background
            border.color: icon.color
            border.width: 1.2
        }
    }

    Item {
        visible: icon.kind === "close"
        anchors.centerIn: parent
        width: 14; height: 14
        Repeater {
            model: [45, -45]
            Rectangle {
                required property var modelData
                anchors.centerIn: parent
                width: 13; height: 1.8; radius: 0.9
                rotation: modelData
                antialiasing: true
                color: icon.color
            }
        }
    }

    // Float: a single frame; tile: a frame split in two.
    Item {
        visible: icon.kind === "float"
        anchors.centerIn: parent
        width: 11; height: 11
        Rectangle {
            anchors.fill: parent
            radius: 1.5
            color: "transparent"
            border.color: icon.color
            border.width: 1.4
        }
        Rectangle {
            visible: !icon.floating
            anchors.centerIn: parent
            width: 1.4; height: parent.height
            color: icon.color
        }
        Rectangle {
            visible: icon.floating
            x: 3; y: 3; width: 5; height: 5; radius: 1
            color: icon.color
        }
    }
}
