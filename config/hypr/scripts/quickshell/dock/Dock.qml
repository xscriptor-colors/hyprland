import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import ".."
import "../WindowRegistry.js" as LayoutMath
import "DockLayout.js" as DockLayout

// ============================================================================
// Dock — the position-agnostic bar.
//
// Replaces the old top-only TopBar.qml. The same island-pill aesthetic and all
// module/data machinery are preserved, but the dock can sit on any screen edge:
//
//   position: "top" | "bottom" | "left" | "right"
//   orientation: derived from position (horizontal / vertical)
//
// The visual + layout config lives in settings.json under "dock" (see
// DockLayout.js). Old "topbar" settings are migrated on first load. Colors
// come from the Matugen-free palette system (dock/Colors.qml).
//
// Data plumbing (watchers/pollers) is centralized here; modules read state
// through the `bar` object — same contract as the old TopBar, so existing
// modules keep working untouched while we migrate them to ModulePill.
// ============================================================================

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: dockWindow

            required property var modelData
            screen: modelData

            // Inline replica of the parent dir's Caching.qml so this component
            // stays self-contained inside dock/.
            QtObject {
                id: paths
                readonly property string home: Quickshell.env("HOME")
                readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")
                readonly property string cacheDir: home + "/.cache/quickshell"
                readonly property string stateDir: home + "/.local/state/quickshell"
                readonly property string runDir: (xdgRuntimeDir !== "" ? xdgRuntimeDir : "/tmp") + "/quickshell"
                readonly property string logDir: runDir + "/logs"
                function getCacheDir(name) {
                    let envPath = Quickshell.env("QS_CACHE_" + name.toUpperCase());
                    let p = envPath ? envPath : (cacheDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getStateDir(name) {
                    let envPath = Quickshell.env("QS_STATE_" + name.toUpperCase());
                    let p = envPath ? envPath : (stateDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getRunDir(name) {
                    let envPath = Quickshell.env("QS_RUN_" + name.toUpperCase());
                    let p = envPath ? envPath : (runDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getLogDir(name) {
                    let envPath = Quickshell.env("QS_LOG_" + name.toUpperCase());
                    let p = envPath ? envPath : (logDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
            }

            // ================================================================
            // SCALING (inlined — avoids importing Scaler.qml from the parent dir)
            // ================================================================
            property real uiScale: 1.0
            readonly property real baseScale: LayoutMath.getScale(
                dockWindow.screen ? dockWindow.screen.width : 1920,
                dockWindow.screen ? dockWindow.screen.height : 1080,
                dockWindow.uiScale)
            function s(val) { return LayoutMath.s(val, baseScale); }

            // ================================================================
            // THEME COLORS (Matugen-free)
            // ================================================================
            Colors {
                id: dockColors
            }
            // Exposed as a property so modules/zones can use `colors.<role>`
            // exactly like they did with the legacy MatugenColors component.
            readonly property var colors: dockColors

            // ================================================================
            // DOCK CONFIG (settings.json "dock" key)
            //
            // CUSTOMIZATION HOOK: every visual/layout value the mega menu edits
            // lands here. `syncDockConfig()` copies the parsed dockConfig into
            // plain properties in ONE synchronous pass so orientation/geometry/
            // zones always stay consistent (readonly binding chains evaluate
            // lazily and caused stale orientation bugs).
            // ================================================================
            property var dockConfig: DockLayout.defaultDock()
            property var zones: dockConfig.zones
            // Becomes true only after settings.json has been read AND the dock
            // config synced, so uiScale/baseScale are final before any module
            // renders (bar.s() is a function, so QML can't reactively rescale).
            property bool configReady: false
            property string position: "top"
            property string orientation: "horizontal"
            property string paletteName: "x"
            property real thickness: 48
            property real edgeGap: 8
            property real roundness: 1.0
            property bool pillBg: true
            property bool pillSolid: false
            // "barBg" — solid/translucent background strip behind the whole bar;
            // islands then float INSIDE it instead of being standalone pills.
            property bool barBg: false
            property real borderWidth: 0
            property string borderColor: "surface1"
            // Configurable font for all module text/icons (dock.font).
            property string fontFamily: "Hack Nerd Font"
            // Alpha used by the optional full-bar background strip (dock.barOpacity).
            property real barOpacity: 0.85
            // Master switch for live island drag & drop (dock.dragModules).
            property bool dragModulesEnabled: true
            // Flat-mode icon tinting for the serp engine (solid/fill styles):
            // when true, ModulePill tints its content with the module accent
            // color instead of filling an island (no double fill on a strip).
            property bool accentTintMode: false
            // Clock format used while the serp engine is active (serpbar.timeFormat).
            property string serpTimeFormat: "" 
            // Tracks the last applied orientation: an axis change (horizontal ↔
            // vertical) remounts the zones in-process (Phase D3) so every module
            // re-reads bar.orientation at creation — no full shell reload.
            property string _lastOrientation: ""

            // ================================================================
            // DUAL BAR ENGINES (Phase D4-E1b): "dock" ⇄ "serp"
            //
            // The same window hosts two render engines. In engine "serp" the
            // classic left/center/right bar (dock/SerpBar.qml) is mounted
            // instead of the zone Repeater, driven by settings.json's top-level
            // "serpbar" key (see DockLayout.js serpbar section). No data is
            // duplicated and no "dock" settings are written: while serpMode the
            // host simply applies the serp style's visual flags (pillBg/
            // pillSolid/barBg/edgeGap via serpStyleFlags()) + the serpbar
            // position onto ITSELF; modules only see the standard contract, so
            // they behave identically in both engines. Switching back to
            // "dock" restores the persisted dockConfig through syncDockConfig().
            // ================================================================
            property string barEngine: "dock"
            property var serpConfig: DockLayout.serpbarDefaults()
            // Revealed state of the optional serp autohide (SerpBar drives it
            // through the bar object; the exclusiveZone binding reacts to it).
            property bool serpAutohideRevealed: true
            readonly property bool serpMode: dockWindow.barEngine === "serp"
            // Fill forces widthPercent to 100 (DockLayout.isFillStyle) — the
            // strip then spans the whole content frame edge-to-edge.
            readonly property bool serpFillStyle: dockWindow.serpMode && DockLayout.isFillStyle(dockWindow.serpConfig.style)
            // The strip/tab sits flush against the screen edge: fill always,
            // autohide bars need the flush edge so the 5px reveal tab is at the
            // very screen edge (the SerpBar translate leaves only that sliver).
            readonly property bool serpEdgeFlush: dockWindow.serpMode && (dockWindow.serpFillStyle || dockWindow.serpConfig.autohide === true)
            // SerpBar's content box (the strip band + sections). The click
            // mask follows this item's geometry (see the Region above).
            property Item serpAreaItem: serpLoader.item ? serpLoader.item.serpContentArea : null
            // Content choke point for the settings reader: text of the last
            // successfully parsed settings.json. Keeps the directory watcher's
            // wakeups on unrelated config files completely silent.
            property string lastSettingsJson: ""

            // ================================================================
            // LIVE ISLAND DRAG & DROP STATE (Phase D2)
            // ================================================================
            property bool dragBusy: false
            property string dragId: ""
            property var dragStartDock: ({})
            property var dragWorkingDock: ({})
            property bool pendingDockConfigRefresh: false
            // Set when an axis flip arrived while a drag owned the config; the
            // remount then runs at the end of the gesture instead (see
            // endDragAt/cancelDrag).
            property bool pendingAxisRemount: false
            // Same deferral for engine/config switches that affect the serp
            // visuals (barEngine/serpConfig/position flips mid-drag).
            property bool pendingSerpRefresh: false
            // Orientation the currently mounted SerpBar was created with
            // ("" = nothing mounted yet). Serp modules bake compact/horizontal
            // branches at creation exactly like dock zones, so an axis flip
            // must recreate the SerpBar loader (see syncSerpLoader()).
            property string _serpOrientation: ""

            // Begin a drag session for module `id` (called by Zone slots).
            function startDrag(id) {
                if (dockWindow.dragBusy || !dockWindow.dragModulesEnabled) return;
                if (!dockWindow.dockConfig || !DockLayout.isList(dockWindow.dockConfig.zones)) return;
                try {
                    dockWindow.dragStartDock = DockLayout.cloneDock(dockWindow.dockConfig);
                    dockWindow.dragWorkingDock = DockLayout.cloneDock(dockWindow.dockConfig);
                } catch (e) { return; }
                dockWindow.dragId = id;
                dockWindow.dragBusy = true;
                dockWindow.pendingDockConfigRefresh = false;
            }

            // Live reorder under the pointer (throttled). `px/py` are in this
            // window's coordinates.
            function updateDragAt(px, py) {
                if (!dockWindow.dragBusy) return;
                let hit = null;
                let zones = barContent.children;
                for (let i = 0; i < zones.length; i++) {
                    let z = zones[i];
                    if (!z || !z.isDockZone) continue;
                    if (z.containsDockPoint(px, py)) {
                        hit = z.dockPointToInsert(px, py);
                        if (hit) break;
                    }
                }
                if (!hit) return; // pointer not over any zone: keep last spot
                let next = DockLayout.moduleMoveTo(dockWindow.dragWorkingDock, dockWindow.dragId, hit.zoneId, hit.index);
                let nextStr = JSON.stringify(next);
                if (nextStr !== JSON.stringify(dockWindow.dockConfig)) {
                    dockWindow.dragWorkingDock = next;
                    dockWindow.dockConfig = next;
                }
            }

            // Commit (drop inside a zone) or cancel (drop outside the bar).
            function endDragAt(px, py) {
                if (!dockWindow.dragBusy) return;
                let inside = false;
                let zones = barContent.children;
                for (let i = 0; i < zones.length; i++) {
                    let z = zones[i];
                    if (z && z.isDockZone && z.containsDockPoint(px, py)) { inside = true; break; }
                }
                let finalDock = dockWindow.dragWorkingDock;
                dockWindow.dragBusy = false;
                dockWindow.dragId = "";
                if (inside) {
                    // Write once, atomically; the in-memory config is already the
                    // result, so the watcher sees no diff and nothing flickers.
                    Config.setSetting("dock", finalDock);
                } else {
                    dockWindow.dockConfig = dockWindow.dragStartDock;
                }
                if (dockWindow.pendingDockConfigRefresh) {
                    dockWindow.pendingDockConfigRefresh = false;
                    settingsReader.running = false;
                    settingsReader.running = true;
                }
                // An axis flip that arrived mid-drag remounts now that the
                // gesture no longer owns the config.
                dockWindow.flushPendingAxisRemount();
                // Same for serp engine/config switches deferred mid-drag.
                dockWindow.flushPendingSerpRefresh();
            }

            // Abort the session (drag cancelled by the slot MouseArea).
            function cancelDrag() {
                if (!dockWindow.dragBusy) return;
                let restore = dockWindow.dragStartDock;
                dockWindow.dragBusy = false;
                dockWindow.dragId = "";
                dockWindow.dockConfig = restore;
                if (dockWindow.pendingDockConfigRefresh) {
                    dockWindow.pendingDockConfigRefresh = false;
                    settingsReader.running = false;
                    settingsReader.running = true;
                }
                dockWindow.flushPendingAxisRemount();
                dockWindow.flushPendingSerpRefresh();
            }

            // Rebuild every zone delegate in THIS process (Phase D3). Crossing
            // the axis used to IPC-reload the whole shell because modules baked
            // stale orientation state at creation. Emptying the zones model
            // destroys each Zone + its module Loaders, and Qt.callLater refills
            // it from the already-synced dockConfig in the next event turn, so
            // fresh modules read the NEW orientation/geometry from the start.
            // syncDockConfig() (geometry, margins, anchors) already ran before
            // this is called, so the window relayouts and the zones mount
            // against the final values. Zone's entrance cascade replays because
            // the new delegates start with ready=false.
            function remountZones() {
                if (!dockWindow.configReady) return;
                dockWindow.zones = [];
                Qt.callLater(() => {
                    let z = (dockWindow.dockConfig && dockWindow.dockConfig.zones)
                          ? dockWindow.dockConfig.zones : [];
                    dockWindow.zones = z;
                });
            }

            // Run a deferred remount after a drag gesture ends (axis flips are
            // impossible mid-drag, but the guard keeps the invariant anyway).
            function flushPendingAxisRemount() {
                if (!dockWindow.pendingAxisRemount) return;
                dockWindow.pendingAxisRemount = false;
                dockWindow.remountZones();
            }

            // Deferred serp-visual refresh after a drag gesture ends.
            function flushPendingSerpRefresh() {
                if (!dockWindow.pendingSerpRefresh) return;
                dockWindow.pendingSerpRefresh = false;
                dockWindow.syncVisualEngine();
            }

            // ---- dual engine: visuals ---------------------------------------
            // In serp mode the host overrides ITS OWN visual flags with the
            // ones derived from the serpbar style, plus the serpbar position
            // (the serpbar owns the screen edge while active). Nothing is ever
            // written back into settings.json's "dock" key — syncDockConfig()
            // restores the persisted values when the engine switches back.
            function applySerpVisuals() {
                if (!dockWindow.serpMode || !dockWindow.dockConfig) return;
                let f = DockLayout.serpStyleFlags(dockWindow.serpConfig.style);
                if (f.pillBg !== undefined) dockWindow.pillBg = f.pillBg;
                if (f.pillSolid !== undefined) dockWindow.pillSolid = f.pillSolid;
                if (f.barBg !== undefined) dockWindow.barBg = f.barBg;
                if (f.edgeGap !== undefined) dockWindow.edgeGap = f.edgeGap;
                // Distinct pills (serpantium BarTab, shown for modular + solid):
                // island fills become SOLID so each pill reads clearly even in
                // modular; on the strip the SerpBar draws the raised slabs.
                if (dockWindow.serpConfig.distinctPills === true) dockWindow.pillSolid = true;
                // Serpantium corners follow the theme radius; ours is a knob
                // (serpbar.roundness) mapped onto the shared pillRadius() so
                // islands/strip/groups stay in sync. Restored on engine exit.
                dockWindow.roundness = (typeof dockWindow.serpConfig.roundness === "number")
                    ? dockWindow.serpConfig.roundness : dockWindow.roundness;
                // Time format for the clock island (dock engine keeps HH:mm:ss).
                if (typeof dockWindow.serpConfig.timeFormat === "string"
                    && dockWindow.serpConfig.timeFormat !== ""
                    && dockWindow.serpTimeFormat !== dockWindow.serpConfig.timeFormat) {
                    dockWindow.serpTimeFormat = dockWindow.serpConfig.timeFormat;
                }
                // serpbar.position is normalized (POSITIONS) by getSerpbar().
                if (dockWindow.position !== dockWindow.serpConfig.position) {
                    dockWindow.position = dockWindow.serpConfig.position;
                    // orientation is a plain property (kept in sync manually,
                    // see syncDockConfig) — never a derived binding.
                    dockWindow.orientation = (dockWindow.position === "top" || dockWindow.position === "bottom") ? "horizontal" : "vertical";
                }
                dockWindow.accentTintMode = dockWindow.serpConfig.style !== "modular";
                // ---- Phase R1: serpbar visual keys (serpantium BarTab parity) ----
                // These live on the host while the classic engine renders and are
                // restored by syncDockConfig() when the engine leaves "serp":
                //   • edgeGap: serpantium floats its bar s(4) off the screen edge
                //     in every non-fill style (Bar.qml:265-270 margins s(4)); the
                //     dock's default 8px edge breathing would read differently on
                //     the classic bar. Style flags may still force 0 (fill).
                //   • thickness: serpbar.thickness (px) overrides the band size;
                //     null = keep the dock's own thickness (inherit).
                //   • barOpacity: serpbar.opacity (percent) → strip alpha; the
                //     strip reads bar.barOpacity only (see SerpBar.qml), so a
                //     leftover dock pillSolid:true can never freeze it opaque.
                dockWindow.edgeGap = (f.edgeGap !== undefined) ? f.edgeGap : 4;
                if (typeof dockWindow.serpConfig.thickness === "number") {
                    dockWindow.thickness = Math.max(24, Math.min(120, dockWindow.serpConfig.thickness));
                }
                if (typeof dockWindow.serpConfig.opacity === "number") {
                    dockWindow.barOpacity = Math.max(0.2, Math.min(1.0, dockWindow.serpConfig.opacity / 100));
                }
                // Config/engine edits always re-reveal (never leave the bar
                // hidden behind a fresh config).
                dockWindow.serpAutohideRevealed = true;
            }

            // Re-apply whichever engine owns the window visuals right now:
            // serp → serp flags/position; dock → the persisted dockConfig.
            // Visual-only: zones are never touched here. Deferred while a drag
            // owns the config (same pattern as the axis remount).
            function syncVisualEngine() {
                if (!dockWindow.configReady) return;
                if (dockWindow.dragBusy) { dockWindow.pendingSerpRefresh = true; return; }
                if (dockWindow.serpMode) dockWindow.applySerpVisuals();
                else dockWindow.syncDockConfig();
                dockWindow.syncSerpLoader();
            }

            // Mount/unmount the SerpBar loader (engine switch) or recreate it
            // when the axis flipped while serp mode was active (serp modules
            // bake compact/horizontal branches at creation, exactly like dock
            // zones do — hence the same in-process remount approach).
            //
            // Robust mount contract: the loader is driven by STATE (engine +
            // configReady), not by one-shot event ordering. We mount whenever
            // the item is missing and retry a few times at boot, because the
            // reader pass that flips the engine may race the very first
            // request. A null item here means NO bar at all, so never leave
            // it half-mounted.
            function syncSerpLoader() {
                if (!dockWindow.configReady) return;
                let want = dockWindow.serpMode;
                let item = serpLoader.item;
                if (want) {
                    let axisFlip = dockWindow._serpOrientation !== "" && dockWindow._serpOrientation !== dockWindow.orientation;
                    if (!item || serpLoader.status !== Loader.Ready || axisFlip) {
                        serpLoader.setSource("SerpBar.qml", serpLoader.serpInitialProps());
                        dockWindow._serpOrientation = dockWindow.orientation;
                    }
                } else if (serpLoader.source !== "") {
                    serpLoader.source = "";
                    dockWindow._serpOrientation = "";
                }
            }
            // Boot/late-config safety: reader passes and handlers can fire out
            // of order (engine flips right after configReady). Re-check the
            // loader a few times after startup until it is actually mounted.
            Timer {
                id: serpMountGuard
                interval: 400
                repeat: true
                running: dockWindow.serpMode && dockWindow.configReady
                property int ticks: 0
                onTriggered: {
                    if (!serpLoader.item || serpLoader.status !== Loader.Ready) dockWindow.syncSerpLoader();
                    ticks++;
                    if (serpLoader.item || ticks > 12) running = false;
                }
            }
            onDockConfigChanged: {
                // syncDockConfig() applies the PERSISTED dock values; while the
                // serp engine is active the serp visuals/position override them
                // right after (restored automatically when engine === "dock").
                syncDockConfig();
                if (dockWindow.serpMode) dockWindow.applySerpVisuals();
                // Only remount on an ACTUAL axis change (vertical ↔ horizontal),
                // and never during boot (before configReady). Same-axis position
                // moves and pure visual changes never rebuild anything. The
                // orientation is read AFTER the serp override above so serp-side
                // flips are caught by the same detector.
                let axisFlip = dockWindow.configReady && dockWindow._lastOrientation !== "" && dockWindow.orientation !== dockWindow._lastOrientation;
                if (axisFlip) {
                    if (dockWindow.serpMode) {
                        if (dockWindow.dragBusy) dockWindow.pendingSerpRefresh = true;
                        else dockWindow.syncSerpLoader();
                    } else if (dockWindow.dragBusy) {
                        dockWindow.pendingAxisRemount = true;
                    } else {
                        dockWindow.remountZones();
                    }
                }
                dockWindow._lastOrientation = dockWindow.orientation;
            }
            // Engine switch ("dock" ⇄ "serp") and serpbar edits re-run the
            // visual pass without touching zones. When the engine returns to
            // "dock", syncVisualEngine() restores the persisted dockConfig.
            onBarEngineChanged: dockWindow.syncVisualEngine()
            onSerpConfigChanged: dockWindow.syncVisualEngine()
            // SerpBar modules bake compact/horizontal branches at creation;
            // remount the bar loader on axis flips in serp mode (see
            // syncSerpLoader). Dock-mode flips keep using the zone remount
            // path above.
            onOrientationChanged: {
                if (!dockWindow.serpMode || !dockWindow.configReady) return;
                if (dockWindow.dragBusy) { dockWindow.pendingSerpRefresh = true; return; }
                dockWindow.syncSerpLoader();
            }
            Component.onCompleted: {
                syncDockConfig();
                dockWindow._lastOrientation = dockWindow.orientation;
                // Keep Hyprland window-border colors in sync with the palette /
                // border overrides at all times (the dock bar is always alive,
                // so this fires whether or not the DockEditor is open).
                dockColors.paletteApplied.connect(function() { dockColors.syncWindowBorders(); });
                dockColors.settingsUpdated.connect(function() { dockColors.syncWindowBorders(); });
            }

            function syncDockConfig() {
                if (!dockConfig) return;
                dockWindow.position = dockConfig.position || "top";
                dockWindow.orientation = (dockWindow.position === "top" || dockWindow.position === "bottom") ? "horizontal" : "vertical";
                dockWindow.paletteName = dockConfig.palette || "x";
                dockWindow.thickness = dockConfig.thickness;
                dockWindow.edgeGap = dockConfig.edgeGap;
                dockWindow.roundness = dockConfig.roundness;
                dockWindow.pillBg = dockConfig.pillBg;
                dockWindow.pillSolid = dockConfig.pillSolid;
                dockWindow.barBg = dockConfig.barBg;
                dockWindow.barOpacity = (typeof dockConfig.barOpacity === "number") ? dockConfig.barOpacity : 0.85;
                dockWindow.dragModulesEnabled = dockConfig.dragModules !== false;
                dockWindow.accentTintMode = false;
                dockWindow.workspacesMarker = (typeof dockConfig.workspacesMarker === "string") ? dockConfig.workspacesMarker : "number";
                dockWindow.workspacesMarkerText = (typeof dockConfig.workspacesMarkerText === "string") ? dockConfig.workspacesMarkerText : "";
                dockWindow.borderWidth = dockConfig.borderWidth;
                dockWindow.borderColor = dockConfig.borderColor;
                dockWindow.fontFamily = dockConfig.font || "Hack Nerd Font";
                dockWindow.zones = dockConfig.zones;
                applyPosition();
            }

            // Legacy aliases so pre-ModulePill modules keep working unchanged.
            property real topbarRoundness: roundness
            property bool topbarPillBg: pillBg
            property bool topbarPillSolid: pillSolid
            onRoundnessChanged: topbarRoundness = roundness
            onPillBgChanged: topbarPillBg = pillBg
            onPillSolidChanged: topbarPillSolid = pillSolid

            // ================================================================
            // GEOMETRY
            // ================================================================
            property int barHeight: s(thickness)
            // Vertical docks need extra width (~50px physical) to fit compact
            // islands and the HH:mm clock comfortably.
            property int barWidth: orientation === "horizontal" ? s(thickness) : Math.max(s(thickness), s(70))
            property int pillHeight: orientation === "horizontal" ? barHeight - s(12) : barWidth - s(8)
            property int pillWidth: orientation === "horizontal" ? barHeight - s(12) : barWidth - s(8)
            function pillRadius(h) { return Math.round(h * 0.5 * roundness); }

            // The settings panel occupies the edge opposite a left/right dock.
            property bool panelFromLeft: position !== "left"

            implicitHeight: orientation === "horizontal" ? barHeight : (dockWindow.screen ? dockWindow.screen.height : 1080)
            implicitWidth: orientation === "horizontal" ? (dockWindow.screen ? dockWindow.screen.width : 1920) : barWidth

            // --- margins -------------------------------------------------------
            // The dock margins offset the whole surface from the anchored edges:
            // the screen-edge side carries edgeGap, the other sides s(4). While
            // the serp engine is active the values above are overridden:
            //   • fill:        EVERY margin is 0 — serpantium's fill reaches all
            //                  four screen edges (Bar.qml:265-270 margins 0 when
            //                  isFill). WidthPercent is forced to 100 so the
            //                  strip truly spans the whole screen.
            //   • autohide:    the edge side is 0 too, so the 4px reveal sliver
            //                  that SerpBar leaves after the hide translate sits
            //                  flush at the very screen edge;
            //   • edge side:   s(4) in every other serp state (applySerpVisuals
            //                  overrides edgeGap to 4 — serpantium margins s(4));
            //   • cross sides (left/right on top/bottom bars and vice versa)
            //                  keep their s(4) — identical to serpantium.
            // Everything restores itself on the way back to the dock engine
            // because the expressions below fall through to the dock formula.
            margins {
                top: orientation === "vertical"
                    ? (dockWindow.serpMode && dockWindow.serpFillStyle ? 0 : s(4))
                    : (dockWindow.serpMode
                        ? (position === "top" ? (dockWindow.serpEdgeFlush ? 0 : s(edgeGap))
                            : (position === "bottom" && dockWindow.serpFillStyle ? 0 : s(4)))
                        : (position === "top" ? s(edgeGap) : s(4)))
                bottom: orientation === "vertical"
                    ? (dockWindow.serpMode && dockWindow.serpFillStyle ? 0 : s(4))
                    : (dockWindow.serpMode
                        ? (position === "bottom" ? (dockWindow.serpEdgeFlush ? 0 : s(edgeGap))
                            : (position === "top" && dockWindow.serpFillStyle ? 0 : s(4)))
                        : (position === "bottom" ? s(edgeGap) : s(4)))
                left: orientation === "horizontal"
                    ? (dockWindow.serpMode && dockWindow.serpFillStyle ? 0 : s(4))
                    : (dockWindow.serpMode
                        ? (position === "left" ? (dockWindow.serpEdgeFlush ? 0 : s(edgeGap))
                            : (position === "right" && dockWindow.serpFillStyle ? 0 : s(4)))
                        : (position === "left" ? s(edgeGap) : s(4)))
                right: orientation === "horizontal"
                    ? (dockWindow.serpMode && dockWindow.serpFillStyle ? 0 : s(4))
                    : (dockWindow.serpMode
                        ? (position === "right" ? (dockWindow.serpEdgeFlush ? 0 : s(edgeGap))
                            : (position === "left" && dockWindow.serpFillStyle ? 0 : s(4)))
                        : (position === "right" ? s(edgeGap) : s(4)))
            }
            // A hidden autohide bar reserves no edge space at all; every other
            // state reserves the same band as the dock engine.
            exclusiveZone: dockWindow.serpMode && dockWindow.serpConfig.autohide === true && !dockWindow.serpAutohideRevealed
                ? 0
                : (orientation === "horizontal" ? barHeight : barWidth)
            color: "transparent"
            
            // --- clickthrough mask (serp engine) --------------------------------
            // The layer surface spans the whole bar band (or the whole screen
            // width for widthPercent < 100), but only the actual strip band +
            // its contents must be interactive. The mask tracks the SerpBar
            // content box ITEM (Region.item watches x/y/w/h, so the autohide
            // slide keeps the clickable area glued to the visible strip — when
            // hidden only the 4px tab sliver remains clickable and everything
            // else passes through to the windows below). null in the dock
            // engine keeps today's whole-band input behavior.
            Region {
                id: serpMask
                Region {
                    item: dockWindow.serpAreaItem
                }
            }
            mask: dockWindow.serpMode && dockWindow.serpAreaItem ? serpMask : null

            function applyPosition() {
                dockWindow.anchors.top = undefined;
                dockWindow.anchors.bottom = undefined;
                dockWindow.anchors.left = undefined;
                dockWindow.anchors.right = undefined;
                if (position === "top") { dockWindow.anchors.top = true; dockWindow.anchors.left = true; dockWindow.anchors.right = true; }
                else if (position === "bottom") { dockWindow.anchors.bottom = true; dockWindow.anchors.left = true; dockWindow.anchors.right = true; }
                else if (position === "left") { dockWindow.anchors.left = true; dockWindow.anchors.top = true; dockWindow.anchors.bottom = true; }
                else { dockWindow.anchors.right = true; dockWindow.anchors.top = true; dockWindow.anchors.bottom = true; }
            }
            onPositionChanged: applyPosition()

            // ================================================================
            // IPC (same target as before so qs_manager / Config keep working)
            // ================================================================
            IpcHandler {
                target: "topbar"
                function forceReload() { Quickshell.reload(true) }
                function queueReload() {
                    if (!dockWindow.isSettingsOpen) Quickshell.reload(true)
                    else dockWindow.pendingReload = true
                }
                function reloadColors() { dockColors.forceRefresh() }
                function toggleUpdate() { dockWindow.forceUpdateShow = !dockWindow.forceUpdateShow }
            }

            // ================================================================
            // WIDGET / RECORDING / UPDATE POLLERS
            // ================================================================
            property bool pendingReload: false
            property string activeWidget: ""
            property bool isSettingsOpen: activeWidget === "settings"
            property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
            Behavior on settingsSlideProgress {
                enabled: dockWindow.startupCascadeFinished
                NumberAnimation { duration: 600; easing.type: Easing.OutExpo }
            }
            onIsSettingsOpenChanged: {
                if (!dockWindow.isSettingsOpen && dockWindow.pendingReload) {
                    dockWindow.pendingReload = false;
                    Quickshell.reload(true);
                }
                // Never let the serp bar autohide while the settings panel is
                // open (the popup sits on the same edge the mouse leaves to).
                if (dockWindow.isSettingsOpen) dockWindow.serpAutohideRevealed = true;
            }

            Process {
                id: widgetPoller
                command: ["bash", "-c", "cat " + paths.runDir + "/current_widget 2>/dev/null || echo ''"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (dockWindow.activeWidget !== txt) dockWindow.activeWidget = txt;
                    }
                }
            }
            Process {
                id: widgetWatcher
                command: ["bash", "-c", "while [ ! -f " + paths.runDir + "/current_widget ]; do sleep 1; done; inotifywait -qq -e modify,close_write " + paths.runDir + "/current_widget"]
                running: true
                onExited: {
                    widgetPoller.running = false;
                    widgetPoller.running = true;
                    running = false;
                    running = true;
                }
            }

            Process {
                id: recPoller
                command: ["bash", "-c", "if [ -s " + paths.getCacheDir("recording") + "/rec_pid ] && kill -0 $(cat " + paths.getCacheDir("recording") + "/rec_pid) 2>/dev/null; then echo '1'; else echo '0'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.isRecording = (this.text.trim() === "1");
                    }
                }
            }
            Process {
                id: updatePoller
                command: ["bash", "-c", "if [ -f " + paths.getCacheDir("updater") + "/update_pending ]; then echo '1'; else echo '0'; fi"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.updateAvailable = (this.text.trim() === "1");
                    }
                }
            }
            Process {
                id: settingsReader
                command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text ? this.text.trim() : "";
                        if (txt === "" || txt === "{}") return;
                        // Choke point (Theme.qml pattern): the directory watcher
                        // below wakes on ANY file event under ~/.config/hypr —
                        // identical settings.json content must not re-apply the
                        // config, reset configReady or replay animations.
                        if (txt === dockWindow.lastSettingsJson) return;
                        try {
                            // A live drag owns dockConfig; defer external reads
                            // until the gesture finishes (commit/cancel).
                            if (dockWindow.dragBusy) {
                                dockWindow.pendingDockConfigRefresh = true;
                                return;
                            }
                            let parsed = JSON.parse(txt);
                            dockWindow.lastSettingsJson = txt;
                            let next = DockLayout.getDock(parsed);
                            if (JSON.stringify(next) !== JSON.stringify(dockWindow.dockConfig)) {
                                dockWindow.dockConfig = next;
                            }
                            if (parsed.uiScale !== undefined && dockWindow.uiScale !== parsed.uiScale) {
                                dockWindow.uiScale = parsed.uiScale;
                            }
                            if (parsed.topbarHelpIcon !== undefined && dockWindow.showHelpIcon !== parsed.topbarHelpIcon) {
                                dockWindow.showHelpIcon = parsed.topbarHelpIcon;
                            }
                            if (parsed.workspaceCount !== undefined && dockWindow.workspaceCount !== parsed.workspaceCount) {
                                dockWindow.workspaceCount = parsed.workspaceCount;
                                wsDaemon.running = false;
                                wsDaemon.running = true;
                            }
                            // uiScale + dockConfig are now final: safe to build modules.
                            dockWindow.configReady = true;
                            // Dual engine: parse the engine switch + serpbar AFTER
                            // the dock config so the serp overrides win when the
                            // engine is "serp". serpConfig is only replaced when
                            // its JSON really changed (avoids a re-render loop
                            // with the compare-based dockConfig choke point).
                            let rawEngine = parsed.barEngine === "serp" ? "serp" : "dock";
                            if (dockWindow.barEngine !== rawEngine) dockWindow.barEngine = rawEngine;
                            let serpNext = DockLayout.getSerpbar(parsed);
                            if (JSON.stringify(serpNext) !== JSON.stringify(dockWindow.serpConfig)) {
                                dockWindow.serpConfig = serpNext;
                            }
                            // First boot: barEngine/serpConfig handlers above ran
                            // before configReady was true, so run the visual
                            // sync + SerpBar mount explicitly now.
                            dockWindow.syncVisualEngine();
                        } catch (e) {}
                    }
                }
            }
            // FileView watch (no shell processes, reload-safe): settings.json
            // is written atomically (tmp + mv), and FileView follows the file
            // across renames — unlike an inotify watch on the inode. On any
            // change the cat-based reader re-runs; identical content is choked
            // in the reader (lastSettingsJson) so unrelated edits stay silent.
            FileView {
                id: settingsWatcher
                path: Quickshell.env("HOME") + "/.config/hypr/settings.json"
                watchChanges: true
                onFileChanged: {
                    if (dockWindow.dragBusy) {
                        dockWindow.pendingDockConfigRefresh = true;
                        return;
                    }
                    settingsReader.running = false;
                    settingsReader.running = true;
                }
            }

            // ================================================================
            // SYSTEM STATE
            // ================================================================
            property bool showHelpIcon: true
            property bool isRecording: false
            property bool updateAvailable: false
            property bool forceUpdateShow: false
            property bool isUpdateVisible: updateAvailable || forceUpdateShow
            property int workspaceCount: 8
            // Empty-workspace marker for the Workspaces module
            // (number|dot|letter|custom) + optional custom character.
            property string workspacesMarker: "number"
            property string workspacesMarkerText: "" 

            property bool isDesktop: false
            property string ethStatus: "Ethernet"

            Process {
                id: chassisDetector
                running: true
                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.isDesktop = (this.text.trim() === "desktop");
                    }
                }
            }

            property bool isStartupReady: false
            Timer { interval: 10; running: true; onTriggered: dockWindow.isStartupReady = true }
            property bool startupCascadeFinished: false
            Timer { interval: 1000; running: true; onTriggered: dockWindow.startupCascadeFinished = true }
            property bool fastPollerLoaded: false
            property bool isDataReady: false
            Timer { interval: 600; running: true; onTriggered: dockWindow.isDataReady = true }

            property string timeStr: ""
            property string fullDateStr: ""
            property int typeInIndex: 0
            property string dateStr: fullDateStr.substring(0, typeInIndex)

            property string weatherIcon: ""
            property string weatherTemp: "--°"
            property string weatherHex: colors.yellow

            // --- focused window (FocusModule) -------------------------------------
            property string focusTitle: ""
            property string focusClass: ""
            property string focusIcon: "󰋼"
            readonly property bool hasFocus: dockWindow.focusTitle !== ""

            // Map common WM_CLASS values to Nerd Font glyphs so the focus island
            // shows a recognizable app icon without spawning any extra process.
            function focusIconForClass(cls) {
                const c = String(cls || "").toLowerCase();
                const icons = {
                    "firefox": "󰈹", "librewolf": "󰈹", "zen": "󰈹",
                    "google-chrome": "󰈹", "chromium": "󰈹", "brave": "󰈹",
                    "kitty": "󰄛", "alacritty": "󰄛", "ghostty": "󰄛", "konsole": "󰄛", "wezterm": "󰄛", "xterm": "󰄛",
                    "code": "󰨞", "codium": "󰨞", "code-oss": "󰨞",
                    "spotify": "󰓇", "discord": "󰙯", "vesktop": "󰙯",
                    "nautilus": "󰉋", "dolphin": "󰉋", "thunar": "󰉋", "nemo": "󰉋",
                    "obsidian": "󰠮", "zathura": "󰈇", "org.gnome.nautilus": "󰉋"
                };
                return icons[c] || "󰋼";
            }

            property string cpuPercent: "--"
            property string ramPercent: "--"
            property bool sysDataReady: false

            property string wifiStatus: "Off"
            property string wifiIcon: "󰤮"
            property string wifiSsid: ""
            property string btStatus: "Off"
            property string btIcon: "󰂲"
            property string btDevice: ""
            property string volPercent: "0%"
            property string volIcon: "󰕾"
            property bool isMuted: false
            property string batPercent: "100%"
            property string batIcon: "󰁹"
            property string batStatus: "Unknown"
            property string kbLayout: "us"

            ListModel {
                id: workspacesModel
                property int activeIndex: 0
            }
            readonly property var wsModel: workspacesModel
            function refreshMusic() { musicForceRefresh.running = true; }

            property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }
            property string displayTitle: ""
            property string displayTime: ""
            property string displayArtUrl: ""
            onMusicDataChanged: {
                if (musicData && musicData.status !== "Stopped" && musicData.title !== "") {
                    displayTitle = musicData.title;
                    displayTime = musicData.timeStr;
                    displayArtUrl = musicData.artUrl;
                }
            }

            property bool isMediaActive: dockWindow.musicData.status !== "Stopped" && dockWindow.musicData.title !== ""
            property bool isWifiOn: dockWindow.wifiStatus.toLowerCase() === "enabled" || dockWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn: dockWindow.btStatus.toLowerCase() === "enabled" || dockWindow.btStatus.toLowerCase() === "on"
            property bool showEthernet: dockWindow.ethStatus === "Connected" || (dockWindow.isDesktop && !dockWindow.isWifiOn)
            property bool isSoundActive: !dockWindow.isMuted && parseInt(dockWindow.volPercent) > 0
            property int batCap: parseInt(dockWindow.batPercent) || 0
            property bool isCharging: dockWindow.batStatus === "Charging" || dockWindow.batStatus === "Full"
            property color batDynamicColor: {
                if (isCharging) return colors.green;
                if (batCap <= 20) return colors.red;
                return colors.text;
            }

            // ================================================================
            // WORKSPACES
            // ================================================================
            Process {
                id: wsDaemon
                command: ["bash", "-c", "~/.config/hypr/scripts/workspaces.sh"]
                running: true
            }
            Process {
                id: wsReader
                running: true
                command: ["cat", paths.getRunDir("workspaces") + "/workspaces.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let newData = JSON.parse(txt);
                                while (workspacesModel.count < newData.length) {
                                    workspacesModel.append({ "wsId": "", "wsState": "", "wsClasses": "" });
                                }
                                while (workspacesModel.count > newData.length) {
                                    workspacesModel.remove(workspacesModel.count - 1);
                                }
                                let newActive = -1;
                                for (let i = 0; i < newData.length; i++) {
                                    if (newData[i].state === "active") newActive = i;
                                    if (workspacesModel.get(i).wsState !== newData[i].state) {
                                        workspacesModel.setProperty(i, "wsState", newData[i].state);
                                    }
                                    if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                        workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                    }
                                    if (newData[i].classes != undefined && workspacesModel.get(i).wsClasses !== newData[i].classes) {
                                        workspacesModel.setProperty(i, "wsClasses", newData[i].classes);
                                    }
                                }
                                if (newActive !== -1 && workspacesModel.activeIndex !== newActive) {
                                    workspacesModel.activeIndex = newActive;
                                }
                            } catch(e) {}
                        }
                    }
                }
            }
            // FileView watch on the workspaces JSON (process-free, follows
            // atomic rewrites). Reload-safe: no shell children to orphan.
            FileView {
                id: wsWatcher
                path: dockWindow.paths.getRunDir("workspaces") + "/workspaces.json"
                watchChanges: true
                onFileChanged: {
                    wsReader.running = false;
                    wsReader.running = true;
                }
            }
            Process {
                id: musicForceRefresh
                running: true
                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee " + paths.getRunDir("music") + "/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { dockWindow.musicData = JSON.parse(txt); } catch(e) {}
                        }
                    }
                }
            }
            Timer {
                interval: 1000
                running: dockWindow.musicData !== null && dockWindow.musicData.status === "Playing"
                repeat: true
                onTriggered: {
                    if (!dockWindow.musicData || dockWindow.musicData.status !== "Playing") return;
                    if (!dockWindow.musicData.timeStr || dockWindow.musicData.timeStr === "") return;
                    let parts = dockWindow.musicData.timeStr.split(" / ");
                    if (parts.length !== 2) return;
                    let posParts = parts[0].split(":").map(Number);
                    let lenParts = parts[1].split(":").map(Number);
                    let posSecs = (posParts.length === 3)
                        ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2])
                        : (posParts[0] * 60 + posParts[1]);
                    let lenSecs = (lenParts.length === 3)
                        ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2])
                        : (lenParts[0] * 60 + lenParts[1]);
                    if (isNaN(posSecs) || isNaN(lenSecs)) return;
                    posSecs++;
                    if (posSecs > lenSecs) posSecs = lenSecs;
                    let newPosStr = "";
                    if (posParts.length === 3) {
                        let h = Math.floor(posSecs / 3600);
                        let m = Math.floor((posSecs % 3600) / 60);
                        let s = posSecs % 60;
                        newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    } else {
                        let m = Math.floor(posSecs / 60);
                        let s = posSecs % 60;
                        newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    }
                    let newData = Object.assign({}, dockWindow.musicData);
                    newData.timeStr = newPosStr + " / " + parts[1];
                    newData.positionStr = newPosStr;
                    if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
                    dockWindow.musicData = newData;
                }
            }
            Process {
                id: kbPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "" && dockWindow.kbLayout !== txt) dockWindow.kbLayout = txt;
                        dockWindow.fastPollerLoaded = true;
                    }
                }
            }


            Process {
                id: audioPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newVol = data.volume.toString() + "%";
                                if (dockWindow.volPercent !== newVol) dockWindow.volPercent = newVol;
                                if (dockWindow.volIcon !== data.icon) dockWindow.volIcon = data.icon;
                                let newMuted = (data.is_muted === "true");
                                if (dockWindow.isMuted !== newMuted) dockWindow.isMuted = newMuted;
                            } catch(e) {}
                        }
                    }
                }
            }


            Process {
                id: networkPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (dockWindow.wifiStatus !== data.status) dockWindow.wifiStatus = data.status;
                                if (dockWindow.wifiIcon !== data.icon) dockWindow.wifiIcon = data.icon;
                                if (dockWindow.wifiSsid !== data.ssid) dockWindow.wifiSsid = data.ssid;
                                if (dockWindow.ethStatus !== data.eth_status) dockWindow.ethStatus = data.eth_status;
                            } catch(e) {}
                        }
                    }
                }
            }


            Process {
                id: btPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (dockWindow.btStatus !== data.status) dockWindow.btStatus = data.status;
                                if (dockWindow.btIcon !== data.icon) dockWindow.btIcon = data.icon;
                                if (dockWindow.btDevice !== data.connected) dockWindow.btDevice = data.connected;
                            } catch(e) {}
                        }
                    }
                }
            }


            Process {
                id: batteryPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newBat = data.percent.toString() + "%";
                                if (dockWindow.batPercent !== newBat) dockWindow.batPercent = newBat;
                                if (dockWindow.batIcon !== data.icon) dockWindow.batIcon = data.icon;
                                if (dockWindow.batStatus !== data.status) dockWindow.batStatus = data.status;
                            } catch(e) {}
                        }
                    }
                }
            }



            // ================================================================
            // POLLING TIMERS (process-free refresh)
            // ================================================================
            // The old fetch+wait/process watchers leaked long-running children
            // across in-process reloads (orphans exhausted inotify/process
            // limits). Polling Timers keep the same data fresh with zero
            // long-running processes.
            Timer { id: kbPollTimer; interval: 2000; running: true; repeat: true; onTriggered: { kbPoller.running = false; kbPoller.running = true; } }
            Timer { id: audioPollTimer; interval: 2000; running: true; repeat: true; onTriggered: { audioPoller.running = false; audioPoller.running = true; } }
            Timer { id: netPollTimer; interval: 3000; running: true; repeat: true; onTriggered: { networkPoller.running = false; networkPoller.running = true; } }
            Timer { id: btPollTimer; interval: 4000; running: true; repeat: true; onTriggered: { btPoller.running = false; btPoller.running = true; } }
            Timer { id: batPollTimer; interval: 3000; running: true; repeat: true; onTriggered: { batteryPoller.running = false; batteryPoller.running = true; } }
            Timer { id: recPollTimer; interval: 2500; running: true; repeat: true; onTriggered: { recPoller.running = false; recPoller.running = true; } }
            Timer { id: updatePollTimer; interval: 4000; running: true; repeat: true; onTriggered: { updatePoller.running = false; updatePoller.running = true; } }
            Timer { id: musicPollTimer; interval: 3000; running: true; repeat: true; onTriggered: { musicForceRefresh.running = false; musicForceRefresh.running = true; } }
            Timer { id: wsPollTimer; interval: 1500; running: true; repeat: true; onTriggered: { wsReader.running = false; wsReader.running = true; } }

            // ================================================================
            // WEATHER
            // ================================================================
            Process {
                id: weatherPoller
                command: ["bash", "-c", `
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
                `]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n");
                        if (lines.length >= 3) {
                            dockWindow.weatherIcon = lines[0];
                            dockWindow.weatherTemp = lines[1];
                            dockWindow.weatherHex = lines[2] || colors.yellow;
                        }
                    }
                }
            }
            Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }

            // ================================================================
            // FOCUSED WINDOW (FocusModule)
            // ================================================================
            Process {
                id: focusPoller
                command: ["bash", "-c",
                    "hyprctl activewindow -j 2>/dev/null | jq -r 'if (.class != null and .class != \"\" and .address != null and .address != \"\") then (.class + \"\\n\" + .title) else empty end' 2>/dev/null"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let line = this.text.trim();
                        if (line === "") {
                            if (dockWindow.focusTitle !== "") dockWindow.focusTitle = "";
                            if (dockWindow.focusClass !== "") dockWindow.focusClass = "";
                            if (dockWindow.focusIcon !== "󰋼") dockWindow.focusIcon = "󰋼";
                            return;
                        }
                        let nl = line.indexOf("\n");
                        let cls = nl !== -1 ? line.substring(0, nl) : line;
                        let title = nl !== -1 ? line.substring(nl + 1).trim() : "";
                        if (title === "") title = cls;
                        if (dockWindow.focusClass !== cls) {
                            dockWindow.focusClass = cls;
                            dockWindow.focusIcon = dockWindow.focusIconForClass(cls);
                        }
                        if (dockWindow.focusTitle !== title) dockWindow.focusTitle = title;
                    }
                }
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: { focusPoller.running = false; focusPoller.running = true; }
            }

            // ================================================================
            // SYSTEM MONITOR
            // ================================================================
            Process {
                id: sysmonPoller; running: true
                command: ["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/system-monitor/fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0) {
                                let d = JSON.parse(this.text.trim());
                                dockWindow.cpuPercent = (d.cpu || 0) + "%";
                                dockWindow.ramPercent = (d.ram_pct || 0) + "%";
                                dockWindow.sysDataReady = true;
                            }
                        } catch(e) {}
                    }
                }
            }
            Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: false; onTriggered: { sysmonPoller.running = false; sysmonPoller.running = true; } }

            // ================================================================
            // CLOCK + TYPEWRITER DATE
            // ================================================================
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    let fmt = dockWindow.serpMode && dockWindow.serpTimeFormat !== "" ? dockWindow.serpTimeFormat : "HH:mm:ss";
                    dockWindow.timeStr = Qt.formatDateTime(d, fmt);
                    dockWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    if (dockWindow.typeInIndex >= dockWindow.fullDateStr.length) {
                        dockWindow.typeInIndex = dockWindow.fullDateStr.length;
                    }
                }
            }
            Timer {
                id: typewriterTimer
                interval: 40
                running: dockWindow.isStartupReady && dockWindow.typeInIndex < dockWindow.fullDateStr.length
                repeat: true
                onTriggered: dockWindow.typeInIndex += 1
            }

            // ================================================================
            // ZONES
            // ================================================================

            // Bar background strip (dock.barBg): a solid/translucent band behind
            // the whole bar with only the inner corners rounded, so the islands
            // float INSIDE it like a taskbar. Pill backgrounds then go transparent
            // (see ModulePill) and the accent islands stay as colored pills.
            // Hidden while the serp engine renders (SerpBar draws its own strip).
            Rectangle {
                id: barBackground
                anchors.fill: parent
                visible: dockWindow.barBg && !dockWindow.serpMode
                radius: dockWindow.pillRadius(dockWindow.pillHeight)
                topLeftRadius: orientation === "vertical" ? 0 : (position === "top" ? 0 : radius)
                topRightRadius: orientation === "vertical" ? 0 : (position === "top" ? 0 : radius)
                bottomLeftRadius: orientation === "vertical" ? 0 : (position === "bottom" ? 0 : radius)
                bottomRightRadius: orientation === "vertical" ? 0 : (position === "bottom" ? 0 : radius)
                // vertical: flat on the screen-edge side
                color: Qt.rgba(dockColors.base.r, dockColors.base.g, dockColors.base.b, dockWindow.pillSolid ? 1.0 : dockWindow.barOpacity)
                border.width: dockWindow.borderWidth
                border.color: dockColors[borderColor] || dockColors.surface1
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Item {
                id: barContent
                anchors.fill: parent

                // Settings panel occupies an edge while open; shift the dock
                // content so nothing sits underneath it.
                anchors.leftMargin: settingsSlideProgress * (dockWindow.panelFromLeft ? s(780) : 0)
                anchors.rightMargin: settingsSlideProgress * (dockWindow.panelFromLeft ? 0 : s(780))

                // Zones only build once uiScale/baseScale are final (bar.s() is a
                // function, so modules can't reactively rescale after creation).
                visible: dockWindow.configReady
                Repeater {
                    // Engine gate: the zone engine only mounts in dock mode. The
                    // empty model destroys every Zone + module Loader while the
                    // serp engine renders (same in-process remount idea as the
                    // axis flip); flipping back recreates them against the still
                    // synced dockConfig.
                    model: dockWindow.serpMode ? [] : dockWindow.zones
                    delegate: Zone {
                        required property var modelData
                        required property int index
                        bar: dockWindow
                        colors: dockWindow.colors
                        zoneData: modelData
                        zoneIndex: index
                    }
                }

                // Classic left/center/right engine (Phase D4-E1b). Mounted only
                // in serp mode; the loaded SerpBar is recreated on engine/axis
                // changes through syncSerpLoader().
                Loader {
                    id: serpLoader
                    anchors.fill: parent
                    // Initial properties for the SerpBar root (required props);
                    // serpConfig is bound live so settings hot-reloads reach the
                    // loaded bar without remounting it.
                    function serpInitialProps() {
                        return {
                            "bar": dockWindow,
                            "colors": dockWindow.colors,
                            "serpConfig": Qt.binding(() => dockWindow.serpConfig)
                        };
                    }
                }
            }
        }
    }
}
