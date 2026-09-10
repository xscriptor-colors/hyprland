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
// BarEditor — the dock mega menu (SUPER+SHIFT+D), visiblemente "Settings".
//
// Fase B: el rail agrupa dos familias de páginas:
//   · "Desktop"  → las 6 tabs compartidas settings/tabs/*.qml (host =
//                  settingsHost, el adaptador que replica la API del popup).
//   · "Dock / Bar" → las 7 páginas del editor dock/editor/*.qml (bar = root),
//                  expandible, subtabs indentados con línea de rail.
// Los Loaders son lazy (ensurePage/setSource con initial properties) y las
// páginas del editor exponen flickable + zonasCol/serpListsCol para el DnD
// (chips en coordenadas del root vía mapToItem(bar,...)). Edits en vivo a
// settings.json; la barra viva no se toca.
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
        // Fase B: d_style/d_zones (dock) y d_serp (serp) dependen del engine;
        // si la página activa desaparece del rail caemos a d_engine (grupo
        // Dock/Bar). El grupo NO se colapsa al cambiar de engine.
        if (root.navIndex(root.currentPage) === -1) root.currentPage = "d_engine";
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

    // ════ LAUNCHER (applauncher, SUPER+D) ════
    // Config del launcher en la key "launcher" de settings.json. El merge con
    // los defaults vive aquí (merge simple); la normalización/clamps la hace
    // el propio launcher con LauncherLayout.normalize al abrirse.
    // NOTA: Config.setSetting muta rawSettings en memoria SIN reasignar la
    // propiedad, por lo que los bindings que leen Config.rawSettings no se
    // re-evalúan; este property local sí notifica y mantiene la UI en vivo.
    property var launcherCfg: (function() {
        let d = { position: "center", width: 800, maxApps: 8, margin: 24, avoidBar: true, showIcons: true };
        let raw = Config.rawSettings.launcher;
        return (raw && typeof raw === "object") ? Object.assign({}, d, raw) : d;
    })()
    function launcherConfig() { return root.launcherCfg; }
    function applyLauncher(partial) {
        root.launcherCfg = Object.assign({}, root.launcherCfg, partial);
        Config.setSetting("launcher", root.launcherCfg);
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
        if (root.engine !== "dock" || root.currentPage !== "d_zones") return [];
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
        if (root.engine !== "serp" || root.currentPage !== "d_serp") return [];
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

    // ════ FASE B: RAIL CON GRUPOS ════
    // Grupo "Desktop" (6 tabs compartidas de settings) + grupo "Dock / Bar"
    // (las 7 páginas del editor, expandible). currentPage usa ids prefijados:
    // s_* = settings/tabs/*.qml (host = settingsHost) · d_* = dock/editor/*.qml
    // (bar = root). La píldora mauve sigue al item activo por su POSICIÓN REAL
    // (navItemMap + mapToItem) con scroll-follow por contentY.
    property string currentPage: "s_general"
    property var navGroups: [
        { id: "desktop", label: "Desktop", items: [
            { id: "s_general",  icon: "󰒓", label: "General" },
            { id: "s_weather",  icon: "󰖐", label: "Weather" },
            { id: "s_keyboard", icon: "󰌌", label: "Keyboard" },
            { id: "s_monitors", icon: "󰍹", label: "Monitors" },
            { id: "s_startup",  icon: "󰐥", label: "Startup" },
            { id: "s_topbar",   icon: "󰹑", label: "Topbar" },
            { id: "d_launcher", icon: "󰀻", label: "Launcher" }
        ] },
        { id: "dockbar", label: "Dock / Bar", expandable: true, items: [
            { id: "d_engine",     icon: "󰮯", label: "Engine" },
            { id: "d_position",   icon: "󱂬", label: "Position" },
            { id: "d_style",      icon: "󰏘", label: "Style",      engine: "dock" },
            { id: "d_palette",    icon: "✦", label: "Palette" },
            { id: "d_zones",      icon: "󰮯", label: "Zones",      engine: "dock" },
            { id: "d_workspaces", icon: "󰠰", label: "Workspaces" },
            { id: "d_serp",       icon: "󰹑", label: "Serp Bar",   engine: "serp" }
        ] }
    ]
    // El grupo Dock/Bar arranca expandido; cambiar de engine NO lo colapsa.
    property bool dockGroupExpanded: true
    // Item del rail por id (lo registran los delegates): la píldora se coloca
    // con la y real del item, no con índices fijos.
    property var navItemMap: ({})
    // Animated pill slot (content px); Behavior lives here so scroll-follow
    // updates through the y binding never lag.
    property real navPillTargetY: 0

    // Items de un grupo visibles bajo el engine actual.
    function groupItems(group) {
        let out = [];
        for (let i = 0; i < group.items.length; i++) {
            let it = group.items[i];
            if (!it.engine || it.engine === root.engine) out.push(it);
        }
        return out;
    }
    // Lista plana (Desktop + Dock/Bar si expandido) para Tab/Shift+Tab.
    function navForEngine() {
        let out = [];
        for (let i = 0; i < root.navGroups.length; i++) {
            let g = root.navGroups[i];
            if (g.expandable && !root.dockGroupExpanded) continue;
            let items = root.groupItems(g);
            for (let j = 0; j < items.length; j++) out.push(items[j]);
        }
        return out;
    }
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
    // Recompute the pill's animated target from the ACTIVE ITEM's real y
    // (content px). Si la página activa no está en el rail (p.ej. grupo
    // colapsado) la píldora se oculta. Behavior 400 ms OutExpo (GP:440-456).
    function syncNavPill() {
        if (!navPill || !colNav) return;
        let item = root.navItemMap[root.currentPage];
        if (!item) { navPill.visible = false; return; }
        navPill.visible = true;
        root.navPillTargetY = item.mapToItem(colNav, 0, 0).y;
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
            // Tabs compartidas de settings (host = settingsHost)
            "s_general":  "../settings/tabs/GeneralTab.qml",
            "s_weather":  "../settings/tabs/WeatherTab.qml",
            "s_keyboard": "../settings/tabs/KeybindTab.qml",
            "s_monitors": "../settings/tabs/MonitorsTab.qml",
            "s_startup":  "../settings/tabs/StartupTab.qml",
            "s_topbar":   "../settings/tabs/TopbarTab.qml",
            // Páginas del editor (bar = root)
            "d_engine":     "editor/GeneralPage.qml",
            "d_position":   "editor/PositionPage.qml",
            "d_style":      "editor/DockStylePage.qml",
            "d_palette":    "editor/PalettePage.qml",
            "d_zones":      "editor/ZonesPage.qml",
            "d_workspaces": "editor/WorkspacesPage.qml",
            "d_serp":       "editor/SerpBarPage.qml",
            "d_launcher":   "editor/LauncherPage.qml"
        };
        return map[id] || "";
    }
    function pageLoader(id) {
        let map = {
            "s_general":  sGeneralLoader,
            "s_weather":  sWeatherLoader,
            "s_keyboard": sKeyboardLoader,
            "s_monitors": sMonitorsLoader,
            "s_startup":  sStartupLoader,
            "s_topbar":   sTopbarLoader,
            "d_engine":     dEngineLoader,
            "d_position":   dPositionLoader,
            "d_style":      dStyleLoader,
            "d_palette":    dPaletteLoader,
            "d_zones":      dZonesLoader,
            "d_workspaces": dWorkspacesLoader,
            "d_serp":       dSerpLoader,
            "d_launcher":   launcherLoader
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
        // s_* → tabs de settings (host) · d_* → páginas del editor (bar).
        if (id.indexOf("s_") === 0) loader.setSource(file, { host: settingsHost });
        else loader.setSource(file, { bar: root });
        // La pestaña Monitors necesita el poller de hyprctl que en el popup
        // arrancaba SettingsPopup al cargar su tab3; aquí lo arrancamos al
        // abrir la página (si no, monitorsModel queda vacío y no hay
        // resoluciones ni refrescos).
        if (id === "s_monitors" && !Config.displayPoller.running) {
            Config.displayPoller.running = true;
        }
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

    // ════ FASE B: HOST DE LAS SETTINGS TABS ════
    // Las tabs compartidas (settings/tabs/*.qml) esperan la API del root de
    // SettingsPopup (host.*). Este adaptador invisible la replica desde el
    // editor: s(), los roles de la instancia local Colors, highlightedBox,
    // isLayoutDropdownOpen, los modelos keybinds/startup y las acciones que en
    // el popup resolvía el host (saveAllKeybinds/saveAllStartup/appScaleStep).
    // Los ListModel son ids: se exponen con `property alias` porque los ids no
    // son accesibles desde otros archivos (mismo motivo que en SettingsPopup).
    Item {
        id: settingsHost
        visible: false
        width: 0
        height: 0

        function s(val) { return root.s(val); }

        readonly property color base: themeColors.base
        readonly property color mantle: themeColors.mantle
        readonly property color crust: themeColors.crust
        readonly property color text: themeColors.text
        readonly property color subtext0: themeColors.subtext0
        readonly property color subtext1: themeColors.subtext1
        readonly property color surface0: themeColors.surface0
        readonly property color surface1: themeColors.surface1
        readonly property color surface2: themeColors.surface2
        readonly property color overlay0: themeColors.overlay0
        readonly property color overlay1: themeColors.overlay1
        readonly property color overlay2: themeColors.overlay2
        readonly property color mauve: themeColors.mauve
        readonly property color blue: themeColors.blue
        readonly property color green: themeColors.green
        readonly property color red: themeColors.red
        readonly property color yellow: themeColors.yellow
        readonly property color peach: themeColors.peach
        readonly property color sapphire: themeColors.sapphire
        readonly property color teal: themeColors.teal
        readonly property color pink: themeColors.pink

        // Estado de la navegación del popup: las tabs lo leen Y lo escriben
        // (hover/click sobre una fila); aquí solo se guarda el valor.
        property int highlightedBox: -1
        function clearHighlight() { highlightedBox = -1; }
        property bool isLayoutDropdownOpen: false

        ListModel { id: kbModelData }
        ListModel { id: startupModelData }
        property alias kbModel: kbModelData
        property alias startupModel: startupModelData

        // Poblar los modelos. Las señales keybindsLoaded()/startupLoaded() de
        // Config se emiten UNA vez al arrancar el shell (antes de que exista
        // este widget), así que además de escucharlas hay que poblar al crear
        // el adaptador y cuando Config termine de leer (dataReady).
        function populateKbModel() {
            kbModelData.clear();
            for (let i = 0; i < Config.keybindsData.length; i++) {
                let k = Config.keybindsData[i];
                kbModelData.append({
                    type: k.type || "bind",
                    mods: k.mods || "",
                    key: k.key || "",
                    dispatcher: k.dispatcher || "exec",
                    command: k.command || "",
                    isEditing: false
                });
            }
        }
        function populateStartupModel() {
            startupModelData.clear();
            for (let s of Config.startupData) {
                startupModelData.append({ command: s.command || "", isEditing: false });
            }
        }

        Component.onCompleted: {
            populateKbModel();
            populateStartupModel();
        }

        Connections {
            target: Config
            function onKeybindsLoaded() { populateKbModel(); }
            function onKeybindsDataChanged() { populateKbModel(); }
            function onStartupLoaded() { populateStartupModel(); }
            function onStartupDataChanged() { populateStartupModel(); }
            function onDataReadyChanged() {
                if (Config.dataReady) {
                    populateKbModel();
                    populateStartupModel();
                }
            }
        }

        function saveAllKeybinds() {
            let bindsArray = [];
            for (let i = 0; i < kbModelData.count; i++) {
                let item = kbModelData.get(i);
                if (!item.key && !item.command) continue;
                bindsArray.push({
                    type: item.type,
                    mods: item.mods,
                    key: item.key,
                    dispatcher: item.dispatcher,
                    command: item.command,
                    isEditing: false // CRITICAL: evita que QML pierda el rol
                });
            }
            Config.saveAllKeybinds(bindsArray);
        }

        function saveAllStartup() {
            let startupArray = [];
            for (let i = 0; i < startupModelData.count; i++) {
                let cmd = startupModelData.get(i).command.trim();
                if (cmd.length > 0) startupArray.push({ command: cmd });
            }
            Config.saveAllStartup(startupArray);
        }

        // App scale (mismo comportamiento que el General tab del popup).
        function appScaleStep(dir) {
            let next = Math.max(0.75, Math.min(2.0, Config.appScale + dir * 0.25));
            Config.appScale = Math.round(next * 100) / 100;
        }
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
                                    text: "Settings"
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
                            // y = y real del item activo (navPillTargetY, animada
                            // 400 ms OutExpo) − scroll de la nav (GP:440-456).
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

                                // ── Grupo: Desktop ─────────────────────────────
                                Item {
                                    width: parent.width
                                    height: s(30)
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: s(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.navGroups[0].label
                                        font.family: "Hack Nerd Font"
                                        font.weight: Font.Bold
                                        font.pixelSize: s(10)
                                        color: colors.subtext0
                                    }
                                }
                                Repeater {
                                    model: root.groupItems(root.navGroups[0])
                                    delegate: NavItem {
                                        id: navRowDesktop
                                        required property var modelData
                                        readonly property string pageId: modelData.id
                                        width: colNav.width
                                        bar: root
                                        icon: modelData.icon
                                        label: modelData.label
                                        active: root.currentPage === modelData.id
                                        onActivated: root.gotoPage(modelData.id)
                                        Component.onCompleted: { root.navItemMap[navRowDesktop.pageId] = navRowDesktop; root.syncNavPill(); }
                                        Component.onDestruction: delete root.navItemMap[navRowDesktop.pageId]
                                        onYChanged: if (root.currentPage === modelData.id) root.syncNavPill()
                                    }
                                }

                                // ── Grupo: Dock / Bar (expandible) ─────────────
                                Item {
                                    id: dockGroupHeader
                                    width: parent.width
                                    height: s(30)
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: s(6)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.navGroups[1].label
                                        font.family: "Hack Nerd Font"
                                        font.weight: Font.Bold
                                        font.pixelSize: s(10)
                                        color: colors.subtext0
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: s(8)
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰅀"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: s(12)
                                        color: colors.subtext0
                                        rotation: root.dockGroupExpanded ? 0 : -90
                                        Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.dockGroupExpanded = !root.dockGroupExpanded;
                                            Qt.callLater(root.syncNavPill);
                                        }
                                    }
                                }
                                Item {
                                    id: dockItemsWrap
                                    width: parent.width
                                    height: dockCol.height
                                    visible: root.dockGroupExpanded

                                    // Línea de rail (estilo Serpantium) para los subtabs.
                                    Rectangle {
                                        x: s(6)
                                        width: s(2)
                                        radius: s(1)
                                        height: Math.max(0, parent.height - s(8))
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.alpha(colors.surface1, 0.5)
                                    }
                                    Column {
                                        id: dockCol
                                        x: s(14)
                                        width: parent.width - s(14)
                                        spacing: 0
                                        Repeater {
                                            model: root.groupItems(root.navGroups[1])
                                            delegate: NavItem {
                                                id: navRowDock
                                                required property var modelData
                                                readonly property string pageId: modelData.id
                                                width: dockCol.width
                                                bar: root
                                                icon: modelData.icon
                                                label: modelData.label
                                                active: root.currentPage === modelData.id
                                                onActivated: root.gotoPage(modelData.id)
                                                Component.onCompleted: { root.navItemMap[navRowDock.pageId] = navRowDock; root.syncNavPill(); }
                                                Component.onDestruction: delete root.navItemMap[navRowDock.pageId]
                                                onYChanged: if (root.currentPage === modelData.id) root.syncNavPill()
                                            }
                                        }
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
                        id: dEngineLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_engine"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dEngineLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: dPositionLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_position"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dPositionLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: dStyleLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_style"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dStyleLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: dPaletteLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_palette"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dPaletteLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: dZonesLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_zones"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dZonesLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        onLoaded: { if (dZonesLoader.item) root.zonesPage = dZonesLoader.item; }
                    }
                    Loader {
                        id: dWorkspacesLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_workspaces"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dWorkspacesLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: dSerpLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_serp"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: dSerpLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        onLoaded: { if (dSerpLoader.item) root.serpPage = dSerpLoader.item; }
                    }
                    Loader {
                        id: launcherLoader
                        anchors.fill: parent
                        visible: root.currentPage === "d_launcher"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: launcherLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    // ── Tabs compartidas de settings (host = settingsHost) ──
                    Loader {
                        id: sGeneralLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_general"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sGeneralLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: sWeatherLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_weather"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sWeatherLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: sKeyboardLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_keyboard"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sKeyboardLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: sMonitorsLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_monitors"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sMonitorsLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: sStartupLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_startup"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sStartupLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                    Loader {
                        id: sTopbarLoader
                        anchors.fill: parent
                        visible: root.currentPage === "s_topbar"
                        opacity: visible ? 1.0 : 0.0
                        property real slideY: visible ? 0 : root.s(10)
                        Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        transform: Translate { y: sTopbarLoader.slideY }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    // ── ADD FLOTANTE (Keyboard / Startup) ───────────────────
                    // El botón "+ Add" del popup vive en SU header (fuera de las
                    // tabs), por eso al embeberlas aquí hay que reponerlo: añade
                    // una fila nueva al modelo correspondiente y la deja en
                    // edición (misma semántica que SettingsPopup.qml:1000-1010).
                    EditorButton {
                        z: 100
                        compact: true
                        bar: root
                        label: "+ Add"
                        visible: root.currentPage === "s_keyboard" || root.currentPage === "s_startup"
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: s(18)
                        anchors.bottomMargin: s(18)
                        onActivated: {
                            if (root.currentPage === "s_startup") {
                                settingsHost.startupModel.append({ command: "", isEditing: true });
                                let l = root.pageLoader("s_startup");
                                if (l && l.item && l.item.scrollToBottom) Qt.callLater(() => l.item.scrollToBottom());
                            } else if (root.currentPage === "s_keyboard") {
                                settingsHost.kbModel.append({ type: "bind", mods: "", key: "", dispatcher: "exec", command: "", isEditing: true });
                                let l = root.pageLoader("s_keyboard");
                                if (l && l.item && l.item.scrollToBottom) Qt.callLater(() => l.item.scrollToBottom());
                            }
                        }
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
