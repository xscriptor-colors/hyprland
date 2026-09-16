import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../dock"

// Clock — text island, blue accent. Compact (vertical): HH:mm.
// Personalization: format (bar.timeFormat), size/color/accent/fill and the
// optional typewriter effect (module config).
ModulePill {
    id: mod
    moduleId: "time"

    fullHeight: true
    idleRole: "blue"
    padH: bar.s(18)

    readonly property bool tw: mod.moduleCfg.effect === "typewriter"
    readonly property bool cursorOn: mod.moduleCfg.cursor !== false
    readonly property int clockSize: mod.moduleCfg.size > 0
        ? bar.s(mod.moduleCfg.size)
        : bar.s(mod.horizontal ? 16 : 14)

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])

    // The cursor travels to the character being typed and returns to its
    // resting position (typewriter carriage).
    function typeCursor(tx) {
        cursor.cursorX = Math.max(0, Math.min(tx, cursor.restX));
        cursorReturn.restart();
    }

    Text {
        visible: mod.horizontal && !mod.tw
        text: bar.timeStr
        font.family: bar.fontFamily
        font.pixelSize: mod.clockSize
        font.weight: Font.Black
        color: mod.contentColor
    }

    // Typewriter: one Text per character slot; only the characters that change
    // replay the reveal (seconds every second, minutes and hours on their own
    // change).
    Item {
        id: twWrap
        visible: mod.horizontal && mod.tw
        implicitWidth: twRow.width + bar.s(7)
        implicitHeight: twRow.height

        RowLayout {
            id: twRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Repeater {
                model: 12

                delegate: Text {
                    id: twChar
                    required property int index
                    readonly property string ch: bar.timeStr.length > index ? bar.timeStr.charAt(index) : ""
                    Layout.alignment: Qt.AlignVCenter
                    text: ch
                    font.family: bar.fontFamily
                    font.pixelSize: mod.clockSize
                    font.weight: Font.Black
                    color: mod.contentColor

                    SequentialAnimation {
                        id: revealAnim
                        PauseAnimation { duration: twChar.index * 12 }
                        NumberAnimation { target: twChar; property: "opacity"; from: 0; to: 1; duration: 100; easing.type: Easing.OutQuad }
                    }
                    onChChanged: {
                        revealAnim.restart();
                        if (mod.cursorOn && twChar.ch !== "") {
                            mod.typeCursor(twChar.x + twChar.width / 2);
                        }
                    }
                }
            }
        }

        // Cursor: rests after the text, slides to the character being typed.
        Item {
            id: cursor
            width: bar.s(2)
            height: twRow.height
            y: 0
            property real restX: twRow.width + bar.s(3)
            property real cursorX: restX
            x: cursorX
            Behavior on cursorX { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
            onRestXChanged: if (!cursorReturn.running) cursorX = restX
            Component.onCompleted: cursorX = restX

            Rectangle {
                anchors.centerIn: parent
                width: bar.s(2)
                height: parent.height - bar.s(4)
                color: mod.contentColor
                visible: mod.cursorOn
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.1; duration: 480 }
                    NumberAnimation { to: 1.0; duration: 480 }
                }
            }

            Timer {
                id: cursorReturn
                interval: 200
                onTriggered: cursor.cursorX = cursor.restX
            }
        }
    }

    // Compact: just HH:mm, clamped to the pill so it never overflows.
    Text {
        visible: mod.compact
        width: Math.max(bar.s(28), bar.pillWidth - bar.s(8))
        text: bar.timeStr.length >= 5 ? bar.timeStr.substring(0, 5) : bar.timeStr
        font.family: bar.fontFamily
        font.pixelSize: mod.clockSize
        font.weight: Font.Black
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: mod.contentColor
    }
}
