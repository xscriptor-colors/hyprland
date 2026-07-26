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

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        property bool isHovered: timePillMouse.containsMouse
        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.95) : Qt.rgba(colors.base.r, colors.base.g, colors.base.b, 0.75)
        radius: bar.pillRadius(bar.barHeight)
        border.width: 1
        border.color: Qt.rgba(colors.text.r, colors.text.g, colors.text.b, isHovered ? 0.15 : 0.05)
        height: bar.barHeight
        width: timeText.implicitWidth + bar.s(36)

        Behavior on color { ColorAnimation { duration: 250 } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

        Text {
            id: timeText
            anchors.centerIn: parent
            text: bar.timeStr
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(16)
            font.weight: Font.Black
            color: colors.blue
        }

        MouseArea {
            id: timePillMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
        }
    }
}
