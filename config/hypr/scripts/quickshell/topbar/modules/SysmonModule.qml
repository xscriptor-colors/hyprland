import QtQuick
import Quickshell
import "../../dock"

// System monitor — red accent island with CPU/RAM. Compact (vertical): two tiny
// stacked values so the info is still readable in a narrow dock.
ModulePill {
    id: mod

    accentRole: "color1"
    accentActive: bar.sysDataReady

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle system-monitor"])

    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uF0E4"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); color: mod.contentColor }
        Text { anchors.verticalCenter: parent.verticalCenter; text: bar.cpuPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); font.weight: Font.Black; color: mod.contentColor }
        Rectangle { width: bar.s(1); height: bar.s(16); color: colors.overlay0; opacity: 0.4 }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "\uF538"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(13); color: mod.contentColor }
        Text { anchors.verticalCenter: parent.verticalCenter; text: bar.ramPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); font.weight: Font.Black; color: mod.contentColor }
    }

    Column {
        visible: mod.compact
        spacing: 1

        Text { anchors.horizontalCenter: parent.horizontalCenter; text: bar.cpuPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(9); font.weight: Font.Black; color: mod.contentColor }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: bar.ramPercent; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(9); font.weight: Font.Black; color: mod.contentColor }
    }
}
