import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// ToggleCard — card ON/OFF de ancho completo (familia GuidePopup).
//
// ON: alpha(mauve, 0.15) + borde mauve; OFF: alpha(surface0, 0.4) + borde
// surface1; hover → borde mauve; glifo mauve (ON) / subtext0 (OFF); label
// s(13) text; estado ON/OFF s(11) Bold; press scale 0.95 (150 ms OutQuart).
// El click solo emite toggled(): los handlers de la página aplican el valor
// invertido desde el modelo (no se muta `checked`, que es un binding).
// API: bar / icon / label / checked / toggled().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: tgl
    property var bar: null
    property string icon: ""
    property string label: ""
    property bool checked: false
    signal toggled()

    height: bar ? bar.s(44) : 44
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent"
        : tgl.checked
            ? Qt.alpha(bar.colors.mauve, 0.15)
            : Qt.alpha(bar.colors.surface0, 0.4)
    border.width: 1
    border.color: !bar ? "transparent"
        : (tgl.checked || tglMa.containsMouse) ? bar.colors.mauve : bar.colors.surface1
    scale: tglMa.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(15) : 15
        anchors.rightMargin: bar ? bar.s(15) : 15
        spacing: bar ? bar.s(10) : 10
        Text {
            visible: tgl.icon !== ""
            text: tgl.icon
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(16) : 16
            Layout.alignment: Qt.AlignVCenter
            color: !bar ? "transparent" : (tgl.checked ? bar.colors.mauve : bar.colors.subtext0)
        }
        Text {
            text: tgl.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            color: !bar ? "transparent" : bar.colors.text
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
        Text {
            text: tgl.checked ? "ON" : "OFF"
            font.family: "Hack Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: bar ? bar.s(11) : 11
            Layout.alignment: Qt.AlignVCenter
            color: !bar ? "transparent" : (tgl.checked ? bar.colors.mauve : bar.colors.subtext0)
        }
    }
    MouseArea {
        id: tglMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tgl.toggled()
    }
}
