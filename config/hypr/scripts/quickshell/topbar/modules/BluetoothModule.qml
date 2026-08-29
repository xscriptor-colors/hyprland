import QtQuick
import Quickshell
import "../../dock"

// Bluetooth — orange accent island when on. Hidden on desktops (no BT hardware).
// Compact (vertical): icon only.
ModulePill {
    id: mod

    accentRole: "color4"
    accentActive: bar.isBtOn
    showState: !bar.isDesktop

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.btIcon
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(16)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.btDevice
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            width: Math.min(implicitWidth, bar.s(100)); elide: Text.ElideRight
            color: mod.contentColor
        }
    }

    Text {
        visible: mod.compact
        text: bar.btIcon
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
