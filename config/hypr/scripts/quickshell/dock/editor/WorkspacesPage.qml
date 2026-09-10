import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// WorkspacesPage — BarEditor tab: empty-workspace marker style.
//
// Fase 5 (look Guide): título s(24) Black + grid 2×2 de OptionCards
// (template cards GP:1276-1302, activo mauve/crust) + FieldCard para el
// carácter custom (visible solo con marcador "custom").
// Contract: receives the BarEditor root as `bar` (bar.s(), bar.colors,
// bar.dock, bar.applyDock, ...). NEVER touches ids of the editor root.
// Exposes the scroll Flickable via `flickable`.
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
                        text: "Workspaces"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // Grid 2×2 de marcadores (cards template GP:1276-1302)
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "123"
                            label: "Numbers"
                            accentRole: "blue"
                            active: root.bar.dock.workspacesMarker === "number"
                            onActivated: root.bar.applyDock(Object.assign({}, root.bar.dock, { workspacesMarker: "number" }))
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "···"
                            label: "Dots"
                            active: root.bar.dock.workspacesMarker === "dot"
                            onActivated: root.bar.applyDock(Object.assign({}, root.bar.dock, { workspacesMarker: "dot" }))
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "abc"
                            label: "Letters"
                            accentRole: "green"
                            active: root.bar.dock.workspacesMarker === "letter"
                            onActivated: root.bar.applyDock(Object.assign({}, root.bar.dock, { workspacesMarker: "letter" }))
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "✦"
                            label: "Custom"
                            accentRole: "peach"
                            active: root.bar.dock.workspacesMarker === "custom"
                            onActivated: root.bar.applyDock(Object.assign({}, root.bar.dock, { workspacesMarker: "custom" }))
                        }
                    }

                    // Carácter custom (solo marcador custom): FieldCard
                    FieldCard {
                        width: parent.width
                        bar: root.bar
                        visible: bar.dock.workspacesMarker === "custom"
                        label: "Character"
                        value: root.bar.dock.workspacesMarkerText || ""
                        fieldWidth: 110
                        maxLength: 4
                        onEdited: (text) => {
                            let v = text.trim().slice(0, 4);
                            if (v !== root.bar.dock.workspacesMarkerText) {
                                root.bar.applyDock(Object.assign({}, root.bar.dock, { workspacesMarkerText: v }));
                            }
                        }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Only for empty workspaces — occupied ones keep showing their app icons. Tip: the Container bg option in each zone adds a themed background behind its islands without unifying them."
                        font.pixelSize: bar.s(12)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
