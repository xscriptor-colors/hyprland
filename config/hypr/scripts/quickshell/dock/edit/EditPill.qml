import QtQuick

// Clickable pill (option / button) for the DockEditor.
Rectangle {
    id: pill
    property var bar: null
    property var modelData: null
    property string text: ""
    property bool active: false
    property bool accentFill: false
    signal activated()

    height: bar ? bar.s(34) : 34
    implicitWidth: txt.implicitWidth + (bar ? bar.s(24) : 24)
    radius: height / 2
    color: (accentFill || active) ? bar.colors.accent : bar.colors.surface2
    opacity: (accentFill || active) ? 1 : 0.55
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
        id: txt
        anchors.centerIn: parent
        text: pill.text
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(12) : 12
        font.weight: Font.Bold
        color: (pill.active || pill.accentFill) ? bar.colors.base : bar.colors.text
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.activated()
    }
}
