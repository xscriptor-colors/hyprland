import QtQuick
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// StepperCard — card numérica de ancho completo (familia GuidePopup).
//
// Card s(44) r18 alpha(surface0, 0.4) + borde surface1: label s(13) text +
// spacer + botón − + valor s(13) Bold (ancho fijo s(52), centrado) + botón +.
// Botones s(28) r14: alpha(surface0, 0.4) + borde surface1; hover
// alpha(mauve, 0.15) + borde mauve; press scale 0.9.
// API: bar / label / value / dec() / inc().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: stp
    property var bar: null
    property string label: ""
    property string value: ""
    signal dec()
    signal inc()

    height: bar ? bar.s(44) : 44
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent" : Qt.alpha(bar.colors.surface0, 0.4)
    border.width: 1
    border.color: bar ? bar.colors.surface1 : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(15) : 15
        anchors.rightMargin: bar ? bar.s(10) : 10
        spacing: bar ? bar.s(8) : 8

        Text {
            text: stp.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            color: !bar ? "transparent" : bar.colors.text
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
        Rectangle {
            id: decBtn
            Layout.preferredWidth: bar ? bar.s(28) : 28
            Layout.preferredHeight: bar ? bar.s(28) : 28
            Layout.alignment: Qt.AlignVCenter
            radius: bar ? bar.s(14) : 14
            color: !bar ? "transparent" : (decMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
            border.width: 1
            border.color: !bar ? "transparent" : (decMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
            scale: decMa.pressed ? 0.9 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: "−"
                font.family: "Hack Nerd Font"
                font.pixelSize: bar ? bar.s(16) : 16
                color: bar ? bar.colors.text : "transparent"
            }
            MouseArea {
                id: decMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stp.dec()
            }
        }
        Text {
            text: stp.value
            font.family: "Hack Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: bar ? bar.s(13) : 13
            color: !bar ? "transparent" : bar.colors.text
            Layout.preferredWidth: bar ? bar.s(52) : 52
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
        }
        Rectangle {
            id: incBtn
            Layout.preferredWidth: bar ? bar.s(28) : 28
            Layout.preferredHeight: bar ? bar.s(28) : 28
            Layout.alignment: Qt.AlignVCenter
            radius: bar ? bar.s(14) : 14
            color: !bar ? "transparent" : (incMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
            border.width: 1
            border.color: !bar ? "transparent" : (incMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
            scale: incMa.pressed ? 0.9 : 1.0
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }
            Text {
                anchors.centerIn: parent
                text: "+"
                font.family: "Hack Nerd Font"
                font.pixelSize: bar ? bar.s(16) : 16
                color: bar ? bar.colors.text : "transparent"
            }
            MouseArea {
                id: incMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stp.inc()
            }
        }
    }
}
