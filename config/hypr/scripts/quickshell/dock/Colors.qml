import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
// Colors — Matugen-free palette system.
//
// Loads a named palette from dock/palettes/<slug>.json (base-16 from
// dock/palettes/*.json + optional explicit "roles" overrides) and derives the
// semantic roles the UI uses (base, surface0/1/2, text, subtext, overlay,
// and the accent set). Every module reads from `colors.<role>` so swapping
// the active palette never touches module code.
//
// The active palette is controlled by settings.json: "dock": { "palette": "x" }
// (case-insensitive, falls back to "x").
//
// The active palette FILE is watched too (Phase T: the DockEditor live base16
// editor rewrites dock/palettes/<slug>.json atomically), so palette edits made
// in the editor re-apply to every running Colors instance in real time through
// the same paletteApplied -> syncWindowBorders() chain the palette switcher
// uses. The watcher targets the palettes DIRECTORY (atomic tmp+mv writes
// replace the file and would kill a watch on the file inode) and every re-read
// goes through a content-compare choke point, so events on unrelated palette
// files (or identical rewrites) never cause redundant repaints.
//
// settings.json is watched the same way (directory watch on ~/.config/hypr,
// atomic-write safe) with its own content choke point: the shell writes the
// file via tmp+mv, which kills file-inode watches, and events on unrelated
// files of the config directory must not re-fire settingsUpdated().
// ============================================================================

