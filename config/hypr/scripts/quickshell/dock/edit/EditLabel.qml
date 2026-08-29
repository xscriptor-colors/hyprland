import QtQuick

// Label for the DockEditor.
Text {
    property var bar: null
    text: ""
    font.family: "Hack Nerd Font"
    font.pixelSize: bar ? bar.s(13) : 13
    color: bar && bar.colors ? bar.colors.text : "#f7f1ff"
}
