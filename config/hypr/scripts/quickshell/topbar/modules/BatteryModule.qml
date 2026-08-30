import QtQuick
import Quickshell
import "../../dock"

// Battery — accent island whose color follows the charge state (bar.batDynamicColor:
// green charging, red ≤20%, text otherwise). Desktops show a power icon only.
// Compact (vertical): icon only.
ModulePill {
    id: mod

    accentColor: bar.batDynamicColor
    accentActive: true

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.isDesktop ? "" : bar.batIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.isDesktop ? bar.s(18) : bar.s(16)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !bar.isDesktop
            text: bar.batPercent
            font.family: bar.fontFamily
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: mod.contentColor
        }
    }

    Text {
        visible: mod.compact
        text: bar.isDesktop ? "" : bar.batIcon
        font.family: bar.fontFamily
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
