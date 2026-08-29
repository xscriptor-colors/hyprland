import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../dock"

// System tray — icon grid. Single row on top/bottom docks, a 2-column grid on
// left/right docks so the icons stay readable in the narrow bar.
ModulePill {
    id: mod

    noFill: true
    padH: bar.s(12)
    showState: trayRepeater.count > 0

    Item {
        id: trayHost
        width: showState ? (mod.compact ? bar.pillWidth : trayGrid.implicitWidth) : 0
        height: showState ? (mod.compact ? trayGrid.implicitHeight : bar.pillHeight) : 0

        Grid {
            id: trayGrid
            visible: mod.compact
            anchors.centerIn: parent
            columns: 2
            spacing: bar.s(4)
            Repeater { id: trayRepeaterC; model: SystemTray.items; delegate: trayDelegate }
        }

        Row {
            id: trayRow
            visible: mod.horizontal
            anchors.centerIn: parent
            spacing: bar.s(13)
            Repeater { id: trayRepeater; model: SystemTray.items; delegate: trayDelegate }
        }
    }

    Component {
        id: trayDelegate
        Image {
            id: trayIcon
            property required var modelData
            source: modelData.icon || ""
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(bar.s(18), bar.s(18))
            width: bar.s(18)
            height: bar.s(18)

            opacity: initAnimTrigger ? (trayMouse.containsMouse ? 1.0 : 0.8) : 0.0
            scale: initAnimTrigger ? (trayMouse.containsMouse ? 1.15 : 1.0) : 0.0

            property bool initAnimTrigger: false
            Component.onCompleted: {
                if (!bar.startupCascadeFinished) {
                    anim.interval = trayIcon.index * 50;
                    anim.start();
                } else initAnimTrigger = true;
            }
            Timer { id: anim; running: false; repeat: false; onTriggered: trayIcon.initAnimTrigger = true }
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            QsMenuAnchor {
                id: menuAnchor
                anchor.window: bar
                anchor.item: trayIcon
                menu: modelData.menu
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        if (modelData.isMenuOnly || modelData.onlyMenu) menuAnchor.open();
                        else if (typeof modelData.activate === "function") modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        if (typeof modelData.secondaryActivate === "function") modelData.secondaryActivate();
                    } else if (mouse.button === Qt.RightButton) {
                        if (modelData.menu) menuAnchor.open();
                        else if (typeof modelData.contextMenu === "function") modelData.contextMenu(mouse.x, mouse.y);
                        else modelData.activate();
                    }
                }
            }
        }
    }
}
