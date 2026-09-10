import QtQuick
import QtQuick.Layouts

// Selector de posición del editor SERP (Fase 4: familia GuidePopup).
// Inactivo: alpha(surface0, 0.4) + borde surface1; hover alpha(mauve, 0.1) +
// borde mauve; activo: relleno mauve + contenido crust; press scale 0.98.
// API intacta: bar / pos / label / glyph / activated().
Rectangle {
    id: card
    property var bar: null
    property string pos: ""
    property string label: ""
    property string glyph: ""
    signal activated()

    readonly property bool isActive: card.bar && card.bar.serp && String(card.bar.serp.position) === card.pos

    height: bar ? bar.s(60) : 60
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent"
        : card.isActive
            ? bar.colors.mauve
            : (cardMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.1) : Qt.alpha(bar.colors.surface0, 0.4))
    border.width: 1
    border.color: !bar ? "transparent"
        : card.isActive
            ? bar.colors.mauve
            : (cardMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
    scale: cardMa.pressed ? 0.98 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: bar ? bar.s(8) : 8
        Text {
            text: card.glyph
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(22) : 22
            font.weight: Font.Black
            color: !bar ? "transparent" : (card.isActive ? bar.colors.crust : bar.colors.text)
        }
        Text {
            text: card.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            font.weight: Font.Bold
            color: !bar ? "transparent" : (card.isActive ? bar.colors.crust : bar.colors.text)
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
