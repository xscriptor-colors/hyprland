import QtQuick
import Quickshell
import "../../dock"

// Keyboard layout — purple accent island. Compact (vertical dock): icon only.
ModulePill {
    id: mod

    accentRole: "color5"
    accentActive: true

    onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "main", "next"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(16)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.kbLayout
            font.family: "Hack Nerd Font"
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: mod.contentColor
        }
    }

    // Compact: icon only.
    Text {
        visible: mod.compact
        text: "󰌌"
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
