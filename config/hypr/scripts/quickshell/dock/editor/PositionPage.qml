import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// PositionPage — BarEditor tab: bar position selector.
//
// Fase 5 (look Guide): título s(24) Black + grid 2 columnas de cards
// (PosCard/PosCardSerp ya en estilo card-guide: alto s(60), radio s(18),
// activo mauve/crust). Sin filas ni cajitas decorativas.
// Contract: receives the BarEditor root as `bar` (bar.s(), bar.colors,
// bar.dock / bar.serp, bar.applyDock / bar.applySerp, ...). NEVER touches ids
// of the editor root. Exposes the scroll Flickable via `flickable`.
//
// PosCard writes straight through bar.applyDock; PosCardSerp emits
// activated() and this page routes it through bar.applySerp.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent   // Phase 3: el item del Loader ocupa la stage

    property var bar: null

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null


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

                    // Título de página (GP:1007-1014)
                    Text {
                        text: "Position"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // ── Dock engine: PosCard 2×2 (escribe vía applyDock) ──
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        visible: bar.engine === "dock"
                        PosCard { Layout.fillWidth: true; bar: root.bar; dockRef: root.bar.dock; pos: "top"; label: "Top"; glyph: "↑" }
                        PosCard { Layout.fillWidth: true; bar: root.bar; dockRef: root.bar.dock; pos: "bottom"; label: "Bottom"; glyph: "↓" }
                        PosCard { Layout.fillWidth: true; bar: root.bar; dockRef: root.bar.dock; pos: "left"; label: "Left"; glyph: "←" }
                        PosCard { Layout.fillWidth: true; bar: root.bar; dockRef: root.bar.dock; pos: "right"; label: "Right"; glyph: "→" }
                    }

                    // ── Serp engine: PosCardSerp 2×2 (rutea a applySerp) ──
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        visible: bar.engine === "serp"
                        PosCardSerp { Layout.fillWidth: true; bar: root.bar; pos: "top"; label: "Top"; glyph: "↑"; onActivated: root.bar.applySerp({ position: "top" }) }
                        PosCardSerp { Layout.fillWidth: true; bar: root.bar; pos: "bottom"; label: "Bottom"; glyph: "↓"; onActivated: root.bar.applySerp({ position: "bottom" }) }
                        PosCardSerp { Layout.fillWidth: true; bar: root.bar; pos: "left"; label: "Left"; glyph: "←"; onActivated: root.bar.applySerp({ position: "left" }) }
                        PosCardSerp { Layout.fillWidth: true; bar: root.bar; pos: "right"; label: "Right"; glyph: "→"; onActivated: root.bar.applySerp({ position: "right" }) }
                    }
                }
            }
        }
    }
}
