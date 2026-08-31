// Throwaway test shell — loads the DockEditor via a Loader exactly like
// Main.qml does, to validate it compiles/renders without errors.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: w
    color: "transparent"
    width: 800
    height: 700
    anchors.top: true
    anchors.left: true
    margins { top: 10; left: 10 }

    Loader {
        anchors.fill: parent
        source: "dock/DockEditor.qml"
        onLoaded: console.log("[EDITOR] cargado OK")
    }
}
