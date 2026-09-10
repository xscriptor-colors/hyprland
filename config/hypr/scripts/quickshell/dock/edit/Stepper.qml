import QtQuick

// − value + stepper del BarEditor (Fase 4: familia GuidePopup).
// Botones: alpha(surface0, 0.4) + borde surface1; hover alpha(mauve, 0.15) +
// borde mauve; press scale 0.94 (150 ms OutQuart). API intacta: label/dec()/inc().
Row {
    id: stepper
    property var bar: null
    property string label: ""
    signal dec()
    signal inc()

    spacing: bar ? bar.s(6) : 6

    Rectangle {
        id: decPill
        width: bar ? bar.s(26) : 26; height: width; radius: width / 2
        color: !bar ? "transparent" : (decMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
        border.width: 1
        border.color: !bar ? "transparent" : (decMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
        scale: decMa.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Text { anchors.centerIn: parent; text: "−"; font.family: "Hack Nerd Font"; font.pixelSize: bar ? bar.s(16) : 16; color: bar ? bar.colors.text : "transparent" }
        MouseArea {
            id: decMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: stepper.dec()
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: stepper.label
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(12) : 12
        font.weight: Font.Black
        width: bar ? bar.s(42) : 42
        horizontalAlignment: Text.AlignHCenter
        color: bar ? bar.colors.text : "transparent"
    }
    Rectangle {
        id: incPill
        width: bar ? bar.s(26) : 26; height: width; radius: width / 2
        color: !bar ? "transparent" : (incMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
        border.width: 1
        border.color: !bar ? "transparent" : (incMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
        scale: incMa.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Text { anchors.centerIn: parent; text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: bar ? bar.s(16) : 16; color: bar ? bar.colors.text : "transparent" }
        MouseArea {
            id: incMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: stepper.inc()
        }
    }
}
