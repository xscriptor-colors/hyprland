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

    property bool initAnimTrigger: false
    Timer { running: mod.zoneReady && !mod.initAnimTrigger; interval: mod.slotIndex * 50; onTriggered: mod.initAnimTrigger = true }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        property bool isHovered: kbMouse.containsMouse
        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.6) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.4)
        radius: bar.pillRadius(bar.pillHeight); height: bar.pillHeight;
        border.width: bar.topbarBorderWidth
        border.color: colors[bar.topbarBorderColor] || colors.surface1
        clip: true

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            opacity: 1.0; Behavior on opacity { NumberAnimation { duration: 300 } }
            color: colors.color5
        }

        property real targetWidth: kbLayoutRow.implicitWidth + bar.s(24)
        width: targetWidth
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on color { ColorAnimation { duration: 200 } }

        opacity: mod.initAnimTrigger ? 1 : 0
        transform: Translate { y: mod.initAnimTrigger ? 0 : bar.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: kbLayoutRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: bar.s(12)
            spacing: bar.s(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰌌"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(16); color: colors.base }
            Text { anchors.verticalCenter: parent.verticalCenter; text: bar.kbLayout; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); font.weight: Font.Black; color: colors.base }
        }
        MouseArea { id: kbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"]) }
    }
}
