import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// OptionCard — card de opción estilo GuidePopup (GP:1276-1302).
//
// Inactiva: alpha(surface0, 0.4) + borde surface1; hover alpha(accent, 0.1) +
// borde del acento; activa: relleno accent + glifo/label crust (label Bold);
// press scale 0.98 (150 ms OutQuart). Contenido: RowLayout margins s(10) con
// glifo s(16) en slot s(24) + label s(12).
// API: bar / icon / label / active / accentRole / activated().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: card
    property var bar: null
    property string icon: ""
    property string label: ""
    property bool active: false
    property string accentRole: "mauve"
    signal activated()

    readonly property color accent: (bar && bar.colors && bar.colors[accentRole] !== undefined)
        ? bar.colors[accentRole] : "#948ae3"

    height: bar ? bar.s(45) : 45
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent"
        : card.active
            ? card.accent
            : (cardMa.containsMouse ? Qt.alpha(card.accent, 0.1) : Qt.alpha(bar.colors.surface0, 0.4))
    border.width: 1
    border.color: !bar ? "transparent"
        : (card.active || cardMa.containsMouse) ? card.accent : bar.colors.surface1
    scale: cardMa.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: bar ? bar.s(10) : 10
        spacing: bar ? bar.s(10) : 10
        Item {
            Layout.preferredWidth: bar ? bar.s(24) : 24
            Layout.alignment: Qt.AlignVCenter
            Text {
                anchors.centerIn: parent
                text: card.icon
                font.family: "Hack Nerd Font"
                font.pixelSize: bar ? bar.s(16) : 16
                color: !bar ? "transparent" : (card.active ? bar.colors.crust : card.accent)
            }
        }
        Text {
            text: card.label
            font.family: "Hack Nerd Font"
            font.weight: card.active ? Font.Bold : Font.Medium
            font.pixelSize: bar ? bar.s(12) : 12
            color: !bar ? "transparent" : (card.active ? bar.colors.crust : bar.colors.text)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }
    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
