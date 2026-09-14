// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components — ConfirmDialog
//
// Overlay de confirmación genérico (dim + card con dos acciones). Emite
// confirmed()/dismissed(); el picker root decide qué hacer en cada caso.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Item {
    id: confirmRoot

    required property var ctx        // picker root (s() + estado)
    required property var theme      // Colors instance

    property bool open: false
    property string title: ""
    property string message: ""

    signal confirmed()
    signal dismissed()

    visible: open
    z: 50
    anchors.fill: parent

    // Fondo atenuado: cierra al hacer click fuera de la card.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.45)
        Behavior on color { ColorAnimation { duration: 250 } }

        MouseArea {
            anchors.fill: parent
            onClicked: confirmRoot.dismissed()
        }
    }

    Rectangle {
        id: dialogCard
        anchors.centerIn: parent
        width: Math.min(ctx.s(420), confirmRoot.parent.width - ctx.s(60))
        height: ctx.s(150)
        radius: ctx.s(16)
        color: theme.mantle
        border.color: theme.surface2
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: ctx.s(18)
            spacing: ctx.s(8)

            Text {
                text: confirmRoot.title
                color: theme.text
                font.family: "Hack Nerd Font"
                font.pixelSize: ctx.s(15)
                font.bold: true
            }

            Text {
                text: confirmRoot.message
                color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                font.family: "Hack Nerd Font"
                font.pixelSize: ctx.s(13)
                elide: Text.ElideMiddle
                width: parent.width
            }

            Item { width: 1; height: ctx.s(6) }

            Row {
                anchors.right: parent.right
                spacing: ctx.s(10)

                // Cancel.
                Rectangle {
                    width: cancelText.implicitWidth + ctx.s(30)
                    height: ctx.s(36)
                    radius: ctx.s(12)
                    color: cancelMouse.containsMouse ? theme.surface1 : theme.surface0
                    border.color: theme.surface1
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: theme.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: ctx.s(13)
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmRoot.dismissed()
                    }
                }

                // Confirm (acción destructiva: acento mauve).
                Rectangle {
                    width: confirmText.implicitWidth + ctx.s(30)
                    height: ctx.s(36)
                    radius: ctx.s(12)
                    color: confirmMouse.containsMouse
                        ? Qt.alpha(theme.mauve, 0.8)
                        : Qt.alpha(theme.mauve, 0.6)
                    border.color: theme.mauve
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: confirmText
                        anchors.centerIn: parent
                        text: "Delete"
                        color: theme.crust
                        font.family: "Hack Nerd Font"
                        font.pixelSize: ctx.s(13)
                        font.bold: true
                    }

                    MouseArea {
                        id: confirmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: confirmRoot.confirmed()
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: confirmRoot.open
        onActivated: confirmRoot.dismissed()
    }
}
