import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."
import "../WindowRegistry.js" as LayoutMath
import "DockLayout.js" as DockLayout
import "Colors.qml"
import "edit"
// Phase 3: pages load lazily via Loader.setSource("editor/<file>.qml", {bar})
// — no `import "editor"` needed (typed instancing caused a null-bar burst).

// ═══════════════════════════════════════════════════════════════════════════
// DockEditor — the dock mega menu (SUPER+SHIFT+D), PHASE 2 rewrite.
// Serpantium-style rail shell: sidebar (brand + animated accent nav pill over
// NavItem rows + footer hints) + content stage where the 7 Phase-1 pages
// (dock/editor/*.qml) stay ALWAYS instantiated (visible switches by page).
// Pages only talk to root via `bar`; ZonesPage/SerpBarPage expose flickable +
// zonasCol/serpListsCol for the editor-wide DnD (chips feed root coordinates
// via mapToItem(bar,...)). Edits write live to settings.json; bar untouched.
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

    // ════ FASE 4: INTRO/CIERRE (paridad con GuidePopup) ════
    // introBase = panel (opacity+scale), introSidebar = rail (opacity+slide x),
    // introContent = stage de páginas (opacity+scale+slide y). GP:214-287.
    property real introBase: 0.0
    property real introSidebar: 0.0
    property real introContent: 0.0

    // ════ DUAL ENGINE STATE (Phase D4-E2) ════
    // The editor edits whichever engine settings.json says is live ("dock" or
    // "serp"); root.serp mirrors the "serpbar" key, dock config untouched.
    property string engine: "dock"
    property var serp: DockLayout.serpbarDefaults()
    property bool _serpDirty: false

    Timer { id: saveTimer; interval: 220; onTriggered: flushSave() }
    function markDirty() { _dirty = true; saveTimer.restart(); }
    // Serp edits share the same debounce; both keys are independent top-level
    // settings keys, so the queues never clobber each other.
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
    // Hot engine switch via the top-level "barEngine" key (the live host swaps
    // in-process). The FIRST switch to "serp" seeds "serpbar" from the dock's
    // position + ENABLED modules, so the classic bar starts with the layout.
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
        // Phase 2: the rail filters by engine — a page gone from the list
        // falls back to General; mid-drag flips abort DnD (pill re-syncs).
        if (root.navIndex(root.currentPage) === -1) root.currentPage = "general";
        root.cancelDnd();
        Qt.callLater(root.syncNavPill);
    }

    // Full-config commit (already normalized): replace root.serp + queue save.
    function commitSerp(cfg) {
        root.serp = cfg;
        root.markDirtySerp();
    }

    // Shallow partial merge + normalize so the in-memory state always
    // satisfies the host invariants before the debounced file write lands.
    function applySerp(partial) {
        root.commitSerp(DockLayout.normalizeSerpbar(Object.assign({}, root.serp, partial)));
    }

    // Pure-engine op helper: commit only when the JSON really changed.
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

    // "Serp defaults": stock layout keeping the current position.
    function serpDefaultsAction() {
        let d = DockLayout.serpbarDefaults();
        d.position = root.serp.position;
        root.applySerp(d);
    }

    // "Mirror dock layout": importa los módulos enabled del dock a serp.
    // Compartida por SerpBarPage (señal mirrorDock → Connections) y
    // GeneralPage (llamada directa bar.mirrorDockAction()).
    function mirrorDockAction() {
        root.applySerp({ modules: DockLayout.dockToSerpModules(root.dock) });
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

    // ════ MODULE CHIP DRAG & DROP (Phase D3, adapted Phase 2) ════
    // One editor-wide session: a chip MouseArea crosses its threshold and
    // calls startDnd()/startSerpDnd(); we own the gesture — ghost at pointer,
    // dndActive + dndInsertIndex on the card under the cursor, auto-scroll of
    // the ACTIVE page's flickable, commit with DockLayout.*MoveTo on release
    // (drop outside every card = cancel). root.dock/root.serp stay untouched
    // until the drop, so no-op drops never write settings.
    //
    // Phase 2: cards now live in the pages' own Flickables (ZonesPage /
    // SerpBarPage). The chips' coordinate contract is unchanged — cards map
    // with mapToItem(bar,...)/mapFromItem(bar,...), points stay in root
    // coordinates and nested scrolls cancel out; only the auto-scroll target
    // becomes dynamic (dndFlick = the current page's flickable).
    property bool dndBusy: false
    property string dndModuleId: ""
    property string dndSourceZoneId: ""
    property point dndPointer: Qt.point(-10000, -10000)

    // Serp drags remember where the dragged item sits: module drags keep
    // dndSourceItemIndex -1 (removal by id); GROUP drags use dndModuleId ""
    // + the group's ITEM index inside dndSourceSerpList.
    property string dndSourceSerpList: ""
    property int dndSourceItemIndex: -1

    // Phase 2: page Flickable locked while a drag runs + auto-scrolled
    // (ZonesPage/SerpBarPage expose their flickables; engine picks the owner).
    property var dndFlick: null

    // Phase 3: lazily-loaded page items (Loader.setSource initial props give
    // `bar` to the page BEFORE its inner bindings evaluate). Null until the
    // page has been opened once; DnD targets only exist while loaded, which is
    // exactly when their page is the visible one.
    property var zonesPage: null   // ZonesPage item (lazy; zone DnD targets)
    property var serpPage: null    // SerpBarPage item (lazy; serp DnD targets)

    // Zone cards: children of the Zones page's zonasCol (isZoneEditorCard
    // marker skips the Repeater). Hidden pages keep valid geometry, so the
    // currentPage guard excludes them.
    function zoneCards() {
        if (root.engine !== "dock" || root.currentPage !== "zones") return [];
        let out = [];
        let kids = root.zonesPage ? root.zonesPage.zonasCol.children : [];
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (c && c.isZoneEditorCard) out.push(c);
        }
        return out;
    }

    // Live list of serp list cards (SerpBar page's serpListsCol, marker
    // isSerpEditorCard); same hidden-page + engine guard as zoneCards().
    function serpCards() {
        if (root.engine !== "serp" || root.currentPage !== "serp") return [];
        let out = [];
        let kids = root.serpPage ? root.serpPage.serpListsCol.children : [];
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (c && c.isSerpEditorCard) out.push(c);
        }
        return out;
    }

    // Only one engine UI renders at a time: targets are always one card kind.
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
        root.dndFlick = (root.engine === "dock" && root.zonesPage) ? root.zonesPage.flickable
                    : (root.serpPage ? root.serpPage.flickable : null);
        if (root.dndFlick) root.dndFlick.interactive = false;
    }

    // Serp chips enter the SAME editor-wide session: moduleId "" marks a
    // whole-group drag located by dndSourceItemIndex inside listId.
    function startSerpDnd(listId, moduleId, itemIndex) {
        if (root.dndBusy) return;
        root.dndBusy = true;
        root.dndModuleId = moduleId || "";
        root.dndSourceZoneId = "";
        root.dndSourceSerpList = listId;
        root.dndSourceItemIndex = (moduleId === "") ? (isFinite(itemIndex) ? itemIndex : -1) : -1;
        root.dndFlick = (root.engine === "dock" && root.zonesPage) ? root.zonesPage.flickable
                    : (root.serpPage ? root.serpPage.flickable : null);
        if (root.dndFlick) root.dndFlick.interactive = false;
    }

    // Pointer moved (root/editor coordinates): repaint ghost + drop feedback
    // (dndActive / dndInsertIndex / serp group join slot under the cursor).
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
    // engine: zone cards commit via DockLayout.moduleMoveTo + applyDock; serp
    // cards branch by payload — module drags join the group under the pointer
    // when offered, else insert as a loose item ("available" only detaches),
    // whole-group drags relocate the cluster (or release on "available").
    // Identical-result drops (JSON-equal) never write settings.
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
        if (root.dndFlick) root.dndFlick.interactive = true;
        root.dndFlick = null;
    }

    // Auto-scroll: keeps off-screen cards of the ACTIVE page reachable
    // (dndFlick null-guards a mid-session page switch).
    Timer {
        id: dndScrollTimer
        interval: 16
        repeat: true
        running: root.dndBusy
        onTriggered: {
            if (!root.dndFlick || !root.dndBusy) return;
            let local = root.dndFlick.mapFromItem(root, root.dndPointer.x, root.dndPointer.y);
            let band = root.s(26);
            if (local.y < band) {
                root.dndFlick.contentY = Math.max(0, root.dndFlick.contentY - root.s(5));
            } else if (local.y > root.dndFlick.height - band) {
                let maxY = Math.max(0, root.dndFlick.contentHeight - root.dndFlick.height);
                root.dndFlick.contentY = Math.min(maxY, root.dndFlick.contentY + root.s(5));
            }
        }
    }

    // ════ PHASE 2 NAVIGATION (rail) ════
    // currentPage picks the visible child; the sidebar lists pages filtered by
    // engine. NavItem rows are transparent — navPill (viewport-fixed, BELOW
    // them) glides to the active slot: navPillTargetY animates (300 ms
    // OutQuint), y subtracts contentY, navArea clips.
    property string currentPage: "general"
    property var navModel: [
        { id: "general",     icon: "󰒓", label: "General",     both: true },
        { id: "position",    icon: "󱂬", label: "Position",    both: true },
        { id: "style",       icon: "󰏘", label: "Style",       engine: "dock" },
        { id: "palette",     icon: "✦", label: "Palette",     both: true },
        { id: "zones",       icon: "󰮯", label: "Zones",       engine: "dock" },
        { id: "workspaces",  icon: "󰠰", label: "Workspaces",  both: true },
        { id: "serp",        icon: "󰹑", label: "Serp Bar",    engine: "serp" }
    ]
    // Animated pill slot (content px); Behavior lives here so scroll-follow
    // updates through the y binding never lag.
    property real navPillTargetY: 0

    // Pages visible under the current engine, in rail order.
    function navForEngine() {
        let out = [];
        let m = root.navModel;
        for (let i = 0; i < m.length; i++) {
            if (m[i].both === true || m[i].engine === root.engine) out.push(m[i]);
        }
        return out;
    }
    function visibleNav() { return root.navForEngine(); }
    function navIndex(id) {
        let nav = root.navForEngine();
        for (let i = 0; i < nav.length; i++) {
            if (nav[i].id === id) return i;
        }
        return -1;
    }
    function gotoPage(id) {
        if (root.navIndex(id) === -1) return;
        root.currentPage = id;
        root.syncNavPill();
    }
    // Recompute the pill's animated target (page/engine change; the y
    // binding handles scroll-follow continuously). Fase 4: filas sin gap,
    // target = idx * s(44) (GP:440-456) y animación 400 ms OutExpo.
    function syncNavPill() {
        if (!navPill || !colNav) return;
        let idx = root.navIndex(root.currentPage);
        if (idx < 0) idx = 0;
        root.navPillTargetY = idx * root.s(44);
    }
    Behavior on navPillTargetY {
        NumberAnimation { duration: 400; easing.type: Easing.OutExpo }
    }

    // ════ PHASE 3: LAZY PAGE LOADING ════
    // Pages are Loaders in the content stage; opening a page (rail click, Tab
    // cycle, initial open) calls ensurePage(), which instantiates the page
    // component with setSource(file, { bar: root }) — initial properties are
    // applied BEFORE the page's internal bindings first evaluate, so `bar` is
    // never null during construction (kills the burst of TypeErrors the typed
    // always-instantiated children produced). Once loaded, the item persists;
    // hiding the page only toggles visible.
    // DnD hooks: zones/serp items are mirrored into root.zonesPage/root.serpPage
    // from their Loader's onLoaded (zoneCards()/serpCards() read the property;
    // Connections below retarget automatically).
    function pageFile(id) {
        let map = {
            "general": "GeneralPage.qml",
            "position": "PositionPage.qml",
            "style": "DockStylePage.qml",
            "palette": "PalettePage.qml",
            "zones": "ZonesPage.qml",
            "workspaces": "WorkspacesPage.qml",
            "serp": "SerpBarPage.qml"
        };
        return map[id] || "";
    }
    function pageLoader(id) {
        let map = {
            "general": generalLoader,
            "position": positionLoader,
            "style": styleLoader,
            "palette": paletteLoader,
            "zones": zonesLoader,
            "workspaces": workspacesLoader,
            "serp": serpLoader
        };
        return map[id] || null;
    }
    function ensurePage(id) {
        let loader = root.pageLoader(id);
        if (!loader) return;
        // NOTE: Loader.source is a QUrl — strict-compare its string form, a
        // bare `loader.source !== ""` is always true and would block loading.
        if (loader.item || String(loader.source) !== "") return;
        let file = root.pageFile(id);
        if (file === "") return;
        loader.setSource("editor/" + file, { bar: root });
    }
    onCurrentPageChanged: root.ensurePage(root.currentPage)

    // ════ LIVE PALETTE EDITOR (Phase T) ════
    // Edits the ACTIVE palette file (dock/palettes/<slug>.json): validated hex
    // commits are debounced (~250 ms, grouped) and written atomically with jq
    // (tmp + mv, unknown keys preserved). First edit snapshots the file to
    // ~/.local/state/quickshell/palette_backup/<slug>.json; Reset restores it.
    // settings.json is never touched: the palette file IS the source and
    // Colors/Theme watchers re-apply edits live.
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

    // Re-read slots from themeColors (file watcher keeps it live); focused
    // rows keep their in-progress draft.
    function syncSlotValues() {
        for (let i = 0; i < root._slotRows.length; i++) {
            let s = root._slotRows[i];
            if (s.field.activeFocus) continue;
            let hex = root.slotColorHex(s.key);
            s.field.text = hex;
            s.chip.color = hex;
        }
    }

    // Valid hex commit: normalize, mirror in the row, queue the debounced
    // atomic file write (rapid edits of several slots share one jq).
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

    // Hex-field commit entry (Enter / focus-out / blur): valid hexes are
    // committed live, anything else drops the draft and re-shows the color.
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
        // Chain: snapshot on the FIRST edit ([ ! -f backup ] guard, so a
        // snapshot from an earlier session is never overwritten).
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
    // the Reset button's enabled look (open / write / reset).
    function checkBackupExists() {
        backupProbe.command = ["bash", "-c", "cat '" + root.backupFilePath(root.activeSlug()) + "' 2>/dev/null | head -c 1"];
        backupProbe.running = false;
        backupProbe.running = true;
    }

    // The instance is torn down right after closing (StackView clear):
    // flush any pending palette write on destroy.
    Component.onDestruction: root.flushPaletteWrite()

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

    Component.onCompleted: {
        startupSequence.start();
        reload();
        paletteReader.running = true;
        scaleReader.running = true;
        // Push window-border colors to Hyprland live on palette re-apply and
        // on settings.json changes (only this instance pushes).
        themeColors.paletteApplied.connect(function() { themeColors.syncWindowBorders(); });
        themeColors.settingsUpdated.connect(function() { themeColors.syncWindowBorders(); });
        // Live palette editor: mirror every palette re-apply into the slot
        // rows (own edits, palette switches and external changes all land here).
        themeColors.paletteApplied.connect(function() { root.syncSlotValues(); });
        themeColors.paletteNameChanged.connect(function() { root.checkBackupExists(); });
        root.syncSlotValues();
        Qt.callLater(root.syncNavPill);
        root.ensurePage(root.currentPage);
    }

    // ════ FASE 4: SECUENCIAS INTRO/CIERRE (GP:223-287) ════
    // Escalonado: base 900 ms OutExpo · sidebar +150 ms 1000 ms OutBack 1.05 ·
    // content +250 ms 1100 ms OutBack 1.02. El cierre colapsa content/sidebar
    // (150 ms InExpo), luego base (200 ms InQuart) y solo entonces flush+close.
    ParallelAnimation {
        id: startupSequence
        NumberAnimation { target: root; property: "introBase"; from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutExpo }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: root; property: "introSidebar"; from: 0.0; to: 1.0; duration: 1000; easing.type: Easing.OutBack; easing.overshoot: 1.05 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { target: root; property: "introContent"; from: 0.0; to: 1.0; duration: 1100; easing.type: Easing.OutBack; easing.overshoot: 1.02 }
        }
    }

    // Flush de ambos buffers antes de cerrar (mismo contrato que el ESC de la
    // Fase 1: nunca perder un debounce pendiente).
    function closeFlush() {
        flushSave();
        flushPaletteWrite();
    }

    SequentialAnimation {
        id: closeSequence
        ParallelAnimation {
            NumberAnimation { target: root; property: "introContent"; to: 0.0; duration: 150; easing.type: Easing.InExpo }
            NumberAnimation { target: root; property: "introSidebar"; to: 0.0; duration: 150; easing.type: Easing.InExpo }
        }
        NumberAnimation { target: root; property: "introBase"; to: 0.0; duration: 200; easing.type: Easing.InQuart }
        ScriptAction { script: root.closeFlush() }
        ScriptAction { script: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh close"]) }
    }

    // ════ PANEL (Fase 4: paridad visual con GuidePopup) ════
    // Fondo base + borde surface0 1 px + radio s(21), SIN márgenes externos;
    // wrapper con intro (opacity/scale, GP:292-303). Interior: Row con
    // márgenes s(20) y spacing s(20) (GP:358-361).
    Item {
        anchors.fill: parent
        opacity: root.introBase
        scale: 0.95 + (0.05 * root.introBase)

        Rectangle {
            anchors.fill: parent
            radius: s(21)
            color: colors.base
            border.width: 1
            border.color: colors.surface0
            clip: true

            Row {
                anchors.fill: parent
                anchors.margins: s(20)
                spacing: s(20)

                // ── SIDEBAR (Fase 4: tokens del Guide) ──────────────────────
                Rectangle {
                    id: sidebar
                    width: s(220)
                    height: parent.height
                    radius: s(16)
                    color: Qt.alpha(colors.surface0, 0.4)
                    border.width: 1
                    border.color: colors.surface1
                    clip: true
                    opacity: root.introSidebar
                    transform: Translate { x: s(-30) * (1.0 - root.introSidebar) }

                    // Brand: caja mauve + título + paleta activa en vivo
                    Column {
                        id: brandCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: s(15)
                        anchors.leftMargin: s(15)
                        anchors.rightMargin: s(15)
                        spacing: s(10)
                        Row {
                            width: parent.width
                            spacing: s(12)
                            Rectangle {
                                width: s(36); height: s(36); radius: s(13)
                                color: colors.mauve
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰫧"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(20)
                                    color: colors.crust
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: s(2)
                                Text {
                                    text: "Dock Editor"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(15)
                                    font.weight: Font.Black
                                    color: colors.text
                                }
                                Row {
                                    spacing: s(6)
                                    Rectangle {
                                        width: s(8); height: s(8); radius: s(4)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: colors.mauve
                                    }
                                    Text {
                                        // Live palette name (Colors watcher keeps it fresh)
                                        text: themeColors.paletteName
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: s(11)
                                        color: colors.subtext0
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        id: navHairline
                        anchors.top: brandCol.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: s(10)
                        anchors.leftMargin: s(15)
                        anchors.rightMargin: s(15)
                        height: 1
                        color: Qt.alpha(colors.surface1, 0.5)
                    }

                    // Nav zone: navPill (mauve) es overlay viewport-fixed — NO
                    // hija del Flickable: el contenido scrollea con contentY y
                    // la píldora debe quedar pegada al slot de la fila activa.
                    Item {
                        id: navArea
                        anchors.top: navHairline.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: footerCol.top
                        anchors.topMargin: s(10)
                        clip: true

                        Rectangle {
                            id: navPill
                            x: colNav.x
                            width: colNav.width
                            height: s(44)
                            radius: s(18)
                            color: colors.mauve
                            // y = target animado (idx*44) − scroll (GP:440-456).
                            y: colNav.y + root.navPillTargetY - navFlick.contentY
                        }

                        Flickable {
                            id: navFlick
                            anchors.fill: parent
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentHeight: colNav.height + s(15)
                            ScrollBar.vertical: ScrollBar {
                                id: navScroll
                                width: s(4)
                                policy: ScrollBar.AsNeeded
                                hoverEnabled: true
                                active: navFlick.moving || navScroll.hovered
                                contentItem: Rectangle {
                                    radius: s(2)
                                    color: colors.surface2
                                    opacity: navScroll.active ? 1.0 : 0.45
                                }
                                background: Item {}
                            }

                            Column {
                                id: colNav
                                x: s(15)
                                width: navFlick.width - s(30)
                                spacing: 0

                                Repeater {
                                    model: root.visibleNav()
                                    delegate: NavItem {
                                        required property var modelData
                                        width: colNav.width
                                        bar: root
                                        icon: modelData.icon
                                        label: modelData.label
                                        active: root.currentPage === modelData.id
                                        onActivated: root.gotoPage(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    // Footer hints
                    Column {
                        id: footerCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: s(15)
                        anchors.rightMargin: s(15)
                        anchors.bottomMargin: s(15)
                        spacing: s(8)
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Qt.alpha(colors.surface1, 0.5)
                        }
                        Column {
                            width: parent.width
                            spacing: s(2)
                            Text {
                                text: "TAB / SHIFT+TAB — switch page"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(10)
                                color: colors.subtext0
                            }
                            Text {
                                text: "ESC — save & close"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(10)
                                color: colors.subtext0
                            }
                        }
                    }
                }

                // ── CONTENT STAGE (Fase 3 lazy Loaders + Fase 4 transición) ──
                // Cada página se instancia UNA vez via ensurePage() (visible
                // false conserva el item). Transición tipo Guide (GP:655-664):
                // opacity 250 ms + slideY s(10) 250 ms OutQuart; el wrapper
                // aplica la intro (opacity/scale/translate y).
                Item {
                    // Ancho = Row − sidebar − spacing s(20) (evita el overflow
                    // que dejaba la stage 20 px fuera del panel).
                    width: parent.width - s(220) - s(20)
                    height: parent.height
                    opacity: root.introContent
                    scale: 0.95 + (0.05 * root.introContent)
                    transform: Translate { y: s(20) * (1.0 - root.introContent) }

                    Loader {
                        id: generalLoader
                        anchors.fill: parent
                        visible: root.currentPage === "general"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: generalLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: positionLoader
                        anchors.fill: parent
                        visible: root.currentPage === "position"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: positionLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: styleLoader
                        anchors.fill: parent
                        visible: root.currentPage === "style"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: styleLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: paletteLoader
                        anchors.fill: parent
                        visible: root.currentPage === "palette"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: paletteLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: zonesLoader
                        anchors.fill: parent
                        visible: root.currentPage === "zones"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: zonesLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        onLoaded: { if (zonesLoader.item) root.zonesPage = zonesLoader.item; }
                    }
                    Loader {
                        id: workspacesLoader
                        anchors.fill: parent
                        visible: root.currentPage === "workspaces"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: workspacesLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: serpLoader
                        anchors.fill: parent
                        visible: root.currentPage === "serp"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: serpLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        onLoaded: { if (serpLoader.item) root.serpPage = serpLoader.item; }
                    }
                }
            }
        }
    }

    // ════ PAGE SIGNAL ROUTING (Phase 2/3) ════
    // Pages never import DockLayout: they declare intent signals, this root
    // computes and commits through the shared helpers. Targets are the lazy
    // item properties (null until loaded): Connections follows the binding,
    // so the routes arm themselves when zonesPage/serpPage get assigned in
    // the Loaders' onLoaded.
    Connections {
        target: root.zonesPage
        function onAddZone() { root.applyDock(DockLayout.addZone(root.dock, "start")); }
        function onCenterAll() { root.applyDock(DockLayout.arrangeAllInZone(root.dock, "center")); }
        function onResetDock() { root.applyDock(DockLayout.defaultDock()); }
    }
    Connections {
        target: root.serpPage
        function onMirrorDock() { root.mirrorDockAction(); }
        function onSerpDefaults() { root.serpDefaultsAction(); }
    }

    // ════ DnD GHOST (Phase D3) ════
    // Floating chip following the pointer during a drag. Purely visual
    // (enabled: false) — input stays with the chip's MouseArea grab.
    Item {
        id: dndGhostLayer
        anchors.fill: parent
        visible: root.dndBusy
        z: 1000
        enabled: false

        Rectangle {
            id: dndGhost
            // group drags have dndModuleId === "" (glyph + member count).
            property bool groupGhost: root.dndModuleId === ""
            property var modInfo: root.dndModuleId !== "" ? DockLayout.getModule(root.dndModuleId) : null
            readonly property int ghostW: ghostRow.implicitWidth + root.s(24)
            height: root.s(30)
            width: ghostW
            x: root.dndPointer.x - width / 2
            y: root.dndPointer.y - height / 2 - root.s(8)
            radius: root.s(8)
            color: colors.mauve
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
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: colors.crust
                }
                Text {
                    text: dndGhost.groupGhost
                        ? ("Group" + (root.serpGroupCount() > 0 ? " (" + root.serpGroupCount() + ")" : ""))
                        : (dndGhost.modInfo ? dndGhost.modInfo.label : root.dndModuleId)
                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(11); font.weight: Font.Bold; color: colors.crust
                }
            }
        }
    }

    // Fase 4: ESC ya no cierra en seco — closeSequence flushea los buffers
    // pendientes (closeFlush) y anima la salida antes de qs_manager.sh close.
    Keys.onEscapePressed: {
        closeSequence.start();
        event.accepted = true;
    }
    // Phase 2: Tab / Shift+Tab cycle the pages visible under the current
    // engine (same list the rail renders); ESC keeps the phase-1 contract.
    Keys.onTabPressed: {
        event.accepted = true;
        let nav = root.navForEngine();
        if (nav.length === 0) return;
        let idx = root.navIndex(root.currentPage);
        root.gotoPage(nav[(idx + 1) % nav.length].id);
    }
    Keys.onBacktabPressed: {
        event.accepted = true;
        let nav = root.navForEngine();
        if (nav.length === 0) return;
        let idx = root.navIndex(root.currentPage);
        if (idx < 0) idx = 0;
        root.gotoPage(nav[(idx - 1 + nav.length) % nav.length].id);
    }
}
