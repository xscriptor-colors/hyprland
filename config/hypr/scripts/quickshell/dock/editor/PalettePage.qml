import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// PalettePage — DockEditor tab: shared palette selector + live base16 editor.
//
// Fase 5 (look Guide): título s(24) Black, grid 3 columnas de cards de paleta
// (template cards GP:1276-1302, activo mauve/crust) y card hero r21 para el
// editor base16 (chips + TextField estilo card).
// Contract: receives the DockEditor root as `bar` (bar.s(), bar.colors,
// bar.dock, bar.palettes, bar.applyDock, bar.paletteEditOpen,
// bar.slotDescriptors, bar.registerSlot/finishSlotEdit/resetActivePalette/
// activeSlug/checkBackupExists/syncSlotValues, ...). NEVER touches ids of the
// editor root. Exposes the scroll Flickable via `flickable`.
//
// The palette cards write through bar.applyDock({ palette }); the inline
// base16 editor registers its rows with the root (registerSlot) and commits
// hexes through the root's debounced atomic palette-file writer
// (finishSlotEdit). bar.colors is the root's own Colors instance.
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
                text: "Palette"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: bar.s(24)
                color: bar.colors.text
            }

            // Grid 3 columnas de cards de paleta (GP:1276-1302)
            GridLayout {
                width: parent.width
                columns: 3
                columnSpacing: bar.s(10)
                rowSpacing: bar.s(10)
                Repeater {
                    model: root.bar.palettes
                    delegate: Rectangle {
                        required property var modelData
                        property var pal: modelData
                        readonly property bool isSel: root.bar.dock.palette === pal.slug
                        Layout.fillWidth: true
                        height: bar.s(45)
                        radius: bar.s(18)
                        color: !bar ? "transparent"
                            : (isSel ? bar.colors.mauve
                                     : (palMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.1) : Qt.alpha(bar.colors.surface0, 0.4)))
                        border.width: 1
                        border.color: !bar ? "transparent"
                            : ((isSel || palMa.containsMouse) ? bar.colors.mauve : bar.colors.surface1)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: bar.s(10)
                            spacing: bar.s(10)
                            Item {
                                Layout.preferredWidth: bar.s(24)
                                Layout.preferredHeight: bar.s(24)
                                Column {
                                    anchors.centerIn: parent
                                    spacing: bar.s(2)
                                    Row {
                                        spacing: bar.s(2)
                                        Repeater {
                                            model: [0, 1]
                                            delegate: Rectangle { width: bar.s(9); height: bar.s(9); radius: bar.s(2); color: pal.colors[index] }
                                        }
                                    }
                                    Row {
                                        spacing: bar.s(2)
                                        Repeater {
                                            model: [0, 1]
                                            delegate: Rectangle { width: bar.s(9); height: bar.s(9); radius: bar.s(2); color: pal.colors[2 + index] }
                                        }
                                    }
                                }
                            }
                            Text {
                                text: pal.name
                                font.family: "Hack Nerd Font"
                                font.weight: isSel ? Font.Bold : Font.Medium
                                font.pixelSize: bar.s(12)
                                color: !bar ? "transparent" : (isSel ? bar.colors.crust : bar.colors.text)
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: palMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.bar.applyDock(Object.assign({}, root.bar.dock, { palette: pal.slug }))
                        }
                    }
                }
            }

            // Fila de acciones: Edit colors / Reset
            Row {
                width: parent.width
                spacing: bar.s(10)
                EditorButton {
                    bar: root.bar
                    icon: "󰏘"
                    label: "Edit colors"
                    active: root.bar.paletteEditOpen
                    onActivated: {
                        root.bar.paletteEditOpen = !root.bar.paletteEditOpen;
                        if (root.bar.paletteEditOpen) {
                            root.bar.syncSlotValues();
                            root.bar.checkBackupExists();
                        }
                    }
                }
                EditorButton {
                    bar: root.bar
                    label: "Reset"
                    opacity: root.bar._hasSessionBackup ? 1 : 0.45
                    onActivated: root.bar.resetActivePalette()
                }
            }

            EditLabel {
                bar: bar
                width: parent.width
                visible: !bar.paletteEditOpen
                text: root.bar.paletteEditOpen ? ("Editing " + root.bar.activeSlug() + (root.bar._hasSessionBackup ? " · snapshot ready" : " · first edit saves a snapshot"))
                                               : "Recolor the active palette file live."
                font.pixelSize: bar.s(12)
                color: bar.colors.subtext0
                wrapMode: Text.WordWrap
            }

            // ── Card hero: editor base16 (visible mientras paletteEditOpen) ──
            // 18 slots (color0..15 + background + foreground), 3 por línea.
            // Los slots se registran en el root (registerSlot) y los commits
            // van por finishSlotEdit → escritura jq atómica agrupada.
            Rectangle {
                width: parent.width
                visible: bar.paletteEditOpen
                radius: bar.s(21)
                color: Qt.alpha(bar.colors.surface0, 0.4)
                border.width: 1
                border.color: bar.colors.surface1
                height: editCol.height + bar.s(30)

                Column {
                    id: editCol
                    x: bar.s(15)
                    y: bar.s(15)
                    width: parent.width - bar.s(30)
                    spacing: bar.s(10)
                    Flow {
                        id: slotFlow
                        width: parent.width
                        spacing: bar.s(8)
                        Repeater {
                            model: root.bar.slotDescriptors
                            delegate: Item {
                                required property var modelData
                                width: (slotFlow.width - bar.s(16)) / 3
                                height: bar.s(30)
                                Row {
                                    anchors.fill: parent
                                    spacing: bar.s(6)
                                    Rectangle {
                                        id: chip
                                        width: bar.s(18)
                                        height: bar.s(18)
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: bar.s(6)
                                        border.width: 1
                                        border.color: bar.colors.surface2
                                    }
                                    Text {
                                        text: modelData.label
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: bar.s(64)
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: bar.s(12)
                                        font.weight: Font.Bold
                                        color: bar.colors.text
                                    }
                                    TextField {
                                        id: hexField
                                        width: bar.s(96)
                                        height: bar.s(28)
                                        anchors.verticalCenter: parent.verticalCenter
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: bar.s(13)
                                        color: bar.colors.text
                                        selectByMouse: true
                                        maximumLength: 7
                                        validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
                                        background: Rectangle {
                                            color: Qt.alpha(bar.colors.surface0, 0.4)
                                            radius: bar.s(13)
                                            border.width: 1
                                            border.color: hexField.activeFocus
                                                ? bar.colors.mauve
                                                : (hexField.acceptableInput ? bar.colors.surface1 : bar.colors.red)
                                        }
                                        onEditingFinished: root.bar.finishSlotEdit(hexField, modelData.key)
                                        onActiveFocusChanged: {
                                            // Commit al perder el foco (click en otra fila / cierre).
                                            if (!hexField.activeFocus) root.bar.finishSlotEdit(hexField, modelData.key);
                                        }
                                    }
                                }
                                Component.onCompleted: root.bar.registerSlot(modelData.key, hexField, chip)
                            }
                        }
                    }
                    EditLabel {
                        bar: bar
                        width: parent.width
                        text: "Edits apply live to the dock, window borders and desktop widgets. Reset restores the session snapshot. Other palettes are untouched."
                        font.pixelSize: bar.s(12)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
