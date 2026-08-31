import QtQuick
import Quickshell
import "../../dock"

// Volume — yellow accent island when audio active. Click opens the volume popup;
// the mouse wheel adjusts the volume directly. Compact (vertical): icon only.
ModulePill {
    id: mod

    accentRole: "color3"
    accentActive: bar.isSoundActive

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle volume"])
    onWheelUp: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/volume.sh up"])
    onWheelDown: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/volume.sh down"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.volIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.s(16)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.volPercent
            font.family: bar.fontFamily
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: mod.contentColor
        }
    }

    Text {
        visible: mod.compact
        text: bar.volIcon
        font.family: bar.fontFamily
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
