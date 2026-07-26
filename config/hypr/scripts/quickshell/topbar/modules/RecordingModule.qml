import QtQuick
import Quickshell

Item {
    id: mod
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex

    implicitWidth: pill.width
    implicitHeight: bar.barHeight
    visible: pill.width > 0 || pill.opacity > 0

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        property bool isHovered: recMouse.containsMouse

        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.95) : Qt.rgba(colors.base.r, colors.base.g, colors.base.b, 0.75)
        radius: bar.s(28)
        border.width: 1
        border.color: Qt.rgba(colors.text.r, colors.text.g, colors.text.b, isHovered ? 0.15 : 0.05)

        property real targetWidth: bar.isRecording ? bar.barHeight : 0
        width: targetWidth
        height: bar.barHeight

        opacity: bar.isRecording ? 1.0 : 0.0
        clip: true

        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 300 } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            id: recIcon
            anchors.centerIn: parent
            text: ""
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(20)
            color: colors.red

            SequentialAnimation on opacity {
                running: bar.isRecording && !pill.isHovered
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
            SequentialAnimation on scale {
                running: bar.isRecording && !pill.isHovered
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }

        MouseArea {
            id: recMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                bar.isRecording = false;
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/screenshot.sh"]);
            }
        }
    }
}
