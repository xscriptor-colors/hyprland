import QtQuick
import QtQuick.Layouts
import "../DockLayout.js" as DockLayout

// Per-zone editor card for the DockEditor. Height grows with content so the
// module chips never overlap the rows below. Width is managed by the parent
// layout (Layout.fillWidth) so it never fights the container.
Rectangle {
    id: zoneCard
    required property var bar
    required property var zoneData
    required property int zoneIndex

    height: contentCol.implicitHeight + bar.s(20)
    radius: bar.s(16)
    color: bar.colors.surface0
    border.width: bar.s(1); border.color: bar.colors.surface2

    function patch(fn) { bar.applyDock(fn(bar.dock)); }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: bar.s(10)
        spacing: bar.s(6)

        // header: id + align + unify + delete
        RowLayout {
            Layout.fillWidth: true
            spacing: bar.s(8)

            Text {
                text: "◈ " + zoneData.id
                font.family: "Hack Nerd Font"
                font.pixelSize: bar.s(13)
                font.weight: Font.Black
                color: bar.colors.text
            }
            EditPill { bar: zoneCard.bar; modelData: "start"; text: "Start"; active: zoneData.align === "start"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "start")) }
            EditPill { bar: zoneCard.bar; modelData: "center"; text: "Center"; active: zoneData.align === "center"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "center")) }
            EditPill { bar: zoneCard.bar; modelData: "end"; text: "End"; active: zoneData.align === "end"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "end")) }
            Item { Layout.fillWidth: true; height: 1 }
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
        RowLayout {
            Layout.fillWidth: true
            spacing: bar.s(8)

            EditLabel { bar: zoneCard.bar; text: "Borde zona" }
            Item { Layout.fillWidth: true; height: 1 }
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

        Rectangle { Layout.fillWidth: true; height: bar.s(1); color: bar.colors.surface2; opacity: 0.4 }

        // module chips (wrap; card grows)
        Flow {
            Layout.fillWidth: true
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
                    color: modelData.enabled === false ? bar.colors.surface2 : bar.colors.surface2
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
                            color: bar.colors.surface2
                            Text { anchors.centerIn: parent; text: "◀"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, -1)) }
                        }
                        Rectangle {
                            width: bar.s(18); height: bar.s(18); radius: bar.s(4)
                            color: bar.colors.surface2
                            Text { anchors.centerIn: parent; text: "▶"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, 1)) }
                        }
                    }
                }
            }
        }
    }
}
