import QtQuick
import QtQuick.Layouts

// Position selector card for the SERP engine editor (DockEditor, Phase D4-E2).
// Same look as PosCard, but engine-agnostic: the active spot is read from
// `bar.serp.position` and clicks emit activated() — the editor routes them
// through applySerp() (settings.json "serpbar"), never through the dock
// config. Width is set by the caller.
Rectangle {
    id: card
    property var bar: null
    property string pos: ""
    property string label: ""
    property string glyph: ""
    signal activated()

    readonly property bool isActive: card.bar && card.bar.serp && String(card.bar.serp.position) === card.pos

    height: bar ? bar.s(64) : 64
    radius: bar ? bar.s(14) : 14
    color: isActive ? bar.colors.accent : bar.colors.surface1
    opacity: isActive ? 1 : 0.55
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: bar ? bar.s(8) : 8
        Text {
            text: card.glyph
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(22) : 22
            font.weight: Font.Black
            color: card.isActive ? bar.colors.base : bar.colors.text
        }
        Text {
            text: card.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            font.weight: Font.Bold
            color: card.isActive ? bar.colors.base : bar.colors.text
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.activated()
    }
}
