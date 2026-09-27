import QtQuick
import "src/ui"

// Bar widget: the row of app icons. Omarchy creates one per monitor; all
// state lives in the Mouse-First service (Service.qml), shared by every copy.
Item {
    id: root

    property QtObject bar: null
    property string moduleName: ""
    property var settings: ({})

    readonly property int barSize: bar ? bar.barSize : 26
    readonly property bool vertical: bar ? bar.vertical : false

    property var service: null
    readonly property bool shown: !!service && service.showAppsInBar && service.apps.rows.length > 0

    implicitWidth: shown ? (vertical ? barSize : row.implicitWidth) : 0
    implicitHeight: shown ? (vertical ? row.implicitHeight : barSize) : barSize
    visible: shown

    // The service may finish loading after the bar; look it up until found.
    function bindService() {
        if (root.service) return
        var host = root.bar && root.bar.shell ? root.bar.shell : null
        if (host && typeof host.serviceFor === "function")
            root.service = host.serviceFor("io.github.mousefirst.controls")
    }
    Timer {
        interval: 250
        repeat: true
        running: !root.service
        triggeredOnStart: true
        onTriggered: root.bindService()
    }
    onBarChanged: bindService()

    Grid {
        id: row
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, repeater.count)
        spacing: 4

        Repeater {
            id: repeater
            model: root.service ? root.service.apps.rows : []
            delegate: AppTile {
                required property var modelData
                row: modelData
                svc: root.service
                bar: root.bar
            }
        }
    }
}
