import QtQuick
import Quickshell
import "DockLayout.js" as DockLayout

// ============================================================================
// SerpBar — the classic left/center/right bar engine (Phase D4-E1b + R1).
//
// Renders the "serpantinum-style" bar on top of the EXISTING dock host
// (dock/Dock.qml): modules are the same topbar/modules/*.qml islands, the
// contract injected per slot is the standard one (bar, colors, zoneReady,
// slotIndex, effectiveBorderWidth/Color, unified) and all data comes from the
// bar object. The host owns everything else (palette, pollers, IPC, settings);
// this file only renders:
//
//   • the strip band      — widthPercent geometry (modular draws no strip),
//   • three sections      — left/center/right along the main axis, each a
//                            Row (horizontal dock) or Column (vertical dock) of
//                            loose modules AND/OR unified "groups",
//   • autohide            — edge tab + slide-out + hover state machine.
//
// Visual flags for the current style (pillBg/pillSolid/barBg/edgeGap,
// thickness/opacity) are applied by the HOST via applySerpVisuals() — SerpBar
// never touches settings and never writes the "dock" key.
//
// ── Phase R1: serpantium visual-parity map (values + upstream citations) ─────
// The classic engine's geometry mirrors serpantium's Bar.qml/TopBar.qml with
// our own scaler/role vocabulary (bar.s(), colors.*):
//
//   band cross size  = bar.barHeight/bar.barWidth of the HOST window, i.e.
//                      s(serpbar.thickness ?? dock.thickness) — serpantium's
//                      fixed barHeight s(40) (Bar.qml:244).
//   edge breathing   = host margins: s(4) off the screen edge in every
//                      non-fill state, 0 in fill (Bar.qml:265-270), applied
//                      by the host (edgeGap override + fill margin rules).
//   strip radius     = solid: bar.s(8)*roundness — serpantium's strip uses
//                      the theme borderRadius (8 raw, ThemeBackend.qml:10);
//                      fill: bar.s(12)*roundness on the far-side corners with
//                      the screen-edge side flat (Bar.qml:245 cornerRadius
//                      s(12) + the fill corner canvases, TopBar.qml:513-615).
//   unit chrome      = groups and, with distinctPills on a flat strip, loose
//                      modules get a subtle raised segment. Serpantium paints
//                      groupBg over the FULL bar height (TopBar.qml:617-679,
//                      height barHeight, y centered) in modular (base tone)
//                      and hides it on plain solid/fill (visible only when
//                      distinctPills, TopBar.qml:655) — same rule here. The
//                      s(3) cross inset of the distinct slabs equals
//                      serpantium's barHeight-6 pills (TopBar.qml:629).
//   group members    = unified:true pills with 0 spacing; every island is
//                      centered on its own band lane (serpantium positions
//                      every widget through getModuleY, TopBar.qml:450-459).
//   item spacing     = s(2) on the strip / s(8) in modular (serpantium uses
//                      a flat s(2) gap, TopBar.qml:237; modular keeps the
//                      dock's island air — deliberate difference).
//   hide sliver      = s(4), the clickable edge tab (Bar.qml:275-276
//                      activeMaskHeight s(4) while hidden).
//
// Distinct pills semantics (serpantium Bar.qml:93-96 + TopBar module
// plumbing): a per-unit background that only makes sense ON a flat strip —
// serpbar.distinctPills renders loose modules and groups as individually
// visible slabs there; in modular it does nothing (islands carry their own
// fill). Tones are the hyprland raised-on-strip role (colors.surface1 at
// 0.55) instead of serpantium's Qt.darker(surface0,1.15) — our palette
// equivalent of "slightly lighter than the strip".
// ============================================================================

