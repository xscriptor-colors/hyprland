import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../.."
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// NotificationsPage — BarEditor tab (grupo System): Do Not Disturb (DND).
//
// El estado vive en <cacheDir("dnd")>/state ("1" = silenciado, "0" = normal),
// el MISMO fichero que usa el toggle de la campana del popup de batería.
// Gate: el cuerpo se crea cuando `bar` ya está inyectado.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property bool dnd: false

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null

    // Cache dir por widget (misma API que usa BatteryPopup).
    Caching { id: paths }

    // Estado reactivo del flag DND (FileView.text() = función en 0.3.x).
    FileView {
        id: stateFile
        path: paths.getCacheDir("dnd") + "/state"
        watchChanges: true
        onLoaded: root.readDnd()
        onFileChanged: root.readDnd()
        onLoadFailed: root.dnd = false
    }
    function readDnd() {
        try {
            root.dnd = stateFile.text().trim() === "1";
        } catch (e) {
            root.dnd = false;
        }
    }
    function setDnd(v) {
        let dir = paths.getCacheDir("dnd");
        Quickshell.execDetached(["sh", "-c", "mkdir -p '" + dir + "' && echo '" + (v ? "1" : "0") + "' > '" + dir + "/state'"]);
    }

    Loader {
        id: body
        anchors.fill: parent
        active: root.bar !== null
        sourceComponent: pageBody
    }

    Component {
        id: pageBody
        Item {
            anchors.fill: parent
            property alias flickable: pageFlick

            Flickable {
                id: pageFlick
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: pageCol.height + bar.s(16)
                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    width: bar.s(4)
                    policy: ScrollBar.AsNeeded
                    hoverEnabled: true
                    active: pageFlick.moving || vScroll.hovered
                    contentItem: Rectangle {
                        radius: bar.s(2)
                        color: bar.colors.surface2
                        opacity: vScroll.active ? 1.0 : 0.45
                    }
                    background: Item {}
                }

                Column {
                    id: pageCol
                    x: bar.s(8)
                    y: bar.s(8)
                    width: pageFlick.width - bar.s(16)
                    spacing: bar.s(12)

                    // Título de página (GP:1007-1014)
                    Text {
                        text: "Notifications"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰂛"
                        label: "Do Not Disturb"
                        checked: root.dnd
                        onToggled: root.setDnd(!root.dnd)
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Silences notification popups. Same state as the bell toggle in the battery popup."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
