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
        property bool isHovered: searchMouse.containsMouse
        color: unified ? "transparent" : (bar.topbarPillBg ? (isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, bar.topbarPillSolid ? 1.0 : 0.6) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, bar.topbarPillSolid ? 1.0 : 0.4)) : "transparent")
        radius: unified ? 0 : bar.pillRadius(bar.pillHeight)
        border.width: unified ? 0 : effectiveBorderWidth
        border.color: unified ? "transparent" : (colors[effectiveBorderColor] || colors.surface1)
        height: bar.pillHeight; width: bar.s(34)

        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: "󰍉"
            font.family: "Hack Nerd Font"; font.pixelSize: bar.s(22)
            color: pill.isHovered ? colors.blue : colors.text
            Behavior on color { ColorAnimation { duration: 200 } }
            scale: pill.isHovered ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        }
        MouseArea {
            id: searchMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])
        }
    }
}
