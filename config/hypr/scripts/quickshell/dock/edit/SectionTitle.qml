import QtQuick

// Título de sección del DockEditor (Fase 4: acento mauve del Guide).
Text {
    property var bar: null
    text: ""
    font.family: "Hack Nerd Font"
    font.pixelSize: bar ? bar.s(12) : 12
    font.weight: Font.Black
    color: bar && bar.colors ? bar.colors.mauve : "#948ae3"
}
