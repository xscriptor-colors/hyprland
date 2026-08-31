import QtQuick
import Quickshell
import "../../dock"

// Network — cyan accent island when connected/ethernet, standard island when off.
// Compact (vertical): icon only.
ModulePill {
    id: mod

    accentRole: "color6"
    accentActive: bar.showEthernet ? (bar.ethStatus === "Connected") : bar.isWifiOn

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.showEthernet ? "󰈀" : bar.wifiIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.s(16)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.showEthernet ? bar.ethStatus : (bar.isWifiOn ? (bar.wifiSsid !== "" ? bar.wifiSsid : "On") : "Off")
            font.family: bar.fontFamily
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            width: Math.min(implicitWidth, bar.s(100)); elide: Text.ElideRight
            color: mod.contentColor
        }
    }

    Text {
        visible: mod.compact
        text: bar.showEthernet ? "󰈀" : bar.wifiIcon
        font.family: bar.fontFamily
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
