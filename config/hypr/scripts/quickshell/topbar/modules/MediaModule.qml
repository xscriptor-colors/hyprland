import QtQuick
import Quickshell

Item {
    id: mod
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex

    implicitWidth: box.width
    implicitHeight: bar.barHeight
    visible: box.width > 0 || box.opacity > 0

    Rectangle {
        id: box
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        radius: bar.s(28); border.width: 0
        height: bar.barHeight
        clip: false

        width: bar.isMediaActive ? innerMediaLayout.implicitWidth + bar.s(24) : 0
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

        opacity: bar.isMediaActive ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Item {
            id: mediaLayoutContainer
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: bar.s(12)
            height: parent.height
            width: innerMediaLayout.implicitWidth

            opacity: bar.isMediaActive ? 1.0 : 0.0
            transform: Translate {
                x: bar.isMediaActive ? 0 : bar.s(-20)
                Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
            }
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            Row {
                id: innerMediaLayout
                anchors.verticalCenter: parent.verticalCenter
                spacing: bar.width < 1920 ? bar.s(10) : bar.s(16)

                MouseArea {
                    id: mediaInfoMouse
                    width: infoLayout.width
                    height: innerMediaLayout.height
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])

                    Row {
                        id: infoLayout
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.s(13)

                        scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                        Rectangle {
                            width: bar.s(32); height: bar.s(32); radius: bar.s(16); color: colors.surface1
                            border.width: bar.musicData.status === "Playing" ? 1 : 0
                            border.color: colors.mauve
                            clip: true
                            Image {
                                anchors.fill: parent;
                                source: bar.displayArtUrl || "";
                                fillMode: Image.PreserveAspectCrop
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.rgba(colors.mauve.r, colors.mauve.g, colors.mauve.b, 0.2)
                            }
                        }
                        Column {
                            spacing: -2
                            anchors.verticalCenter: parent.verticalCenter
                            property real maxColWidth: bar.width < 1920 ? bar.s(120) : bar.s(180)
                            width: maxColWidth

                            Text {
                                text: bar.displayTitle;
                                font.family: "Hack Nerd Font";
                                font.weight: Font.Black;
                                font.pixelSize: bar.s(13);
                                color: colors.text;
                                width: parent.width
                                elide: Text.ElideRight;
                            }
                            Text {
                                text: bar.displayTime;
                                font.family: "Hack Nerd Font";
                                font.weight: Font.Black;
                                font.pixelSize: bar.s(13);
                                color: colors.subtext0;
                                width: parent.width
                                elide: Text.ElideRight;
                            }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: bar.width < 1920 ? bar.s(4) : bar.s(10)
                    Item {
                        width: bar.s(24); height: bar.s(24);
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent; text: "󰒮"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(26);
                            color: prevMouse.containsMouse ? colors.text : colors.overlay2;
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: prevMouse.containsMouse ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        }
                        MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "previous"]); bar.refreshMusic(); } }
                    }
                    Item {
                        width: bar.s(28); height: bar.s(28);
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent; text: bar.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(30);
                            color: playMouse.containsMouse ? colors.green : colors.text;
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: playMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        }
                        MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); bar.refreshMusic(); } }
                    }
                    Item {
                        width: bar.s(24); height: bar.s(24);
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent; text: "󰒭"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(26);
                            color: nextMouse.containsMouse ? colors.text : colors.overlay2;
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: nextMouse.containsMouse ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                        }
                        MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "next"]); bar.refreshMusic(); } }
                    }
                }
            }
        }
    }
}
