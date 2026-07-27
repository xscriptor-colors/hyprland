import QtQuick
import Quickshell

Item {
    id: mod
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex
    required property real effectiveBorderWidth
    required property string effectiveBorderColor
    required property bool unified

    implicitWidth: pill.width
    implicitHeight: bar.barHeight

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        property bool isHovered: timePillMouse.containsMouse
        color: unified ? "transparent" : (bar.topbarPillBg ? (isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, bar.topbarPillSolid ? 1.0 : 0.95) : Qt.rgba(colors.base.r, colors.base.g, colors.base.b, bar.topbarPillSolid ? 1.0 : 0.75)) : "transparent")
        radius: unified ? 0 : bar.pillRadius(bar.barHeight)
        border.width: unified ? 0 : effectiveBorderWidth
        border.color: unified ? "transparent" : (colors[effectiveBorderColor] || colors.surface1)
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
