import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../WindowRegistry.js" as LayoutMath
import "DockLayout.js" as DockLayout
import "Colors.qml"
import "edit"

// ═══════════════════════════════════════════════════════════════════════════
// DockEditor — the dock mega menu (SUPER+SHIFT+D).
//
// Concentrates ALL dock customization: position, palette, appearance
// (roundness/fill/thickness/gap/border) and the zone/module layout. Every edit
// writes live to settings.json "dock"; the dock hot-reloads via its watcher.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // Widget contract (injected by Main.qml)
    property var notifModel: null
    property var liveNotifs: null
    property int layoutWidth: 0
    property int layoutHeight: 0
    implicitWidth: layoutWidth > 0 ? layoutWidth : s(780)
    implicitHeight: layoutHeight > 0 ? layoutHeight : s(680)

    property real uiScale: 1.0
    readonly property real baseScale: LayoutMath.getScale(Screen.width, Screen.height, root.uiScale)
    function s(val) { return LayoutMath.s(val, baseScale); }

    Colors { id: themeColors }
    readonly property var colors: themeColors

    property var dock: DockLayout.defaultDock()
    property var palettes: ([])
    property bool _dirty: false

    Timer { id: saveTimer; interval: 220; onTriggered: flushSave() }
    function markDirty() { _dirty = true; saveTimer.restart(); }
    function flushSave() {
        if (!_dirty) return;
        _dirty = false;
        Config.setSetting("dock", root.dock);
    }
    function applyDock(dock) { root.dock = dock; root.markDirty(); }
    function reload() { root.dock = DockLayout.getDock(Config.rawSettings); }

    Component.onCompleted: {
        reload();
        paletteReader.running = true;
        scaleReader.running = true;
    }

    Process {
        id: scaleReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null | jq -r '.uiScale // 1'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseFloat(this.text.trim());
                if (!isNaN(v) && v > 0) root.uiScale = v;
            }
        }
    }

    Process {
        id: paletteReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/dock/palettes/index.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.palettes = JSON.parse(this.text.trim()); } catch (e) {}
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: s(10)
        radius: s(24)
        color: Qt.rgba(colors.base.r, colors.base.g, colors.base.b, 0.94)
        border.width: s(1)
        border.color: colors.surface1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: s(16)

            Row {
                width: parent.width
                spacing: s(12)
                Text { anchors.verticalCenter: parent.verticalCenter; text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: s(24); color: colors.accent }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "Dock Editor"; font.family: "Hack Nerd Font"; font.pixelSize: s(20); font.weight: Font.Black; color: colors.text }
                Item { width: parent.width - s(260); height: 1 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "SUPER+SHIFT+D · ESC cerrar"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: colors.overlay1 }
            }

            Rectangle { width: parent.width; height: 1; color: colors.surface1; opacity: 0.5 }

            Flickable {
                width: parent.width
                height: parent.height - s(86)
                contentHeight: bodyCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: bodyCol
                    width: parent.width
                    spacing: s(12)

                    // ── POSICIÓN ──────────────────────────────────────────────
                    SectionTitle { bar: root; text: "Posición" }
                    Row {
                        spacing: s(8)
                        Repeater {
                            model: ["top", "bottom", "left", "right"]
                            delegate: EditPill {
                                required property string modelData
                                bar: root
                                text: modelData === "top" ? "↑ Arriba" : modelData === "bottom" ? "↓ Abajo" : modelData === "left" ? "← Izquierda" : "→ Derecha"
                                active: root.dock.position === modelData
                                onActivated: root.applyDock(Object.assign({}, root.dock, { position: modelData }))
                            }
                        }
                    }

                    // ── PALETA ────────────────────────────────────────────────
                    SectionTitle { bar: root; text: "Paleta" }
                    Flow {
                        width: parent.width
                        spacing: s(6)
                        Repeater {
                            model: root.palettes
                            delegate: Item {
                                required property var modelData
                                property var pal: modelData
                                width: s(78)
                                height: s(46)
                                Rectangle {
                                    anchors.fill: parent
                                    radius: s(10)
                                    color: root.dock.palette === pal.slug ? colors.accent : colors.surface1
                                    opacity: root.dock.palette === pal.slug ? 1 : 0.4
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: s(2)
                                        radius: s(8)
                                        color: colors.base
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: s(3)
                                            Row {
                                                spacing: s(3)
                                                Repeater {
                                                    model: [0, 1, 2]
                                                    delegate: Rectangle { width: s(14); height: s(9); radius: s(3); color: pal.colors[0] }
                                                }
                                            }
                                            Row {
                                                spacing: s(3)
                                                Repeater {
                                                    model: [0, 1, 2]
                                                    delegate: Rectangle { width: s(14); height: s(9); radius: s(3); color: pal.colors[1 + index] }
                                                }
                                            }
                                        }
                                    }
                                }
                                Text {
                                    anchors.top: parent.bottom
                                    anchors.topMargin: s(2)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: pal.name
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(9)
                                    color: root.dock.palette === pal.slug ? colors.text : colors.overlay1
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.applyDock(Object.assign({}, root.dock, { palette: pal.slug }))
                                }
                            }
                        }
                    }
                    Item { width: 1; height: s(6) }

                    // ── ASPECTO ───────────────────────────────────────────────
                    SectionTitle { bar: root; text: "Aspecto" }
                    Rectangle {
                        width: parent.width
                        height: s(152)
                        radius: s(16)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        Column {
                            anchors.fill: parent
                            anchors.margins: s(12)
                            spacing: s(8)
                            Row {
                                width: parent.width
                                EditLabel { bar: root; text: "Redondez" }
                                Item { width: parent.width - s(220); height: 1 }
                                Stepper {
                                    bar: root
                                    label: Math.round(root.dock.roundness * 100) + "%"
                                    onDec: root.applyDock(Object.assign({}, root.dock, { roundness: Math.max(0, +(root.dock.roundness - 0.1).toFixed(1)) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { roundness: Math.min(1, +(root.dock.roundness + 0.1).toFixed(1)) }))
                                }
                            }
                            Row {
                                width: parent.width
                                EditLabel { bar: root; text: "Grosor" }
                                Item { width: parent.width - s(220); height: 1 }
                                Stepper {
                                    bar: root
                                    label: Math.round(root.dock.thickness) + "px"
                                    onDec: root.applyDock(Object.assign({}, root.dock, { thickness: Math.max(32, root.dock.thickness - 4) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { thickness: Math.min(96, root.dock.thickness + 4) }))
                                }
                            }
                            Row {
                                width: parent.width
                                EditLabel { bar: root; text: "Margen del borde" }
                                Item { width: parent.width - s(220); height: 1 }
                                Stepper {
                                    bar: root
                                    label: Math.round(root.dock.edgeGap) + "px"
                                    onDec: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.max(0, root.dock.edgeGap - 2) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.min(24, root.dock.edgeGap + 2) }))
                                }
                            }
                            Row {
                                width: parent.width
                                EditLabel { bar: root; text: "Relleno de islas" }
                                Item { width: parent.width - s(220); height: 1 }
                                ToggleSwitch { bar: root; checked: root.dock.pillBg; onToggled: root.applyDock(Object.assign({}, root.dock, { pillBg: !root.dock.pillBg })) }
                            }
                            Row {
                                width: parent.width
                                EditLabel { bar: root; text: "Relleno sólido" }
                                Item { width: parent.width - s(220); height: 1 }
                                ToggleSwitch { bar: root; checked: root.dock.pillSolid; onToggled: root.applyDock(Object.assign({}, root.dock, { pillSolid: !root.dock.pillSolid })) }
                            }
                        }
                    }

                    // ── BORDE GLOBAL ──────────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        height: s(52)
                        radius: s(16)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        Row {
                            anchors.fill: parent
                            anchors.margins: s(12)
                            EditLabel { bar: root; text: "Borde (global)" }
                            Item { width: parent.width - s(280); height: 1 }
                            Stepper {
                                bar: root
                                label: Math.round(root.dock.borderWidth) + "px"
                                onDec: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.max(0, root.dock.borderWidth - 1) }))
                                onInc: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.min(8, root.dock.borderWidth + 1) }))
                            }
                            ColorCycle {
                                bar: root
                                role: root.dock.borderColor
                                onCycled: (role) => root.applyDock(Object.assign({}, root.dock, { borderColor: role }))
                            }
                        }
                    }

                    // ── ZONAS ─────────────────────────────────────────────────
                    SectionTitle { bar: root; text: "Zonas" }
                    Repeater {
                        model: root.dock.zones
                        delegate: ZoneEditorCard {
                            required property var modelData
                            required property int index
                            bar: root
                            zoneData: modelData
                            zoneIndex: index
                        }
                    }

                    Row {
                        spacing: s(8)
                        EditPill { bar: root; modelData: "add"; text: "+ Añadir zona"; accentFill: true; onActivated: root.applyDock(DockLayout.addZone(root.dock, "start")) }
                        EditPill { bar: root; modelData: "reset"; text: "Restaurar por defecto"; onActivated: root.applyDock(DockLayout.defaultDock()) }
                    }
                    Item { width: 1; height: s(12) }
                }
            }
        }
    }

    Keys.onEscapePressed: {
        flushSave();
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh close"]);
        event.accepted = true;
    }
}
