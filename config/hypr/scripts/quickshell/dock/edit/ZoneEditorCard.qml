import QtQuick
import "../DockLayout.js" as DockLayout

// Per-zone editor card for the DockEditor.
Rectangle {
    id: zoneCard
    required property var bar
    required property var zoneData
    required property int zoneIndex

    width: parent ? parent.width : 0
    height: bar.s(200)
    radius: bar.s(16)
    color: bar.colors.surface0
    border.width: bar.s(1); border.color: bar.colors.surface1

    function patch(fn) { bar.applyDock(fn(bar.dock)); }

    Column {
        anchors.fill: parent
        anchors.margins: bar.s(10)
        spacing: bar.s(6)

        // header: id + align + unify + delete
        Row {
            width: parent.width
            spacing: bar.s(8)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "◈ " + zoneData.id
                font.family: "Hack Nerd Font"
                font.pixelSize: bar.s(13)
                font.weight: Font.Black
                color: bar.colors.text
            }
            EditPill { bar: zoneCard.bar; modelData: "start"; text: "Start"; active: zoneData.align === "start"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "start")) }
            EditPill { bar: zoneCard.bar; modelData: "center"; text: "Center"; active: zoneData.align === "center"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "center")) }
            EditPill { bar: zoneCard.bar; modelData: "end"; text: "End"; active: zoneData.align === "end"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "end")) }
            Item { width: parent.width - bar.s(280); height: 1 }
            EditLabel { bar: zoneCard.bar; text: "Unify" }
            ToggleSwitch { bar: zoneCard.bar; checked: zoneData.unify === true; onToggled: patch(d => DockLayout.setZoneUnify(d, zoneData.id, !zoneData.unify)) }
            Rectangle {
                width: bar.s(28); height: bar.s(28); radius: bar.s(8)
                color: bar.colors.red
                Text { anchors.centerIn: parent; text: ""; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(14); color: bar.colors.base }
                MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.removeZone(d, zoneData.id)) }
            }
        }

        // zone border
        Row {
            width: parent.width
            EditLabel { bar: zoneCard.bar; text: "Borde zona" }
            Item { width: parent.width - bar.s(230); height: 1 }
            Stepper {
                bar: zoneCard.bar
                label: Math.round(zoneData.borderWidth || 0) + "px"
                onDec: patch(d => DockLayout.setZoneBorder(d, zoneData.id, Math.max(0, (zoneData.borderWidth || 0) - 1)))
                onInc: patch(d => DockLayout.setZoneBorder(d, zoneData.id, Math.min(8, (zoneData.borderWidth || 0) + 1)))
            }
            ColorCycle {
                bar: zoneCard.bar
                role: zoneData.borderColor || "surface1"
                onCycled: (role) => patch(d => DockLayout.setZoneBorder(d, zoneData.id, zoneData.borderWidth || 0, role))
            }
        }

        // module chips
        Flow {
            width: parent.width
            spacing: bar.s(5)
            Repeater {
                model: zoneData.modules
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property var mod: DockLayout.getModule(modelData.id)
                    width: chipRow.implicitWidth + bar.s(42)
                    height: bar.s(30)
                    radius: bar.s(8)
                    color: modelData.enabled === false ? bar.colors.surface1 : bar.colors.surface2
                    opacity: modelData.enabled === false ? 0.4 : 1

                    Row {
                        id: chipRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: bar.s(6)
                        spacing: bar.s(5)
                        Text { text: mod ? mod.icon : "?"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text }
                        Text { text: mod ? mod.label : modelData.id; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(11); color: bar.colors.text }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: patch(d => DockLayout.toggleEnabled(d, modelData.id))
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: bar.s(2)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.s(2)
                        Rectangle {
                            width: bar.s(18); height: bar.s(18); radius: bar.s(4)
                            color: bar.colors.surface1
                            Text { anchors.centerIn: parent; text: "◀"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, -1)) }
                        }
                        Rectangle {
                            width: bar.s(18); height: bar.s(18); radius: bar.s(4)
                            color: bar.colors.surface1
                            Text { anchors.centerIn: parent; text: "▶"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, 1)) }
                        }
                    }
                }
            }
        }
    }
}
