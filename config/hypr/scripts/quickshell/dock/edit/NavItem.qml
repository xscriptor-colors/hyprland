import QtQuick

// Sidebar navigation item for the DockEditor.
Rectangle {
    id: nav
    property var bar: null
    property string icon: ""
    property string label: ""
    property bool active: false
    signal activated()

    // Width is managed by the parent layout (Layout.fillWidth) — setting
    // `width: parent.width` here would create a circular binding that blows up
    // the sidebar's implicit width.
    height: bar ? bar.s(42) : 42
    radius: bar ? bar.s(12) : 12
    color: active ? bar.colors.accent : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(14) : 14
        spacing: bar ? bar.s(10) : 10
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: nav.icon
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(17) : 17
            color: nav.active ? bar.colors.base : bar.colors.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: nav.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            font.weight: nav.active ? Font.Black : Font.Medium
            color: nav.active ? bar.colors.base : bar.colors.text
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nav.activated()
    }
}
