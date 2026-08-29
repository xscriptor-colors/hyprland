import QtQuick

// Border color cycle button for the DockEditor.
Rectangle {
    id: cc
    property var bar: null
    property string role: "surface1"
    signal cycled(string role)

    width: bar ? bar.s(66) : 66
    height: bar ? bar.s(30) : 30
    radius: height / 2
    color: bar.colors.surface2

    property var roles: ["surface1", "surface0", "text", "red", "blue", "green", "yellow", "mauve", "teal"]

    Text {
        anchors.centerIn: parent
        text: " " + cc.role
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(11) : 11
        font.weight: Font.Bold
        color: bar.colors.text
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            let i = cc.roles.indexOf(cc.role);
            cc.cycled(cc.roles[(i + 1) % cc.roles.length]);
        }
    }
}
