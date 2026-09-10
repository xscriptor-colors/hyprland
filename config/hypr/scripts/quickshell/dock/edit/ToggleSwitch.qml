import QtQuick

// on/off toggle del DockEditor (Fase 4: familia GuidePopup).
// Track: surface1 (off) → mauve (on); handle: text (off) → crust (on);
// press scale 0.95 (200 ms OutBack). API intacta: checked / toggled().
Rectangle {
    id: tgl
    property var bar: null
    property bool checked: false
    signal toggled()

    width: bar ? bar.s(46) : 46
    height: bar ? bar.s(26) : 26
    radius: height / 2
    color: !bar ? "transparent" : (checked ? bar.colors.mauve : bar.colors.surface1)
    Behavior on color { ColorAnimation { duration: 150 } }
    scale: tglMa.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    Rectangle {
        width: tgl.height - (bar ? bar.s(6) : 6)
        height: width
        radius: width / 2
        color: !bar ? "transparent" : (tgl.checked ? bar.colors.crust : bar.colors.text)
        Behavior on color { ColorAnimation { duration: 150 } }
        x: tgl.checked ? tgl.width - width - (bar ? bar.s(3) : 3) : (bar ? bar.s(3) : 3)
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: tglMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { tgl.checked = !tgl.checked; tgl.toggled(); }
    }
}
