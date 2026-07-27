import QtQuick
import Quickshell

Item {
    id: mod
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex
    required property real effectiveBorderWidth
    required property string effectiveBorderColor
    required property bool unified

    implicitWidth: box.width
    implicitHeight: bar.barHeight
    visible: box.width > 0 || box.opacity > 0

    Rectangle {
        id: box
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"
        radius: bar.pillRadius(bar.barHeight)
        border.width: unified ? 0 : effectiveBorderWidth
        border.color: unified ? "transparent" : (colors[effectiveBorderColor] || colors.surface1)
        height: bar.barHeight
        clip: false

        width: bar.wsModel.count > 0 ? wsLayout.implicitWidth + bar.s(20) : 0

        // Keeps the last workspace pills out of the way of the settings panel
        // when a media pill is also competing for horizontal space.
        property bool limitActive: bar.isSettingsOpen && bar.isMediaActive

        opacity: bar.wsModel.count > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Rectangle {
            id: activeHighlight
            y: (box.height - bar.s(32)) / 2
            height: bar.s(32)
            radius: bar.pillRadius(bar.s(32))
            color: colors.mauve
            z: 0

            property int prevIdx: 0
            property int curIdx: bar.wsModel.activeIndex

            onCurIdxChanged: {
                if (curIdx > prevIdx) {
                    rightAnim.duration = 200; leftAnim.duration = 350;
                } else if (curIdx < prevIdx) {
                    leftAnim.duration = 200; rightAnim.duration = 350;
                }
                prevIdx = curIdx;
            }

            // itemAt() is not reactive on its own: depending on the pill count too
            // makes this re-resolve once the Repeater has actually built its items,
            // which otherwise leaves the highlight parked at x = 0.
            property int pillCount: wsPillRepeater.count
            property var activePill: pillCount > curIdx ? wsPillRepeater.itemAt(curIdx) : null
            property real targetLeft: activePill ? wsLayout.x + activePill.x : 0
            property real targetRight: activePill ? targetLeft + activePill.width : bar.s(32)

            property real actualLeft: targetLeft
            property real actualRight: targetRight

            Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 250; easing.type: Easing.OutExpo } }
            Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 250; easing.type: Easing.OutExpo } }

            x: actualLeft
            width: actualRight - actualLeft
            opacity: bar.wsModel.count > 0 ? 1 : 0
        }

        Row {
            id: wsLayout
            anchors.centerIn: parent
            spacing: bar.s(8)

            Repeater {
                id: wsPillRepeater
                model: bar.wsModel
                delegate: Rectangle {
                    id: wsPill

                    property bool isLimited: box.limitActive && index >= 6
                    visible: !isLimited

                    property bool isHovered: wsPillMouse.containsMouse

                    property string stateLabel: model.wsState
                    property string wsName: model.wsId
                    property int wsIndex: index

                    property real targetWidth: appIconList.length > 0 ? bar.s(24) + appIconList.length * bar.s(16) + (hasManyIcons ? bar.s(18) : 0) : bar.s(36)
                    width: targetWidth
                    Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                    height: bar.s(36); radius: bar.pillRadius(bar.s(36))

                    color: isHovered ? Qt.rgba(colors.text.r, colors.text.g, colors.text.b, 0.1) : (stateLabel === "occupied" ? Qt.rgba(colors.text.r, colors.text.g, colors.text.b, 0.15) : "transparent")

                    scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                    property bool initAnimTrigger: false
                    opacity: initAnimTrigger ? 1 : 0
                    transform: Translate {
                        y: wsPill.initAnimTrigger ? 0 : bar.s(15)
                        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                    }

                    Component.onCompleted: {
                        if (!bar.startupCascadeFinished) {
                            animTimer.interval = index * 60;
                            animTimer.start();
                        } else {
                            initAnimTrigger = true;
                        }
                    }

                    Timer {
                        id: animTimer
                        running: false
                        repeat: false
                        onTriggered: wsPill.initAnimTrigger = true
                    }

                    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 250 } }

                    property string wsClassesStr: model.wsClasses || ""

                    function classIcon(cls) {
                        var c = String(cls).toLowerCase();
                        var map = {
                            "kitty": "\uF489", "alacritty": "\uF489", "wezterm": "\uF489", "foot": "\uF489", "ghostty": "\uF489", "terminal": "\uF489",
                            "firefox": "\uF269", "firefoxdeveloperedition": "\uF269", "brave": "\uF269", "brave-browser": "\uF269", "zen": "\uF269",
                            "chromium": "\uF269", "google-chrome": "\uF269", "microsoft-edge": "\uF269", "edge": "\uF269",
                            "code": "\uF121", "code-oss": "\uF121", "codium": "\uF121", "vscodium": "\uF121", "visual-studio-code": "\uF121", "code-insiders": "\uF121", "visual-studio-code-insiders": "\uF121",
                            "nautilus": "\uF07C", "org.gnome.nautilus": "\uF07C", "dolphin": "\uF07C", "thunar": "\uF07C", "pcmanfm": "\uF07C",
                            "spotify": "\uF1BC",
                            "discord": "\uF392",
                            "slack": "\uF392",
                            "obsidian": "\uF4A5",
                            "gimp": "\uF338",
                            "inkscape": "\uF344",
                            "libreoffice": "\uF15C", "soffice": "\uF15C",
                            "evince": "\uF15C", "org.gnome.evince": "\uF15C",
                            "jetbrains-idea": "\uF121", "idea": "\uF121", "intellij": "\uF121",
                            "thunderbird": "\uF7E5",
                            "org.wezfurlong.wezterm": "\uF489",
                            "steam": "\uF1B7", "steamwebhelper": "\uF1B7",
                            "vlc": "\uF15C",
                            "virt-manager": "\uF17B",
                            "": ""
                        };
                        return map[c] || "\uF128";
                    }

                    property var appClassList: wsClassesStr !== "" ? wsClassesStr.split(",") : []
                    property bool hasManyIcons: appClassList.length > 3
                    property int maxShowIcons: hasManyIcons ? 2 : Math.min(appClassList.length, 3)
                    property var appIconList: {
                        var icons = [];
                        for (var i = 0; i < appClassList.length && i < maxShowIcons; i++) {
                            icons.push(classIcon(appClassList[i]));
                        }
                        return icons;
                    }

                    Item {
                        anchors.fill: parent

                        Text {
                            anchors.centerIn: parent
                            text: wsPill.wsName
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(18)
                            font.weight: wsPill.stateLabel === "active" ? Font.Black : (wsPill.stateLabel === "occupied" ? Font.Bold : Font.Medium)
                            color: index === bar.wsModel.activeIndex ? colors.crust : (wsPill.isHovered ? colors.text : (wsPill.stateLabel === "occupied" ? colors.text : colors.overlay0))
                            Behavior on color { ColorAnimation { duration: 250 } }
                            visible: wsPill.appIconList.length === 0
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: bar.s(2)
                            visible: wsPill.appIconList.length > 0

                            Repeater {
                                model: wsPill.appIconList
                                delegate: Text {
                                    text: modelData
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: bar.s(12)
                                    color: wsPill.wsIndex === bar.wsModel.activeIndex ? colors.crust : (wsPill.isHovered ? colors.text : (wsPill.stateLabel === "occupied" ? colors.text : colors.overlay0))
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            Text {
                                text: wsPill.hasManyIcons ? "+" + (wsPill.appClassList.length - 2) : ""
                                font.family: "Hack Nerd Font"
                                font.pixelSize: bar.s(10)
                                font.weight: Font.Black
                                color: index === bar.wsModel.activeIndex ? colors.crust : colors.overlay0
                                visible: wsPill.hasManyIcons
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: bar.s(2)
                            anchors.bottomMargin: bar.s(1)
                            text: wsPill.wsName
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(9)
                            font.weight: Font.Black
                            color: Qt.rgba(colors.text.r, colors.text.g, colors.text.b, 0.4)
                            visible: wsPill.appIconList.length > 0
                        }
                    }

                    MouseArea {
                        id: wsPillMouse
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsPill.wsName])
                    }
                }
            }
        }
    }
}
