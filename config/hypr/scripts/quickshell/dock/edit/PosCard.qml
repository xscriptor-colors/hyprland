import QtQuick
import QtQuick.Layouts

// Position selector card for the DockEditor. Width is set by the caller.
Rectangle {
    id: card
    property var bar: null
    property var dockRef: null
    property string pos: ""
    property string label: ""
    property string glyph: ""

    height: bar ? bar.s(64) : 64
    radius: bar ? bar.s(14) : 14
    color: (dockRef && dockRef.position === pos) ? bar.colors.accent : bar.colors.surface1
    opacity: (dockRef && dockRef.position === pos) ? 1 : 0.55
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.centerIn: parent
        spacing: bar ? bar.s(8) : 8
        Text {
            text: card.glyph
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(22) : 22
            font.weight: Font.Black
            color: (dockRef && dockRef.position === pos) ? bar.colors.base : bar.colors.text
        }
        Text {
            text: card.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            font.weight: Font.Bold
            color: (dockRef && dockRef.position === pos) ? bar.colors.base : bar.colors.text
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (card.bar && card.dockRef) {
                card.bar.applyDock(Object.assign({}, card.dockRef, { position: card.pos }));
            }
        }
    }
}