Item {
    id: serpRoot

    required property var bar
    required property var colors
    required property var serpConfig

    // The host's Loader fills the content frame (anchors.fill); this root MUST
    // follow it or every child collapses to 0x0 and the classic bar vanishes.
    anchors.fill: parent

    // The strip band box. The host's clickthrough mask (dockWindow.mask)
    // tracks this item, so only the visible strip + contents are interactive;
    // outside the band (widthPercent < 100) clicks pass through to windows.
    property alias serpContentArea: contentWrap

    // Cross extent of the band = the frame's cross dimension (both serpRoot
    // and contentWrap span the whole host content frame, see below).
    readonly property real bandCross: vertical ? width : height

    // --- engine-derived helpers ----------------------------------------------
    readonly property bool vertical: bar.orientation === "vertical"
    readonly property string style: String(serpConfig.style || "modular")
    readonly property bool fillStyle: DockLayout.isFillStyle(style)
    readonly property bool stripShown: style !== "modular" && bar.barBg === true
    readonly property bool distinctPills: serpConfig.distinctPills === true
    readonly property bool autohideOn: serpConfig.autohide === true
    readonly property int pad: bar.s(6)
    // serpantium spacing: s(2) between adjacent units on the strip
    // (TopBar.qml:237 gap s(2)); modular keeps the dock island air (s(8),
    // deliberate difference — see the header map).
    readonly property int itemGap: stripShown ? bar.s(2) : bar.s(8)
    // Themed corner radii. Serpantium derives them from its theme
    // (ThemeBackend.borderRadius = 8 raw) and the fixed window cornerRadius
    // s(12) (Bar.qml:245); our equivalent scales the shared roundness knob:
    readonly property real effRoundness: typeof bar.roundness === "number" ? bar.roundness : 1
    // Radius of the solid strip + every unit slab (groups, distinct pills).
    readonly property int rectRadius: Math.max(0, Math.round(bar.s(8) * effRoundness))
    // Radius of the fill strip's far-side corners (edge side stays flat).
    readonly property int fillCornerRadius: Math.max(0, Math.round(bar.s(12) * effRoundness))
    readonly property int stripRadius: fillStyle ? fillCornerRadius : rectRadius
    // The bar is flush against its screen edge (fill always, autohide keeps a
    // flush s(4) reveal sliver): the edge-side corners then go flat.
    readonly property bool edgeFlush: bar.serpEdgeFlush === true
    // Cross-axis inset of the distinct unit slabs: serpantium shrinks each
    // pill to barHeight-6 (TopBar.qml:629), i.e. s(3) per side.
    readonly property int unitInset: bar.s(3)

    // --- strip band geometry (serpRoot == the host content frame) ------------
    // widthPercent only constrains the MAIN axis (length) of the band; fill
    // forces 100% (isFillStyle). The band spans the full frame cross extent,
    // i.e. the strip thickness is bar.barHeight on horizontal docks and
    // bar.barWidth on vertical docks — both equal to the host content cross
    // size; the host margins already applied the edgeGap/edge-flush rules
    // before this component lays out.
    readonly property real stripLen: Math.max(0, Math.round((vertical ? height : width)
        * (fillStyle ? 1.0 : (Math.min(100, Math.max(40, serpConfig.widthPercent || 100)) / 100.0))))
    readonly property real stripStart: Math.max(0, Math.round(((vertical ? height : width) - stripLen) / 2))

    // --- autohide -------------------------------------------------------------
    // Reveal state lives on the bar (the host's exclusiveZone binding reads
    // bar.serpAutohideRevealed), so this file only writes it. Hiding slides
    // the band out of the window along the cross axis, leaving exactly
    // bar.s(4) inside — the tab sliver, flush at the screen edge (the host
    // zeroes the edge margin while autohide is on; serpantium keeps an s(4)
    // clickable sliver at the edge too — Bar.qml:275-276). Modular has no
    // strip, but the same magnitude still clears every island (they are
    // centered and never reach the last s(4) of the frame; only fullHeight
    // islands leave a sliver, which doubles as a visible tab).
    readonly property bool revealed: !autohideOn || bar.serpAutohideRevealed !== false
    readonly property real hideShift: {
        if (revealed) return 0;
        let m = Math.max(0, (vertical ? width : height) - bar.s(4));
        if (vertical) return bar.position === "left" ? -m : m;
        return bar.position === "top" ? -m : m;
    }

    // ========================================================================
    // CONTENT BAND
    // ========================================================================
    Item {
        id: contentWrap
        x: serpRoot.vertical ? serpRoot.hideShift : serpRoot.stripStart
        y: serpRoot.vertical ? serpRoot.stripStart : serpRoot.hideShift
        width: serpRoot.vertical ? serpRoot.width : serpRoot.stripLen
        height: serpRoot.vertical ? serpRoot.stripLen : serpRoot.height
        // Sections anchor by their own edges: when the combined content is
        // wider than the band the side sections simply overlap and the strip
        // clip cuts the overflow (documented behaviour, same as the dock
        // engine's fixed-position zones).
        clip: serpRoot.stripShown

        Behavior on x { enabled: serpRoot.autohideOn; NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on y { enabled: serpRoot.autohideOn; NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        // --- strip rectangle (solid/fill styles) -----------------------------
        // Base color at the bar opacity (bar.barOpacity = serpbar.opacity/100,
        // applied by the host). Corner rules (serpantium parity):
        //   • solid: rectRadius all around (the strip floats s(4) off the
        //     screen edge, so every corner is rounded);
        //   • fill: the screen-edge side stays flat, the far-side corners use
        //     fillCornerRadius (serpantium paints those with corner canvases,
        //     TopBar.qml:513-615);
        //   • autohide: the strip is flush while revealed, so its edge-side
        //     corners are flat too (same rule as fill).
        Rectangle {
            anchors.fill: parent
            visible: serpRoot.stripShown
            radius: serpRoot.stripRadius
            topLeftRadius: serpRoot.vertical
                ? ((bar.position === "left" && serpRoot.edgeFlush) ? 0 : radius)
                : ((bar.position === "top" && serpRoot.edgeFlush) ? 0 : radius)
            topRightRadius: serpRoot.vertical
                ? ((bar.position === "right" && serpRoot.edgeFlush) ? 0 : radius)
                : ((bar.position === "top" && serpRoot.edgeFlush) ? 0 : radius)
            bottomLeftRadius: serpRoot.vertical
                ? ((bar.position === "left" && serpRoot.edgeFlush) ? 0 : radius)
                : ((bar.position === "bottom" && serpRoot.edgeFlush) ? 0 : radius)
            bottomRightRadius: serpRoot.vertical
                ? ((bar.position === "right" && serpRoot.edgeFlush) ? 0 : radius)
                : ((bar.position === "bottom" && serpRoot.edgeFlush) ? 0 : radius)
            color: Qt.rgba(colors.base.r, colors.base.g, colors.base.b, bar.barOpacity)
            border.width: bar.borderWidth
            border.color: colors[bar.borderColor] || colors.surface1
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // ====================================================================
        // SECTIONS (left → start edge, center → middle, right → end edge)
        // ====================================================================
        // Slot lists are recomputed when the settings reader replaces the
        // serpConfig object (the section flow models re-evaluate → fresh
        // module Loaders → entrance cascade replays, exactly like a dock
        // config edit).
        property var leftSlots: serpRoot.buildSlots(serpConfig.modules.left)
        property var centerSlots: serpRoot.buildSlots(serpConfig.modules.center)
        property var rightSlots: serpRoot.buildSlots(serpConfig.modules.right)

        // --- LEFT (top) section ----------------------------------------------
        Row {
            visible: !serpRoot.vertical
            x: serpRoot.pad
            y: Math.round((parent.height - height) / 2)
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? [] : contentWrap.leftSlots; delegate: slotDelegate }
        }
        Column {
            visible: serpRoot.vertical
            x: Math.round((parent.width - width) / 2)
            y: serpRoot.pad
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? contentWrap.leftSlots : []; delegate: slotDelegate }
        }

        // --- CENTER section ---------------------------------------------------
        Row {
            visible: !serpRoot.vertical
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? [] : contentWrap.centerSlots; delegate: slotDelegate }
        }
        Column {
            visible: serpRoot.vertical
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? contentWrap.centerSlots : []; delegate: slotDelegate }
        }

        // --- RIGHT (bottom) section -------------------------------------------
        Row {
            visible: !serpRoot.vertical
            x: parent.width - width - serpRoot.pad
            y: Math.round((parent.height - height) / 2)
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? [] : contentWrap.rightSlots; delegate: slotDelegate }
        }
        Column {
            visible: serpRoot.vertical
            x: Math.round((parent.width - width) / 2)
            y: parent.height - height - serpRoot.pad
            spacing: serpRoot.itemGap
            Repeater { model: serpRoot.vertical ? contentWrap.rightSlots : []; delegate: slotDelegate }
        }

        // ====================================================================
        // SLOT DELEGATE — one entry of a section list.
        //
        // Loose entry (modelData.isGroup === false): a single module island.
        // Group entry (modelData.isGroup === true): one chrome rectangle
        // (the "group pill") hosting one module per id with unified:true and
        // 0 spacing. Slot lanes span the FULL band cross extent and every
        // island is centered on its own lane, exactly like serpantium
        // positions widgets individually (TopBar.qml getModuleY) — a row of
        // mixed-height islands never top-aligns.
        //
        // Unit chrome (see the header parity map): group slabs are painted
        // in modular (colors.surface0 — the dock unified tone) and on a flat
        // strip only when serpbar.distinctPills is on (raised segment,
        // colors.surface1 @ 0.55, inset s(3) per cross side). Loose modules
        // only get chrome on the strip with distinctPills — in modular they
        // render their own island fill through ModulePill.
        // ====================================================================
        Component {
            id: slotDelegate
            Item {
                id: slotWrap
                required property var modelData
                required property int index

                readonly property bool groupSlot: !!modelData && modelData.isGroup === true
                readonly property bool horizontal: !serpRoot.vertical
                // Cross extent of the band (strip thickness / width).
                readonly property real bandCross: serpRoot.bandCross
                // Group chrome visibility mirrors TopBar.qml:655
                // (!isSolid || distinctPills): hidden on a plain flat strip.
                readonly property bool groupChromeVisible: groupSlot && (!serpRoot.stripShown || serpRoot.distinctPills)

                // Per-member data: module id, stagger index, unified flag.
                readonly property var memberModel: {
                    if (!modelData) return [];
                    if (groupSlot) {
                        let out = [];
                        let ids = modelData.ids;
                        for (let i = 0; i < ids.length; i++) out.push({ id: ids[i], ix: i, unified: true });
                        return out;
                    }
                    return [{ id: modelData.id, ix: index, unified: false }];
                }

                readonly property real memberW: horizontal ? memberFlowH.implicitWidth : memberFlowV.implicitHeight
                readonly property real memberH: horizontal ? memberFlowH.implicitHeight : memberFlowV.implicitWidth

                // Main axis: the member union (groups hug their members, no
                // extra breathing — TopBar's groupBg metrics are the exact
                // member bounds, TopBar.qml:625-647). Cross axis: the full
                // band, so chrome slabs can span it and every module centers.
                width: horizontal ? memberW : bandCross
                height: horizontal ? bandCross : memberH

                // Unit chrome (behind the members, see the header map).
                Rectangle {
                    id: unitChrome
                    visible: slotWrap.groupSlot
                        ? (slotWrap.groupChromeVisible)
                        : (serpRoot.stripShown && serpRoot.distinctPills)
                    // Group slabs in modular use the dock unified tone; every
                    // flat-strip slab (group + loose distinct pills) uses the
                    // raised-on-strip tone.
                    color: (slotWrap.groupSlot && !serpRoot.stripShown)
                        ? colors.surface0
                        : Qt.rgba(colors.surface1.r, colors.surface1.g, colors.surface1.b, 0.55)
                    radius: serpRoot.rectRadius
                    x: (serpRoot.vertical && serpRoot.stripShown) ? serpRoot.unitInset : 0
                    y: (!serpRoot.vertical && serpRoot.stripShown) ? serpRoot.unitInset : 0
                    width: slotWrap.width - ((serpRoot.vertical && serpRoot.stripShown) ? serpRoot.unitInset * 2 : 0)
                    height: slotWrap.height - ((!serpRoot.vertical && serpRoot.stripShown) ? serpRoot.unitInset * 2 : 0)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Member lanes: one wrapper per island spanning the full band
                // cross, each centering its own module (see the header map).
                Row {
                    id: memberFlowH
                    visible: slotWrap.horizontal
                    spacing: 0
                    Repeater {
                        model: slotWrap.horizontal ? slotWrap.memberModel : []
                        delegate: memberDelegate
                    }
                }
                Column {
                    id: memberFlowV
                    visible: !slotWrap.horizontal
                    spacing: 0
                    Repeater {
                        model: slotWrap.horizontal ? [] : slotWrap.memberModel
                        delegate: memberDelegate
                    }
                }
            }
        }

        // One island inside a slot (loose module or group member). Same
        // creation pattern as Zone.qml's module loader: module components live
        // one directory up (topbar/modules/*.qml) and the standard contract is
        // injected as initial properties. zoneReady: true + the per-member
        // slotIndex replay the dock's entrance cascade.
        Component {
            id: memberDelegate
            Item {
                id: memberWrap
                required property var modelData

                readonly property bool horizontal: !serpRoot.vertical
                // Lane cross extent = the full band (see the slotDelegate
                // comment): every island centers on its own lane.
                width: horizontal ? memberLoader.width : serpRoot.bandCross
                height: horizontal ? serpRoot.bandCross : memberLoader.height
                // Lanes must advertise their size through implicitWidth/
                // implicitHeight: the parent flow Row/Column measures the
                // slot's memberW/memberH from the lanes' IMPLICIT extents
                // (positioners never use plain width for their own implicit
                // size), so a lane without them would collapse the slot.
                implicitWidth: width
                implicitHeight: height

                Loader {
                    id: memberLoader
                    x: horizontal ? 0 : Math.round((parent.width - width) / 2)
                    y: horizontal ? Math.round((parent.height - height) / 2) : 0
                    width: item ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : 0
                    Component.onCompleted: {
                        let mod = DockLayout.getModule(modelData.id);
                        if (!mod) return;
                        setSource(Qt.resolvedUrl("../" + mod.component), {
                            "bar": serpRoot.bar,
                            "colors": serpRoot.colors,
                            "zoneReady": true,
                            "slotIndex": modelData.ix,
                            "effectiveBorderWidth": 0,
                            "effectiveBorderColor": "surface1",
                            "unified": modelData.unified
                        });
                    }
                }
            }
        }
    }

    // ========================================================================
    // AUTOHIDE (edge tab + hover state machine)
    // ========================================================================
    // The invisible tab band sits at the very screen edge (the host zeroes the
    // edge margin while autohide is on). Hover detection uses HoverHandler on
    // the FRAME and on the TAB: HoverHandler is non-exclusive and never steals
    // hover/clicks from the module MouseAreas, so hovering a pill counts as
    // "inside" and only leaving the whole frame arms the hide timer. While
    // hidden only the tab can reveal — hovering the s(4) sliver (or the empty
    // edge for modular) — which also prevents an hide/reveal oscillation when
    // the cursor rests on the leftover sliver.
    Item {
        id: tabHit
        z: 5
        property int tabThickness: bar.s(4)
        x: serpRoot.vertical && bar.position === "right" ? serpRoot.width - tabThickness : 0
        y: !serpRoot.vertical && bar.position === "bottom" ? serpRoot.height - tabThickness : 0
        width: serpRoot.vertical ? tabThickness : serpRoot.width
        height: serpRoot.vertical ? serpRoot.height : tabThickness
    }
    HoverHandler {
        id: frameHover
        acceptedDevices: PointerDevice.Mouse
        onHoveredChanged: serpRoot.pollAutohide()
    }
    HoverHandler {
        id: tabHover
        acceptedDevices: PointerDevice.Mouse
        target: tabHit
        onHoveredChanged: serpRoot.pollAutohide()
    }
    Timer {
        id: hideTimer
        interval: serpConfig.autohideTimeout
        onTriggered: {
            if (serpRoot.autohideOn) bar.serpAutohideRevealed = false;
        }
    }
    function pollAutohide() {
        if (!autohideOn) return;
        if (bar.serpAutohideRevealed !== false) {
            // Revealed: anything inside the frame (or on the tab) keeps the
            // bar out; leaving it arms the hide timer.
            if (frameHover.hovered || tabHover.hovered) hideTimer.stop();
            else hideTimer.start();
        } else if (tabHover.hovered) {
            // Hidden: only the edge tab reveals (see comment above).
            hideTimer.stop();
            bar.serpAutohideRevealed = true;
        }
    }
    // Enabling autohide on a live config must never start hidden; arm the
    // timer right away when the cursor is already outside. Same after the
    // HOST re-reveals the bar (engine/config edits): if the cursor is not on
    // the bar, re-arm the hide timer instead of staying open forever.
    onAutohideOnChanged: {
        if (!autohideOn) return;
        bar.serpAutohideRevealed = true;
        Qt.callLater(() => serpRoot.pollAutohide());
    }
    onRevealedChanged: {
        if (serpRoot.revealed && serpRoot.autohideOn) Qt.callLater(() => serpRoot.pollAutohide());
    }
    // Boot with autohide already enabled: start hidden when the cursor is not
    // on the bar (pollAutohide() arms the timer if nothing is hovered).
    Component.onCompleted: {
        if (serpRoot.autohideOn) Qt.callLater(() => serpRoot.pollAutohide());
    }

    // ========================================================================
    // SLOT MODEL BUILDING
    // ========================================================================
    // Flattens one serpbar section list into renderable slots: strings expand
    // through DockLayout.serpTokenModules() (a token becomes several LOOSE
    // modules), arrays become group slots. A replaced serpConfig re-runs the
    // flow models above (reading the top-level var registers the dependency).
    function buildSlots(list) {
        let out = [];
        if (!list || typeof list.length !== "number") return out;
        for (let i = 0; i < list.length; i++) {
            let entry = list[i];
            if (typeof entry === "string") {
                let expanded = DockLayout.serpTokenModules(entry);
                for (let k = 0; k < expanded.length; k++) out.push({ isGroup: false, id: expanded[k] });
            } else if (entry !== null && typeof entry === "object" && typeof entry.length === "number") {
                out.push({ isGroup: true, ids: entry });
            }
        }
        return out;
    }
}
