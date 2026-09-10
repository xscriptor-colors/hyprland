import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// GeneralPage — DockEditor tab: engine switcher (dock / serpantinum).
//
// Fase 5 (look Guide): título s(24) Black + grid de OptionCards (template
// cards GP:1276-1302); sin filas con cajita decorativa. Con engine serp se
// añaden los EditorButton de acciones (llaman a las funciones del root:
// mirrorDockAction() / serpDefaultsAction()).
// Contract: receives the DockEditor root as `bar` (bar.s(), bar.colors,
// bar.setEngine(), ...). NEVER touches ids of the editor root. Exposes the
// scroll Flickable via `flickable` so the root can drive DnD auto-scroll.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent   // Phase 3: el item del Loader ocupa la stage

    property var bar: null
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
                text: "Engine"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(24)
                color: bar.colors.text
            }

            // Grid de opciones (cards template GP:1276-1302)
            GridLayout {
                width: parent.width
                columns: 2
                columnSpacing: bar.s(10)
                rowSpacing: bar.s(10)
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰮯"
                    label: "Dock"
                    active: root.bar.engine === "dock"
                    onActivated: root.bar.setEngine("dock")
                }
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰹑"
                    label: "Serpantinum"
                    accentRole: "blue"
                    active: root.bar.engine === "serp"
                    onActivated: root.bar.setEngine("serp")
                }
            }

            // Acciones de serp (solo con engine serp): funciones del root
            Row {
                width: parent.width
                spacing: bar.s(10)
                visible: bar.engine === "serp"
                EditorButton { bar: root.bar; icon: "󰚰"; label: "Mirror dock layout"; onActivated: root.bar.mirrorDockAction() }
                EditorButton { bar: root.bar; label: "Serp defaults"; onActivated: root.bar.serpDefaultsAction() }
            }

            EditLabel {
                bar: bar
                width: parent.width
                text: "Hot switch between the zone dock and the left/center/right bar."
                font.pixelSize: bar.s(12)
                color: bar.colors.subtext0
                wrapMode: Text.WordWrap
            }
        }
    }
}
