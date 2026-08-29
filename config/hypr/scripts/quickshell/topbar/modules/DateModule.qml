import QtQuick
import Quickshell
import "../../dock"

// Date — soft base-tone island with the typewriter date. Hidden in vertical docks
// (the clock already carries the day info; reduced = less clutter).
ModulePill {
    id: mod

    fullHeight: true
    bgRole: "base"
    bgHoverRole: "base"
    idleRole: "subtext0"
    padH: bar.s(18)
    showState: mod.horizontal

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])

    Text {
        text: bar.dateStr
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(11)
        font.weight: Font.Bold
        color: mod.contentColor
    }
}
