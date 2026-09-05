import QtQuick
import Quickshell
import "../../dock"

// ============================================================================
// Focus — island showing the currently focused window.
//
// Data comes from the dock's 1s watcher on `hyprctl activewindow -j`
// (bar.focusTitle / bar.focusIcon). The island collapses entirely when no
// window is focused (empty desktop). Click opens the app launcher.
//
// Compact (vertical dock): icon only, so it stays readable at pill width.
// ============================================================================

ModulePill {
    id: mod

    showState: bar.hasFocus

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle applauncher"])

    // --- horizontal: app icon + window title ----------------------------------
    Row {
        visible: mod.horizontal
        spacing: bar.s(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.focusIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.s(18)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.focusTitle
            font.family: bar.fontFamily
            font.weight: Font.Black
            font.pixelSize: bar.s(13)
            color: mod.contentColor
            width: Math.min(implicitWidth, bar.s(180))
            elide: Text.ElideRight
        }
    }

    // --- compact: icon only ----------------------------------------------------
    Text {
        visible: mod.compact
        text: bar.focusIcon
        font.family: bar.fontFamily
        font.pixelSize: bar.s(20)
        color: mod.contentColor
    }
}
