import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../edit"

// ═══════════════════════════════════════════════════════════════════════════
// HyprlandPage — BarEditor tab (grupo System): las 12 perillas de efectos de
// ventana / layout del widget window-controls (SUPER+SHIFT+B), con el MISMO
// manejo de color por fila y el MISMO script de persistencia.
//
//   · Lectura: `hyprctl getoption ...` (mismo comando que WindowControls).
//   · Guardado: window-controls/persist.sh con los 12 args (mismo orden que
//     WindowControls.saveChanges); persist.sh escribe config/gaps.lua +
//     config/window-effects.lua y recarga Hyprland.
//   · Auto-save con debounce de 600 ms (cada `edited` lo reinicia).
// Gate: el cuerpo se crea cuando `bar` ya está inyectado.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null

    // ── Las 12 perillas (mismos defaults que WindowControls.qml) ──
    property real activeOpacity: 0.85
    property real inactiveOpacity: 0.80
    property real roundness: 20
    property int blurSize: 8
    property int blurPasses: 3
    property int gapsIn: 16
    property int gapsOut: 25
    property int borderSize: 2
    property int shadowRange: 35
    property int shadowPower: 5
    property int shadowOffX: 0
    property int shadowOffY: 10

    // Gate: el cuerpo se crea cuando bar ya está inyectado (initial
    // property aplicada tras la creación del root). Evita bindings
    // evaluados con bar null que quedaban muertos en negro.
    readonly property var flickable: body.item ? body.item.flickable : null

    // ── Lectura de los valores actuales (mismo comando que el widget) ──
    function loadCurrent() {
        reader.command = ["bash", "-c",
            "echo active_opacity=$(hyprctl getoption decoration:active_opacity | grep 'float:' | awk '{print $2}');" +
            "echo inactive_opacity=$(hyprctl getoption decoration:inactive_opacity | grep 'float:' | awk '{print $2}');" +
            "echo roundness=$(hyprctl getoption decoration:rounding | grep 'int:' | awk '{print $2}');" +
            "echo blur_size=$(hyprctl getoption decoration:blur:size | grep 'int:' | awk '{print $2}');" +
            "echo blur_passes=$(hyprctl getoption decoration:blur:passes | grep 'int:' | awk '{print $2}');" +
            "echo gaps_in=$(hyprctl getoption general:gaps_in | grep 'int:' | awk '{print $2}');" +
            "echo gaps_out=$(hyprctl getoption general:gaps_out | grep 'int:' | awk '{print $2}');" +
            "echo border_size=$(hyprctl getoption general:border_size | grep 'int:' | awk '{print $2}');" +
            "echo shadow_range=$(hyprctl getoption decoration:shadow:range | grep 'int:' | awk '{print $2}');" +
            "echo shadow_render_power=$(hyprctl getoption decoration:shadow:render_power | grep 'int:' | awk '{print $2}');" +
            "echo shadow_offset=$(hyprctl getoption decoration:shadow:offset | grep 'vec2:' | awk '{print $2, $3}')"
        ];
        reader.running = true;
    }

    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) return;
                    let lines = this.text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split('=');
                        if (parts.length < 2) continue;
                        let v = parts[1].trim();
                        let f = parseFloat(v);
                        // Fallback solo si el valor no es numérico (0 es válido).
                        if (parts[0] === 'active_opacity') root.activeOpacity = isNaN(f) ? 0.85 : f;
                        else if (parts[0] === 'inactive_opacity') root.inactiveOpacity = isNaN(f) ? 0.80 : f;
                        else if (parts[0] === 'roundness') root.roundness = isNaN(f) ? 20 : Math.round(f);
                        else if (parts[0] === 'blur_size') root.blurSize = isNaN(f) ? 8 : Math.round(f);
                        else if (parts[0] === 'blur_passes') root.blurPasses = isNaN(f) ? 3 : Math.round(f);
                        else if (parts[0] === 'gaps_in') root.gapsIn = isNaN(f) ? 16 : Math.round(f);
                        else if (parts[0] === 'gaps_out') root.gapsOut = isNaN(f) ? 25 : Math.round(f);
                        else if (parts[0] === 'border_size') root.borderSize = isNaN(f) ? 2 : Math.round(f);
                        else if (parts[0] === 'shadow_range') root.shadowRange = isNaN(f) ? 35 : Math.round(f);
                        else if (parts[0] === 'shadow_render_power') root.shadowPower = isNaN(f) ? 5 : Math.round(f);
                        else if (parts[0] === 'shadow_offset') {
                            // hyprctl imprime "vec2: [x, y]" → limpiamos corchetes
                            // y comas (el widget leía X=0 por este formato).
                            let offsets = v.replace(/[\[\],]/g, " ").trim().split(/\s+/);
                            let ox = parseFloat(offsets[0]);
                            let oy = parseFloat(offsets[1]);
                            root.shadowOffX = isNaN(ox) ? 0 : Math.round(ox);
                            root.shadowOffY = isNaN(oy) ? 10 : Math.round(oy);
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Timer { interval: 300; running: true; repeat: false; onTriggered: root.loadCurrent() }

    // ── Guardado (debounce 600 ms) vía persist.sh ──
    Timer { id: saveTimer; interval: 600; onTriggered: root.saveChanges() }
    function markDirty() { saveTimer.restart(); }
    function saveChanges() {
        Quickshell.execDetached(["bash",
            Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/window-controls/persist.sh",
            root.activeOpacity.toFixed(2),
            root.inactiveOpacity.toFixed(2),
            String(Math.round(root.roundness)),
            String(Math.round(root.blurSize)),
            String(Math.round(root.blurPasses)),
            String(Math.round(root.gapsIn)),
            String(Math.round(root.gapsOut)),
            String(Math.round(root.borderSize)),
            String(Math.round(root.shadowRange)),
            String(Math.round(root.shadowPower)),
            String(Math.round(root.shadowOffX)),
            String(Math.round(root.shadowOffY))
        ]);
    }

    // Reset: solo opacidades/blur/rounding/shadow (gaps y border intactos,
    // igual que WindowControls.resetDefaults).
    function resetDefaults() {
        root.activeOpacity = 0.85;
        root.inactiveOpacity = 0.80;
        root.blurSize = 8;
        root.blurPasses = 3;
        root.roundness = 20;
        root.shadowRange = 35;
        root.shadowPower = 5;
        root.shadowOffX = 0;
        root.shadowOffY = 10;
        root.markDirty();
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
                        text: "Hyprland"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Window effects and layout. Applies live via a Hyprland reload (same knobs as SUPER+SHIFT+B)."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    // ── Opacity ─────────────────────────────────────────────
                    Text {
                        text: "Opacity"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF06E"
                        label: "Active Opacity"
                        from: 0.3; to: 1.0; step: 0.05
                        decimals: 2
                        accentColor: bar.colors.mauve
                        value: root.activeOpacity
                        onEdited: (v) => { root.activeOpacity = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF070"
                        label: "Inactive Opacity"
                        from: 0.3; to: 1.0; step: 0.05
                        decimals: 2
                        accentColor: bar.colors.blue
                        value: root.inactiveOpacity
                        onEdited: (v) => { root.inactiveOpacity = v; root.markDirty(); }
                    }

                    // ── Rounding ────────────────────────────────────────────
                    Text {
                        text: "Rounding"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF192"
                        label: "Rounding"
                        from: 0; to: 35; step: 1
                        suffix: "px"
                        accentColor: bar.colors.green
                        value: root.roundness
                        onEdited: (v) => { root.roundness = v; root.markDirty(); }
                    }

                    // ── Blur ────────────────────────────────────────────────
                    Text {
                        text: "Blur"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF0EB"
                        label: "Blur Size"
                        from: 0; to: 24; step: 1
                        suffix: "px"
                        accentColor: bar.colors.peach
                        value: root.blurSize
                        onEdited: (v) => { root.blurSize = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF2C8"
                        label: "Blur Passes"
                        from: 0; to: 10; step: 1
                        accentColor: bar.colors.sapphire
                        value: root.blurPasses
                        onEdited: (v) => { root.blurPasses = v; root.markDirty(); }
                    }

                    // ── Layout ──────────────────────────────────────────────
                    Text {
                        text: "Layout"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF239"
                        label: "Gaps In"
                        from: 0; to: 50; step: 2
                        suffix: "px"
                        accentColor: bar.colors.mauve
                        value: root.gapsIn
                        onEdited: (v) => { root.gapsIn = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF7A4"
                        label: "Gaps Out"
                        from: 0; to: 50; step: 2
                        suffix: "px"
                        accentColor: bar.colors.blue
                        value: root.gapsOut
                        onEdited: (v) => { root.gapsOut = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF358"
                        label: "Border Width"
                        from: 0; to: 20; step: 1
                        suffix: "px"
                        accentColor: bar.colors.peach
                        value: root.borderSize
                        onEdited: (v) => { root.borderSize = v; root.markDirty(); }
                    }

                    // ── Shadow ──────────────────────────────────────────────
                    Text {
                        text: "Shadow"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF042"
                        label: "Shadow Range"
                        from: 0; to: 50; step: 1
                        suffix: "px"
                        accentColor: bar.colors.peach
                        value: root.shadowRange
                        onEdited: (v) => { root.shadowRange = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF0E7"
                        label: "Shadow Power"
                        from: 0; to: 10; step: 1
                        accentColor: bar.colors.sapphire
                        value: root.shadowPower
                        onEdited: (v) => { root.shadowPower = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF061"
                        label: "Shadow Offset X"
                        from: -30; to: 30; step: 1
                        suffix: "px"
                        accentColor: bar.colors.mauve
                        value: root.shadowOffX
                        onEdited: (v) => { root.shadowOffX = v; root.markDirty(); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: "\uF063"
                        label: "Shadow Offset Y"
                        from: -30; to: 30; step: 1
                        suffix: "px"
                        accentColor: bar.colors.green
                        value: root.shadowOffY
                        onEdited: (v) => { root.shadowOffY = v; root.markDirty(); }
                    }

                    // Acciones: Reset (defaults del widget) + Refresh de lectura.
                    Row {
                        width: parent.width
                        spacing: bar.s(10)
                        EditorButton {
                            bar: root.bar
                            compact: true
                            icon: "\uF0E2"
                            label: "Reset"
                            onActivated: root.resetDefaults()
                        }
                        EditorButton {
                            bar: root.bar
                            compact: true
                            icon: "\uF021"
                            label: "Refresh"
                            onActivated: root.loadCurrent()
                        }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Border colors follow the active palette. Gaps, blur and shadows persist via config/gaps.lua and config/window-effects.lua."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
