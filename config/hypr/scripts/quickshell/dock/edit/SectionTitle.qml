import QtQuick

// Section header for the DockEditor.
Text {
    property var bar: null
    text: ""
    font.family: "Hack Nerd Font"
    font.pixelSize: bar ? bar.s(12) : 12
    font.weight: Font.Black
    color: bar && bar.colors ? bar.colors.accent : "#fc618d"
}
