pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
// Theme — shared desktop-widget theming singleton.
//
// Exposes the same read API the serpantinum faces consume from ThemeBackend
// (color roles, fontFamily, borderRadius, clampedBorderRadius) but derives
// every color from the ACTIVE base16 palette used by the dock
// (dock/palettes/<slug>.json, selected through settings.json -> dock.palette).
// The derivation below replicates dock/Colors.qml applyPalette()/mix()/toRGB()
// exactly, so widgets, dock and borders always agree on one palette.
//
// Live updates:
//   - settings.json is watched with inotify (palette switches, dock.font).
//   - the palette file itself is watched with inotify as well, so palette
//     edits made by the Phase-T editor re-parse and re-apply in real time
//     without any widget code having to refresh.
// Both watchers watch DIRECTORIES (settings.json and palette files are
// written atomically via mv, which kills inotify watches on the file inode)
// and every re-read goes through a content-compare choke point, so events on
// unrelated files in the same directory never trigger redundant repaints or
// refresh loops.
//
// Unlike dock/Colors.qml this singleton never touches window borders
// (no syncWindowBorders) — it is a pure read-only color backend.
// ============================================================================

Item {
    id: root

    // --- palette identity -----------------------------------------------------
    readonly property string palettesDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/dock/palettes"
    readonly property string settingsFilePath: Quickshell.env("HOME") + "/.config/hypr/settings.json"
    property string paletteName: "x"

    // Emitted whenever a palette file finished applying.
    signal paletteChanged()
    // Emitted whenever settings.json was re-read (font / palette switch).
    signal settingsChanged()

    // --- read API (mirrors serpantinum singletons/ThemeBackend.qml) -----------
    property string fontFamily: "Hack Nerd Font"
    property int borderRadius: 10
    property int clampedBorderRadius: {
        const r = root.borderRadius;
        return Math.floor(
            r <= 24
                ? r
                : 24 + Math.pow(r - 24, 0.55)
        );
    }

    property color base: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color subtext0: "#a6adc8"
    property color subtext1: "#bac2de"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color overlay0: "#6c7086"
    property color overlay1: "#7f849c"
    property color overlay2: "#9399b2"
    property color blue: "#89b4fa"
    property color sapphire: "#74c7ec"
    property color peach: "#fab387"
    property color green: "#a6e3a1"
    property color red: "#f38ba8"
    property color mauve: "#cba6f7"
    property color pink: "#f5c2e7"
    property color yellow: "#f9e2af"
    property color maroon: "#eba0ac"
    property color teal: "#94e2d5"

    // Dock-compatible convenience aliases (dock Colors exposes these too).
    property color accent: red
    property color accent2: mauve
    property color background: base
    property color foreground: text

    // --- internal base16 (needed for role derivation) --------------------------
    property color color0: "#1e1e2e"
    property color color1: "#f38ba8"
    property color color2: "#a6e3a1"
    property color color3: "#f9e2af"
    property color color4: "#fab387"
    property color color5: "#cba6f7"
    property color color6: "#89b4fa"
    property color color7: "#cdd6f4"
    property color color8: "#6c7086"
    property color color9: "#eba0ac"
    property color color10: "#a6e3a1"
    property color color11: "#f9e2af"
    property color color12: "#fab387"
    property color color13: "#cba6f7"
    property color color14: "#89b4fa"
    property color color15: "#cdd6f4"

    // --- helpers (verbatim port from dock/Colors.qml) --------------------------
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

    // Convert a QML color (or pass-through hex string) into "#rrggbb".
    function hexOf(c) {
        if (typeof c === "string") return c;
        try {
            let pad = (v) => ("0" + Math.max(0, Math.min(255, Math.round(v * 255))).toString(16)).slice(-2);
            return "#" + pad(c.r) + pad(c.g) + pad(c.b);
        } catch (e) { return "#000000"; }
    }

    // --- palette application (exact dock/Colors.qml applyPalette port) ----------
    function applyPalette(c) {
        if (!c || !c.base16) return;
        let b = c.base16;

        root.color0 = b.color0 || root.color0;
        root.color1 = b.color1 || root.color1;
        root.color2 = b.color2 || root.color2;
        root.color3 = b.color3 || root.color3;
        root.color4 = b.color4 || root.color4;
        root.color5 = b.color5 || root.color5;
        root.color6 = b.color6 || root.color6;
        root.color7 = b.color7 || root.color7;
        root.color8 = b.color8 || root.color8;
        root.color9 = b.color9 || root.color9;
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
        root.base = root.background;
        root.mantle = root.mix(root.base, "#000000", 0.15);
        root.crust = root.mix(root.base, "#000000", 0.30);
        root.text = root.foreground;
        root.subtext0 = root.mix(root.text, root.base, 0.20);
        root.subtext1 = root.mix(root.text, root.base, 0.10);
        root.surface0 = root.mix(root.base, root.text, 0.06);
        root.surface1 = root.mix(root.base, root.text, 0.12);
        root.surface2 = root.mix(root.base, root.text, 0.20);
        root.overlay0 = root.mix(root.text, root.base, 0.45);
        root.overlay1 = root.mix(root.text, root.base, 0.35);
        root.overlay2 = root.mix(root.text, root.base, 0.25);

        // Accents — mapped from base-16, overridable per palette.
        root.red = root.color1;
        root.green = root.color2;
        root.yellow = root.color3;
        root.peach = root.color4;
        root.mauve = root.color5;
        root.blue = root.color6;
        root.teal = root.color6;
        root.sapphire = root.color6;
        root.pink = root.color5;
        root.maroon = root.color9;
        root.accent = root.color1;
        root.accent2 = root.color5;

        // Explicit per-palette role overrides win over derivation.
        let r = c.roles || {};
        for (let key in r) {
            if (root.hasOwnProperty(key) && key !== "paletteName" && key !== "palettesDir") {
                try { root[key] = r[key]; } catch (e) {}
            }
        }
        root.paletteChanged();
    }

    // --- settings.json reader (active palette + font) --------------------------
    // Content-change guards: the text of the last successfully parsed
    // settings.json / palette file is remembered, and identical re-reads are
    // ignored. Directory watchers therefore stay cheap and can never fan an
    // unrelated file's event into repeated refreshes.
    property string lastSettingsJson: ""
    property string lastPaletteKey: ""

    // Single choke point for settings.json content (called by the reader and
    // after every directory-watcher wakeup).
    function applySettingsText(txt) {
        txt = txt ? txt.trim() : "";
        if (txt === "" || txt === root.lastSettingsJson) return;
        let parsed;
        try {
            parsed = JSON.parse(txt);
        } catch (e) {
            // Broken settings file: remember the text so directory-watcher
            // wakeups on unrelated files stay silent, keep the palette
            // refresh that the old code performed on parse failure.
            root.lastSettingsJson = txt;
            root.refreshPalette();
            return;
        }
        root.lastSettingsJson = txt;
        let dock = (parsed.dock && typeof parsed.dock === "object") ? parsed.dock : {};
        if (dock.font) root.fontFamily = String(dock.font);
        let want = dock.palette ? String(dock.palette).toLowerCase() : "x";
        want = want.replace(/[^a-zA-Z0-9_-]/g, "");
        if (!want) want = "x";
        if (root.paletteName !== want) {
            root.paletteName = want; // handler re-reads palette + watcher
        } else {
            root.refreshPalette();
        }
        root.settingsChanged();
    }

    // Single choke point for palette file content. The key embeds the palette
    // name, so switching between two palettes re-applies even if the files
    // happen to be byte-identical.
    function applyPaletteText(txt) {
        txt = txt ? txt.trim() : "";
        let key = root.paletteName + "|" + txt;
        if (txt === "" || key === root.lastPaletteKey) return;
        try {
            root.applyPalette(JSON.parse(txt));
            root.lastPaletteKey = key;
        } catch (e) {}
    }

    function refreshSettings() {
        settingsReader.running = false;
        settingsReader.running = true;
    }

    function refreshPalette() {
        paletteReader.running = false;
        paletteReader.running = true;
    }


    Process {
        id: settingsReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.applySettingsText(this.text)
        }
    }

    // FileView watch (no shell processes, reload-safe): settings.json is
    // replaced atomically (tmp + mv) and FileView follows the file across
    // renames, unlike an inotify watch on the inode. applySettingsText()
    // compares content and stays silent when settings.json did not change.
    FileView {
        id: settingsWatcher
        path: root.settingsFilePath
        watchChanges: true
        onFileChanged: root.refreshSettings()
    }

    // --- palette file reader -----------------------------------------------------
    Process {
        id: paletteReader
        command: ["bash", "-c", "cat '" + root.palettesDir + "/" + root.paletteName + ".json' 2>/dev/null || cat '" + root.palettesDir + "/x.json' 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyPaletteText(this.text)
        }
    }

    // --- live palette-file watcher (Phase-T palette edits refresh instantly) ------
    // FileView on the ACTIVE palette file: the editor rewrites it atomically
    // (tmp + mv) and FileView follows the path across renames — no shell
    // processes, reload-safe. applyPaletteText() re-reads and only re-applies
    // when the parsed content really differs. The watch retargets itself when
    // paletteName changes through the FileView.path binding.
    FileView {
        id: paletteWatcher
        path: root.palettesDir + "/" + root.paletteName + ".json"
        watchChanges: true
        onFileChanged: root.refreshPalette()
    }

    onPaletteNameChanged: {
        root.refreshPalette();
        root.paletteWatcher.reload();
    }

    Component.onCompleted: root.refreshSettings()
}