Item {
    id: root

    // --- which palette is active -------------------------------------------------
    property string paletteName: "x"

    // Latest parsed "dock" section of settings.json (border overrides, etc.)
    property var dockSettings: ({})
    // Latest explicit per-palette role overrides (borderActive/borderInactive…)
    property var _roles: ({})
    // Content guard for the palette file watcher: text of the last applied
    // palette file, keyed by palette name (so switching between two palettes
    // with byte-identical files still re-applies).
    property string lastPaletteKey: ""
    // Content guard for the settings.json reader: text of the last successfully
    // parsed settings file. Directory watchers wake on ANY event under
    // ~/.config/hypr, so identical content must not re-fire settingsUpdated()
    // nor re-read the palette (Theme.qml uses the same choke-point pattern).
    property string lastSettingsJson: ""

    // Emitted whenever the active palette finished applying (per instance).
    signal paletteApplied()
    // Emitted whenever settings.json was re-read (per instance).
    signal settingsUpdated()

    readonly property string palettesDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/dock/palettes"
    readonly property string settingsFilePath: Quickshell.env("HOME") + "/.config/hypr/settings.json"

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
    // Optional per-palette override for the WORKSPACE active fill (roles
    // "workspaceActive" in a palette file). Transparent = unset → modules fall
    // back to colors.mauve, so themes without the key are untouched.
    property color workspaceActive: "transparent"

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

    // Convert a QML color (or pass-through hex string) into "#rrggbb".
    function hexOf(c) {
        if (typeof c === "string") return c;
        try {
            let pad = (v) => ("0" + Math.max(0, Math.min(255, Math.round(v * 255))).toString(16)).slice(-2);
            return "#" + pad(c.r) + pad(c.g) + pad(c.b);
        } catch (e) { return "#000000"; }
    }

    // Effective window-border color for a given border ("active"|"inactive"):
    // manual override when "follow palette" is off, per-palette role override,
    // else derived from the palette (active = accent, inactive = muted).
    function borderHex(which) {
        const d = root.dockSettings || {};
        const valid = (s) => typeof s === "string" && /^#[0-9a-fA-F]{6}$/.test(s);
        if (d.borderFollowPalette === false) {
            const saved = which === "active" ? d.borderActive : d.borderInactive;
            if (valid(saved)) return saved.toLowerCase();
        }
        const r = root._roles || {};
        if (which === "active") return valid(r.borderActive) ? r.borderActive.toLowerCase() : root.hexOf(root.accent);
        return valid(r.borderInactive) ? r.borderInactive.toLowerCase() : root.hexOf(root.color8);
    }

    // Push the effective border colors to Hyprland LIVE (no window restart)
    // using `hyprctl eval` with the Lua config API. Only touches the border
    // option; nothing else is modified.
    function syncWindowBorders() {
        const a = root.borderHex("active").slice(1);
        const i = root.borderHex("inactive").slice(1);
        const lua = 'hl.config({ general = { col = { active_border = "rgba(' + a + 'ee)", inactive_border = "rgba(' + i + 'aa)" } } })';
        const cmd = "hyprctl eval '" + lua + "' 2>/dev/null";
        Quickshell.execDetached(["bash", "-c", cmd]);
        // Keep the SDDM login theme in sync with the active palette (local file
        // always regenerates; the sudo copy to /usr/share silently no-ops when
        // passwordless sudo is unavailable).
        Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/sddm-colors.sh >/dev/null 2>&1"]);
        // Sync kitty + nvim themes to the active palette.
        Quickshell.execDetached(["bash", "-c", "bash ~/.config/hypr/scripts/theme-sync.sh >/dev/null 2>&1"]);
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
        root._roles = (c.roles && typeof c.roles === "object") ? c.roles : {};
        root.paletteApplied();
    }

    function forceRefresh() {
        settingsReader.running = false;
        settingsReader.running = true;
    }

    function readSettings() {
        paletteReader.running = false;
        paletteReader.running = true;
    }

    // Single choke point for palette file content. The key embeds the palette
    // name, so switching between two palettes re-applies even if the files
    // happen to be byte-identical; identical rewrites of the same palette
    // (e.g. a DockEditor commit that did not actually change the value) are
    // ignored so directory-watcher wakeups stay cheap and never loop.
    function applyPaletteText(txt) {
        txt = txt ? txt.trim() : "";
        let key = root.paletteName + "|" + txt;
        if (txt === "" || key === root.lastPaletteKey) return;
        try {
            root.applyPalette(JSON.parse(txt));
            root.lastPaletteKey = key;
        } catch (e) {}
    }

    // --- settings.json reader (pick the active palette name) ----------------------
    Process {
        id: settingsReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text ? this.text.trim() : "";
                if (txt === "" || txt === "{}") return;
                // Choke point: the directory watcher wakes on unrelated config
                // file events too — identical content must stay silent.
                if (txt === root.lastSettingsJson) return;
                try {
                    let parsed = JSON.parse(txt);
                    root.lastSettingsJson = txt;
                    root.dockSettings = (parsed.dock && typeof parsed.dock === "object") ? parsed.dock : {};
                    let want = (parsed.dock && parsed.dock.palette)
                             ? String(parsed.dock.palette).toLowerCase() : "x";
                    if (root.paletteName !== want) root.paletteName = want;
                    root.settingsUpdated();
                } catch (e) {
                    return;
                }
                // Apply the (possibly switched) active palette file.
                root.readSettings();
            }
        }
    }

    // FileView watch (no shell processes, reload-safe): settings.json is
    // replaced atomically (tmp + mv) and FileView follows the file across
    // renames, unlike an inotify watch on the inode. Any change re-runs the
    // reader; the content choke point above keeps identical rewrites silent.
    FileView {
        id: settingsWatcher
        path: root.settingsFilePath
        watchChanges: true
        onFileChanged: root.forceRefresh()
    }

    // --- palette file reader --------------------------------------------------------
    Process {
        id: paletteReader
        command: ["bash", "-c", "cat '" + root.palettesDir + "/" + root.paletteName + ".json' 2>/dev/null || cat '" + root.palettesDir + "/x.json'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyPaletteText(this.text)
        }
    }

    // --- live watcher on the active palette file (Phase-T DockEditor edits) ---------
    // FileView on the ACTIVE palette file: the editor rewrites it atomically
    // (tmp + mv) and FileView follows the path across renames — no shell
    // processes, reload-safe. applyPaletteText() stays silent when the content
    // did not actually change, so the DockEditor <-> Colors refresh loop is
    // impossible. The watch retargets automatically when paletteName changes
    // (FileView.path binding) and re-reads through the paletteReader process.
    FileView {
        id: paletteWatcher
        path: root.palettesDir + "/" + root.paletteName + ".json"
        watchChanges: true
        onFileChanged: root.readSettings()
    }

    onPaletteNameChanged: {
        root.readSettings();
        root.paletteWatcher.reload();
    }

    Component.onCompleted: root.readSettings()
}
