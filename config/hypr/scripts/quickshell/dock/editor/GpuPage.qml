import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// GpuPage — BarEditor tab (grupo System): modo Optimus de la GPU.
//
//   integrated · hybrid · nvidia  (envycontrol)
//
// El modo actual se lee con `envycontrol --query`; el cambio llama a
// gpu-mode.sh (usa sudo envycontrol y notifica). Si envycontrol no está
// instalado la query falla y se muestra un aviso. Gate: el cuerpo se crea
// cuando `bar` ya está inyectado.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property string currentMode: ""
    property bool envyMissing: false

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null

    // Modo actual: envycontrol --query (vacío/fallo = no instalado).
    Process {
        id: queryProc
        command: ["envycontrol", "--query"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let t = this.text.trim();
                if (t === "") {
                    root.envyMissing = true;
                    root.currentMode = "";
                } else {
                    root.envyMissing = false;
                    root.currentMode = t;
                }
            }
        }
    }
    function reread() {
        queryProc.running = false;
        queryProc.running = true;
    }
    // Cambio de modo: gpu-mode.sh (puede tardar por sudo/envycontrol);
    // refrescamos la query 3 s después para reflejar el nuevo estado.
    function setMode(mode) {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/gpu-mode.sh", mode]);
        refreshTimer.restart();
    }
    Timer {
        id: refreshTimer
        interval: 3000
        onTriggered: root.reread()
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
                        text: "GPU"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // ── Modo Optimus ────────────────────────────────────────
                    Text {
                        text: "Optimus mode"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    GridLayout {
                        width: parent.width
                        columns: 3
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        // Iconos = los mismos que usa gpu-mode.sh en la barra
                        // (batería/swap/speed), verificados en la fuente.
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰁹"
                            label: "Integrated"
                            active: root.currentMode === "integrated"
                            onActivated: root.setMode("integrated")
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰚰"
                            label: "Hybrid"
                            active: root.currentMode === "hybrid"
                            onActivated: root.setMode("hybrid")
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰓅"
                            label: "NVIDIA"
                            active: root.currentMode === "nvidia"
                            onActivated: root.setMode("nvidia")
                        }
                    }

                    // Aviso si envycontrol no está disponible.
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        visible: root.envyMissing
                        text: "envycontrol is not installed — install it to read and switch the GPU mode."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.red
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        width: parent.width
                        spacing: bar.s(10)
                        EditorButton {
                            bar: root.bar
                            compact: true
                            icon: "󰑓"
                            label: "Refresh"
                            onActivated: root.reread()
                        }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Switching uses envycontrol and may require logout/reboot. Hybrid is the default for Optimus laptops."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
