import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// IdlePage — BarEditor tab (grupo System): modo de energía del sistema.
//
//   Auto  = hypridle activo (auto-dim / lock / suspend según hypridle.conf)
//   Awake = hypridle parado (nada automático; lock/suspend manuales)
//
// El estado vive en ~/.config/hypr/idle-settings.json (el MISMO fichero que
// usa el popup Idle) y se cambia con idle-mode.sh, que escribe el JSON y
// gestiona hypridle. Gate: el cuerpo se crea cuando `bar` ya está inyectado.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property string idleMode: "normal"

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null

    // Estado reactivo (FileView.text() = función en Quickshell 0.3.x).
    FileView {
        id: idleFile
        path: Quickshell.env("HOME") + "/.config/hypr/idle-settings.json"
        watchChanges: true
        onLoaded: root.readState()
        onFileChanged: root.readState()
        onLoadFailed: root.idleMode = "normal"
    }
    function readState() {
        try {
            let d = JSON.parse(idleFile.text());
            root.idleMode = (d && d.idleMode === "awake") ? "awake" : "normal";
        } catch (e) {
            root.idleMode = "normal";
        }
    }
    function setIdleMode(mode) {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/idle-mode.sh", mode]);
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
                        text: "Idle"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // ── Modo de energía ─────────────────────────────────────
                    Text {
                        text: "Power mode"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰒲"
                            label: "Auto"
                            active: root.idleMode === "normal"
                            onActivated: root.setIdleMode("normal")
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰛓"
                            label: "Awake"
                            active: root.idleMode === "awake"
                            onActivated: root.setIdleMode("awake")
                        }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Awake stops hypridle: nothing auto-dims, locks or suspends. Manual lock: SUPER+L · suspend: SUPER+CTRL+L. Same state as the Idle popup."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
