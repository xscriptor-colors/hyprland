// ═══════════════════════════════════════════════════════════════════════════
// TopbarTab — pestaña "Topbar" de SettingsPopup, extraída del Component
// inline para poder compartirla (popup de settings + BarEditor).
//
// `host` = root de SettingsPopup: el cuerpo del tab quedó intacto y usa
// root.s(), root.<rol>, root.highlightedBox, etc. mediante el bloque de
// forwarding de abajo (mismos nombres que el root del popup).
// ═══════════════════════════════════════════════════════════════════════════

import QtQuick
import Quickshell

// ── BARRA (dock) ─────────────────────────────────────────────────────
// The bar is edited by the dedicated BarEditor (SUPER+SHIFT+D). This
// section is a clean gateway that opens it, instead of the old inline
// topbar editor (which was replaced by the position-agnostic dock).
Item {
    id: root

    // ════ Forwarding al host (SettingsPopup) ════
    // El cuerpo de este tab quedó intacto y sigue usando root.s(),
    // root.<rol>, root.highlightedBox… vía estos proxies.
    property var host: null
    readonly property color base: host ? host.base : "#363537"
    readonly property color mauve: host ? host.mauve : "#948ae3"
    readonly property color subtext0: host ? host.subtext0 : "#f7f1ff"
    readonly property color surface0: host ? host.surface0 : "#363537"
    readonly property color surface1: host ? host.surface1 : "#363537"
    readonly property color text: host ? host.text : "#f7f1ff"
    function s(val) { return host ? host.s(val) : val; }


    // ════ Cuerpo original del tab ════

    function scrollTo(y) {}
    function scrollToBox(approxItemY) {}

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: barCard.implicitHeight + root.s(40)
        clip: true
        boundsBehavior: Flickable.DragAndOvershootBounds

        Rectangle {
            id: barCard
            width: parent.width - root.s(20)
            radius: root.s(18)
            color: root.surface0
            border.color: root.surface1
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: root.s(18)
                spacing: root.s(12)

                Row {
                    spacing: root.s(10)
                    Rectangle {
                        width: root.s(40); height: root.s(40); radius: root.s(12)
                        color: root.mauve
                        Text { anchors.centerIn: parent; text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(20); color: root.base }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "Customize the bar"; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: root.s(15); color: root.text }
                        Text { text: "Position, palette, size, zones and modules"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(11); color: root.subtext0 }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: root.surface1; opacity: 0.6 }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "El dock se personaliza desde su propio editor (SUPER+SHIFT+D). Desde aquí puedes abrirlo, y todos los cambios se guardan en vivo y se sincronizan con las paletas de colores elegidas en la barra."
                    font.family: "Hack Nerd Font"
                    font.pixelSize: root.s(12)
                    lineHeight: 1.3
                    color: root.subtext0
                }

                // Open the BarEditor widget (same IPC the bar module uses).
                Rectangle {
                    width: root.s(180)
                    height: root.s(38)
                    radius: root.s(18)
                    color: openBarMa.containsMouse ? root.mauve : root.surface1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: root.s(8)
                        Text { text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(15); color: openBarMa.containsMouse ? root.base : root.mauve }
                        Text { text: "Open Dock Editor"; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(12); color: openBarMa.containsMouse ? root.base : root.text }
                    }
                    MouseArea {
                        id: openBarMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", "-c", "qs -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call main handleCommand open bar-editor ''"])
                    }
                }
            }
        }
    }
}
