import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "../WindowRegistry.js" as LayoutMath
import "DockLayout.js" as DockLayout
import "Colors.qml"
import "edit"

// ═══════════════════════════════════════════════════════════════════════════
// DockEditor — the dock mega menu (SUPER+SHIFT+D).
//
// Matches the QuickShell widget aesthetic (SettingsPopup-style): a rounded
// panel with a single scrollable column of section cards (surface0 + surface1
// border). Every edit writes live to settings.json "dock" and the dock
// hot-reloads through its own watcher.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root

    property var notifModel: null
    property var liveNotifs: null
    property int layoutWidth: 0
    property int layoutHeight: 0
    implicitWidth: layoutWidth > 0 ? layoutWidth : s(900)
    implicitHeight: layoutHeight > 0 ? layoutHeight : s(700)

    property real uiScale: 1.0
    readonly property real baseScale: LayoutMath.getScale(Screen.width, Screen.height, root.uiScale)
    function s(val) { return LayoutMath.s(val, baseScale); }

    Colors { id: themeColors }
    readonly property var colors: themeColors

    property var dock: DockLayout.defaultDock()
    property var palettes: ([])
    property bool _dirty: false
    property bool borderTargetActive: true

    // ════ DUAL ENGINE STATE (Phase D4-E2) ════
    // The editor edits whichever engine the settings say is live: "dock"
    // (zone cards) or "serp" (serpbar cards). root.serp mirrors settings.json's
    // top-level "serpbar" key; the dock config is preserved untouched while
    // the serp engine is active (and vice versa).
    property string engine: "dock"
    property var serp: DockLayout.serpbarDefaults()
    property bool _serpDirty: false

    Timer { id: saveTimer; interval: 220; onTriggered: flushSave() }
    function markDirty() { _dirty = true; saveTimer.restart(); }
    // Serp edits share the same debounce; flushSave() writes whichever key is
    // dirty ("dock" and "serpbar" are independent top-level settings keys, so
    // the two queues never clobber each other and the dock flush is intact).
    function markDirtySerp() { _serpDirty = true; saveTimer.restart(); }
    function flushSave() {
        if (_dirty) {
            _dirty = false;
            Config.setSetting("dock", root.dock);
        }
        if (_serpDirty) {
            _serpDirty = false;
            Config.setSetting("serpbar", root.serp);
        }
    }
    function applyDock(dock) { root.dock = dock; root.markDirty(); }
    function reload() {
        root.dock = DockLayout.getDock(Config.rawSettings);
        root.engine = Config.rawSettings.barEngine === "serp" ? "serp" : "dock";
        root.serp = DockLayout.getSerpbar(Config.rawSettings);
    }

    // ════ ENGINE SWITCHING + SERP EDITS (Phase D4-E2) ════
    // Hot engine switch: writes the top-level "barEngine" key; the live dock
    // host swaps its render engine in-process (no reload) and never touches
    // the persisted "dock" config. The FIRST switch to "serp" seeds the
    // "serpbar" key from the dock's position + ENABLED modules, so the classic
    // bar starts with the current layout instead of the stock defaults.
    function setEngine(v) {
        if (v === "serp") {
            let raw = Config.rawSettings;
            let sb = raw.serpbar;
            if (!sb || typeof sb !== "object") {
                let init = DockLayout.serpbarDefaults();
                init.position = root.dock.position;
                init.modules = DockLayout.dockToSerpModules(root.dock);
                init = DockLayout.normalizeSerpbar(init);
                Config.setSetting("serpbar", init);
                root.serp = init;
            } else {
                root.serp = DockLayout.getSerpbar(raw);
            }
            Config.setSetting("barEngine", "serp");
        } else {
            Config.setSetting("barEngine", "dock");
        }
        root.engine = v === "serp" ? "serp" : "dock";
    }

    // Full-config commit (already normalized): replace root.serp + queue save.
    function commitSerp(cfg) {
        root.serp = cfg;
        root.markDirtySerp();
    }

    // Shallow partial merge (position/style/width/autohide/modules/...) then
    // normalize, so the in-memory state always satisfies the host invariants
    // before the debounced file write lands.
    function applySerp(partial) {
        root.commitSerp(DockLayout.normalizeSerpbar(Object.assign({}, root.serp, partial)));
    }

    // Pure-engine op helper: compute `next` through DockLayout and commit only
    // when the JSON really changed (no-op drops never write settings).
    function commitSerpOp(next) {
        if (next && JSON.stringify(next) !== JSON.stringify(root.serp)) root.commitSerp(next);
    }

    // Chips send modules back to the pool / break a cluster apart.
    function serpRemoveModule(id) {
        root.commitSerpOp(DockLayout.serpMoveTo(root.serp, id, "available", 0));
    }
    function serpUngroupAt(list, itemIndex) {
        root.commitSerpOp(DockLayout.serpUngroup(root.serp, list, itemIndex));
    }

    // "Serp defaults": stock layout (including the module lists) while keeping
    // the position the user currently has the bar at.
    function serpDefaultsAction() {
        let d = DockLayout.serpbarDefaults();
        d.position = root.serp.position;
        root.applySerp(d);
    }

    // Member count of the group currently being dragged (0 = module drag).
    function serpGroupCount() {
        if (root.dndModuleId !== "" || root.dndSourceSerpList === "" || root.dndSourceItemIndex < 0) return 0;
        let list = root.serp.modules[root.dndSourceSerpList];
        if (!list || root.dndSourceItemIndex >= list.length) return 0;
        let item = list[root.dndSourceItemIndex];
        return (typeof item === "object" && DockLayout.isList(item)) ? item.length : 0;
    }

    // ════ BAR STYLE PRESETS (Phase D3) ════
    function applyStyle(preset) {
        root.applyDock(DockLayout.applyStylePreset(root.dock, preset));
    }

    // ════ MODULE CHIP DRAG & DROP (Phase D3) ════
    // One editor-wide session: a chip MouseArea in a ZoneEditorCard crosses its
    // threshold and calls startDnd(); we then own the gesture — paint the ghost
    // at the pointer, highlight the card under the cursor (dndActive) with its
    // insertion index (dndInsertIndex), auto-scroll the editor when the pointer
    // nears the top/bottom edge, and commit with DockLayout.moduleMoveTo on
    // release (drop outside every card = cancel). The whole session keeps
    // root.dock untouched until the drop, so no-op drops never write settings.
    property bool dndBusy: false
    property string dndModuleId: ""
    property string dndSourceZoneId: ""
    property point dndPointer: Qt.point(-10000, -10000)

    // Serp drags additionally remember where the dragged item sits: module
    // drags (loose chip, group member or pool chip) keep dndSourceItemIndex
    // at -1 because removal is by id; whole-GROUP drags use dndModuleId === ""
    // and point dndSourceItemIndex at the group's ITEM in dndSourceSerpList.
    property string dndSourceSerpList: ""
    property int dndSourceItemIndex: -1

    // Live list of zone cards (children of the Zones column; filtered by the
    // isZoneEditorCard marker so the Repeater object itself is skipped). Only
    // reachable while the dock engine UI is showing: hidden dock cards would
    // still answer containsRootPoint geometrically, so they are excluded.
    function zoneCards() {
        if (root.engine !== "dock") return [];
        let out = [];
        let kids = zonasCol.children;
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (c && c.isZoneEditorCard) out.push(c);
        }
        return out;
    }

    // Live list of serp list cards (children of the Modules card's column,
    // isSerpEditorCard marker), only reachable while the serp UI is showing.
    function serpCards() {
        if (root.engine !== "serp") return [];
        let out = [];
        let kids = serpListsCol.children;
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (c && c.isSerpEditorCard) out.push(c);
        }
        return out;
    }

    // Both engine UIs never render at the same time, so the target universe is
    // always exactly one kind of card — the manager can branch without fear of
    // overlapping drop zones.
    function dndTargets() {
        return root.engine === "dock" ? root.zoneCards() : root.serpCards();
    }

    function startDnd(zoneId, moduleId) {
        if (root.dndBusy) return;
        root.dndBusy = true;
        root.dndModuleId = moduleId;
        root.dndSourceZoneId = zoneId;
        root.dndSourceSerpList = "";
        root.dndSourceItemIndex = -1;
        if (editorFlick) editorFlick.interactive = false;
    }

    // Serp chips enter the SAME editor-wide session: moduleId "" marks a
    // whole-group drag whose itemIndex locates the group ITEM in listId.
    function startSerpDnd(listId, moduleId, itemIndex) {
        if (root.dndBusy) return;
        root.dndBusy = true;
        root.dndModuleId = moduleId || "";
        root.dndSourceZoneId = "";
        root.dndSourceSerpList = listId;
        root.dndSourceItemIndex = (moduleId === "") ? (isFinite(itemIndex) ? itemIndex : -1) : -1;
        if (editorFlick) editorFlick.interactive = false;
    }

    // Pointer moved (root/editor coordinates): repaint ghost + drop feedback.
    // Zone and serp cards share one state vocabulary; serp cards additionally
    // expose a join slot (drop INTO a group under the pointer).
    function updateDnd(px, py) {
        if (!root.dndBusy) return;
        root.dndPointer = Qt.point(px, py);
        let targets = root.dndTargets();
        let target = null;
        for (let i = 0; i < targets.length; i++) {
            if (targets[i].containsRootPoint(px, py)) { target = targets[i]; break; }
        }
        for (let i = 0; i < targets.length; i++) {
            let c = targets[i];
            if (c === target) {
                if (!c.dndActive) c.dndActive = true;
                if (c.isSerpEditorCard) {
                    let j = c.groupJoinIndexAt(px, py);
                    if (c.dndJoinIndex !== j) c.dndJoinIndex = j;
                }
                let idx = c.dropIndexAt(px, py);
                if (c.dndInsertIndex !== idx) c.dndInsertIndex = idx;
            } else {
                if (c.dndActive) { c.dndActive = false; c.dndInsertIndex = -1; }
                if (c.isSerpEditorCard && c.dndJoinIndex !== -1) c.dndJoinIndex = -1;
            }
        }
    }

    // Drop: commit only when released over a card. The TARGET KIND decides the
    // engine: zone cards (dock UI) commit through DockLayout.moduleMoveTo +
    // applyDock; serp cards (serp UI) branch by payload — module drags join
    // the group under the pointer when the card offers one, otherwise they
    // insert as a loose item (a drop on "available" only detaches the module
    // from the bar); whole-group drags relocate the cluster, or release it on
    // "available". Both engines write through the shared debounced queue, and
    // identical-result drops (JSON-equal) never write settings.
    function endDnd(px, py) {
        if (!root.dndBusy) return;
        let target = null;
        let targets = root.dndTargets();
        for (let i = 0; i < targets.length; i++) {
            if (targets[i].containsRootPoint(px, py)) { target = targets[i]; break; }
        }
        let id = root.dndModuleId;
        let result = null;
        if (target) {
            if (target.isZoneEditorCard && id !== "") {
                let idx = target.dropIndexAt(px, py);
                if (idx >= 0) {
                    result = DockLayout.moduleMoveTo(root.dock, id, target.cardZoneId, idx);
                    if (JSON.stringify(result) === JSON.stringify(root.dock)) result = null;
                }
            } else if (target.isSerpEditorCard) {
                if (id !== "") {
                    if (target.dndTargetId === "available") {
                        result = DockLayout.serpMoveTo(root.serp, id, "available", 0);
                    } else {
                        let joinIdx = target.groupJoinIndexAt(px, py);
                        if (joinIdx >= 0) {
                            result = DockLayout.serpJoinGroup(root.serp, id, target.dndTargetId, joinIdx);
                        } else {
                            let idx = target.dropIndexAt(px, py);
                            if (idx >= 0) result = DockLayout.serpMoveTo(root.serp, id, target.dndTargetId, idx);
                        }
                    }
                    if (result && JSON.stringify(result) === JSON.stringify(root.serp)) result = null;
                } else {
                    // whole-group drag: move (or release) the cluster
                    let idx = target.dropIndexAt(px, py);
                    if (idx >= 0) {
                        result = DockLayout.serpMoveGroupTo(root.serp, root.dndSourceSerpList, root.dndSourceItemIndex, target.dndTargetId, idx);
                        if (JSON.stringify(result) === JSON.stringify(root.serp)) result = null;
                    }
                }
            }
        }
        root.clearDnd();
        if (result) {
            if (target && target.isZoneEditorCard) root.applyDock(result);
            else root.commitSerp(result);
        }
    }

    // Release anywhere (or session abort): restore interactive scrolling.
    function cancelDnd() { root.clearDnd(); }
    function clearDnd() {
        let cards = root.dndTargets();
        for (let i = 0; i < cards.length; i++) {
            let c = cards[i];
            c.dndActive = false;
            c.dndInsertIndex = -1;
            if (c.isSerpEditorCard && c.dndJoinIndex !== -1) c.dndJoinIndex = -1;
        }
        root.dndBusy = false;
        root.dndModuleId = "";
        root.dndSourceZoneId = "";
        root.dndSourceSerpList = "";
        root.dndSourceItemIndex = -1;
        root.dndPointer = Qt.point(-10000, -10000);
        if (editorFlick) editorFlick.interactive = true;
    }

    // Auto-scroll while dragging: keeps off-screen zone cards reachable.
    Timer {
        id: dndScrollTimer
        interval: 16
        repeat: true
        running: root.dndBusy
        onTriggered: {
            if (!editorFlick || !root.dndBusy) return;
            let local = editorFlick.mapFromItem(root, root.dndPointer.x, root.dndPointer.y);
            let band = root.s(26);
            if (local.y < band) {
                editorFlick.contentY = Math.max(0, editorFlick.contentY - root.s(5));
            } else if (local.y > editorFlick.height - band) {
                let maxY = Math.max(0, editorFlick.contentHeight - editorFlick.height);
                editorFlick.contentY = Math.min(maxY, editorFlick.contentY + root.s(5));
            }
        }
    }

    Component.onCompleted: {
        reload();
        paletteReader.running = true;
        scaleReader.running = true;
        // Push window-border colors to Hyprland live whenever the palette
        // re-applies or settings.json changes (only this instance pushes).
        themeColors.paletteApplied.connect(function() { themeColors.syncWindowBorders(); });
        themeColors.settingsUpdated.connect(function() { themeColors.syncWindowBorders(); });
        // Live palette editor: mirror every palette re-apply into the slot
        // rows and refresh the Reset state (own edits, palette switches and
        // external file changes all land here).
        themeColors.paletteApplied.connect(function() { root.syncSlotValues(); });
        themeColors.paletteNameChanged.connect(function() { root.checkBackupExists(); });
        root.syncSlotValues();
    }

    Process {
        id: scaleReader
        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null | jq -r '.uiScale // 1'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseFloat(this.text.trim());
                if (!isNaN(v) && v > 0) root.uiScale = v;
            }
        }
    }

    Process {
        id: paletteReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/dock/palettes/index.json"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.palettes = JSON.parse(this.text.trim()); } catch (e) {}
            }
        }
    }

    // ════ LIVE PALETTE EDITOR (Phase T) ════
    // Edits the ACTIVE palette file (dock/palettes/<slug>.json) straight from
    // the Palette card: validated hex commits are debounced (~250 ms, grouped
    // per palette) and written atomically with jq (tmp + mv, preserving
    // name/author/slug/roles and unknown keys). The first edit of a palette
    // snapshots the pristine file to
    // ~/.local/state/quickshell/palette_backup/<slug>.json; "Reset" restores
    // that snapshot atomically and removes it. settings.json is never touched:
    // the palette file IS the source. Every Colors instance watches the
    // palettes directory (see dock/Colors.qml) and the Theme singleton does
    // too, so edits re-apply live to the dock, window borders (via
    // syncWindowBorders), kitty/starship/SDDM and the desktop-widget faces.
    property bool paletteEditOpen: false
    property bool _hasSessionBackup: false
    property var _slotRows: ([])
    property var _pendingWrite: null
    property var slotDescriptors: [
        { key: "color0", label: "color0" },
        { key: "color1", label: "color1" },
        { key: "color2", label: "color2" },
        { key: "color3", label: "color3" },
        { key: "color4", label: "color4" },
        { key: "color5", label: "color5" },
        { key: "color6", label: "color6" },
        { key: "color7", label: "color7" },
        { key: "color8", label: "color8" },
        { key: "color9", label: "color9" },
        { key: "color10", label: "color10" },
        { key: "color11", label: "color11" },
        { key: "color12", label: "color12" },
        { key: "color13", label: "color13" },
        { key: "color14", label: "color14" },
        { key: "color15", label: "color15" },
        { key: "background", label: "background" },
        { key: "foreground", label: "foreground" }
    ]

    Timer {
        id: paletteWriteTimer
        interval: 250
        onTriggered: root.flushPaletteWrite()
    }

    Process {
        id: backupProbe
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._hasSessionBackup = (this.text && this.text.trim() !== "")
        }
    }

    function activeSlug() {
        return String(themeColors.paletteName || "x").replace(/[^a-zA-Z0-9_-]/g, "");
    }
    function paletteFilePath(slug) { return themeColors.palettesDir + "/" + slug + ".json"; }
    function backupDir() { return Quickshell.env("HOME") + "/.local/state/quickshell/palette_backup"; }
    function backupFilePath(slug) { return root.backupDir() + "/" + slug + ".json"; }

    // Display hex of a slot (base16 colorN or top-level background/foreground),
    // read from the local Colors instance that mirrors the active palette file.
    function slotColorHex(key) {
        if (key === "background") return themeColors.hexOf(themeColors.background);
        if (key === "foreground") return themeColors.hexOf(themeColors.foreground);
        let n = key.length > 5 ? key.substring(5) : "";
        return themeColors.hexOf(themeColors["color" + n]);
    }

    function registerSlot(key, field, chip) {
        for (let i = 0; i < root._slotRows.length; i++) {
            if (root._slotRows[i].key === key) return;
        }
        let hex = root.slotColorHex(key);
        root._slotRows.push({ key: key, field: field, chip: chip });
        field.text = hex;
        chip.color = hex;
    }

    // Re-read every slot from themeColors (kept live by the file watcher).
    // Rows whose hex field is focused keep their in-progress draft untouched.
    function syncSlotValues() {
        for (let i = 0; i < root._slotRows.length; i++) {
            let s = root._slotRows[i];
            if (s.field.activeFocus) continue;
            let hex = root.slotColorHex(s.key);
            s.field.text = hex;
            s.chip.color = hex;
        }
    }

    // Valid hex commit (hexField.onEditingFinished): normalize to lowercase,
    // reflect the value in its row immediately, then queue the debounced
    // atomic file write (batched: rapid edits of several slots share one jq).
    function commitPaletteSlot(key, hex) {
        hex = String(hex || "").toLowerCase();
        if (!/^#[0-9a-f]{6}$/.test(hex)) return;
        for (let i = 0; i < root._slotRows.length; i++) {
            if (root._slotRows[i].key === key) {
                root._slotRows[i].field.text = hex;
                root._slotRows[i].chip.color = hex;
                break;
            }
        }
        let slug = root.activeSlug();
        if (root._pendingWrite && root._pendingWrite.slug !== slug) root.flushPaletteWrite();
        if (!root._pendingWrite) root._pendingWrite = { slug: slug, edits: {} };
        root._pendingWrite.edits[key] = hex;
        paletteWriteTimer.restart();
    }

    // Commit entry point for a hex field: Enter, focus-out or blur all land
    // here. Valid hexes are committed (live write), anything else drops the
    // draft and shows the currently applied color again.
    function finishSlotEdit(field, key) {
        let t = field.text.trim();
        if (field.acceptableInput && /^#[0-9a-fA-F]{6}$/.test(t)) {
            root.commitPaletteSlot(key, t);
        } else {
            field.text = root.slotColorHex(key);
        }
    }

    function flushPaletteWrite() {
        let w = root._pendingWrite;
        if (!w) return;
        root._pendingWrite = null;
        let keys = Object.keys(w.edits);
        if (keys.length === 0) return;
        let slug = w.slug;
        let dir = themeColors.palettesDir;
        let file = root.paletteFilePath(slug);
        let backup = root.backupFilePath(slug);
        let args = [], parts = [];
        for (let i = 0; i < keys.length; i++) {
            let k = keys[i];
            args.push("--arg", "a" + i, w.edits[k]);
            parts.push(((k === "background" || k === "foreground") ? "." : ".base16.") + k + " = $a" + i);
        }
        // The chain snapshots the pristine file on the FIRST edit of the
        // palette: mkdir + cp are guarded by [ ! -f backup ], so a snapshot
        // from an earlier session is never overwritten and Reset always
        // restores the state the palette had before it was first edited.
        let cmd = "mkdir -p '" + root.backupDir() + "' && { [ ! -f '" + backup + "' ] && cp '" + file + "' '" + backup + "'; }; "
                + "tmp=$(mktemp '" + dir + "/palette.tmp.XXXXXX') && "
                + "jq " + args.join(" ") + " '" + parts.join(" | ") + "' '" + file + "' > \"$tmp\" && "
                + "mv \"$tmp\" '" + file + "'; rm -f \"$tmp\"";
        Quickshell.execDetached(["bash", "-c", cmd]);
        Qt.callLater(root.checkBackupExists);
    }

    // Restore the session snapshot of the ACTIVE palette (atomic, same
    // tmp + mv pattern), then delete it so the button disables again.
    function resetActivePalette() {
        if (!root._hasSessionBackup) return;
        let slug = root.activeSlug();
        let dir = themeColors.palettesDir;
        let file = root.paletteFilePath(slug);
        let backup = root.backupFilePath(slug);
        let cmd = "tmp=$(mktemp '" + dir + "/restore.tmp.XXXXXX') && "
                + "cp '" + backup + "' \"$tmp\" && "
                + "mv \"$tmp\" '" + file + "' && "
                + "rm -f '" + backup + "'; rm -f \"$tmp\"";
        Quickshell.execDetached(["bash", "-c", cmd]);
        root._hasSessionBackup = false;
        Qt.callLater(root.syncSlotValues);
        Qt.callLater(root.checkBackupExists);
    }

    // Async existence check of the CURRENT palette's session snapshot; drives
    // the Reset button's enabled look. Refresh on open, on write and on reset.
    function checkBackupExists() {
        backupProbe.command = ["bash", "-c", "cat '" + root.backupFilePath(root.activeSlug()) + "' 2>/dev/null | head -c 1"];
        backupProbe.running = false;
        backupProbe.running = true;
    }

    // Never lose a queued edit: the popup instance can be torn down right
    // after closing (StackView clear), so flush any pending write on destroy.
    Component.onDestruction: root.flushPaletteWrite()

    // ════ PANEL (widget-style) ════
    Rectangle {
        anchors.fill: parent
        anchors.margins: s(10)
        radius: s(26)
        color: Qt.rgba(colors.base.r, colors.base.g, colors.base.b, 0.97)
        border.width: s(1)
        border.color: colors.surface0
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: s(16)
            spacing: s(10)

            // header
            Row {
                width: parent.width
                spacing: s(10)
                Rectangle {
                    width: s(34); height: s(34); radius: s(10)
                    color: colors.accent
                    Text { anchors.centerIn: parent; text: "󰫧"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: colors.base }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Dock Editor"; font.family: "Hack Nerd Font"; font.pixelSize: s(17); font.weight: Font.Black; color: colors.text }
                    Text { text: "Customize the bar · SUPER+SHIFT+D · ESC to close"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: colors.overlay1 }
                }
            }
            Rectangle { width: parent.width; height: 1; color: colors.surface1; opacity: 0.5 }

            // scrollable cards
            Flickable {
                id: editorFlick
                width: parent.width
                height: parent.height - s(64)
                contentHeight: cardsCol.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: cardsCol
                    width: parent.width
                    spacing: s(12)

                    // ── CARD: ENGINE (D4-E2) ───────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: engineCol.implicitHeight + s(28)
                        Column {
                            id: engineCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Engine" }
                            Row {
                                width: parent.width
                                spacing: s(8)
                                EditPill { bar: root; text: "Dock"; active: root.engine === "dock"; onActivated: root.setEngine("dock") }
                                EditPill { bar: root; text: "Serpantinum"; active: root.engine === "serp"; onActivated: root.setEngine("serp") }
                            }
                            EditLabel {
                                width: parent.width
                                text: "Hot switch between the zone dock and the left/center/right bar."
                                font.pixelSize: s(10)
                                color: colors.overlay1
                            }
                        }
                    }

                    // ── CARD: POSICIÓN ────────────────────────────────────────
                    Rectangle {
                        visible: root.engine === "dock"
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: posCol.implicitHeight + s(28)
                        Column {
                            id: posCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Position" }
                            Row {
                                width: parent.width
                                spacing: s(8)
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "top";    label: "Top";    glyph: "↑" }
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "bottom"; label: "Bottom";     glyph: "↓" }
                            }
                            Row {
                                width: parent.width
                                spacing: s(8)
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "left";   label: "Left"; glyph: "←" }
                                PosCard { width: (parent.width - s(8)) / 2; bar: root; dockRef: root.dock; pos: "right";  label: "Right";   glyph: "→" }
                            }
                        }
                    }

                    // ── CARD: PALETA ──────────────────────────────────────────
                    // Shown in BOTH engines (Phase R1): the palette is shared
                    // through settings.json "dock.palette" — the classic serp
                    // bar reads the same Colors roles, so switching palettes
                    // recolors whichever engine is live. Writes go through
                    // root.dock (the persisted dock config) exactly as before.
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: palCol.implicitHeight + s(28)
                        Column {
                            id: palCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(10)
                            SectionTitle { bar: root; text: "Palette" }
                            Flickable {
                                width: parent.width
                                height: s(100)
                                contentWidth: palRow.width
                                clip: true
                                Row {
                                    id: palRow
                                    spacing: s(8)
                                    Repeater {
                                        model: root.palettes
                                        delegate: Item {
                                            required property var modelData
                                            property var pal: modelData
                                            width: s(70)
                                            height: s(100)
                                            Rectangle {
                                                width: parent.width
                                                height: s(70)
                                                radius: s(10)
                                                color: root.dock.palette === pal.slug ? colors.accent : colors.surface2
                                                opacity: root.dock.palette === pal.slug ? 1 : 0.5
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Rectangle {
                                                    anchors.fill: parent
                                                    anchors.margins: s(2)
                                                    radius: s(8)
                                                    color: colors.base
                                                    Column {
                                                        anchors.centerIn: parent
                                                        spacing: s(3)
                                                        Row {
                                                            spacing: s(3)
                                                            Repeater { model: [0,1,2]; delegate: Rectangle { width: s(12); height: s(8); radius: s(2); color: pal.colors[0] } }
                                                        }
                                                        Row {
                                                            spacing: s(3)
                                                            Repeater { model: [0,1,2]; delegate: Rectangle { width: s(12); height: s(8); radius: s(2); color: pal.colors[1 + index] } }
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: s(3)
                                                    width: s(14); height: s(14); radius: s(7)
                                                    visible: root.dock.palette === pal.slug
                                                    color: colors.base
                                                    Text { anchors.centerIn: parent; text: "✓"; font.family: "Hack Nerd Font"; font.pixelSize: s(9); color: colors.accent }
                                                }
                                            }
                                            Text {
                                                anchors.top: parent.top; anchors.topMargin: s(74)
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: pal.name
                                                font.family: "Hack Nerd Font"; font.pixelSize: s(10); font.weight: Font.Bold
                                                color: root.dock.palette === pal.slug ? colors.text : colors.overlay1
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: root.applyDock(Object.assign({}, root.dock, { palette: pal.slug }))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Actions row: open/close the live base16 editor + Reset
                        // (dimmed and inert until a session snapshot exists).
                        Item {
                            width: parent.width
                            height: s(30)
                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: s(8)
                                EditPill {
                                    bar: root
                                    text: "Edit colors"
                                    active: root.paletteEditOpen
                                    onActivated: {
                                        root.paletteEditOpen = !root.paletteEditOpen;
                                        if (root.paletteEditOpen) {
                                            root.syncSlotValues();
                                            root.checkBackupExists();
                                        }
                                    }
                                }
                                EditPill {
                                    bar: root
                                    text: "Reset"
                                    opacity: root._hasSessionBackup ? 1 : 0.45
                                    onActivated: root.resetActivePalette()
                                }
                            }
                            EditLabel {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.paletteEditOpen ? ("Editing " + root.activeSlug() + (root._hasSessionBackup ? " · snapshot ready" : " · first edit saves a snapshot"))
                                                           : "Recolor the active palette file live"
                                font.pixelSize: s(10)
                                color: colors.overlay1
                            }
                        }

                        // Inline base16 editor (visible while editing): 18 slots
                        // (color0..15 + background + foreground), one compact
                        // row per slot, 3 per line so nothing breaks the width.
                        Column {
                            width: parent.width
                            visible: root.paletteEditOpen
                            spacing: s(6)
                            Flow {
                                id: slotFlow
                                width: parent.width
                                spacing: s(8)
                                Repeater {
                                    model: root.slotDescriptors
                                    delegate: Item {
                                        required property var modelData
                                        width: (slotFlow.width - s(16)) / 3
                                        height: s(26)
                                        Row {
                                            anchors.fill: parent
                                            spacing: s(6)
                                            Rectangle {
                                                id: chip
                                                width: s(18)
                                                height: s(18)
                                                anchors.verticalCenter: parent.verticalCenter
                                                radius: s(5)
                                                border.width: 1
                                                border.color: colors.surface2
                                            }
                                            Text {
                                                text: modelData.label
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: s(64)
                                                font.family: "Hack Nerd Font"
                                                font.pixelSize: s(10)
                                                font.weight: Font.Bold
                                                color: colors.text
                                            }
                                            TextField {
                                                id: hexField
                                                width: s(96)
                                                height: s(24)
                                                anchors.verticalCenter: parent.verticalCenter
                                                font.family: "Hack Nerd Font"
                                                font.pixelSize: s(11)
                                                color: colors.text
                                                selectByMouse: true
                                                maximumLength: 7
                                                validator: RegularExpressionValidator { regularExpression: /^#[0-9a-fA-F]{6}$/ }
                                                background: Rectangle {
                                                    color: colors.surface1
                                                    radius: s(6)
                                                    border.width: 1
                                                    border.color: hexField.acceptableInput ? colors.surface2 : "#e05561"
                                                }
                                                onEditingFinished: root.finishSlotEdit(hexField, modelData.key)
                                                onActiveFocusChanged: {
                                                    // Commit on blur too (clicking another row / closing the editor).
                                                    if (!hexField.activeFocus) root.finishSlotEdit(hexField, modelData.key);
                                                }
                                            }
                                        }
                                        Component.onCompleted: root.registerSlot(modelData.key, hexField, chip)
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                text: "Edits apply live to the dock, window borders and desktop widgets. Reset restores the session snapshot. Other palettes are untouched."
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(10)
                                color: colors.overlay1
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // ── CARD: ASPECTO ─────────────────────────────────────────
                    Rectangle {
                        visible: root.engine === "dock"
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: aspCol.implicitHeight + s(28)
                        Column {
                            id: aspCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(9)
                            SectionTitle { bar: root; text: "Appearance" }
                            Item {
                                width: parent.width
                                height: s(34)
                                EditLabel { bar: root; text: "Style"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(6)
                                    EditPill { bar: root; text: "Modular"; active: root.dock.stylePreset === "modular"; onActivated: root.applyStyle("modular") }
                                    EditPill { bar: root; text: "Solid"; active: root.dock.stylePreset === "solid"; onActivated: root.applyStyle("solid") }
                                    EditPill { bar: root; text: "Fill"; active: root.dock.stylePreset === "fill"; onActivated: root.applyStyle("fill") }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(22)
                                Text {
                                    anchors.fill: parent
                                    text: "Modular: floating islands · Solid: continuous bar · Fill: edge-to-edge strip (no gap). Presets are shortcuts — manual tweaks below stay possible."
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                    color: colors.overlay1
                                    wrapMode: Text.WordWrap
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Roundness"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.roundness*100)+"%"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { roundness: Math.max(0, +(root.dock.roundness-0.1).toFixed(1)) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { roundness: Math.min(1, +(root.dock.roundness+0.1).toFixed(1)) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Thickness"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.thickness)+"px"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { thickness: Math.max(32, root.dock.thickness-4) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { thickness: Math.min(96, root.dock.thickness+4) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Edge margin"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.edgeGap)+"px"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.max(0, root.dock.edgeGap-2) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { edgeGap: Math.min(24, root.dock.edgeGap+2) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Island fill"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.pillBg; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { pillBg: !root.dock.pillBg })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Solid fill"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.pillSolid; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { pillSolid: !root.dock.pillSolid })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Unified bar"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.barBg; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { barBg: !root.dock.barBg })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Bar opacity"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Stepper { bar: root; label: Math.round(root.dock.barOpacity * 100) + "%"
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    onDec: root.applyDock(Object.assign({}, root.dock, { barOpacity: Math.max(0.2, +(root.dock.barOpacity - 0.05).toFixed(2)) }))
                                    onInc: root.applyDock(Object.assign({}, root.dock, { barOpacity: Math.min(1.0, +(root.dock.barOpacity + 0.05).toFixed(2)) })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Drag modules"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.dragModules !== false; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applyDock(Object.assign({}, root.dock, { dragModules: root.dock.dragModules !== false ? false : true })) }
                            }
                            Item {
                                width: parent.width
                                height: s(34)
                                Text {
                                    anchors.fill: parent
                                    text: "Tip: grab any island and drag it along the bar to reorder it between zones (release outside the bar cancels)."
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                    color: colors.overlay1
                                    wrapMode: Text.WordWrap
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(32)
                                EditLabel { bar: root; text: "Font"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                TextField {
                                    id: fontField
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: s(240)
                                    height: s(30)
                                    text: root.dock.font || "Hack Nerd Font"
                                    font.family: text
                                    font.pixelSize: s(12)
                                    color: colors.text
                                    selectByMouse: true
                                    background: Rectangle { color: colors.surface1; radius: s(8); border.color: colors.surface2 }
                                    onEditingFinished: {
                                        let v = text.trim();
                                        root.applyDock(Object.assign({}, root.dock, { font: v !== "" ? v : "Hack Nerd Font" }));
                                    }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Border (global)"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(8)
                                    Stepper { bar: root; label: Math.round(root.dock.borderWidth)+"px"
                                        onDec: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.max(0, root.dock.borderWidth-1) }))
                                        onInc: root.applyDock(Object.assign({}, root.dock, { borderWidth: Math.min(8, root.dock.borderWidth+1) })) }
                                    ColorCycle { bar: root; role: root.dock.borderColor; onCycled: (role) => root.applyDock(Object.assign({}, root.dock, { borderColor: role })) }
                                }
                            }
                        }
                    }

                    // ── CARD: WINDOW BORDERS ──────────────────────────────────
                    Rectangle {
                        visible: root.engine === "dock"
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: winBordCol.implicitHeight + s(28)
                        Column {
                            id: winBordCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(9)
                            SectionTitle { bar: root; text: "Window borders" }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Follow palette"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                ToggleSwitch { bar: root; checked: root.dock.borderFollowPalette !== false; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter;
                                    onToggled: root.applyDock(Object.assign({}, root.dock, { borderFollowPalette: root.dock.borderFollowPalette !== false ? false : true })) }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                visible: root.dock.borderFollowPalette === false
                                EditLabel { bar: root; text: "Target"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(8)
                                    EditPill { bar: root; text: "Active"; active: root.borderTargetActive; onActivated: root.borderTargetActive = true }
                                    EditPill { bar: root; text: "Inactive"; active: !root.borderTargetActive; onActivated: root.borderTargetActive = false }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                visible: root.dock.borderFollowPalette === false
                                EditLabel { bar: root; text: root.borderTargetActive ? "Active color" : "Inactive color"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: s(92); height: s(26); radius: s(8)
                                    color: root.borderTargetActive ? themeColors.borderHex("active") : themeColors.borderHex("inactive")
                                    border.width: 1; border.color: colors.surface2
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.borderTargetActive ? themeColors.borderHex("active") : themeColors.borderHex("inactive")
                                        font.family: "Hack Nerd Font"; font.pixelSize: s(9); font.weight: Font.Bold
                                        color: colors.text
                                    }
                                }
                            }
                            Flow {
                                width: parent.width
                                visible: root.dock.borderFollowPalette === false
                                spacing: s(6)
                                Repeater {
                                    model: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
                                    delegate: Rectangle {
                                        required property int modelData
                                        width: s(26); height: s(26); radius: s(7)
                                        color: themeColors["color" + modelData]
                                        border.width: 1; border.color: colors.surface2
                                        Rectangle {
                                            anchors.fill: parent; anchors.margins: s(2); radius: s(5)
                                            visible: (root.borderTargetActive
                                                ? themeColors.borderHex("active") === themeColors.hexOf(themeColors["color" + modelData])
                                                : themeColors.borderHex("inactive") === themeColors.hexOf(themeColors["color" + modelData]))
                                            border.width: 2; border.color: colors.text
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let hex = themeColors.hexOf(themeColors["color" + modelData]);
                                                root.applyDock(Object.assign({}, root.dock, root.borderTargetActive
                                                    ? { borderActive: hex }
                                                    : { borderInactive: hex }));
                                            }
                                        }
                                    }
                                }
                            }
                            Text {
                                width: parent.width
                                visible: root.dock.borderFollowPalette !== false
                                text: "Borders follow the active palette accent. Turn this off to pick custom colors (applies live, no window restart)."
                                font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                color: colors.overlay1
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // ── CARD: ZONAS ───────────────────────────────────────────
                    Rectangle {
                        visible: root.engine === "dock"
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: zonasCol.implicitHeight + s(28)
                        Column {
                            id: zonasCard
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(8)
                            Item {
                                width: parent.width
                                height: s(28)
                                SectionTitle { bar: root; text: "Zones"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(8)
                                    EditPill { bar: root; modelData: "add"; text: "+ Add"; accentFill: true; onActivated: root.applyDock(DockLayout.addZone(root.dock, "start")) }
                                    EditPill { bar: root; text: "Center all"; onActivated: root.applyDock(DockLayout.arrangeAllInZone(root.dock, "center")) }
                                    EditPill { bar: root; modelData: "reset"; text: "Default"; onActivated: root.applyDock(DockLayout.defaultDock()) }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(24)
                                Text {
                                    anchors.fill: parent
                                    text: "Center all gathers every enabled island into the center zone. Tip: drag a chip onto another zone card to move the island there (release between chips to choose the exact spot)."
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                    color: colors.overlay1
                                    wrapMode: Text.WordWrap
                                }
                            }
                            Column {
                                id: zonasCol
                                width: parent.width
                                spacing: s(8)
                                Repeater {
                                    model: root.dock.zones
                                    delegate: ZoneEditorCard {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        bar: root
                                        zoneData: modelData
                                        zoneIndex: index
                                    }
                                }
                            }
                        }
                    }

                    // ── CARD: WORKSPACES ──────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        radius: s(18)
                        color: colors.surface0
                        border.width: s(1); border.color: colors.surface1
                        height: wsCol.implicitHeight + s(28)
                        Column {
                            id: wsCol
                            anchors.fill: parent
                            anchors.margins: s(14)
                            spacing: s(9)
                            SectionTitle { bar: root; text: "Workspaces" }
                            Item {
                                width: parent.width
                                height: s(28)
                                EditLabel { bar: root; text: "Empty workspace"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: s(6)
                                    EditPill { bar: root; text: "Numbers"; active: root.dock.workspacesMarker === "number"; onActivated: root.applyDock(Object.assign({}, root.dock, { workspacesMarker: "number" })) }
                                    EditPill { bar: root; text: "Dots"; active: root.dock.workspacesMarker === "dot"; onActivated: root.applyDock(Object.assign({}, root.dock, { workspacesMarker: "dot" })) }
                                    EditPill { bar: root; text: "Letters"; active: root.dock.workspacesMarker === "letter"; onActivated: root.applyDock(Object.assign({}, root.dock, { workspacesMarker: "letter" })) }
                                    EditPill { bar: root; text: "Custom"; active: root.dock.workspacesMarker === "custom"; onActivated: root.applyDock(Object.assign({}, root.dock, { workspacesMarker: "custom" })) }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(28)
                                visible: root.dock.workspacesMarker === "custom"
                                EditLabel { bar: root; text: "Character"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                TextField {
                                    id: wsMarkerCharField
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: s(110)
                                    height: s(28)
                                    text: root.dock.workspacesMarkerText || ""
                                    font.family: root.dock.font || "Hack Nerd Font"
                                    font.pixelSize: s(13)
                                    color: colors.text
                                    selectByMouse: true
                                    maximumLength: 4
                                    background: Rectangle { color: colors.surface1; radius: s(8); border.color: colors.surface2 }
                                    onEditingFinished: {
                                        let v = text.trim().slice(0, 4);
                                        if (v !== root.dock.workspacesMarkerText) {
                                            root.applyDock(Object.assign({}, root.dock, { workspacesMarkerText: v }));
                                        }
                                    }
                                }
                            }
                            Item {
                                width: parent.width
                                height: s(26)
                                Text {
                                    anchors.fill: parent
                                    text: "Only for empty workspaces — occupied ones keep showing their app icons. Tip: the Container bg option in each zone adds a themed background behind its islands without unifying them."
                                    font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                    color: colors.overlay1
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                    // ════ SERP ENGINE CARDS (Phase D4-E2) ════
                    // Visible only while root.engine === "serp": the classic
                    // bar's position, style & size, module lists and quick
                    // actions. Every edit lands on the top-level "serpbar"
                    // settings key (never on "dock") through applySerp()/
                    // commitSerpOp() and hot-reloads in the live host.
                    Column {
                        id: serpUi
                        width: parent.width
                        spacing: s(12)
                        visible: root.engine === "serp"

                        // ── SERP CARD: POSITION ────────────────────────────────
                        Rectangle {
                            width: parent.width
                            radius: s(18)
                            color: colors.surface0
                            border.width: s(1); border.color: colors.surface1
                            height: serpPosCol.implicitHeight + s(28)
                            Column {
                                id: serpPosCol
                                anchors.fill: parent
                                anchors.margins: s(14)
                                spacing: s(10)
                                SectionTitle { bar: root; text: "Position" }
                                Row {
                                    width: parent.width
                                    spacing: s(8)
                                    PosCardSerp { width: (parent.width - s(8)) / 2; bar: root; pos: "top"; label: "Top"; glyph: "↑"; onActivated: root.applySerp({ position: "top" }) }
                                    PosCardSerp { width: (parent.width - s(8)) / 2; bar: root; pos: "bottom"; label: "Bottom"; glyph: "↓"; onActivated: root.applySerp({ position: "bottom" }) }
                                }
                                Row {
                                    width: parent.width
                                    spacing: s(8)
                                    PosCardSerp { width: (parent.width - s(8)) / 2; bar: root; pos: "left"; label: "Left"; glyph: "←"; onActivated: root.applySerp({ position: "left" }) }
                                    PosCardSerp { width: (parent.width - s(8)) / 2; bar: root; pos: "right"; label: "Right"; glyph: "→"; onActivated: root.applySerp({ position: "right" }) }
                                }
                            }
                        }

                        // ── SERP CARD: STYLE & SIZE ────────────────────────────
                        Rectangle {
                            width: parent.width
                            radius: s(18)
                            color: colors.surface0
                            border.width: s(1); border.color: colors.surface1
                            height: serpStyleCol.implicitHeight + s(28)
                            Column {
                                id: serpStyleCol
                                anchors.fill: parent
                                anchors.margins: s(14)
                                spacing: s(9)
                                SectionTitle { bar: root; text: "Style & size" }
                                Item {
                                    width: parent.width
                                    height: s(34)
                                    EditLabel { bar: root; text: "Style"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: s(6)
                                        EditPill { bar: root; text: "Modular"; active: root.serp.style === "modular"; onActivated: root.applySerp({ style: "modular" }) }
                                        EditPill { bar: root; text: "Solid"; active: root.serp.style === "solid"; onActivated: root.applySerp({ style: "solid" }) }
                                        EditPill { bar: root; text: "Fill"; active: root.serp.style === "fill"; onActivated: root.applySerp({ style: "fill" }) }
                                    }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    // serpantium offers distinct pills on every
                                    // style but fill (BarTab.qml:1175: the fill
                                    // bar is edge-to-edge and always unified).
                                    visible: root.serp.style !== "fill"
                                    EditLabel { bar: root; text: "Distinct pills"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    ToggleSwitch { bar: root; checked: root.serp.distinctPills === true; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applySerp({ distinctPills: root.serp.distinctPills !== true }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    // Corner knob for every serp unit (islands,
                                    // groups, slabs, strip). roundness 0.6 ≈ the
                                    // serpantium theme radius on a s(40) band.
                                    EditLabel { bar: root; text: "Roundness"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Stepper { bar: root; label: Math.round(root.serp.roundness * 100) + "%"
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        onDec: root.applySerp({ roundness: Math.max(0, +(root.serp.roundness - 0.1).toFixed(1)) })
                                        onInc: root.applySerp({ roundness: Math.min(1, +(root.serp.roundness + 0.1).toFixed(1)) }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    EditLabel { bar: root; text: "Time format"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Row {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: s(6)
                                        EditPill { bar: root; text: "24h"; active: root.serp.timeFormat === "HH:mm:ss" || !root.serp.timeFormat; onActivated: root.applySerp({ timeFormat: "HH:mm:ss" }) }
                                        EditPill { bar: root; text: "24h :mm"; active: root.serp.timeFormat === "HH:mm"; onActivated: root.applySerp({ timeFormat: "HH:mm" }) }
                                        EditPill { bar: root; text: "12h"; active: root.serp.timeFormat === "h:mm a"; onActivated: root.applySerp({ timeFormat: "h:mm a" }) }
                                    }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    EditLabel { bar: root; text: "Thickness"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Stepper { bar: root; label: Math.round(root.serp.thickness !== null ? root.serp.thickness : root.dock.thickness) + "px"
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        onDec: root.applySerp({ thickness: Math.max(24, Math.round(root.serp.thickness !== null ? root.serp.thickness : root.dock.thickness) - 4) })
                                        onInc: root.applySerp({ thickness: Math.min(120, Math.round(root.serp.thickness !== null ? root.serp.thickness : root.dock.thickness) + 4) }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    visible: root.serp.style !== "modular"
                                    EditLabel { bar: root; text: "Bar opacity"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Stepper { bar: root; label: Math.round(root.serp.opacity) + "%"
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        onDec: root.applySerp({ opacity: Math.max(20, Math.round(root.serp.opacity) - 5) })
                                        onInc: root.applySerp({ opacity: Math.min(100, Math.round(root.serp.opacity) + 5) }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    visible: root.serp.style !== "fill"
                                    EditLabel { bar: root; text: "Width"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Stepper { bar: root; label: Math.round(root.serp.widthPercent) + "%"
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        onDec: root.applySerp({ widthPercent: Math.max(40, Math.round(root.serp.widthPercent) - 5) })
                                        onInc: root.applySerp({ widthPercent: Math.min(100, Math.round(root.serp.widthPercent) + 5) }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    EditLabel { bar: root; text: "Autohide"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    ToggleSwitch { bar: root; checked: root.serp.autohide === true; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; onToggled: root.applySerp({ autohide: root.serp.autohide !== true }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(28)
                                    visible: root.serp.autohide === true
                                    EditLabel { bar: root; text: "Hide delay"; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                                    Stepper { bar: root; label: root.serp.autohideTimeout + "ms"
                                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        onDec: root.applySerp({ autohideTimeout: Math.max(200, root.serp.autohideTimeout - 100) })
                                        onInc: root.applySerp({ autohideTimeout: Math.min(5000, root.serp.autohideTimeout + 100) }) }
                                }
                                Item {
                                    width: parent.width
                                    height: s(24)
                                    Text {
                                        anchors.fill: parent
                                        text: "Modular: floating islands · Solid: continuous strip · Fill: edge-to-edge strip (width locked at 100%). Distinct pills give every module and group its own subtle slab on the strip; opacity fades the strip itself. Thickness = the bar's own size (null inherits the dock engine's). Corners follow the shared Roundness knob (Dock engine → Appearance); module fonts follow dock.font. Autohide slides the bar off-screen; touching the screen edge reveals it."
                                        font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                        color: colors.overlay1
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        // ── SERP CARD: MODULES ─────────────────────────────────
                        Rectangle {
                            width: parent.width
                            radius: s(18)
                            color: colors.surface0
                            border.width: s(1); border.color: colors.surface1
                            height: serpModCard.implicitHeight + s(28)
                            Column {
                                id: serpModCard
                                anchors.fill: parent
                                anchors.margins: s(14)
                                spacing: s(8)
                                SectionTitle { bar: root; text: "Modules" }
                                Item {
                                    width: parent.width
                                    height: s(24)
                                    Text {
                                        anchors.fill: parent
                                        text: "Each box is one continuous pill (a group). Drag chips between sections, drop a chip onto a group to join it, drag group headers to move whole clusters, use – to send a module back to Available."
                                        font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                                        color: colors.overlay1
                                        wrapMode: Text.WordWrap
                                    }
                                }
                                Column {
                                    id: serpListsCol
                                    width: parent.width
                                    spacing: s(8)
                                    SerpSectionCard { width: parent.width; bar: root; listId: "left" }
                                    SerpSectionCard { width: parent.width; bar: root; listId: "center" }
                                    SerpSectionCard { width: parent.width; bar: root; listId: "right" }
                                    SerpSectionCard { width: parent.width; bar: root; listId: "available" }
                                }
                            }
                        }

                        // ── SERP CARD: ACTIONS ─────────────────────────────────
                        Rectangle {
                            width: parent.width
                            radius: s(18)
                            color: colors.surface0
                            border.width: s(1); border.color: colors.surface1
                            height: serpActCol.implicitHeight + s(28)
                            Column {
                                id: serpActCol
                                anchors.fill: parent
                                anchors.margins: s(14)
                                spacing: s(10)
                                SectionTitle { bar: root; text: "Actions" }
                                Row {
                                    width: parent.width
                                    spacing: s(8)
                                    EditPill { bar: root; text: "Mirror dock layout"; onActivated: root.applySerp({ modules: DockLayout.dockToSerpModules(root.dock) }) }
                                    EditPill { bar: root; text: "Serp defaults"; onActivated: root.serpDefaultsAction() }
                                }
                                EditLabel {
                                    width: parent.width
                                    text: "Mirror imports the zone dock's enabled modules into the classic sections (the dock config itself stays untouched). Serp defaults restores the stock layout and keeps the current position."
                                    font.pixelSize: s(10)
                                    color: colors.overlay1
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                    Item { width: 1; height: s(12) }
                }
            }
        }
    }

    // ════ DnD GHOST (Phase D3) ════
    // Floating chip that follows the pointer while a module chip drags. Purely
    // visual (enabled: false) — the real input still belongs to the chip's
    // MouseArea grab.
    Item {
        id: dndGhostLayer
        anchors.fill: parent
        visible: root.dndBusy
        z: 1000
        enabled: false

        Rectangle {
            id: dndGhost
            // Whole-group drags have dndModuleId === "" (the ghost then shows
            // the cluster glyph + member count via serpGroupCount()).
            property bool groupGhost: root.dndModuleId === ""
            property var modInfo: root.dndModuleId !== "" ? DockLayout.getModule(root.dndModuleId) : null
            readonly property int ghostW: ghostRow.implicitWidth + root.s(24)
            height: root.s(30)
            width: ghostW
            x: root.dndPointer.x - width / 2
            y: root.dndPointer.y - height / 2 - root.s(8)
            radius: root.s(8)
            color: colors.accent
            opacity: 0.95
            scale: 1.06
            Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Row {
                id: ghostRow
                anchors.centerIn: parent
                spacing: root.s(5)
                Text {
                    text: dndGhost.groupGhost ? "◧" : (dndGhost.modInfo ? dndGhost.modInfo.icon : "?")
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: colors.base
                }
                Text {
                    text: dndGhost.groupGhost
                        ? ("Group" + (root.serpGroupCount() > 0 ? " (" + root.serpGroupCount() + ")" : ""))
                        : (dndGhost.modInfo ? dndGhost.modInfo.label : root.dndModuleId)
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(11); font.weight: Font.Bold; color: colors.base
                }
            }
        }
    }

    Keys.onEscapePressed: {
        flushSave();
        flushPaletteWrite();
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh close"]);
        event.accepted = true;
    }
}
