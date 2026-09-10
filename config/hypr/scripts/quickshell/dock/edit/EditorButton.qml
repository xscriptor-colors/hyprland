import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// EditorButton — botón de acción del BarEditor (Fase 4, familia GuidePopup).
//
// Réplica del patrón GP:970-987 (nav button): superficie alpha(surface0, 0.4)
// + borde surface1 1 px, hover alpha(accent, 0.15) + borde del acento, press
// scale 0.95 (150 ms OutQuart), contenido centrado en RowLayout con icono
// opcional s(16) + label Bold. `active` lo pinta relleno (acento + crust).
// API: bar / icon / label / active / accentRole / compact / activated().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: btn
    property var bar: null
    property string icon: ""
    property string label: ""
    property bool active: false
    property string accentRole: "mauve"
    // Filas horizontales compactas: alto s(36) en vez de s(44).
    property bool compact: false
    signal activated()

    readonly property color accent: (bar && bar.colors && bar.colors[accentRole] !== undefined)
        ? bar.colors[accentRole] : "#948ae3"

    height: bar ? bar.s(compact ? 36 : 44) : (compact ? 36 : 44)
    implicitWidth: btnRow.implicitWidth + (bar ? bar.s(compact ? 28 : 36) : (compact ? 28 : 36))
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent"
        : btn.active
            ? btn.accent
            : (btnMa.containsMouse ? Qt.alpha(btn.accent, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
    border.width: 1
    border.color: !bar ? "transparent"
        : btn.active
            ? btn.accent
            : (btnMa.containsMouse ? btn.accent : bar.colors.surface1)
    scale: btnMa.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        id: btnRow
        anchors.centerIn: parent
        spacing: bar ? bar.s(8) : 8
        Text {
            visible: btn.icon !== ""
            text: btn.icon
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(16) : 16
            color: !bar ? "transparent" : (btn.active ? bar.colors.crust : btn.accent)
        }
        Text {
            text: btn.label
            font.family: "Hack Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: bar ? bar.s(13) : 13
            color: !bar ? "transparent" : (btn.active ? bar.colors.crust : bar.colors.text)
        }
    }
    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }
}
