import QtQuick

// ═══════════════════════════════════════════════════════════════════════════
// NavItem — fila de navegación del rail (Fase 4: paridad con GuidePopup).
//
// Réplica del tab del Guide (GP:468-530): la fila es transparente (la píldora
// activa, mauve, vive detrás en el root); hover inactivo alpha(surface1, 0.5)
// con ColorAnimation 150; activo → contenido crust, inactivo → subtext0;
// icono s(18) en slot s(24), label s(13) Bold(activo)/Medium(inactivo);
// contentShift s(6) con 400 ms OutExpo (GP:485-489).
// API: bar / icon / label / active / activated().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: nav
    property var bar: null
    property string icon: ""
    property string label: ""
    property bool active: false
    signal activated()

    height: bar ? bar.s(44) : 44
    radius: bar ? bar.s(18) : 18
    color: nav.active ? "transparent"
        : (navMa.containsMouse ? Qt.alpha(bar.colors.surface1, 0.5) : "transparent")
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        id: navRow
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(15) : 15
        spacing: bar ? bar.s(12) : 12
        // Desplaza icono+label s(6) al activarse (GP:485-489).
        property real contentShift: nav.active ? (bar ? bar.s(6) : 6) : 0
        Behavior on contentShift { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        transform: Translate { x: navRow.contentShift }

        Item {
            width: bar ? bar.s(24) : 24
            height: parent.height
            Text {
                anchors.centerIn: parent
                text: nav.icon
                font.family: "Hack Nerd Font"
                font.pixelSize: bar ? bar.s(18) : 18
                color: nav.active ? bar.colors.crust : bar.colors.subtext0
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: nav.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            font.weight: nav.active ? Font.Bold : Font.Medium
            color: nav.active ? bar.colors.crust : bar.colors.subtext0
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
    MouseArea {
        id: navMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nav.activated()
    }
}
