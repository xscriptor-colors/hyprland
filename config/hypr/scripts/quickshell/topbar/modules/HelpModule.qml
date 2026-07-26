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
        property bool isHovered: helpMouse.containsMouse
        color: isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.6) : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.4)
        radius: bar.s(20)

        property real targetWidth: bar.showHelpIcon ? bar.s(34) : 0
        width: targetWidth
        height: bar.pillHeight
        opacity: bar.showHelpIcon ? 1.0 : 0.0
        clip: true

        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on color { ColorAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: "Hack Nerd Font"; font.pixelSize: bar.s(22)
            color: pill.isHovered ? colors.teal : colors.text
            Behavior on color { ColorAnimation { duration: 200 } }
            scale: pill.isHovered ? 1.15 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        }
        MouseArea {
            id: helpMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
        }
    }
}
