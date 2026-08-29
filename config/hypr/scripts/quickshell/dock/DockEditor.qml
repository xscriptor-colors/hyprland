import QtQuick
import QtQuick.Controls
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
// Matches the QuickShell widget aesthetic (SettingsPopup-style): a rounded
// panel with a single scrollable column of section cards (surface0 + surface1
// border). Every edit writes live to settings.json "dock" and the dock
// hot-reloads through its own watcher.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root

    property var notifModel: null
    property var liveNotifs: null
    property int layoutWidth: 0
    property int layoutHeight: 0
    implicitWidth: layoutWidth > 0 ? layoutWidth : s(900)
    implicitHeight: layoutHeight > 0 ? layoutHeight : s(700)

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

    // ════ PANEL (widget-style) ════
    Rectangle {
        anchors.fill: parent
        anchors.margins: s(10)
        radius: s(24)
        color: Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.94)
        border.width: s(1)
        border.color: colors.surface1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: s(16)
            spacing: s(10)

            // header
            Row {
                width: parent.width
                spacing: s(10)
                Rectangle {
                    width: s(34); height: s(34); radius: s(10)
                    color: colors.accent
                    Text { anchors.centerIn: parent; text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: colors.base }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Dock Editor"; font.family: "Hack Nerd Font"; font.pixelSize: s(17); font.weight: Font.Black; color: colors.text }
                    Text { text: "Personaliza la barra · SUPER+SHIFT+D · ESC cerrar"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: colors.overlay1 }
                }
            }
            Rectangle { width: parent.width; height: 1; color: colors.surface1; opacity: 0.5 }

            // scrollable cards
            Flickable {
                width: parent.width
                height: parent.height - s(64)
                contentHeight: cardsCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: cardsCol
                    width: parent.width
                    spacing: s(12)

                    // ── CARD: POSICIÓN ────────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface1
                        border.width: s(1); border.color: colors.surface2
                        height: posCol.implicitHeight + s(28)
                        Column {
                            id: posCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Posición" }
                            Row {
                                width: parent.width
                                spacing: s(8)
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "top";    label: "Arriba";    glyph: "↑" }
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "bottom"; label: "Abajo";     glyph: "↓" }
                            }
                            Row {
                                width: parent.width
                                spacing: s(8)
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "left";   label: "Izquierda"; glyph: "←" }
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "right";  label: "Derecha";   glyph: "→" }
                            }
                        }
                    }

                    // ── CARD: PALETA ──────────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface1
                        border.width: s(1); border.color: colors.surface2
                        height: palCol.implicitHeight + s(28)
                        Column {
                            id: palCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Paleta" }
                            Flickable {
                                width: parent.width
                                height: s(100)
                                contentWidth: palRow.width
                                clip: true
                                Row {
                                    id: palRow
                                    spacing: s(8)
                                    Repeater {
                                        model: root.palettes
                                        delegate: Item {
                                            required property var modelData
                                            property var pal: modelData
                                            width: s(70)
                                            height: s(100)
                                            Rectangle {
                                                width: parent.width
                                                height: s(70)
                                                radius: s(10)
                                                color: root.dock.palette === pal.slug ? colors.accent : colors.surface2
                                                opacity: root.dock.palette === pal.slug ? 1 : 0.5
                                                Behavior on color { ColorAnimation { duration: 150 } }
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
                                                            Repeater { model: [0,1,2]; delegate: Rectangle { width: s(12); height: s(8); radius: s(2); color: pal.colors[0] } }
                                                        }
                                                        Row {
                                                            spacing: s(3)
                                                            Repeater { model: [0,1,2]; delegate: Rectangle { width: s(12); height: s(8); radius: s(2); color: pal.colors[1 + index] } }
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: s(3)
                                                    width: s(14); height: s(14); radius: s(7)
                                                    visible: root.dock.palette === pal.slug
                                                    color: colors.base
                                                    Text { anchors.centerIn: parent; text: "✓"; font.family: "Hack Nerd Font"; font.pixelSize: s(9); color: colors.accent }
                                                }
                                            }
                                            Text {
                                                anchors.top: parent.top; anchors.topMargin: s(74)
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: pal.name
                                                font.family: "Hack Nerd Font"; font.pixelSize: s(10); font.weight: Font.Bold
                                                color: root.dock.palette === pal.slug ? colors.text : colors.overlay1
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: root.applyDock(Object.assign({}, root.dock, { palette: pal.slug }))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── CARD: ASPECTO ─────────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface1
                        border.width: s(1); border.color: colors.surface2
                        height: aspCol.implicitHeight + s(28)
                        Column {
                            id: aspCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(9)
                            SectionTitle { bar: root; text: "Aspecto" }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Redondez"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.roundness*100)+"%"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { roundness: Math.max(0, +(root.dock.roundness-0.1).toFixed(1)) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { roundness: Math.min(1, +(root.dock.roundness+0.1).toFixed(1)) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Grosor"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.thickness)+"px"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { thickness: Math.max(32, root.dock.thickness-4) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { thickness: Math.min(96, root.dock.thickness+4) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Margen del borde"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.edgeGap)+"px"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.max(0, root.dock.edgeGap-2) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.min(24, root.dock.edgeGap+2) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Relleno de islas"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.pillBg; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { pillBg: !root.dock.pillBg })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Relleno sólido"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.pillSolid; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { pillSolid: !root.dock.pillSolid })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Barra unificada"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.barBg; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { barBg: !root.dock.barBg })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Borde (global)"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(8)
                                    Stepper { bar: root; label: Math.round(root.dock.borderWidth)+"px"
                                        onDec: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.max(0, root.dock.borderWidth-1) }))
                                        onInc: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.min(8, root.dock.borderWidth+1) })) }
                                    ColorCycle { bar: root; role: root.dock.borderColor; onCycled: (role) => root.applyDock(Object.assign({}, root.dock, { borderColor: role })) }
                                }
                            }
                        }
                    }

                    // ── CARD: ZONAS ───────────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface1
                        border.width: s(1); border.color: colors.surface2
                        height: zonasCol.implicitHeight + s(28)
                        Column {
                            id: zonasCard
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(8)
                            Item {
                                width: parent.width
                                height: s(28)
                                SectionTitle { bar: root; text: "Zonas"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(8)
                                    EditPill { bar: root; modelData: "add"; text: "+ Añadir"; accentFill: true; onActivated: root.applyDock(DockLayout.addZone(root.dock, "start")) }
                                    EditPill { bar: root; modelData: "reset"; text: "Default"; onActivated: root.applyDock(DockLayout.defaultDock()) }
                                }
                            }
                            Column {
                                id: zonasCol
                                width: parent.width
                                spacing: s(8)
                                Repeater {
                                    model: root.dock.zones
                                    delegate: ZoneEditorCard {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        bar: root
                                        zoneData: modelData
                                        zoneIndex: index
                                    }
                                }
                            }
                        }
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
