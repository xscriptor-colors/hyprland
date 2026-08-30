import QtQuick
import Quickshell
import "../../dock"

// CUSTOMIZATION HOOK: icon/action/accent overridable from the mega menu.
ModulePill {
    id: mod

    padH: bar.s(6)
    idleRole: "text"
    hoverRole: "blue"

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])

    Text {
        text: "󰊨"
        font.family: bar.fontFamily
        font.pixelSize: bar.s(22)
        color: mod.contentColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
