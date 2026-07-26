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
        property bool isHovered: wifiMouse.containsMouse
        radius: bar.s(20); height: bar.pillHeight;
        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.6) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.4)
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: bar.s(20)
            opacity: bar.showEthernet ? (bar.ethStatus === "Connected" ? 1.0 : 0.0) : (bar.isWifiOn ? 1.0 : 0.0)
            Behavior on opacity { NumberAnimation { duration: 300 } }
            color: colors.color6
        }

        property real targetWidth: wifiLayoutRow.implicitWidth + bar.s(24)
        width: targetWidth
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

        scale: isHovered ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on color { ColorAnimation { duration: 200 } }

        opacity: mod.initAnimTrigger ? 1 : 0
        transform: Translate { y: mod.initAnimTrigger ? 0 : bar.s(15); Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        Row {
            id: wifiLayoutRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: bar.s(12)
            spacing: bar.s(10)
            Text {
                anchors.verticalCenter: parent.verticalCenter;
                text: bar.showEthernet ? "󰈀" : bar.wifiIcon;
                font.family: "Hack Nerd Font"; font.pixelSize: bar.s(16);
                color: bar.showEthernet ? (bar.ethStatus === "Connected" ? colors.base : colors.subtext0) : (bar.isWifiOn ? colors.base : colors.subtext0)
            }
            Text {
                id: wifiText
                anchors.verticalCenter: parent.verticalCenter
                text: bar.showEthernet ? bar.ethStatus : ((bar.isWifiOn ? (bar.wifiSsid !== "" ? bar.wifiSsid : "On") : "Off"))
                visible: text !== ""
                font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); font.weight: Font.Black;
                color: bar.showEthernet ? (bar.ethStatus === "Connected" ? colors.base : colors.text) : (bar.isWifiOn ? colors.base : colors.text);
                width: Math.min(implicitWidth, bar.s(100)); elide: Text.ElideRight
            }
        }
        MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"]) }
    }
}
