import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: mod
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex
    required property real effectiveBorderWidth
    required property string effectiveBorderColor
    required property bool unified

    property real targetWidth: trayRepeater.count > 0 ? trayLayout.width + bar.s(24) : 0
    implicitWidth: targetWidth
    implicitHeight: bar.barHeight
    Behavior on implicitWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

    visible: targetWidth > 0
    opacity: targetWidth > 0 ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300 } }

    Row {
        id: trayLayout
        anchors.centerIn: parent
        spacing: bar.s(13)

        Repeater {
            id: trayRepeater
            model: SystemTray.items
            delegate: Image {
                id: trayIcon
                source: modelData.icon || ""
                fillMode: Image.PreserveAspectFit

                sourceSize: Qt.size(bar.s(18), bar.s(18))
                width: bar.s(18)
                height: bar.s(18)
                anchors.verticalCenter: parent.verticalCenter

                property bool isHovered: trayMouse.containsMouse
                property bool initAnimTrigger: false
                opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0

                Component.onCompleted: {
                    if (!bar.startupCascadeFinished) {
                        trayAnimTimer.interval = index * 50;
                        trayAnimTimer.start();
                    } else {
                        initAnimTrigger = true;
                    }
                }
                Timer {
                    id: trayAnimTimer
                    running: false
                    repeat: false
                    onTriggered: trayIcon.initAnimTrigger = true
                }

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
                            if (modelData.isMenuOnly || modelData.onlyMenu) {
                                menuAnchor.open();
                            } else if (typeof modelData.activate === "function") {
                                modelData.activate();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            if (typeof modelData.secondaryActivate === "function") {
                                modelData.secondaryActivate();
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.menu) {
                                menuAnchor.open();
                            } else if (typeof modelData.contextMenu === "function") {
                                modelData.contextMenu(mouse.x, mouse.y);
                            } else {
                                modelData.activate();
                            }
                        }
                    }
                }
            }
        }
    }
}
