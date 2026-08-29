import QtQuick
import Quickshell
import "../../dock"

// Update indicator — green accent island + pulse ring while an update is pending.
ModulePill {
    id: mod

    padH: bar.s(6)
    accentRole: "green"
    accentActive: bar.isUpdateVisible
    pulse: true
    showState: bar.isUpdateVisible

    onClicked: {
        bar.updateAvailable = false;
        bar.forceUpdateShow = false;
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"]);
    }

    Text {
        text: "󰚰"
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(22)
        color: mod.contentColor
        Behavior on color { ColorAnimation { duration: 200 } }

        rotation: mod.hovered ? 360 : 0
        Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }
    }
}
