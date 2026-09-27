import QtQuick
import QtQuick.Layouts
import "../js/i18n.js" as I18n

// Settings, opened with a right-click on the control bar. Every change is
// saved immediately to ~/.config/omarchy/mouse-first.json.
Rectangle {
    id: panel

    required property var svc
    property Item anchorItem: null
    property real maxHeight: 800
    property real topLimit: 8

    readonly property var cfg: svc.cfg
    readonly property Item host: parent

    width: 390
    height: Math.min(maxHeight, body.implicitHeight + 32)
    radius: 12
    color: svc.bg
    border.color: Qt.rgba(1, 1, 1, 0.12)
    border.width: 1

    x: {
        var hostW = host ? host.width : 1920
        var want = anchorItem ? anchorItem.x + anchorItem.width - width : (hostW - width) / 2
        return Math.max(8, Math.min(hostW - width - 8, want))
    }
    y: {
        var hostH = host ? host.height : 1080
        var want = anchorItem ? anchorItem.y + anchorItem.height + 8 : (hostH - height) / 2
        return Math.max(topLimit, Math.min(hostH - height - 8, want))
    }

    function t(key) { return panel.svc.tr(key) }
    function set(key, value) { panel.svc.cfgFile.set(key, value) }

    // Swallow clicks so they do not reach the backdrop behind the panel.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            width: parent.width
            spacing: 12

            Text {
                text: panel.t("settingsTitle")
                color: panel.svc.fg
                font.family: panel.svc.fontFamily
                font.pixelSize: 14
                font.bold: true
            }
            Caption { text: panel.t("settingsHint") }
            Divider {}

            // Language
            Row {
                width: parent.width
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - chips.width - 8
                    leftPadding: 4
                    text: panel.t("language")
                    color: panel.svc.fg
                    font.family: panel.svc.fontFamily
                    font.pixelSize: 12
                }
                Row {
                    id: chips
                    spacing: 4
                    Repeater {
                        model: I18n.LANGUAGES
                        Chip {
                            required property var modelData
                            label: modelData.label
                            selected: panel.cfg.language === modelData.id
                            onClicked: panel.set("language", modelData.id)
                        }
                    }
                }
            }

            Section { text: panel.t("systemBehavior") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("disableTiling"); sublabel: panel.t("disableTilingSub")
                checked: panel.cfg.disableTiling
                onToggled: panel.set("disableTiling", !panel.cfg.disableTiling)
            }

            Section { text: panel.t("minimizedSectionTitle") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("minimizeToBar"); sublabel: panel.t("minimizeToBarSub")
                checked: panel.cfg.minimizeToBar
                onToggled: panel.set("minimizeToBar", !panel.cfg.minimizeToBar)
            }
            Column {
                x: 16
                width: parent.width - 16
                spacing: 6
                enabled: panel.svc.showAppsInBar
                opacity: enabled ? 1 : 0.35
                Text {
                    width: parent.width
                    text: panel.t("minimizedAppsLocation")
                    color: panel.svc.fg
                    font.family: panel.svc.fontFamily
                    font.pixelSize: 12
                }
                Caption { text: panel.t("minimizedAppsLocationSub") }
                Row {
                    spacing: 4
                    topPadding: 2
                    Repeater {
                        model: [
                            { id: "left", key: "locLeft" },
                            { id: "center", key: "locCenter" },
                            { id: "right", key: "locRight" }
                        ]
                        Chip {
                            required property var modelData
                            label: panel.t(modelData.key)
                            selected: panel.svc.barSection === modelData.id
                            onClicked: panel.svc.setBarSection(modelData.id)
                        }
                    }
                }
            }

            Section { text: panel.t("visibility") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("alwaysVisible"); sublabel: panel.t("alwaysVisibleSub")
                checked: panel.cfg.alwaysVisible
                onToggled: panel.set("alwaysVisible", !panel.cfg.alwaysVisible)
            }

            Section { text: panel.t("dragging") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("dragZone"); sublabel: panel.t("dragZoneSub")
                checked: panel.cfg.dragFullWidth
                onToggled: panel.set("dragFullWidth", !panel.cfg.dragFullWidth)
            }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("dragHandle"); sublabel: panel.t("dragHandleSub")
                checked: panel.cfg.showDragHandle
                onToggled: panel.set("showDragHandle", !panel.cfg.showDragHandle)
            }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("ignoreDock"); sublabel: panel.t("ignoreDockSub")
                checked: panel.cfg.ignoreDock
                onToggled: panel.set("ignoreDock", !panel.cfg.ignoreDock)
            }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("disableSnapping"); sublabel: panel.t("disableSnappingSub")
                checked: panel.cfg.disableSnapping
                onToggled: panel.set("disableSnapping", !panel.cfg.disableSnapping)
            }

            Section { text: panel.t("menuDragging") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("enableMenuDrag"); sublabel: panel.t("enableMenuDragSub")
                checked: panel.cfg.enableMenuDrag
                onToggled: panel.set("enableMenuDrag", !panel.cfg.enableMenuDrag)
            }
            Column {
                x: 16
                width: parent.width - 16
                spacing: 8
                enabled: panel.cfg.enableMenuDrag
                SettingsToggle {
                    svc: panel.svc
                    label: panel.t("rememberMenuPerWindow"); sublabel: panel.t("rememberMenuPerWindowSub")
                    checked: panel.cfg.rememberMenuPerWindow
                    onToggled: {
                        var on = !panel.cfg.rememberMenuPerWindow
                        panel.set("rememberMenuPerWindow", on)
                        if (on) panel.set("rememberMenuGlobal", false)
                    }
                }
                SettingsToggle {
                    svc: panel.svc
                    label: panel.t("rememberMenuGlobal"); sublabel: panel.t("rememberMenuGlobalSub")
                    checked: panel.cfg.rememberMenuGlobal
                    onToggled: {
                        var on = !panel.cfg.rememberMenuGlobal
                        panel.set("rememberMenuGlobal", on)
                        if (on) panel.set("rememberMenuPerWindow", false)
                    }
                }
                SettingsToggle {
                    svc: panel.svc
                    label: panel.t("alwaysShowMenuDragZone"); sublabel: panel.t("alwaysShowMenuDragZoneSub")
                    checked: panel.cfg.alwaysShowMenuDragZone
                    onToggled: panel.set("alwaysShowMenuDragZone", !panel.cfg.alwaysShowMenuDragZone)
                }
            }

            Section { text: panel.t("buttonsTitle") }
            Caption { text: panel.t("buttonsHint") }
            Column {
                width: parent.width
                spacing: 4
                Repeater {
                    model: panel.cfg.buttonOrder
                    delegate: Rectangle {
                        id: btnRow
                        required property string modelData
                        required property int index
                        readonly property bool shown: panel.cfg.buttonVisible[modelData] !== false
                        width: parent.width
                        height: 40
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.color: Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 6
                                color: Qt.rgba(1, 1, 1, 0.07)
                                ButtonIcon {
                                    anchors.centerIn: parent
                                    kind: btnRow.modelData
                                    color: btnRow.modelData === "close" ? panel.svc.red : panel.svc.fg
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var id = btnRow.modelData
                                    if (id === "float") return panel.t("floatTile")
                                    if (id === "maximize") return panel.t("maxRestore")
                                    return panel.t(id)
                                }
                                color: panel.svc.fg
                                font.family: panel.svc.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            ArrowButton {
                                glyph: "↑"
                                active: btnRow.index > 0
                                onClicked: panel.svc.moveButton(btnRow.index, -1)
                            }
                            ArrowButton {
                                glyph: "↓"
                                active: btnRow.index < panel.cfg.buttonOrder.length - 1
                                onClicked: panel.svc.moveButton(btnRow.index, 1)
                            }
                            Switch {
                                svc: panel.svc
                                checked: btnRow.shown
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: panel.svc.setButtonVisible(btnRow.modelData, !btnRow.shown)
                                }
                            }
                        }
                    }
                }
            }

            Section { text: panel.t("colorTitle") }
            SettingsToggle {
                svc: panel.svc
                label: panel.t("themeFollow"); sublabel: panel.t("themeFollowSub")
                checked: panel.cfg.colorMode !== "custom"
                onToggled: panel.set("colorMode", panel.cfg.colorMode === "custom" ? "theme" : "custom")
            }

            Divider {}
            Rectangle {
                width: parent.width
                height: 32
                radius: 6
                color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: panel.t("closeSettings")
                    color: panel.svc.muted
                    font.family: panel.svc.fontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.svc.settingsOpen = false
                }
            }
        }
    }

    component Section: Text {
        width: parent ? parent.width : 0
        topPadding: 4
        color: panel.svc.muted
        font.family: panel.svc.fontFamily
        font.pixelSize: 9
        font.bold: true
        font.letterSpacing: 0.5
    }

    component Caption: Text {
        width: parent ? parent.width : 0
        color: panel.svc.muted
        font.family: panel.svc.fontFamily
        font.pixelSize: 10
        wrapMode: Text.Wrap
    }

    component Divider: Rectangle {
        width: parent ? parent.width : 0
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        signal clicked()
        width: chipText.implicitWidth + 20
        height: 24
        radius: 12
        color: selected ? Qt.rgba(panel.svc.accent.r, panel.svc.accent.g, panel.svc.accent.b, 0.22)
             : (chipArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
        border.color: selected ? panel.svc.accent : Qt.rgba(1, 1, 1, 0.1)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? panel.svc.fg : panel.svc.muted
            font.family: panel.svc.fontFamily
            font.pixelSize: 11
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component ArrowButton: Rectangle {
        id: arrow
        property string glyph: ""
        property bool active: true
        signal clicked()
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        radius: 5
        color: arrowArea.containsMouse && active ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04)
        Text {
            anchors.centerIn: parent
            text: arrow.glyph
            color: panel.svc.fg
            opacity: arrow.active ? 1 : 0.25
            font.pixelSize: 13
        }
        MouseArea {
            id: arrowArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: arrow.active
            onClicked: arrow.clicked()
        }
    }
}
