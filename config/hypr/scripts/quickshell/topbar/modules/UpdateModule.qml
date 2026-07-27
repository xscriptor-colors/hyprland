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
    visible: pill.width > 0 || pill.opacity > 0

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        property bool isHovered: updateMouse.containsMouse
        color: unified ? "transparent" : (bar.topbarPillBg ? (isHovered ? Qt.rgba(colors.green.r, colors.green.g, colors.green.b, 0.15) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.4)) : "transparent")
        radius: unified ? 0 : bar.pillRadius(bar.pillHeight)
        border.width: unified ? 0 : effectiveBorderWidth
        border.color: unified ? "transparent" : (colors[effectiveBorderColor] || colors.surface1)

        width: bar.isUpdateVisible ? bar.s(34) : 0
        height: bar.pillHeight

        opacity: bar.isUpdateVisible ? 1.0 : 0.0
        clip: false

        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: colors.green
            z: -1

            SequentialAnimation on scale {
                running: bar.isUpdateVisible && !pill.isHovered
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.3; duration: 2000; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: bar.isUpdateVisible && !pill.isHovered
                loops: Animation.Infinite
                NumberAnimation { from: 0.15; to: 0.0; duration: 2000; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰚰"
            font.family: "Hack Nerd Font"; font.pixelSize: bar.s(22)
            color: pill.isHovered ? colors.text : colors.green
            Behavior on color { ColorAnimation { duration: 200 } }

            rotation: pill.isHovered ? 360 : 0
            Behavior on rotation {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutBack
                }
            }

            scale: pill.isHovered ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        }

        MouseArea {
            id: updateMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                bar.updateAvailable = false;
                bar.forceUpdateShow = false;
                Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"]);
            }
        }
    }
}
