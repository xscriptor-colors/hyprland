import QtQuick

// Ciclo de color de borde del DockEditor (Fase 4: familia GuidePopup).
// alpha(surface0, 0.4) + borde surface1; hover alpha(mauve, 0.15) + borde
// mauve; press scale 0.95. API intacta: bar / role / cycled().
Rectangle {
    id: cc
    property var bar: null
    property string role: "surface1"
    signal cycled(string role)

    width: bar ? bar.s(66) : 66
    height: bar ? bar.s(30) : 30
    radius: height / 2
    color: !bar ? "transparent" : (ccMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.4))
    border.width: 1
    border.color: !bar ? "transparent" : (ccMa.containsMouse ? bar.colors.mauve : bar.colors.surface1)
    scale: ccMa.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    property var roles: ["surface1", "surface0", "text", "red", "blue", "green", "yellow", "mauve", "teal"]

    Text {
        anchors.centerIn: parent
        text: " " + cc.role
        font.family: "Hack Nerd Font"
        font.pixelSize: bar ? bar.s(11) : 11
        font.weight: Font.Bold
        color: bar ? bar.colors.text : "transparent"
    }
    MouseArea {
        id: ccMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            let i = cc.roles.indexOf(cc.role);
            cc.cycled(cc.roles[(i + 1) % cc.roles.length]);
        }
    }
}
