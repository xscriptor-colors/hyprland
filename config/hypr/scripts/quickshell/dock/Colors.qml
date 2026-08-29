import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
// Colors — Matugen-free palette system.
//
// Loads a named palette from dock/palettes/<slug>.json (base-16 from
// references.md + optional explicit "roles" overrides) and derives the
// semantic roles the UI uses (base, surface0/1/2, text, subtext, overlay,
// and the accent set). Every module reads from `colors.<role>` so swapping
// the active palette never touches module code.
//
// The active palette is controlled by settings.json: "dock": { "palette": "x" }
// (case-insensitive, falls back to "x").
// ============================================================================

Item {
    id: root

    // --- which palette is active -------------------------------------------------
    property string paletteName: "x"

    readonly property string palettesDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/dock/palettes"

    // --- core palette (base-16) --------------------------------------------------
    property color color0: "#363537"
    property color color1: "#fc618d"
    property color color2: "#7bd88f"
    property color color3: "#fce566"
    property color color4: "#fd9353"
    property color color5: "#948ae3"
    property color color6: "#5ad4e6"
    property color color7: "#f7f1ff"
    property color color8: "#69676c"
    property color color9: "#fc618d"
    property color color10: "#7bd88f"
    property color color11: "#fce566"
    property color color12: "#fd9353"
    property color color13: "#948ae3"
    property color color14: "#5ad4e6"
    property color color15: "#f7f1ff"

    // --- semantic roles (the only thing modules should read) ----------------------
    property color background: color0
    property color foreground: color7
    property color accent: color1
    property color accent2: color5

    property color base: color0
    property color mantle: color0
    property color crust: color0
    property color text: color7
    property color subtext0: color7
    property color subtext1: color7
    property color surface0: color0
    property color surface1: color0
    property color surface2: color0
    property color overlay0: color7
    property color overlay1: color7
    property color overlay2: color7

    property color blue: color6
    property color sapphire: color6
    property color peach: color4
    property color green: color2
    property color red: color1
    property color mauve: color5
    property color pink: color5
    property color yellow: color3
    property color maroon: color9
    property color teal: color6

    // --- helpers ------------------------------------------------------------------
    // Normalize a "#rrggbb" / "#rrggbbaa" string into {r,g,b} 0..255.
    function toRGB(hex) {
        let h = String(hex || "").replace("#", "").trim();
        if (h.length >= 6) h = h.substring(0, 6);
        let n = parseInt(h, 16);
        if (isNaN(n)) return { r: 0, g: 0, b: 0 };
        return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
    }

    // Blend a into b by t (0..1). Returns "#rrggbb".
    function mix(a, b, t) {
        let ca = root.toRGB(a), cb = root.toRGB(b);
        let r = Math.round(ca.r + (cb.r - ca.r) * t);
        let g = Math.round(ca.g + (cb.g - ca.g) * t);
        let bl = Math.round(ca.b + (cb.b - ca.b) * t);
        let pad = (v) => (v < 16 ? "0" : "") + v.toString(16);
        return "#" + pad(r) + pad(g) + pad(bl);
    }

    function applyPalette(c) {
        if (!c || !c.base16) return;
        let b = c.base16;

        root.color0  = b.color0  || root.color0;
        root.color1  = b.color1  || root.color1;
        root.color2  = b.color2  || root.color2;
        root.color3  = b.color3  || root.color3;
        root.color4  = b.color4  || root.color4;
        root.color5  = b.color5  || root.color5;
        root.color6  = b.color6  || root.color6;
        root.color7  = b.color7  || root.color7;
        root.color8  = b.color8  || root.color8;
        root.color9  = b.color9  || root.color9;
        root.color10 = b.color10 || root.color10;
        root.color11 = b.color11 || root.color11;
        root.color12 = b.color12 || root.color12;
        root.color13 = b.color13 || root.color13;
        root.color14 = b.color14 || root.color14;
        root.color15 = b.color15 || root.color15;

        // Backgrounds — prefer the palette's explicit background/foreground
        // (they can differ from color0/color7), derive everything else from them.
        root.background = b.background || root.color0;
        root.foreground = b.foreground || root.color7;
        root.base   = root.background;
        root.mantle = root.mix(root.base, "#000000", 0.15);
        root.crust  = root.mix(root.base, "#000000", 0.30);
        root.text   = root.foreground;
        root.subtext0 = root.mix(root.text, root.base, 0.20);
        root.subtext1 = root.mix(root.text, root.base, 0.10);
        root.surface0 = root.mix(root.base, root.text, 0.06);
        root.surface1 = root.mix(root.base, root.text, 0.12);
        root.surface2 = root.mix(root.base, root.text, 0.20);
        root.overlay0 = root.mix(root.text, root.base, 0.45);
        root.overlay1 = root.mix(root.text, root.base, 0.35);
        root.overlay2 = root.mix(root.text, root.base, 0.25);

        // Accents — mapped from base-16, overridable per palette.
        root.red     = root.color1;
        root.green   = root.color2;
        root.yellow  = root.color3;
        root.peach   = root.color4;
        root.mauve   = root.color5;
        root.blue    = root.color6;
        root.teal    = root.color6;
        root.sapphire = root.color6;
        root.pink    = root.color5;
        root.maroon  = root.color9;
        root.accent  = root.color1;
        root.accent2 = root.color5;

        // Explicit per-palette role overrides win over derivation.
        let r = c.roles || {};
        for (let key in r) {
            if (root.hasOwnProperty(key) && key !== "paletteName" && key !== "palettesDir") {
                try { root[key] = r[key]; } catch (e) {}
            }
        }
    }

    function forceRefresh() {
        settingsReader.running = false;
        settingsReader.running = true;
    }

    function readSettings() {
        paletteReader.running = false;
        paletteReader.running = true;
    }

    // --- settings.json reader (pick the active palette name) ----------------------
    Process {
        id: settingsReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        let parsed = JSON.parse(this.text);
                        let want = (parsed.dock && parsed.dock.palette)
                                 ? String(parsed.dock.palette).toLowerCase() : "x";
                        if (root.paletteName !== want) root.paletteName = want;
                    }
                } catch (e) {}
                root.readSettings();
            }
        }
    }

    Process {
        id: settingsWatcher
        command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                settingsReader.running = false;
                settingsReader.running = true;
                settingsWatcher.running = false;
                settingsWatcher.running = true;
            }
        }
    }

    // --- palette file reader --------------------------------------------------------
    Process {
        id: paletteReader
        command: ["bash", "-c", "cat '" + root.palettesDir + "/" + root.paletteName + ".json' 2>/dev/null || cat '" + root.palettesDir + "/x.json'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text ? this.text.trim() : "";
                if (txt !== "") {
                    try { root.applyPalette(JSON.parse(txt)); } catch (e) {}
                }
            }
        }
    }

    onPaletteNameChanged: root.readSettings()

    Component.onCompleted: root.readSettings()
}
