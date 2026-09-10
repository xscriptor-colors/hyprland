import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// EffectSlider — fila-card con slider para el panel Settings (grupo System).
//
// Réplica del DragSlider de window-controls/WindowControls.qml (track surface1,
// relleno del acento al 50%, knob redondo con hover scale 1.2 OutBack y
// arrastre stepped) presentada como card de fila de la familia guide.
//
// API: bar / icon / label / from / to / step / value / accentColor / decimals /
//      suffix + signal edited(real v) (al arrastrar/soltar).
// El valor es bidireccional: onValueChanged sincroniza el slider salvo mientras
// se arrastra; cada cambio emite edited() para que la página persista.
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: slider
    property var bar: null
    property string icon: ""
    property string label: ""
    property real from: 0
    property real to: 1
    property real step: 0.05
    property real value: from
    property color accentColor: "#948ae3"
    property int decimals: 0
    property string suffix: ""
    signal edited(real v)

    // Posición interna del slider: sigue a `value` salvo durante el arrastre.
    property real current: value
    onValueChanged: if (!dragArea.pressed) current = value

    readonly property real frac: (to - from) === 0 ? 0
                                : Math.max(0, Math.min(1, (current - from) / (to - from)))
    readonly property string display: decimals > 0
        ? Number(current).toFixed(decimals)
        : (Math.round(current) + suffix)

    height: bar ? bar.s(44) : 44
    radius: bar ? bar.s(18) : 18
    color: bar ? Qt.alpha(bar.colors.surface0, 0.4) : "transparent"
    border.width: 1
    border.color: bar ? bar.colors.surface1 : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(15) : 15
        anchors.rightMargin: bar ? bar.s(10) : 10
        spacing: bar ? bar.s(10) : 10

        Text {
            text: slider.icon
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(14) : 14
            color: slider.accentColor
            Layout.preferredWidth: bar ? bar.s(20) : 20
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: slider.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(11) : 11
            color: bar ? bar.colors.subtext0 : "transparent"
            Layout.preferredWidth: bar ? bar.s(110) : 110
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }

        // ── Track + relleno + knob (mismo look que DragSlider) ──
        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: bar ? bar.s(30) : 30
            Layout.alignment: Qt.AlignVCenter
            radius: bar ? bar.s(6) : 6
            color: bar ? bar.colors.surface1 : "transparent"

            Rectangle {
                id: fillBar
                height: parent.height
                radius: parent.radius
                color: slider.accentColor
                opacity: 0.5
                width: parent.width * slider.frac
                Behavior on width { enabled: !dragArea.pressed; NumberAnimation { duration: 80 } }
            }

            Rectangle {
                id: knob
                y: (parent.height - height) / 2
                width: bar ? bar.s(18) : 18
                height: width
                radius: width / 2
                color: slider.accentColor
                scale: dragArea.containsMouse || dragArea.pressed ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                x: Math.max(0, Math.min(parent.width - width, parent.width * slider.frac - width / 2))
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) { updateFromMouse(mouse.x); }
                onPositionChanged: function(mouse) { if (pressed) updateFromMouse(mouse.x); }
                function updateFromMouse(mx) {
                    let frac = Math.max(0, Math.min(1, mx / width));
                    let raw = slider.from + frac * (slider.to - slider.from);
                    let stepped = Math.round(raw / slider.step) * slider.step;
                    stepped = Math.max(slider.from, Math.min(slider.to, stepped));
                    // Redondeo fino para evitar 0.30000000000000004.
                    stepped = Math.round(stepped * 1000000) / 1000000;
                    slider.current = stepped;
                    slider.edited(stepped);
                }
            }
        }

        Text {
            text: slider.display
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(12) : 12
            font.weight: Font.Bold
            color: bar ? bar.colors.text : "transparent"
            Layout.preferredWidth: bar ? bar.s(48) : 48
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
