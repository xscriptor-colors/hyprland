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
        property bool isHovered: sysMouse.containsMouse
        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.6) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.4)
        radius: bar.pillRadius(bar.pillHeight); height: bar.pillHeight;
        clip: true

        Rectangle {
            anchors.fill: parent; radius: parent.radius
            opacity: bar.sysDataReady ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            color: colors.color1
        }

        property real targetWidth: sysLayoutRow.implicitWidth + bar.s(24)
        width: targetWidth
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on color { ColorAnimation { duration: 200 } }

        opacity: mod.initAnimTrigger ? 1 : 0
        transform: Translate { y: mod.initAnimTrigger ? 0 : bar.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: sysLayoutRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: bar.s(12)
            spacing: bar.s(10)
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\uF0E4"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); color: bar.sysDataReady ? colors.base : colors.subtext0 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: bar.cpuPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); font.weight: Font.Black; color: bar.sysDataReady ? colors.base : colors.text }
            Rectangle { width: bar.s(1); height: bar.s(16); color: colors.overlay0; opacity: 0.3 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "\uF538"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); color: bar.sysDataReady ? colors.base : colors.subtext0 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: bar.ramPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); font.weight: Font.Black; color: bar.sysDataReady ? colors.base : colors.text }
        }
        MouseArea { id: sysMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle system-monitor"]) }
    }
}
