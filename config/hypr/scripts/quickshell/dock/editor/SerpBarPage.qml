import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// SerpBarPage — DockEditor tab (serp engine only): classic bar style & size,
// module sections (DnD lists) and layout actions.
//
// Fase 5 (look Guide): títulos s(24) Black, sub-títulos s(16), grids de
// OptionCards (GP:1276-1302), toggles/steppers como cards de ancho completo,
// card hero r21 para las secciones de módulos y EditorButton full-width en
// Actions. SIN filas con cajita decorativa.
// Contract: receives the DockEditor root as `bar` (bar.s(), bar.colors,
// bar.serp, bar.applySerp, bar.serpRemoveModule, ...). NEVER touches ids of
// the editor root. Exposes the scroll Flickable via `flickable` and the
// section-lists column via `serpListsCol` (contrato DnD intacto).
//
// Position is NOT duplicated here: PositionPage covers both engines. The
// Actions buttons need DockLayout (dockToSerpModules), which lives in the
// editor root: this page only declares mirrorDock()/serpDefaults() and the
// root connects them (phase 2).
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent   // Phase 3: el item del Loader ocupa la stage

    property var bar: null
    property alias flickable: pageFlick
    property alias serpListsCol: serpListsCol

    // Emitidas por los EditorButton de Actions; el root del DockEditor las
    // conecta en la Fase 2 (applySerp({modules}) / serpDefaultsAction).
    signal mirrorDock()
    signal serpDefaults()

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
            visible: bar.engine === "serp"

            // ════ STYLE & SIZE ════
            Text {
                text: "Style & size"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(24)
                color: bar.colors.text
            }

            // Sub-título + presets
            Text {
                text: "Style"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(16)
                color: bar.colors.text
            }
            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: bar.s(10)
                rowSpacing: bar.s(10)
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰍜"
                    label: "Modular"
                    active: root.bar.serp.style === "modular"
                    onActivated: root.bar.applySerp({ style: "modular" })
                }
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰍛"
                    label: "Solid"
                    accentRole: "blue"
                    active: root.bar.serp.style === "solid"
                    onActivated: root.bar.applySerp({ style: "solid" })
                }
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰹑"
                    label: "Fill"
                    accentRole: "teal"
                    active: root.bar.serp.style === "fill"
                    onActivated: root.bar.applySerp({ style: "fill" })
                }
            }

            // Sub-título + Time format
            Text {
                text: "Time format"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(16)
                color: bar.colors.text
            }
            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: bar.s(10)
                rowSpacing: bar.s(10)
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰅐"
                    label: "24h"
                    active: root.bar.serp.timeFormat === "HH:mm:ss" || !root.bar.serp.timeFormat
                    onActivated: root.bar.applySerp({ timeFormat: "HH:mm:ss" })
                }
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰅐"
                    label: "24h :mm"
                    accentRole: "blue"
                    active: root.bar.serp.timeFormat === "HH:mm"
                    onActivated: root.bar.applySerp({ timeFormat: "HH:mm" })
                }
                OptionCard {
                    Layout.fillWidth: true
                    bar: root.bar
                    icon: "󰅐"
                    label: "12h"
                    accentRole: "green"
                    active: root.bar.serp.timeFormat === "h:mm a"
                    onActivated: root.bar.applySerp({ timeFormat: "h:mm a" })
                }
            }

            // Toggles (cards de ancho completo)
            ToggleCard {
                width: parent.width
                bar: root.bar
                visible: bar.serp.style !== "fill"
                icon: "󰍜"
                label: "Distinct pills"
                checked: root.bar.serp.distinctPills === true
                onToggled: root.bar.applySerp({ distinctPills: root.bar.serp.distinctPills !== true })
            }
            ToggleCard {
                width: parent.width
                bar: root.bar
                icon: "󰈉"
                label: "Autohide"
                checked: root.bar.serp.autohide === true
                onToggled: root.bar.applySerp({ autohide: root.bar.serp.autohide !== true })
            }

            // Steppers numéricos (cards de ancho completo)
            StepperCard {
                width: parent.width
                bar: root.bar
                label: "Roundness"
                value: Math.round(root.bar.serp.roundness * 100) + "%"
                onDec: root.bar.applySerp({ roundness: Math.max(0, +(root.bar.serp.roundness - 0.1).toFixed(1)) })
                onInc: root.bar.applySerp({ roundness: Math.min(1, +(root.bar.serp.roundness + 0.1).toFixed(1)) })
            }
            StepperCard {
                width: parent.width
                bar: root.bar
                label: "Thickness"
                value: Math.round(root.bar.serp.thickness !== null ? root.bar.serp.thickness : root.bar.dock.thickness) + "px"
                onDec: root.bar.applySerp({ thickness: Math.max(24, Math.round(root.bar.serp.thickness !== null ? root.bar.serp.thickness : root.bar.dock.thickness) - 4) })
                onInc: root.bar.applySerp({ thickness: Math.min(120, Math.round(root.bar.serp.thickness !== null ? root.bar.serp.thickness : root.bar.dock.thickness) + 4) })
            }
            StepperCard {
                width: parent.width
                bar: root.bar
                visible: bar.serp.style !== "modular"
                label: "Bar opacity"
                value: Math.round(root.bar.serp.opacity) + "%"
                onDec: root.bar.applySerp({ opacity: Math.max(20, Math.round(root.bar.serp.opacity) - 5) })
                onInc: root.bar.applySerp({ opacity: Math.min(100, Math.round(root.bar.serp.opacity) + 5) })
            }
            StepperCard {
                width: parent.width
                bar: root.bar
                visible: bar.serp.style !== "fill"
                label: "Width"
                value: Math.round(root.bar.serp.widthPercent) + "%"
                onDec: root.bar.applySerp({ widthPercent: Math.max(40, Math.round(root.bar.serp.widthPercent) - 5) })
                onInc: root.bar.applySerp({ widthPercent: Math.min(100, Math.round(root.bar.serp.widthPercent) + 5) })
            }
            StepperCard {
                width: parent.width
                bar: root.bar
                visible: bar.serp.autohide === true
                label: "Hide delay"
                value: root.bar.serp.autohideTimeout + "ms"
                onDec: root.bar.applySerp({ autohideTimeout: Math.max(200, root.bar.serp.autohideTimeout - 100) })
                onInc: root.bar.applySerp({ autohideTimeout: Math.min(5000, root.bar.serp.autohideTimeout + 100) })
            }

            EditLabel {
                bar: bar
                width: parent.width
                text: "Modular: floating islands · Solid: continuous strip · Fill: edge-to-edge strip (width locked at 100%). Distinct pills give every module and group its own subtle slab on the strip; opacity fades the strip itself. Thickness = the bar's own size (null inherits the dock engine's). Corners follow the shared Roundness knob (Dock engine → Appearance); module fonts follow dock.font. Autohide slides the bar off-screen; touching the screen edge reveals it."
                font.pixelSize: bar.s(12)
                color: bar.colors.subtext0
                wrapMode: Text.WordWrap
            }

            // ════ MODULES ════
            Text {
                text: "Modules"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(24)
                color: bar.colors.text
            }

            // Card hero r21 con las secciones (targets DnD)
            Rectangle {
                width: parent.width
                radius: bar.s(21)
                color: Qt.alpha(bar.colors.surface0, 0.4)
                border.width: 1
                border.color: bar.colors.surface1
                height: modCol.height + bar.s(30)

                Column {
                    id: modCol
                    x: bar.s(15)
                    y: bar.s(15)
                    width: parent.width - bar.s(30)
                    spacing: bar.s(10)
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Each box is one continuous pill (a group). Drag chips between sections, drop a chip onto a group to join it, drag group headers to move whole clusters, use – to send a module back to Available."
                        font.pixelSize: bar.s(12)
                        color: root.bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                    Column {
                        id: serpListsCol
                        width: parent.width
                        spacing: bar.s(10)
                        SerpSectionCard { width: parent.width; bar: root.bar; listId: "left" }
                        SerpSectionCard { width: parent.width; bar: root.bar; listId: "center" }
                        SerpSectionCard { width: parent.width; bar: root.bar; listId: "right" }
                        SerpSectionCard { width: parent.width; bar: root.bar; listId: "available" }
                    }
                }
            }

            // ════ ACTIONS ════
            Text {
                text: "Actions"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(24)
                color: bar.colors.text
            }

            // Botones full-width (como el Close del guide GP:605-637)
            Column {
                width: parent.width
                spacing: bar.s(10)
                EditorButton { width: parent.width; bar: root.bar; icon: "󰚰"; label: "Mirror dock layout"; onActivated: root.mirrorDock() }
                EditorButton { width: parent.width; bar: root.bar; label: "Serp defaults"; onActivated: root.serpDefaults() }
            }

            EditLabel {
                bar: bar
                width: parent.width
                text: "Mirror imports the zone dock's enabled modules into the classic sections (the dock config itself stays untouched). Serp defaults restores the stock layout and keeps the current position."
                font.pixelSize: bar.s(12)
                color: bar.colors.subtext0
                wrapMode: Text.WordWrap
            }
        }
    }
}
