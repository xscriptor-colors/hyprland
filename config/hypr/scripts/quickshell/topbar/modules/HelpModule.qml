import QtQuick
import Quickshell
import "../../dock"

// CUSTOMIZATION HOOK: action / icon / colors can be overridden from the mega menu
// via future dock.modules.help.{icon,action,accent}. Idle/hover roles are declared
// here as the defaults.
ModulePill {
    id: mod

    padH: bar.s(6)
    idleRole: "text"
    hoverRole: "teal"
    showState: bar.showHelpIcon

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])

    Text {
        text: "󰅖"
        font.family: bar.fontFamily
        font.pixelSize: bar.s(22)
        color: mod.contentColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
