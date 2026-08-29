import QtQuick
import Quickshell
import "../../dock"

// Workspaces — the centerpiece. A horizontal row of workspace pills (top/bottom
// docks) or a vertical stack (left/right docks), with a sliding mauve highlight
// that follows the active workspace in both axes. Each pill shows the workspace
// number, or app icons when occupied.
ModulePill {
    id: mod

    fullHeight: true
    bgRole: "crust"
    bgHoverRole: "crust"
    padH: bar.s(10)
    padV: bar.s(4)

    // NOTE: children of a ModulePill land in its contentHost via the default
    // property — do NOT use `content: Item {...}` (the alias-to-data assignment
    // silently drops the item, collapsing the pill to its padding).
    Item {
        id: wsContent
        width: mod.compact ? bar.pillWidth : wsFlowH.implicitWidth
        height: mod.compact ? wsFlowV.implicitHeight : bar.pillHeight

        // --- sliding active highlight (mauve) ----------------------------------
        Rectangle {
            id: activeHighlight
            radius: bar.pillRadius(mod.compact ? bar.pillWidth : bar.s(32))
            color: colors.mauve
            z: 0

            property int curIdx: bar.wsModel.activeIndex
            property int pillCount: mod.compact ? wsRepeaterV.count : wsRepeaterH.count
            property var activePill: (curIdx >= 0 && curIdx < pillCount)
                ? (mod.compact ? wsRepeaterV.itemAt(curIdx) : wsRepeaterH.itemAt(curIdx))
                : null

            property real targetL: activePill ? (mod.compact ? bar.s(4) : activePill.x) : 0
            property real targetT: activePill ? (mod.compact ? activePill.y : bar.s(6)) : 0
            property real targetW: activePill ? (mod.compact ? bar.pillWidth - bar.s(8) : activePill.width) : bar.s(32)
            property real targetH: activePill ? (mod.compact ? activePill.height : bar.s(32)) : bar.s(32)

            property real actualL: targetL
            property real actualT: targetT
            property real actualW: targetW
            property real actualH: targetH

            Behavior on actualL { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            Behavior on actualT { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            Behavior on actualW { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            Behavior on actualH { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

            x: actualL; y: actualT; width: actualW; height: actualH
        }

        Row {
            id: wsFlowH
            visible: mod.horizontal
            z: 1
            spacing: bar.s(8)
            Repeater { id: wsRepeaterH; model: bar.wsModel; delegate: wsDelegate }
        }

        Column {
            id: wsFlowV
            visible: mod.compact
            z: 1
            spacing: bar.s(8)
            Repeater { id: wsRepeaterV; model: bar.wsModel; delegate: wsDelegate }
        }
    }

    Component {
        id: wsDelegate
        Rectangle {
            id: wsPill

            // `index` + `model.*` come from the Repeater context.
            property bool isLimited: !mod.compact && bar.isSettingsOpen && bar.isMediaActive && index >= 6
            visible: !isLimited

            property bool isHovered: wsMouse.containsMouse
            property string stateLabel: model.wsState
            property string wsName: model.wsId
            property int wsIndex: index

            readonly property var appClassList: (model.wsClasses || "") !== "" ? model.wsClasses.split(",") : []
            readonly property bool hasManyIcons: appClassList.length > 3
            readonly property int maxShowIcons: hasManyIcons ? 2 : Math.min(appClassList.length, 3)
            readonly property var appIconList: {
                var icons = [];
                for (var i = 0; i < appClassList.length && i < maxShowIcons; i++) icons.push(classIcon(appClassList[i]));
                return icons;
            }

            function classIcon(cls) {
                var c = String(cls).toLowerCase();
                var map = {
                    "kitty": "\uF489", "alacritty": "\uF489", "wezterm": "\uF489", "foot": "\uF489", "ghostty": "\uF489", "terminal": "\uF489",
                    "firefox": "\uF269", "firefoxdeveloperedition": "\uF269", "brave": "\uF269", "brave-browser": "\uF269", "zen": "\uF269",
                    "chromium": "\uF269", "google-chrome": "\uF269", "microsoft-edge": "\uF269", "edge": "\uF269",
                    "code": "\uF121", "code-oss": "\uF121", "codium": "\uF121", "vscodium": "\uF121", "visual-studio-code": "\uF121", "code-insiders": "\uF121",
                    "nautilus": "\uF07C", "org.gnome.nautilus": "\uF07C", "dolphin": "\uF07C", "thunar": "\uF07C", "pcmanfm": "\uF07C",
                    "spotify": "\uF1BC", "discord": "\uF392", "slack": "\uF392", "obsidian": "\uF4A5",
                    "gimp": "\uF338", "inkscape": "\uF344",
                    "libreoffice": "\uF15C", "soffice": "\uF15C", "evince": "\uF15C", "org.gnome.evince": "\uF15C", "vlc": "\uF15C",
                    "jetbrains-idea": "\uF121", "idea": "\uF121", "intellij": "\uF121",
                    "thunderbird": "\uF7E5", "org.wezfurlong.wezterm": "\uF489",
                    "steam": "\uF1B7", "steamwebhelper": "\uF1B7", "virt-manager": "\uF17B",
                    "": ""
                };
                return map[c] || "\uF128";
            }

            width: mod.compact
                ? bar.pillWidth - bar.s(8)
                : (appIconList.length > 0 ? bar.s(24) + appIconList.length * bar.s(16) + (hasManyIcons ? bar.s(18) : 0) : bar.s(36))
            height: mod.compact ? bar.s(30) : bar.s(36)
            radius: bar.pillRadius(mod.compact ? bar.pillWidth : bar.s(36))

            color: stateLabel === "active" ? "transparent"
                : (bar.topbarPillBg
                    ? (isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, bar.topbarPillSolid ? 1.0 : 0.6)
                        : (stateLabel === "occupied" ? Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, bar.topbarPillSolid ? 1.0 : 0.4)
                            : Qt.rgba(colors.base.r, colors.base.g, colors.base.b, bar.topbarPillSolid ? 1.0 : 0.4)))
                    : (isHovered ? Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.2)
                        : Qt.rgba(colors.surface0.r, colors.surface0.g, colors.surface0.b, 0.3)))

            scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

            Item {
                anchors.fill: parent

                Text {
                    anchors.centerIn: parent
                    // In compact (vertical) docks always show the number; the
                    // app-icon layout is too wide for the narrow pill.
                    visible: mod.compact || wsPill.appIconList.length === 0
                    text: wsPill.wsName
                    font.family: "Hack Nerd Font"
                    font.pixelSize: mod.compact ? bar.s(13) : bar.s(18)
                    font.weight: wsPill.stateLabel === "active" ? Font.Black : (wsPill.stateLabel === "occupied" ? Font.Bold : Font.Medium)
                    color: index === bar.wsModel.activeIndex ? colors.crust : (wsPill.isHovered ? colors.text : (wsPill.stateLabel === "occupied" ? colors.text : colors.overlay0))
                    Behavior on color { ColorAnimation { duration: 250 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: bar.s(2)
                    visible: !mod.compact && wsPill.appIconList.length > 0
                    Repeater {
                        model: wsPill.appIconList
                        delegate: Text {
                            text: modelData
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(12)
                            color: wsPill.wsIndex === bar.wsModel.activeIndex ? colors.crust : (wsPill.isHovered ? colors.text : colors.text)
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
            }

            MouseArea {
                id: wsMouse
                hoverEnabled: true
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsPill.wsName])
            }
        }
    }
}
