import QtQuick
import Quickshell
import "../../dock"

// Clock — text island, blue accent. Compact (vertical): HH:mm.
ModulePill {
    id: mod

    fullHeight: true
    idleRole: "blue"
    padH: bar.s(18)

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])

    Text {
        visible: mod.horizontal
        text: bar.timeStr
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(16)
        font.weight: Font.Black
        color: mod.contentColor
    }

    // Compact: just HH:mm, clamped to the pill so it never overflows.
    Text {
        visible: mod.compact
        width: Math.max(bar.s(28), bar.pillWidth - bar.s(8))
        text: bar.timeStr.length >= 5 ? bar.timeStr.substring(0, 5) : bar.timeStr
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(14)
        font.weight: Font.Black
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: mod.contentColor
    }
}
