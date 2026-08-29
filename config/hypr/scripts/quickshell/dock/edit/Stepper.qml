import QtQuick

// − value + stepper for the DockEditor.
Row {
    id: stepper
    property var bar: null
    property string label: ""
    signal dec()
    signal inc()

    spacing: bar ? bar.s(6) : 6

    Rectangle {
        width: bar ? bar.s(26) : 26; height: width; radius: width / 2
        color: bar.colors.surface2
        Text { anchors.centerIn: parent; text: "−"; font.family: "Hack Nerd Font"; font.pixelSize: bar ? bar.s(16) : 16; color: bar.colors.text }
        MouseArea { anchors.fill: parent; onClicked: stepper.dec() }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: stepper.label
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(12) : 12
        font.weight: Font.Black
        width: bar ? bar.s(42) : 42
        horizontalAlignment: Text.AlignHCenter
        color: bar.colors.text
    }
    Rectangle {
        width: bar ? bar.s(26) : 26; height: width; radius: width / 2
        color: bar.colors.surface2
        Text { anchors.centerIn: parent; text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: bar ? bar.s(16) : 16; color: bar.colors.text }
        MouseArea { anchors.fill: parent; onClicked: stepper.inc() }
    }
}
