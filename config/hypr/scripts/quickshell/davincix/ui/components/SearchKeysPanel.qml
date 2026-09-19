// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components — SearchKeysPanel
//
// Panel de API keys de proveedores (las que pidan). Los datos vienen del
// kernel (`davincix.sh keys list`: NAME|label|where|0-1); guardar delega en
// `keys set`.
//
// Estilo: réplica del panel principal (DavincixFilterBar) — contenedor
// mantle 0.90 + borde surface2 + radio s(18), y dentro pills surface0/
// surface1 con radio s(13), bordes y tipografías del mismo lenguaje.
// Se renderiza centrado bajo la tira de wallpapers, ancho de la búsqueda.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Item {
    id: panelRoot

    required property var ctx        // picker root (s(), estado)
    required property var theme      // Colors instance (paleta activa)

    property bool open: false
    property var keys: []            // [{name,label,where,set}]

    signal saveRequested(string name, string value)
    signal closed()

    visible: open
    z: 45
    anchors.fill: parent

    // Click fuera → cerrar (dim suave, como el ConfirmDialog).
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.25)

        MouseArea {
            anchors.fill: parent
            onClicked: panelRoot.closed()
        }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: ctx.s(14)
        width: ctx.s(440)
        height: rows.implicitHeight + ctx.s(20)
        radius: ctx.s(18)

        color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.90)
        border.color: theme.surface2
        border.width: 1

        // Los clicks dentro de la card no cierran el panel.
        MouseArea { anchors.fill: parent }

        Column {
            id: rows
            anchors.fill: parent
            anchors.margins: ctx.s(10)
            spacing: ctx.s(8)

            Repeater {
                model: panelRoot.keys

                delegate: Row {
                    width: rows.width
                    spacing: ctx.s(8)

                    // Pill del proveedor: mismo estilo que el botón de
                    // transición de la barra (surface0, borde surface1).
                    Rectangle {
                        id: provPill
                        width: provRow.width + ctx.s(20)
                        height: ctx.s(36)
                        radius: ctx.s(13)

                        color: theme.surface0
                        border.color: theme.surface1
                        border.width: 1

                        Row {
                            id: provRow
                            anchors.centerIn: parent
                            spacing: ctx.s(6)

                            Rectangle {
                                width: ctx.s(8)
                                height: ctx.s(8)
                                radius: ctx.s(4)
                                color: modelData.set ? theme.green : theme.yellow
                            }

                            Text {
                                text: modelData.label
                                color: theme.text
                                font.family: "Hack Nerd Font"
                                font.pixelSize: ctx.s(11)
                            }

                            Text {
                                text: modelData.set ? "set" : "not set"
                                color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.55)
                                font.family: "Hack Nerd Font"
                                font.pixelSize: ctx.s(10)
                            }
                        }
                    }

                    // Input: mismo estilo que la caja de búsqueda (surface2
                    // al 0.8, borde theme.text al enfocar).
                    Rectangle {
                        id: inputBox
                        width: rows.width - provPill.width - savePill.width - ctx.s(16)
                        height: ctx.s(36)
                        radius: ctx.s(13)

                        color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8)
                        border.color: keyInput.activeFocus ? theme.text : theme.surface1
                        border.width: keyInput.activeFocus ? ctx.s(2) : 1

                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        TextInput {
                            id: keyInput
                            anchors.fill: parent
                            anchors.leftMargin: ctx.s(12)
                            anchors.rightMargin: ctx.s(12)
                            verticalAlignment: TextInput.AlignVCenter
                            color: theme.text
                            font.family: "Hack Nerd Font"
                            font.pixelSize: ctx.s(11)
                            clip: true
                            selectionColor: Qt.alpha(theme.mauve, 0.5)
                            selectedTextColor: theme.text

                            onAccepted: panelRoot.saveRequested(modelData.name, keyInput.text)
                        }

                        // Placeholder manual (TextInput no lo soporta aquí).
                        Text {
                            visible: keyInput.text === ""
                            anchors.left: parent.left
                            anchors.leftMargin: ctx.s(12)
                            anchors.right: parent.right
                            anchors.rightMargin: ctx.s(12)
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.set
                                ? "replace " + modelData.name + "..."
                                : "paste " + modelData.name + " · free at " + modelData.where
                            color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.35)
                            font.family: "Hack Nerd Font"
                            font.pixelSize: ctx.s(11)
                            elide: Text.ElideRight
                        }
                    }

                    // Guardar: mismo estilo que el botón submit de la caja de
                    // búsqueda (borde surface2 → theme.text, hover surface1).
                    Rectangle {
                        id: savePill
                        width: saveRow.width + ctx.s(22)
                        height: ctx.s(36)
                        radius: ctx.s(13)
                        property bool ready: keyInput.text.trim() !== ""

                        color: (saveMouse.containsMouse && ready) ? theme.surface1 : theme.surface0
                        border.color: ready && saveMouse.containsMouse ? theme.text : theme.surface1
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            id: saveRow
                            anchors.centerIn: parent
                            spacing: ctx.s(6)

                            Text {
                                text: "\uF00C"  // fa-check
                                color: savePill.ready
                                    ? theme.text
                                    : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.35)
                                font.family: "Hack Nerd Font"
                                font.pixelSize: ctx.s(11)
                            }

                            Text {
                                text: "Save"
                                color: savePill.ready
                                    ? theme.text
                                    : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.35)
                                font.family: "Hack Nerd Font"
                                font.pixelSize: ctx.s(11)
                            }
                        }

                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: savePill.ready
                            cursorShape: Qt.PointingHandCursor
                            onClicked: panelRoot.saveRequested(modelData.name, keyInput.text)
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: panelRoot.open
        onActivated: panelRoot.closed()
    }
}
