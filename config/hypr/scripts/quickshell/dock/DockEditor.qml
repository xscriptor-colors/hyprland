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
// Two-pane settings UI (sidebar navigation + content). Layout uses explicit
// anchors with a fixed-width sidebar (no nested panel RowLayout — that caused
// the content pane to collapse to 4px). Every edit writes live to settings.json
// "dock"; the dock hot-reloads via its own watcher.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root

    property var notifModel: null
    property var liveNotifs: null
    property int layoutWidth: 0
    property int layoutHeight: 0
    implicitWidth: layoutWidth > 0 ? layoutWidth : s(920)
    implicitHeight: layoutHeight > 0 ? layoutHeight : s(720)

    property real uiScale: 1.0
    readonly property real baseScale: LayoutMath.getScale(Screen.width, Screen.height, root.uiScale)
    function s(val) { return LayoutMath.s(val, baseScale); }

    Colors { id: themeColors }
    readonly property var colors: themeColors

    property var dock: DockLayout.defaultDock()
    property var palettes: ([])
    property bool _dirty: false
    property int currentSection: 0

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

    // ════ PANEL SHELL ════
    Rectangle {
        anchors.fill: parent
        anchors.margins: s(10)
        radius: s(24)
        color: Qt.rgba(colors.base.r, colors.base.g, colors.base.b, 0.95)
        border.width: s(1)
        border.color: colors.surface1
        clip: true

        Item {
            anchors.fill: parent
            anchors.margins: s(14)

            // ── SIDEBAR (fixed width, anchored left) ──────────────────────────
            Column {
                id: sideBar
                width: s(180)
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: s(6)

                Row {
                    width: parent.width
                    spacing: s(8)
                    Text { text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: s(22); anchors.verticalCenter: parent.verticalCenter; color: colors.accent }
                    Text { text: "Dock"; font.family: "Hack Nerd Font"; font.pixelSize: s(17); font.weight: Font.Black; anchors.verticalCenter: parent.verticalCenter; color: colors.text }
                }
                Rectangle { width: parent.width; height: 1; color: colors.surface1; opacity: 0.5 }

                NavItem { width: parent.width; bar: root; icon: "󰁪"; label: "Posición"; active: currentSection === 0; onActivated: root.currentSection = 0 }
                NavItem { width: parent.width; bar: root; icon: "󰨷"; label: "Paleta"; active: currentSection === 1; onActivated: root.currentSection = 1 }
                NavItem { width: parent.width; bar: root; icon: "󰦖"; label: "Aspecto"; active: currentSection === 2; onActivated: root.currentSection = 2 }
                NavItem { width: parent.width; bar: root; icon: "󰕪"; label: "Zonas"; active: currentSection === 3; onActivated: root.currentSection = 3 }

                Rectangle { width: parent.width; height: 1; color: colors.surface1; opacity: 0.5 }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "SUPER+SHIFT+D\nESC para cerrar"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(10)
                    color: colors.overlay1
                }
            }

            // divider between sidebar and content
            Rectangle {
                width: 1
                anchors.left: sideBar.right
                anchors.leftMargin: s(14)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: colors.surface1
                opacity: 0.5
            }

            // ── CONTENT (anchored right of sidebar) ───────────────────────────
            Item {
                id: contentArea
                anchors.left: sideBar.right
                anchors.leftMargin: s(28)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Flickable {
                    id: flick
                    anchors.fill: parent
                    contentHeight: contentPane.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentPane
                        width: parent.width
                        spacing: s(14)

                        // ════ SECCIÓN: POSICIÓN ════
                        Column {
                            id: posSection
                            width: parent.width
                            visible: currentSection === 0
                            spacing: s(10)

                            SectionTitle { bar: root; text: "Posición de la barra" }

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

                        // ════ SECCIÓN: PALETA ════
                        Column {
                            width: parent.width
                            visible: currentSection === 1
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Paleta de colores" }
                            Flow {
                                width: parent.width
                                spacing: s(8)
                                Repeater {
                                    model: root.palettes
                                    delegate: Item {
                                        required property var modelData
                                        property var pal: modelData
                                        width: s(92)
                                        height: s(74)
                                        Rectangle {
                                            width: parent.width
                                            height: s(56)
                                            radius: s(12)
                                            color: root.dock.palette === pal.slug ? colors.accent : colors.surface1
                                            opacity: root.dock.palette === pal.slug ? 1 : 0.45
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: s(2)
                                                radius: s(10)
                                                color: colors.base
                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: s(3)
                                                    Row {
                                                        spacing: s(3)
                                                        Repeater {
                                                            model: [0, 1, 2]
                                                            delegate: Rectangle { width: s(15); height: s(10); radius: s(3); color: pal.colors[0] }
                                                        }
                                                    }
                                                    Row {
                                                        spacing: s(3)
                                                        Repeater {
                                                            model: [0, 1, 2]
                                                            delegate: Rectangle { width: s(15); height: s(10); radius: s(3); color: pal.colors[1 + index] }
                                                        }
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                anchors.right: parent.right; anchors.top: parent.top
                                                anchors.margins: s(4)
                                                width: s(16); height: s(16); radius: s(8)
                                                visible: root.dock.palette === pal.slug
                                                color: colors.base
                                                Text { anchors.centerIn: parent; text: "✓"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: colors.accent }
                                            }
                                        }
                                        Text {
                                            anchors.top: parent.top
                                            anchors.topMargin: s(60)
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: pal.name
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: s(10)
                                            font.weight: Font.Bold
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

                        // ════ SECCIÓN: ASPECTO ════
                        Column {
                            width: parent.width
                            visible: currentSection === 2
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Aspecto y tamaño" }

                            Rectangle {
                                width: parent.width
                                height: s(300)
                                radius: s(16)
                                color: colors.surface0
                                border.width: s(1); border.color: colors.surface1
                                Column {
                                    anchors.fill: parent
                                    anchors.margins: s(14)
                                    spacing: s(10)
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
                                    Row {
                                        width: parent.width
                                        EditLabel { bar: root; text: "Barra unificada" }
                                        Item { width: parent.width - s(220); height: 1 }
                                        ToggleSwitch { bar: root; checked: root.dock.barBg; onToggled: root.applyDock(Object.assign({}, root.dock, { barBg: !root.dock.barBg })) }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: s(56)
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
                        }

                        // ════ SECCIÓN: ZONAS ════
                        Column {
                            width: parent.width
                            visible: currentSection === 3
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Zonas y módulos" }

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

                            Row {
                                width: parent.width
                                spacing: s(8)
                                EditPill { bar: root; modelData: "add"; text: "+ Añadir zona"; accentFill: true; onActivated: root.applyDock(DockLayout.addZone(root.dock, "start")) }
                                EditPill { bar: root; modelData: "reset"; text: "Restaurar por defecto"; onActivated: root.applyDock(DockLayout.defaultDock()) }
                            }
                        }
                        Item { width: 1; height: s(12) }
                    }
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
