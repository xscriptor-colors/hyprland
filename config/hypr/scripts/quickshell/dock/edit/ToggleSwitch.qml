import QtQuick

// on/off toggle for the DockEditor.
Rectangle {
    id: tgl
    property var bar: null
    property bool checked: false
    signal toggled()

    width: bar ? bar.s(46) : 46
    height: bar ? bar.s(26) : 26
    radius: height / 2
    color: checked ? bar.colors.accent : bar.colors.surface1
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: tgl.height - (bar ? bar.s(6) : 6)
        height: width
        radius: width / 2
        color: bar.colors.base
        x: tgl.checked ? tgl.width - width - (bar ? bar.s(3) : 3) : (bar ? bar.s(3) : 3)
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; onClicked: { tgl.checked = !tgl.checked; tgl.toggled(); } }
}
