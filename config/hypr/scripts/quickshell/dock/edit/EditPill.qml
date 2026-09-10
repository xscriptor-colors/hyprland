import QtQuick

// Opción segmentada del BarEditor (Fase 4: familia GuidePopup).
// Inactiva: alpha(surface0, 0.4) + borde surface1; hover: alpha(mauve, 0.12) +
// borde mauve; activa: relleno mauve + texto crust; press scale 0.95 (150 ms).
// API intacta: bar / modelData / text / active / accentFill / activated().
Rectangle {
    id: pill
    property var bar: null
    property var modelData: null
    property string text: ""
    property bool active: false
    property bool accentFill: false
    signal activated()

    height: bar ? bar.s(34) : 34
    implicitWidth: txt.implicitWidth + (bar ? bar.s(24) : 24)
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent"
        : (pill.accentFill || pill.active)
            ? bar.colors.mauve
            : (pillMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.12) : Qt.alpha(bar.colors.surface0, 0.4))
    border.width: 1
    border.color: !bar ? "transparent"
        : (pill.accentFill || pill.active)
            ? bar.colors.mauve
            : (pillMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
    scale: pillMa.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Text {
        id: txt
        anchors.centerIn: parent
        text: pill.text
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(12) : 12
        font.weight: Font.Bold
        color: !bar ? "transparent" : ((pill.active || pill.accentFill) ? bar.colors.crust : bar.colors.text)
    }
    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.activated()
    }
}
