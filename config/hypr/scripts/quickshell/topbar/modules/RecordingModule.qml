import QtQuick
import Quickshell
import "../../dock"

// Recording indicator — red accent island + blinking icon while recording.
ModulePill {
    id: mod

    padH: bar.s(6)
    accentRole: "red"
    accentActive: bar.isRecording
    pulse: true
    showState: bar.isRecording

    onClicked: {
        bar.isRecording = false;
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/screenshot.sh"]);
    }

    Text {
        text: ""
        font.family: "Hack Nerd Font"
        font.pixelSize: bar.s(20)
        color: mod.contentColor

        SequentialAnimation on opacity {
            running: bar.isRecording && !mod.hovered
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        }
    }
}
