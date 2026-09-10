import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// InputPage — BarEditor tab (grupo System): pointer + touchpad.
//
// El panel regenera config/user-input.lua (cargado al final de hyprland.lua →
// siempre gana) y recarga. NO toca kb_layout/kb_options/follow_mouse: se
// quedan en settings.lua (el merge parcial de hl.config los conserva, igual
// que config/gaps.lua sobre `general`).
//
// Semilla: si settings.json no tiene key "input", al abrir la página se leen
// los valores vivos con `hyprctl getoption` (Process) y se rellena la UI SIN
// persistir; el primer cambio del usuario es el que escribe.
// Guardado debounced en BarEditor: applyInput → persist-hypr.sh input, 600 ms.
// Gate: el cuerpo se crea cuando `bar` ya está inyectado.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    // El reader de hyprctl se lanza una sola vez por carga de página.
    property bool _seedRequested: false

    readonly property var flickable: body.item ? body.item.flickable : null

    // ── Semilla desde hyprctl (solo si no hay key "input" en settings.json) ──
    function seedFromHyprctl() {
        if (root._seedRequested) return;
        if (!root.bar || !root.bar.needsInputSeed || !root.bar.needsInputSeed()) return;
        root._seedRequested = true;
        reader.running = true;
    }

    Process {
        id: reader
        command: ["bash", "-c",
            "echo sensitivity=$(hyprctl getoption input:sensitivity | grep 'float:' | awk '{print $2}');" +
            "echo accel_profile=$(hyprctl getoption input:accel_profile | sed -n 's/^str: *//p');" +
            "echo tap_to_click=$(hyprctl getoption input:touchpad:tap_to_click | grep 'bool:' | awk '{print $2}');" +
            "echo natural_scroll=$(hyprctl getoption input:touchpad:natural_scroll | grep 'bool:' | awk '{print $2}');" +
            "echo disable_while_typing=$(hyprctl getoption input:touchpad:disable_while_typing | grep 'bool:' | awk '{print $2}')"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) return;
                    let obj = {};
                    let lines = this.text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        let p = lines[i].split('=');
                        if (p.length < 2) continue;
                        let k = p[0].trim();
                        let v = p[1].trim();
                        if (k === 'sensitivity') {
                            let f = parseFloat(v);
                            obj.sensitivity = isNaN(f) ? 0 : f;
                        } else if (k === 'accel_profile') {
                            obj.accelProfile = (v === 'flat') ? 'flat' : 'adaptive';
                        } else if (k === 'tap_to_click') {
                            obj.tapToClick = (v === 'true');
                        } else if (k === 'natural_scroll') {
                            obj.naturalScroll = (v === 'true');
                        } else if (k === 'disable_while_typing') {
                            obj.disableWhileTyping = (v === 'true');
                        }
                    }
                    root.bar.seedInputCfg(obj);
                } catch (e) {}
            }
        }
    }
    // Pequeña espera: deja que la página esté montada antes de consultar.
    Timer { interval: 300; running: true; repeat: false; onTriggered: root.seedFromHyprctl() }

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
                        text: "Input"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }

                    // ── Pointer ─────────────────────────────────────────────
                    Text {
                        text: "Pointer"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    StepperCard {
                        width: parent.width
                        bar: root.bar
                        label: "Sensitivity"
                        value: Number(root.bar.inputCfg.sensitivity).toFixed(1)
                        onDec: root.bar.applyInput({
                            sensitivity: Math.max(-1.0, Math.round((root.bar.inputCfg.sensitivity - 0.1) * 10) / 10)
                        })
                        onInc: root.bar.applyInput({
                            sensitivity: Math.min(1.0, Math.round((root.bar.inputCfg.sensitivity + 0.1) * 10) / 10)
                        })
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Accel profile"
                    }
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰚩"
                            label: "Adaptive"
                            active: root.bar.inputCfg.accelProfile !== "flat"
                            onActivated: root.bar.applyInput({ accelProfile: "adaptive" })
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "↔"
                            label: "Flat"
                            active: root.bar.inputCfg.accelProfile === "flat"
                            onActivated: root.bar.applyInput({ accelProfile: "flat" })
                        }
                    }

                    // ── Touchpad ────────────────────────────────────────────
                    Text {
                        text: "Touchpad"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰟸"
                        label: "Tap to click"
                        checked: root.bar.inputCfg.tapToClick
                        onToggled: root.bar.applyInput({ tapToClick: !root.bar.inputCfg.tapToClick })
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰍽"
                        label: "Natural scroll"
                        checked: root.bar.inputCfg.naturalScroll
                        onToggled: root.bar.applyInput({ naturalScroll: !root.bar.inputCfg.naturalScroll })
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: "󰌌"
                        label: "Disable while typing"
                        checked: root.bar.inputCfg.disableWhileTyping
                        onToggled: root.bar.applyInput({ disableWhileTyping: !root.bar.inputCfg.disableWhileTyping })
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Applies via config/user-input.lua + Hyprland reload. Keyboard layout stays in General."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
