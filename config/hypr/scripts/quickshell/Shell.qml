//@ pragma UseQApplication
import QtQuick
import Quickshell
import "dock"
import "widgets"

ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup() }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup() }
    }

    Main {}
    Dock {}
    Floating {}
    Widgets {}
}
