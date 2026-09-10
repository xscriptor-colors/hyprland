import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// ═══════════════════════════════════════════════════════════════════════════
// FieldCard — card de texto de ancho completo (familia GuidePopup).
//
// Card s(44) r18 alpha(surface0, 0.4) + borde surface1: label s(13) text +
// spacer + TextField estilo card (fondo alpha(surface0, 0.4), radio s(13),
// borde mauve en foco). `previewFont` usa el propio texto como familia (vista
// previa del campo Font). El commit emite edited(text) y la página aplica.
// API: bar / label / value / fieldWidth / maxLength / previewFont / edited().
// ═══════════════════════════════════════════════════════════════════════════

Rectangle {
    id: fld
    property var bar: null
    property string label: ""
    property string value: ""
    property int fieldWidth: 240
    property int maxLength: 32767
    property bool previewFont: false
    signal edited(string text)

    height: bar ? bar.s(44) : 44
    radius: bar ? bar.s(18) : 18
    color: !bar ? "transparent" : Qt.alpha(bar.colors.surface0, 0.4)
    border.width: 1
    border.color: bar ? bar.colors.surface1 : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: bar ? bar.s(15) : 15
        anchors.rightMargin: bar ? bar.s(10) : 10
        spacing: bar ? bar.s(10) : 10
        Text {
            text: fld.label
            font.family: "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            color: !bar ? "transparent" : bar.colors.text
            Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true; height: 1 }
        TextField {
            id: field
            Layout.preferredWidth: bar ? bar.s(fld.fieldWidth) : fld.fieldWidth
            Layout.preferredHeight: bar ? bar.s(30) : 30
            Layout.alignment: Qt.AlignVCenter
            text: fld.value
            font.family: fld.previewFont && field.text !== "" ? field.text : "Hack Nerd Font"
            font.pixelSize: bar ? bar.s(13) : 13
            color: bar ? bar.colors.text : "transparent"
            selectByMouse: true
            maximumLength: fld.maxLength
            background: Rectangle {
                color: bar ? Qt.alpha(bar.colors.surface0, 0.4) : "transparent"
                radius: bar ? bar.s(13) : 13
                border.width: 1
                border.color: bar ? (field.activeFocus ? bar.colors.mauve : bar.colors.surface1) : "transparent"
            }
            onEditingFinished: fld.edited(field.text)
        }
    }
}
