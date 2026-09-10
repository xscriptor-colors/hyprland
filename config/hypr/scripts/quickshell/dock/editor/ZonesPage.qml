import QtQuick
import QtQuick.Controls
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// ZonesPage — BarEditor tab (dock engine only): zone management + the zone
// editor cards (module chips + DnD targets).
//
// Fase 5 (look Guide): título s(24) Black, fila de EditorButton y card hero
// r21 (estilo sysBox GP:684-695) que envuelve la Column `zonasCol` con las
// ZoneEditorCard (contrato DnD intacto).
// Contract: receives the BarEditor root as `bar` (bar.s(), bar.colors,
// bar.dock, ...). NEVER touches ids of the editor root. Exposes the scroll
// Flickable via `flickable` and the zone cards column via `zonasCol` so the
// root can drive DnD auto-scroll + enumerate drop targets (phase 2).
//
// The zone CRUD buttons need DockLayout, which lives in the editor root: this
// page only declares addZone()/centerAll()/resetDock() and the root connects
// them (phase 2). ZoneEditorCard DnD talks to bar.startDnd/updateDnd/endDnd.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent   // Phase 3: el item del Loader ocupa la stage

    property var bar: null

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null
    readonly property var zonasCol: body.item ? body.item.zonasCol : null

    // Emitidas por los EditorButton de la página; el root del BarEditor las
    // conecta (DockLayout.addZone / arrangeAllInZone / defaultDock + applyDock).
    signal addZone()
    signal centerAll()
    signal resetDock()


    Loader {
        id: body
        anchors.fill: parent
        active: root.bar !== null
        sourceComponent: pageBody
    }

    Component {
        id: pageBody
        Item {
            anchors.fill: parent
            property alias flickable: pageFlick
            property alias zonasCol: zonasCol

            Flickable {
                id: pageFlick
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: pageCol.height + bar.s(16)
                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    width: bar.s(4)
                    policy: ScrollBar.AsNeeded
                    hoverEnabled: true
                    active: pageFlick.moving || vScroll.hovered
                    contentItem: Rectangle {
                        radius: bar.s(2)
                        color: bar.colors.surface2
                        opacity: vScroll.active ? 1.0 : 0.45
                    }
                    background: Item {}
                }

                Column {
                    id: pageCol
                    x: bar.s(8)
                    y: bar.s(8)
                    width: pageFlick.width - bar.s(16)
                    spacing: bar.s(12)
                    visible: bar.engine === "dock"

                    // Título de página (GP:1007-1014)
                    Text {
                        text: "Zones"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // Fila de acciones
                    Row {
                        width: parent.width
                        spacing: bar.s(10)
                        EditorButton { bar: root.bar; label: "+ Add"; active: true; onActivated: root.addZone() }
                        EditorButton { bar: root.bar; label: "Center all"; onActivated: root.centerAll() }
                        EditorButton { bar: root.bar; label: "Default"; onActivated: root.resetDock() }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Center all gathers every enabled island into the center zone. Tip: drag a chip onto another zone card to move the island there (release between chips to choose the exact spot)."
                        font.pixelSize: bar.s(12)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    // ── Card hero con las tarjetas de zona (targets DnD) ──────────
                    Rectangle {
                        width: parent.width
                        radius: bar.s(21)
                        color: Qt.alpha(bar.colors.surface0, 0.4)
                        border.width: 1
                        border.color: bar.colors.surface1
                        height: zonasCol.height + bar.s(30)

                        Column {
                            id: zonasCol
                            x: bar.s(15)
                            y: bar.s(15)
                            width: parent.width - bar.s(30)
                            spacing: bar.s(10)
                            Repeater {
                                model: bar.dock.zones
                                delegate: ZoneEditorCard {
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    bar: root.bar
                                    zoneData: modelData
                                    zoneIndex: index
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
