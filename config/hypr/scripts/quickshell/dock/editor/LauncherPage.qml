import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// LauncherPage — DockEditor/BarEditor tab: configuración del applauncher
// (SUPER+D): posición en pantalla, ancho, nº de apps visibles, margen y
// anti-solape con la barra.
//
// Contrato: recibe el root del editor como `bar` (bar.s(), bar.colors,
// bar.launcherConfig() y bar.applyLauncher(partial) — que escribe la key
// "launcher" de settings.json). Los cambios se aplican al ABRIR el launcher.
// Gate: el cuerpo se crea cuando `bar` ya está inyectado (initial property
// aplicada tras la creación del root), evitando bindings evaluados con null.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

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
                        text: "Launcher"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // ── Posición en pantalla ────────────────────────────────
                    Text {
                        text: "Position"
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
                            icon: "◎"
                            label: "Center"
                            active: root.bar.launcherCfg.position === "center"
                            onActivated: root.bar.applyLauncher({ position: "center" })
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "↑"
                            label: "Top"
                            active: root.bar.launcherCfg.position === "top"
                            onActivated: root.bar.applyLauncher({ position: "top" })
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "↓"
                            label: "Bottom"
                            active: root.bar.launcherCfg.position === "bottom"
                            onActivated: root.bar.applyLauncher({ position: "bottom" })
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "←"
                            label: "Left"
                            active: root.bar.launcherCfg.position === "left"
                            onActivated: root.bar.applyLauncher({ position: "left" })
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "→"
                            label: "Right"
                            active: root.bar.launcherCfg.position === "right"
                            onActivated: root.bar.applyLauncher({ position: "right" })
                        }
                    }

                    // ── Tamaño y margen ─────────────────────────────────────
                    Text {
                        text: "Size"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    StepperCard {
                        width: parent.width
                        bar: root.bar
                        label: "Width"
                        value: Math.round(root.bar.launcherCfg.width) + "px"
                        onDec: root.bar.applyLauncher({ width: Math.max(480, root.bar.launcherCfg.width - 40) })
                        onInc: root.bar.applyLauncher({ width: Math.min(1280, root.bar.launcherCfg.width + 40) })
                    }
                    StepperCard {
                        width: parent.width
                        bar: root.bar
                        label: "Visible apps"
                        value: Math.round(root.bar.launcherCfg.maxApps) + ""
                        onDec: root.bar.applyLauncher({ maxApps: Math.max(4, root.bar.launcherCfg.maxApps - 1) })
                        onInc: root.bar.applyLauncher({ maxApps: Math.min(20, root.bar.launcherCfg.maxApps + 1) })
                    }
                    StepperCard {
                        width: parent.width
                        bar: root.bar
                        label: "Margin"
                        value: Math.round(root.bar.launcherCfg.margin) + "px"
                        onDec: root.bar.applyLauncher({ margin: Math.max(0, root.bar.launcherCfg.margin - 8) })
                        onInc: root.bar.applyLauncher({ margin: Math.min(200, root.bar.launcherCfg.margin + 8) })
                    }

                    // ── Anti-solape con la barra ────────────────────────────
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰀻"
                        label: "Avoid bar"
                        checked: root.bar.launcherCfg.avoidBar
                        onToggled: root.bar.applyLauncher({ avoidBar: !root.bar.launcherCfg.avoidBar })
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰈈"
                        label: "Show icons"
                        checked: root.bar.launcherCfg.showIcons
                        onToggled: root.bar.applyLauncher({ showIcons: !root.bar.launcherCfg.showIcons })
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Changes apply the next time you open the launcher (SUPER+D). Avoid bar adds the bar's thickness + edge gap when the launcher is anchored to the same screen side."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
