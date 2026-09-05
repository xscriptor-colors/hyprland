// ============================================================================
// WidgetRedactor — full-screen desktop-widget editor (Phase W5).
// Registered in WindowRegistry.js as "widgets-redactor" (w: mw, h: mh, rx: 0,
// ry: 0): the popup covers the whole monitor, so local coordinates equal the
// screen coordinates that WidgetLoader persists in layout.json.
// The editor lives INSIDE the main quickshell process (Main.qml's StackView),
// i.e. in the same process that owns the real WidgetLoader/Widget windows of
// the target screen. Opening the redactor calls
// WidgetSync.setRedactMode(targetScreen, true) — the loader hides the real
// widget windows and flushes its debounced persistence when redaction ends,
// so there is no save button; every edit is applied live through WidgetSync.
// Each widget is rendered as a "proxy": a chrome box hosting the REAL face
// (WidgetRegistry.faceFile) so the preview is faithful and the face's
// declared constraints (minWidth/.../minAspect/maxAspect) drive the same
// clamp that widgets/Widget.qml updateEffectiveSize() applies to the real
// window. Faces that declare `windowShown` get it bound to false so no Cava
// consumer or media gating is started while the real windows are hidden.
// Toolbar (floating, top): add type, variant cycle, rotate 90°, stretch
// width, duplicate, opacity, image picker (image widgets), delete, clear all.
// ESC (or the qs_manager close convention) exits and restores the windows.
// ============================================================================

import ".."
import "../WindowRegistry.js" as LayoutMath
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Optional props injected by Main.qml when the popup is opened.
    property int layoutWidth: 0
    property int layoutHeight: 0
    property real uiScale: 1
    // --- target screen (the screen this popup window lives on) ------------------
    property string targetScreen: ""
    property string safeTarget: ""
    property int sw: 1920
    property int sh: 1080
    readonly property real baseScale: LayoutMath.getScale(root.sw, root.sh, root.uiScale)
    property string selectedId: ""
    property bool applying: false
    property var gesture: null
    property var guidesX: []
    property var guidesY: []
    property int gridStep: 20
    // ---------------------------------------------------------------------------
    // Face constraints (probe-cached): the clamp must agree with the real Widget
    // window, which reads the constraints of its loaded face. A single hidden
    // probe loader instantiates each (type, variant) face once per session and
    // caches the declared numbers; faces are only instantiated while hidden, so
    // they never register Cava consumers.
    // ---------------------------------------------------------------------------
    property var constraintCache: ({})
    property string probeType: ""
    property string probeVariant: ""
    property bool clearArmed: false
    // ---------------------------------------------------------------------------
    // Toolbar state: enables/disables the selection-dependent controls.
    // ---------------------------------------------------------------------------
    property var selRow: null
    property string selTypeName: ""
    property string selVariantLabel: ""
    property bool selStretchable: false
    property string _sliderId: ""
    // ---------------------------------------------------------------------------
    // Exit / redaction lifecycle
    // ---------------------------------------------------------------------------
    property bool exited: false
    property int redactRetryCount: 0
    // ---------------------------------------------------------------------------
    // Image picker state
    // ---------------------------------------------------------------------------
    property bool pickerOpen: false
    property string pickerTargetId: ""
    property string pickerPath: ""
    property string pickerStatusText: ""
    property bool pickerPathValid: false
    property var imageCandidates: []
    readonly property string homeDirPath: Quickshell.env("HOME")
    readonly property string wallpapersDir: {
        let env = Quickshell.env("WALLPAPER_DIR");
        return (env && env !== "") ? env : homeDirPath + "/.config/hypr/wallpapers";
    }
    readonly property string thumbsDir: homeDirPath + "/.cache/quickshell/wallpaper_picker/thumbs"
    readonly property string thumbDirUrl: "file://" + root.thumbsDir
    readonly property var imageFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp"]
    // Gallery: wallpaper folder model joined with the thumbnail cache (the
    // thumbs cache lives in ~/.cache/quickshell/wallpaper_picker/thumbs and is
    // maintained by qs_manager.sh; fall back to the raw file when no thumb).
    property var imageThumbsMap: ({})

    function s(val) {
        return LayoutMath.s(val, root.baseScale);
    }

    function snapTol() {
        return Math.max(3, root.s(3));
    }

    // ---------------------------------------------------------------------------
    // Screen resolution / target detection
    // ---------------------------------------------------------------------------
    function resolveTarget() {
        let name = "";
        try {
            if (Screen.name && Screen.name !== "")
                name = String(Screen.name);
        } catch (e) {}
        if (name === "") {
            try {
                if (Screen.model && Screen.model !== "")
                    name = String(Screen.model);
            } catch (e) {}
        }
        let w = 0;
        let h = 0;
        try {
            w = Math.round(Screen.width || 0);
            h = Math.round(Screen.height || 0);
        } catch (e) {}
        if (name === "" || w <= 0 || h <= 0) {
            // Fall back to Quickshell.screens (matched by size first, else first).
            for (let i = 0; i < (Quickshell.screens ? Quickshell.screens.length : 0); i++) {
                let scr = Quickshell.screens[i];
                if (!scr)
                    continue;

                if (name === "")
                    name = (scr.name && scr.name !== "") ? String(scr.name) : String(scr.model || "");

                if (w <= 0 && scr.width)
                    w = Math.round(scr.width);

                if (h <= 0 && scr.height)
                    h = Math.round(scr.height);

                if (name !== "" && w > 0 && h > 0)
                    break;
            }
        }
        root.targetScreen = name;
        root.safeTarget = name.replace(/[^a-zA-Z0-9_-]/g, "_");
        if (w > 0)
            root.sw = w;

        if (h > 0)
            root.sh = h;
    }

    function extractConstraints(item) {
        if (!item)
            return null;

        return {
            "minW": item.minWidth !== undefined ? item.minWidth : 10,
            "minH": item.minHeight !== undefined ? item.minHeight : 10,
            "maxW": item.maxWidth !== undefined ? item.maxWidth : 99999,
            "maxH": item.maxHeight !== undefined ? item.maxHeight : 99999,
            "minA": item.minAspect !== undefined ? item.minAspect : 0,
            "maxA": item.maxAspect !== undefined ? item.maxAspect : 99999
        };
    }

    function constraintsFor(type, variant) {
        let key = type + "|" + variant;
        let cached = root.constraintCache[key];
        if (cached)
            return cached;

        if (root.probeType === type && root.probeVariant === variant && probeLoader.item) {
            let c = root.extractConstraints(probeLoader.item);
            if (c) {
                let n = Object.assign({}, root.constraintCache);
                n[key] = c;
                root.constraintCache = n;
                return c;
            }
        }
        // Probe (re)instantiation — synchronous for local face files.
        root.probeType = type;
        root.probeVariant = variant;
        probeLoader.source = registry.faceFile(type, variant);
        let cons = root.extractConstraints(probeLoader.item);
        if (cons) {
            let n = Object.assign({}, root.constraintCache);
            n[key] = cons;
            root.constraintCache = n;
        }
        return cons;
    }

    // Clamp logical size with the face's constraints — port of the real window
    // clamp (widgets/Widget.qml updateEffectiveSize()): per-axis min/max first,
    // then aspect correction, capped to the screen like the loader does.
    function clampLogical(type, variant, w, h) {
        let c = root.constraintsFor(type, variant);
        if (!c)
            c = {
                "minW": 16,
                "minH": 16,
                "maxW": root.sw,
                "maxH": root.sh,
                "minA": 0,
                "maxA": 99999
            };

        let cw = Math.max(c.minW, Math.min(c.maxW, w));
        let ch = Math.max(c.minH, Math.min(c.maxH, h));
        let ratio = cw / ch;
        if (ratio < c.minA && c.minA > 0) {
            let mA = c.minA;
            let hProj = (cw * mA + ch) / (mA * mA + 1);
            let hMin = Math.max(c.minH, c.minW / mA);
            let hMax = Math.min(c.maxH, c.maxW / mA);
            ch = Math.max(hMin, Math.min(hMax, hProj));
            cw = ch * mA;
        } else if (ratio > c.maxA && c.maxA > 0) {
            let mA = c.maxA;
            let hProj = (cw * mA + ch) / (mA * mA + 1);
            let hMin = Math.max(c.minH, c.minW / mA);
            let hMax = Math.min(c.maxH, c.maxW / mA);
            ch = Math.max(hMin, Math.min(hMax, hProj));
            cw = ch * mA;
        }
        cw = Math.max(c.minW, Math.min(c.maxW, cw));
        ch = Math.max(c.minH, Math.min(c.maxH, ch));
        // Screen caps + minimum (same guarantees WidgetLoader.sanitizeGeometry gives).
        cw = Math.max(16, Math.min(root.sw, Math.round(cw)));
        ch = Math.max(16, Math.min(root.sh, Math.round(ch)));
        return {
            "w": cw,
            "h": ch
        };
    }

    function effSize(type, variant, w, h) {
        return root.clampLogical(type, variant, w, h);
    }

    // Visual (surface) box of a widget: rotation swaps the box axes exactly like
    // Widget.qml implicitWidth/implicitHeight (rot % 180).
    function parityOf(rot) {
        let r = Math.round(rot || 0) % 360;
        if (r < 0)
            r += 360;

        return (r % 180) !== 0;
    }

    function boxDims(type, variant, w, h, rot) {
        let e = root.effSize(type, variant, w, h);
        let p = root.parityOf(rot);
        return {
            "w": p ? e.h : e.w,
            "h": p ? e.w : e.h
        };
    }

    // ---------------------------------------------------------------------------
    // Model helpers
    // ---------------------------------------------------------------------------
    function rowIndex(id) {
        for (let i = 0; i < proxyModel.count; i++) {
            if (String(proxyModel.get(i).wId) === String(id))
                return i;
        }
        return -1;
    }

    function refreshModel() {
        if (root.applying)
            return;

        // The bus may emit widgetsChanged while this popup is still being
        // constructed (e.g. a loader finishing its initial layout load):
        // bail out until every child the model touches exists.
        if (!proxyModel || !registry)
            return;

        let info = WidgetSync.redactorInfo || null;
        if (!info || info.screenName !== root.safeTarget)
            return;

        let keep = root.selectedId;
        proxyModel.clear();
        let widgets = info.widgets || [];
        for (let i = 0; i < widgets.length; i++) {
            let o = widgets[i] || {};
            proxyModel.append({
                "wId": String(o.id),
                "wType": o.type || "time",
                "wVariant": o.variant || registry.defaultVariant(o.type || "time"),
                "wX": Math.round(parseFloat(o.x) || 0),
                "wY": Math.round(parseFloat(o.y) || 0),
                "wW": Math.round(parseFloat(o.w) || 250),
                "wH": Math.round(parseFloat(o.h) || 120),
                "wOpacity": (parseFloat(o.opacity) === o.opacity) ? parseFloat(o.opacity) : 1,
                "wRotation": Math.round(parseFloat(o.rotation) || 0),
                "wImagePath": o.imagePath || ""
            });
        }
        if (keep !== "" && root.rowIndex(keep) === -1)
            keep = "";

        root.selectedId = keep;
        root.refreshToolbarState();
    }

    // ---------------------------------------------------------------------------
    // Gestures (move / resize). Each change updates the local model row AND is
    // pushed through WidgetSync so the real loader + persistence follow live.
    // WidgetSync ops are synchronous in-process; the widgetsChanged rebuild is
    // suppressed (applying guard) because the local model already matches.
    // ---------------------------------------------------------------------------
    function pushGeometry(id, x, y, w, h, silent) {
        if (!id)
            return;

        if (silent === undefined)
            silent = true;

        root.applying = silent;
        WidgetSync.setGeometry(id, Math.round(x), Math.round(y), Math.round(w), Math.round(h), root.targetScreen);
        root.applying = false;
        if (!silent)
            root.refreshModel();
    }

    function otherBoxes(excludeId) {
        let out = [];
        for (let i = 0; i < proxyModel.count; i++) {
            let r = proxyModel.get(i);
            if (String(r.wId) === String(excludeId))
                continue;

            let d = root.boxDims(r.wType, r.wVariant, r.wW, r.wH, r.wRotation);
            out.push({
                "x": r.wX,
                "y": r.wY,
                "w": d.w,
                "h": d.h
            });
        }
        return out;
    }

    // Snap one coordinate on an axis. isCenter enables monitor-center / other
    // widget centers as targets; otherwise grid lines, screen edges and other
    // widgets' edges are the targets. Returns { d, guide } or null.
    function snapCoordinate(v, isCenter, others, extent) {
        let tol = root.snapTol();
        let best = null;
        let consider = target => {
            let d = target - v;
            if (Math.abs(d) <= tol && (!best || Math.abs(d) < Math.abs(best.d)))
                best = {
                    "d": d,
                    "guide": target
                };
        };
        if (isCenter) {
            consider(extent / 2);
            for (let i = 0; i < others.length; i++)
                consider(others[i].x + others[i].w / 2);
        } else {
            consider(Math.round(v / root.gridStep) * root.gridStep);
            consider(0);
            consider(extent);
            for (let i = 0; i < others.length; i++) {
                consider(others[i].x);
                consider(others[i].x + others[i].w);
            }
        }
        return best;
    }

    function beginGesture(id, mode, pullL, pullR, pullT, pullB) {
        if (root.pickerOpen)
            return;

        root.endGesture();
        let i = root.rowIndex(id);
        if (i === -1)
            return;

        let r = proxyModel.get(i);
        let e = root.effSize(r.wType, r.wVariant, r.wW, r.wH);
        root.selectedId = String(r.wId);
        root.gesture = {
            "id": String(r.wId),
            "mode": mode,
            "rot": Math.round(r.wRotation || 0),
            "type": r.wType,
            "variant": r.wVariant,
            "pullL": pullL,
            "pullR": pullR,
            "pullT": pullT,
            "pullB": pullB,
            "wx0": r.wX,
            "wy0": r.wY,
            "ew0": e.w,
            "eh0": e.h,
            "sx": 0,
            "sy": 0
        };
    }

    function updateGesturePos(gx, gy) {
        let g = root.gesture;
        if (!g)
            return;

        let dx = gx - g.sx;
        let dy = gy - g.sy;
        let p = root.parityOf(g.rot);
        let others = root.otherBoxes(g.id);
        let guideX = [];
        let guideY = [];
        let bw0 = p ? g.eh0 : g.ew0;
        let bh0 = p ? g.ew0 : g.eh0;
        if (g.mode === "move") {
            let nx = g.wx0 + dx;
            let ny = g.wy0 + dy;
            // Snap: our left/right/center edges against grid / screen / others.
            let cand = null;
            let pick = c => {
                if (c && (!cand || Math.abs(c.d) < Math.abs(cand.d)))
                    cand = c;
            };
            pick(root.snapCoordinate(nx, false, others, root.sw));
            pick(root.snapCoordinate(nx + bw0, false, others, root.sw));
            pick(root.snapCoordinate(nx + bw0 / 2, true, others, root.sw));
            if (cand) {
                nx += cand.d;
                guideX.push(cand.guide);
            }
            cand = null;
            pick(root.snapCoordinate(ny, false, others, root.sh));
            pick(root.snapCoordinate(ny + bh0, false, others, root.sh));
            pick(root.snapCoordinate(ny + bh0 / 2, true, others, root.sh));
            if (cand) {
                ny += cand.d;
                guideY.push(cand.guide);
            }
            // Loader-consistent screen clamp (positions use the stored logical w/h).
            nx = Math.max(0, Math.min(nx, Math.max(0, root.sw - g.ew0)));
            ny = Math.max(0, Math.min(ny, Math.max(0, root.sh - g.eh0)));
            root.guidesX = guideX;
            root.guidesY = guideY;
            if (nx === g.wx0 && ny === g.wy0)
                return;

            let i = root.rowIndex(g.id);
            if (i === -1)
                return;

            proxyModel.setProperty(i, "wX", nx);
            proxyModel.setProperty(i, "wY", ny);
            g.wx0 = nx;
            g.wy0 = ny;
            root.pushGeometry(g.id, nx, ny, g.ew0, g.eh0, true);
        } else {
            // Resize: work on the visual box; derive logical sizes afterwards.
            let left0 = g.wx0;
            let top0 = g.wy0;
            let right0 = g.wx0 + bw0;
            let bottom0 = g.wy0 + bh0;
            let L = left0;
            let R = right0;
            let T = top0;
            let B = bottom0;
            if (g.pullL) {
                let raw = left0 + dx;
                let s = root.snapCoordinate(raw, false, others, root.sw);
                if (s) {
                    raw += s.d;
                    guideX.push(s.guide);
                }
                L = raw;
            }
            if (g.pullR) {
                let raw = right0 + dx;
                let s = root.snapCoordinate(raw, false, others, root.sw);
                if (s) {
                    raw += s.d;
                    guideX.push(s.guide);
                }
                R = raw;
            }
            if (g.pullT) {
                let raw = top0 + dy;
                let s = root.snapCoordinate(raw, false, others, root.sh);
                if (s) {
                    raw += s.d;
                    guideY.push(s.guide);
                }
                T = raw;
            }
            if (g.pullB) {
                let raw = bottom0 + dy;
                let s = root.snapCoordinate(raw, false, others, root.sh);
                if (s) {
                    raw += s.d;
                    guideY.push(s.guide);
                }
                B = raw;
            }
            let bw1 = Math.max(16, R - L);
            let bh1 = Math.max(16, B - T);
            // Visual box -> logical requested size (rotation swaps axes).
            let lwT = p ? bh1 : bw1;
            let lhT = p ? bw1 : bh1;
            let c = root.clampLogical(g.type, g.variant, lwT, lhT);
            let cbw = p ? c.h : c.w;
            let cbh = p ? c.w : c.h;
            // Anchor the edge(s) opposite to the pulled ones.
            let vx = g.pullL ? right0 - cbw : left0;
            let vy = g.pullT ? bottom0 - cbh : top0;
            let nx = Math.max(0, Math.min(Math.round(vx), Math.max(0, root.sw - c.w)));
            let ny = Math.max(0, Math.min(Math.round(vy), Math.max(0, root.sh - c.h)));
            root.guidesX = guideX;
            root.guidesY = guideY;
            let i = root.rowIndex(g.id);
            if (i === -1)
                return;

            if (nx === g.wx0 && ny === g.wy0 && c.w === g.ew0 && c.h === g.eh0)
                return;

            proxyModel.setProperty(i, "wX", nx);
            proxyModel.setProperty(i, "wY", ny);
            proxyModel.setProperty(i, "wW", c.w);
            proxyModel.setProperty(i, "wH", c.h);
            g.wx0 = nx;
            g.wy0 = ny;
            g.ew0 = c.w;
            g.eh0 = c.h;
            root.pushGeometry(g.id, nx, ny, c.w, c.h, true);
        }
    }

    function endGesture() {
        root.gesture = null;
        root.guidesX = [];
        root.guidesY = [];
        root.applying = false;
    }

    // ---------------------------------------------------------------------------
    // Toolbar actions
    // ---------------------------------------------------------------------------
    function selectLastAdded() {
        let last = proxyModel.count - 1;
        if (last >= 0)
            root.selectedId = String(proxyModel.get(last).wId);

        root.refreshToolbarState();
    }

    function addWidgetOfType(type) {
        WidgetSync.addWidget(type, root.targetScreen);
        root.selectLastAdded();
        if (type === "image")
            root.openPicker(root.selectedId);
    }

    function deleteSelected() {
        if (root.selectedId === "")
            return;

        let id = root.selectedId;
        root.selectedId = "";
        root.refreshToolbarState();
        WidgetSync.removeWidget(id, root.targetScreen);
    }

    function rotateSelected() {
        let i = root.rowIndex(root.selectedId);
        if (i === -1)
            return;

        let r = proxyModel.get(i);
        let rot = (Math.round(r.wRotation || 0) + 90) % 360;
        WidgetSync.setRotation(root.selectedId, rot, root.targetScreen);
        root.refreshToolbarState();
    }

    function cycleVariant() {
        let i = root.rowIndex(root.selectedId);
        if (i === -1)
            return;

        let r = proxyModel.get(i);
        let list = registry.variantList(r.wType);
        if (list.length === 0)
            return;

        let cur = 0;
        for (let k = 0; k < list.length; k++) {
            if (list[k].id === r.wVariant) {
                cur = k;
                break;
            }
        }
        let next = list[(cur + 1) % list.length].id;
        WidgetSync.setVariant(root.selectedId, next, root.targetScreen);
        root.refreshToolbarState();
    }

    function duplicateSelected() {
        let i = root.rowIndex(root.selectedId);
        if (i === -1)
            return;

        let r = proxyModel.get(i);
        let c = root.clampLogical(r.wType, r.wVariant, r.wW, r.wH);
        let nid = "";
        WidgetSync.addWidget(r.wType, root.targetScreen);
        let last = proxyModel.count - 1;
        if (last < 0)
            return;

        nid = String(proxyModel.get(last).wId);
        WidgetSync.setVariant(nid, r.wVariant, root.targetScreen);
        WidgetSync.setRotation(nid, Math.round(r.wRotation || 0), root.targetScreen);
        WidgetSync.setOpacity(nid, r.wOpacity, root.targetScreen);
        WidgetSync.setImagePath(nid, r.wImagePath || "", root.targetScreen);
        let nx = Math.max(0, Math.min(r.wX + root.s(24), Math.max(0, root.sw - c.w)));
        let ny = Math.max(0, Math.min(r.wY + root.s(24), Math.max(0, root.sh - c.h)));
        root.pushGeometry(nid, nx, ny, c.w, c.h, false);
        root.selectedId = nid;
        root.refreshToolbarState();
    }

    function stretchSelected() {
        let i = root.rowIndex(root.selectedId);
        if (i === -1)
            return;

        let r = proxyModel.get(i);
        if (!registry.allowsStretchWidth(r.wType))
            return;

        let margin = Math.max(16, Math.round(root.s(24)));
        let p = root.parityOf(r.wRotation);
        // The target is the WIDTH of the visual box: screen width minus margins.
        // Logical w drives the box width when unrotated, logical h when rotated.
        let wT = p ? r.wW : root.sw - 2 * margin;
        let hT = p ? root.sw - 2 * margin : r.wH;
        let c = root.clampLogical(r.wType, r.wVariant, wT, hT);
        let boxW = p ? c.h : c.w;
        let nx = Math.max(0, Math.round((root.sw - boxW) / 2));
        let ny = Math.max(0, Math.min(Math.round(r.wY), Math.max(0, root.sh - c.h)));
        root.pushGeometry(root.selectedId, nx, ny, c.w, c.h, false);
        root.refreshToolbarState();
    }

    function clearAll() {
        if (!root.clearArmed) {
            root.clearArmed = true;
            clearDisarm.restart();
            return;
        }
        clearDisarm.stop();
        root.clearArmed = false;
        root.selectedId = "";
        root.refreshToolbarState();
        WidgetSync.clearWidgets(root.targetScreen);
    }

    function refreshToolbarState() {
        let i = root.rowIndex(root.selectedId);
        if (i === -1) {
            root.selRow = null;
            root.selTypeName = "";
            root.selVariantLabel = "";
            root.selStretchable = false;
            return;
        }
        let r = proxyModel.get(i);
        let vl = registry.variantList(r.wType);
        let vLabel = r.wVariant;
        for (let k = 0; k < vl.length; k++) {
            if (vl[k].id === r.wVariant) {
                vLabel = vl[k].label;
                break;
            }
        }
        let id = String(r.wId);
        root.selRow = {
            "id": id,
            "type": r.wType,
            "variant": r.wVariant,
            "opacity": r.wOpacity,
            "hasImage": r.wType === "image"
        };
        let t = registry.types[r.wType] || null;
        root.selTypeName = t ? t.name : r.wType;
        root.selVariantLabel = vLabel;
        root.selStretchable = !!registry.allowsStretchWidth(r.wType);
        if (opacitySlider && root._sliderId !== id) {
            root._sliderId = id;
            opacitySlider.value = Math.round((r.wOpacity !== undefined ? r.wOpacity : 1) * 100);
        }
    }

    function exitRedactor() {
        if (root.exited)
            return;

        root.exited = true;
        root.endGesture();
        WidgetSync.setRedactMode(root.targetScreen, false);
        Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh close"]);
    }

    function fileUrlOf(p) {
        if (!p || p === "")
            return "";

        if (p.indexOf("file://") === 0 || p.indexOf("http://") === 0 || p.indexOf("https://") === 0)
            return p;

        // Plain absolute path: encode (spaces, non-ASCII) but keep the slashes.
        return "file://" + encodeURI(p);
    }

    function plainPathOf(p) {
        let s = String(p || "");
        if (s.indexOf("file://") === 0)
            s = s.substring("file://".length);

        // FolderListModel fileUrl values are percent-encoded; stored layout
        // paths (imagePath) are plain, so decode before persisting.
        try {
            s = decodeURIComponent(s);
        } catch (e) {}
        return s;
    }

    function isImageExtension(p) {
        let lower = String(p || "").toLowerCase();
        let dot = lower.lastIndexOf(".");
        if (dot === -1)
            return false;

        let ext = lower.substring(dot + 1);
        return ["jpg", "jpeg", "png", "gif", "webp"].indexOf(ext) !== -1;
    }

    function openPicker(widgetId) {
        if (widgetId === "")
            return;

        root.pickerTargetId = widgetId;
        let i = root.rowIndex(widgetId);
        root.pickerPath = i !== -1 ? (proxyModel.get(i).wImagePath || "") : "";
        root.pickerStatusText = "";
        root.validatePickerPath();
        root.rebuildImageGallery();
        root.pickerOpen = true;
    }

    function closePicker() {
        root.pickerOpen = false;
        root.pickerTargetId = "";
    }

    function validatePickerPath() {
        let p = String(root.pickerPath || "").trim();
        if (p === "") {
            // Empty path clears the widget image (face falls back to its placeholder).
            root.pickerPathValid = true;
            root.pickerStatusText = "";
            return;
        }
        if (!root.isImageExtension(p)) {
            root.pickerPathValid = false;
            root.pickerStatusText = "Only jpg/jpeg/png/gif/webp images are supported";
            return;
        }
        root.pickerPathValid = true;
        root.pickerStatusText = "";
        // Probe the file through a real Image; its status handlers adjust validity.
        pickerProbe.source = root.fileUrlOf(p);
    }

    function applyPickerPath() {
        if (!root.pickerPathValid)
            return;

        let p = String(root.pickerPath || "").trim();
        // Never apply while the file probe is still loading (double-click can
        // otherwise race the probe and persist a path that does not exist).
        if (p !== "" && pickerProbe.source === root.fileUrlOf(p) && pickerProbe.status === Image.Loading)
            return;

        let id = root.pickerTargetId;
        WidgetSync.setImagePath(id, p, root.targetScreen);
        root.closePicker();
        root.selectedId = id;
        root.refreshToolbarState();
    }

    function rebuildImageGallery() {
        let list = [];
        let src = wallpaperFolder;
        for (let i = 0; i < src.count; i++) {
            let fname = String(src.get(i, "fileName") || "");
            if (fname === "")
                continue;

            let fUrl = String(src.get(i, "fileUrl") || "");
            let plain = root.plainPathOf(fUrl);
            let useThumb = root.imageThumbsMap[fname] === true;
            // Thumbnail names come from the filesystem raw; encode them when
            // building the URL (fileUrl from FolderListModel is pre-encoded).
            list.push({
                "name": fname,
                "thumb": useThumb ? root.thumbDirUrl + "/" + encodeURIComponent(fname) : fUrl,
                "full": plain
            });
        }
        root.imageCandidates = list;
    }

    function syncThumbMap() {
        let map = {};
        for (let i = 0; i < thumbFolder.count; i++) {
            let fname = String(thumbFolder.get(i, "fileName") || "");
            if (fname !== "")
                map[fname] = true;
        }
        root.imageThumbsMap = map;
        root.rebuildImageGallery();
    }

    // ---------------------------------------------------------------------------
    // Keyboard
    // ---------------------------------------------------------------------------
    Keys.onEscapePressed: {
        if (root.pickerOpen) {
            root.closePicker();
            event.accepted = true;
            return;
        }
        root.exitRedactor();
        event.accepted = true;
    }
    Keys.onDeletePressed: {
        if (!root.pickerOpen)
            root.deleteSelected();

        event.accepted = true;
    }
    Component.onCompleted: {
        root.resolveTarget();
        // Make sure the thumbnails folder exists so FolderListModel settles.
        Quickshell.execDetached(["mkdir", "-p", root.thumbsDir]);
        WidgetSync.setRedactMode(root.targetScreen, true);
        scaleReader.running = true;
        root.refreshModel();
        // Re-assert redaction a few times: if this popup opened before the
        // target screen's WidgetLoader finished registering (shell startup),
        // the first setRedactMode call had no loader to hide windows on.
        root.redactRetryCount = 0;
        redactRetry.start();
    }
    Component.onDestruction: {
        root.exited = true;
        redactRetry.stop();
        if (WidgetSync.redactorOpen && WidgetSync.redactorScreen === root.safeTarget)
            WidgetSync.setRedactMode(root.targetScreen, false);
    }

    WidgetRegistry {
        id: registry
    }

    // --- local editing model (mirror of the loader's layout list) ---------------
    // Rows keep the same shape as layout.json entries ({id,type,variant,x,y,w,h,
    // opacity,rotation,imagePath}) under loader-style role names (wId, wX, ...).
    ListModel {
        id: proxyModel
    }

    Timer {
        id: clearDisarm

        interval: 2500
        onTriggered: root.clearArmed = false
    }

    Timer {
        id: redactRetry

        interval: 700
        onTriggered: {
            if (root.exited)
                return;

            root.redactRetryCount++;
            if (root.redactRetryCount <= 8) {
                WidgetSync.setRedactMode(root.targetScreen, true);
                redactRetry.restart();
            }
        }
    }

    Connections {
        function onWidgetsChanged() {
            root.refreshModel();
        }

        target: WidgetSync
    }

    Process {
        id: scaleReader

        command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null | jq -r '.uiScale // 1'"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let v = parseFloat(this.text.trim());
                if (!isNaN(v) && v > 0 && root.uiScale !== v)
                    root.uiScale = v;
            }
        }
    }

    // ===========================================================================
    // VISUAL TREE
    // ===========================================================================
    // Dim layer (must not cover the dock — Main's mask punches the top strip).
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35
        z: 0
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: {
            if (root.pickerOpen)
                return;

            if (root.selectedId !== "") {
                root.selectedId = "";
                root.refreshToolbarState();
            }
        }
    }

    // --- proxies ----------------------------------------------------------------
    Item {
        id: canvas

        anchors.fill: parent
        z: 2

        Repeater {
            model: proxyModel

            delegate: Item {
                id: proxy

                required property int index
                required property string wId
                required property string wType
                required property string wVariant
                required property real wX
                required property real wY
                required property real wW
                required property real wH
                required property real wOpacity
                required property real wRotation
                required property string wImagePath
                property bool selected: root.selectedId === wId
                property bool hovered: false
                // Effective logical size (face-clamped) and visual box size.
                property var eff: root.effSize(wType, wVariant, wW, wH)
                property bool odd: root.parityOf(wRotation)
                property real boxW: odd ? eff.h : eff.w
                property real boxH: odd ? eff.w : eff.h
                property int chipH: s(18)

                x: Math.round(wX)
                y: Math.round(wY)
                width: Math.round(boxW)
                height: Math.round(boxH)
                z: selected ? 500 : 0
                visible: !root.pickerOpen

                // --- face preview (the real face, faithful to the widget window) ---
                Loader {
                    id: faceLoader

                    property string imagePath: wImagePath

                    anchors.centerIn: parent
                    width: proxy.eff.w
                    height: proxy.eff.h
                    rotation: wRotation
                    opacity: wOpacity
                    source: registry.faceFile(wType, wVariant)
                    onLoaded: {
                        let it = faceLoader.item;
                        if (!it)
                            return;

                        // The real windows are hidden while editing: preview faces
                        // must not register Cava consumers or run media gating.
                        if (it.windowShown !== undefined)
                            it.windowShown = false;

                        // Image faces read the path under several names.
                        let names = ["imagePath", "wImagePath", "path"];
                        for (let k = 0; k < names.length; k++) {
                            if (it[names[k]] !== undefined)
                                it[names[k]] = Qt.binding(() => {
                                    return faceLoader.imagePath;
                                });
                        }
                    }
                }

                // --- selection ring -------------------------------------------------
                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(Theme.clampedBorderRadius, Math.min(proxy.boxW, proxy.boxH) / 2)
                    color: "transparent"
                    border.width: proxy.selected ? 2 : 1
                    border.color: proxy.selected ? Theme.accent : (proxy.hovered ? Theme.overlay1 : Theme.surface1)
                    opacity: proxy.selected ? 1 : (proxy.hovered ? 0.9 : 0.45)
                }

                // type/variant chip (selected only)
                Rectangle {
                    visible: proxy.selected
                    anchors.top: parent.top
                    anchors.topMargin: -proxy.chipH - 2
                    anchors.left: parent.left
                    height: proxy.chipH
                    radius: s(6)
                    color: Theme.base
                    border.width: 1
                    border.color: Theme.accent

                    Text {
                        anchors.fill: parent
                        anchors.margins: s(2)
                        text: root.selRow && root.selRow.id === proxy.wId ? root.selTypeName + " · " + root.selVariantLabel : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: Theme.text
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // --- move area -------------------------------------------------------
                MouseArea {
                    id: moveArea

                    anchors.fill: parent
                    cursorShape: Qt.SizeAllCursor
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    onEntered: proxy.hovered = true
                    onExited: proxy.hovered = false
                    onPressed: mouse => {
                        root.beginGesture(proxy.wId, "move", false, false, false, false);
                        let g = root.gesture;
                        if (!g)
                            return;

                        let c = proxy.mapToItem(root, mouse.x, mouse.y);
                        g.sx = c.x;
                        g.sy = c.y;
                    }
                    onPositionChanged: mouse => {
                        let g = root.gesture;
                        if (!g || g.id !== proxy.wId || g.mode !== "move")
                            return;

                        let c = proxy.mapToItem(root, mouse.x, mouse.y);
                        root.updateGesturePos(c.x, c.y);
                    }
                    onReleased: {
                        root.endGesture();
                    }
                    onCanceled: {
                        root.endGesture();
                    }
                }

                // --- resize handles (8: corners + edge midpoints) ---------------------
                Repeater {
                    model: [
                        {
                            "pullL": true,
                            "pullT": true,
                            "cursor": Qt.SizeFDiagCursor
                        },
                        {
                            "pullR": true,
                            "pullT": true,
                            "cursor": Qt.SizeBDiagCursor
                        },
                        {
                            "pullL": true,
                            "pullB": true,
                            "cursor": Qt.SizeBDiagCursor
                        },
                        {
                            "pullR": true,
                            "pullB": true,
                            "cursor": Qt.SizeFDiagCursor
                        },
                        {
                            "pullL": true,
                            "cursor": Qt.SizeHorCursor
                        },
                        {
                            "pullR": true,
                            "cursor": Qt.SizeHorCursor
                        },
                        {
                            "pullT": true,
                            "cursor": Qt.SizeVerCursor
                        },
                        {
                            "pullB": true,
                            "cursor": Qt.SizeVerCursor
                        }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index
                        property bool hov: false

                        width: s(12)
                        height: s(12)
                        visible: proxy.selected
                        x: {
                            if (modelData.pullL)
                                return 0;

                            if (modelData.pullR)
                                return proxy.boxW - width;

                            return (proxy.boxW - width) / 2;
                        }
                        y: {
                            if (modelData.pullT)
                                return 0;

                            if (modelData.pullB)
                                return proxy.boxH - height;

                            return (proxy.boxH - height) / 2;
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: 3
                            color: hov ? Theme.accent : Theme.base
                            border.width: 1
                            border.color: hov ? Theme.accent : Theme.surface2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: modelData.cursor
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            onEntered: hov = true
                            onExited: hov = false
                            onPressed: mouse => {
                                root.beginGesture(proxy.wId, "resize", modelData.pullL, modelData.pullR, modelData.pullT, modelData.pullB);
                                let g = root.gesture;
                                if (!g)
                                    return;

                                let c = proxy.mapToItem(root, mouse.x, mouse.y);
                                g.sx = c.x;
                                g.sy = c.y;
                            }
                            onPositionChanged: mouse => {
                                let g = root.gesture;
                                if (!g || g.id !== proxy.wId || g.mode !== "resize")
                                    return;

                                let c = proxy.mapToItem(root, mouse.x, mouse.y);
                                root.updateGesturePos(c.x, c.y);
                            }
                            onReleased: {
                                root.endGesture();
                            }
                            onCanceled: {
                                root.endGesture();
                            }
                        }
                    }
                }
            }
        }
    }

    // --- snap guide lines -----------------------------------------------------------
    Repeater {
        model: root.guidesX
        z: 3

        delegate: Rectangle {
            required property var modelData

            x: modelData
            y: 0
            width: 1
            height: root.sh
            color: Theme.mauve
            opacity: 0.8
        }
    }

    Repeater {
        model: root.guidesY
        z: 3

        delegate: Rectangle {
            required property var modelData

            x: 0
            y: modelData
            width: root.sw
            height: 1
            color: Theme.mauve
            opacity: 0.8
        }
    }

    // --- empty-state hint -------------------------------------------------------------
    Text {
        visible: proxyModel.count === 0 && !root.pickerOpen
        anchors.centerIn: parent
        text: "No desktop widgets yet\nAdd one from the toolbar above (SUPER+SHIFT+W)"
        font.family: Theme.fontFamily
        font.pixelSize: s(16)
        color: Theme.overlay1
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 1.5
        z: 2
    }

    // --- toolbar ----------------------------------------------------------------------
    Rectangle {
        id: toolbar

        anchors.horizontalCenter: parent.horizontalCenter
        y: 48 + s(8)
        z: 10
        width: Math.min(root.width - 2 * s(8), toolbarRow.implicitWidth + s(20))
        height: s(46)
        radius: s(14)
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.94)
        border.width: 1
        border.color: Theme.surface1

        Flickable {
            id: toolbarScroll

            anchors.fill: parent
            anchors.margins: s(6)
            contentWidth: toolbarRow.width
            contentHeight: toolbarRow.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Row {
                id: toolbarRow

                height: toolbarScroll.height
                spacing: s(6)

                // ---- add types ----
                Repeater {
                    model: registry.typeList()

                    delegate: Button {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: s(88)
                        height: s(30)
                        hoverEnabled: true
                        enabled: true
                        onClicked: root.addWidgetOfType(modelData.id)

                        background: Rectangle {
                            radius: s(8)
                            border.width: 1
                            border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                            color: {
                                if (!parent.enabled)
                                    return Theme.surface0;

                                return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                            }
                        }

                        contentItem: Text {
                            text: modelData.icon + "  " + modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: s(10)
                            color: parent.enabled ? Theme.text : Theme.overlay1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: s(22)
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface2
                }

                // ---- selection controls ----
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(126)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow
                    onClicked: root.cycleVariant()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                        }
                    }

                    contentItem: Text {
                        text: "Variant: " + (root.selRow ? root.selVariantLabel : "—")
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.text : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(96)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow
                    onClicked: root.rotateSelected()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                        }
                    }

                    contentItem: Text {
                        text: "Rotate 90°"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.text : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(108)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow && root.selStretchable
                    onClicked: root.stretchSelected()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                        }
                    }

                    contentItem: Text {
                        text: "Stretch width"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.text : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(112)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow && root.selRow.hasImage
                    onClicked: root.openPicker(root.selRow.id)

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                        }
                    }

                    contentItem: Text {
                        text: "Pick image…"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.text : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(96)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow
                    onClicked: root.duplicateSelected()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                        }
                    }

                    contentItem: Text {
                        text: "Duplicate"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.text : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(80)
                    height: s(30)
                    hoverEnabled: true
                    enabled: !!root.selRow
                    onClicked: root.deleteSelected()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            if (parent.down)
                                return Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.4);

                            return parent.hovered ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.16);
                        }
                    }

                    contentItem: Text {
                        text: "Delete"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.red : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: s(22)
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface2
                }

                // ---- opacity ----
                Item {
                    width: s(150)
                    height: parent.height
                    visible: !!root.selRow

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Opacity"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: Theme.overlay1
                    }

                    Slider {
                        id: opacitySlider

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: s(44)
                        anchors.rightMargin: s(26)
                        anchors.verticalCenter: parent.verticalCenter
                        from: 10
                        to: 100
                        value: 100
                        onValueChanged: {
                            if (!opacitySlider.pressed)
                                return;

                            if (!root.selRow)
                                return;

                            let i = root.rowIndex(root.selRow.id);
                            if (i === -1)
                                return;

                            let v = opacitySlider.value / 100;
                            proxyModel.setProperty(i, "wOpacity", v);
                            root.applying = true;
                            WidgetSync.setOpacity(root.selRow.id, v, root.targetScreen);
                            root.applying = false;
                        }

                        background: Rectangle {
                            x: opacitySlider.leftPadding
                            y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                            width: opacitySlider.availableWidth
                            height: s(4)
                            radius: s(2)
                            color: Theme.surface1

                            Rectangle {
                                width: opacitySlider.visualPosition * parent.width
                                height: parent.height
                                radius: s(2)
                                color: Theme.accent
                            }
                        }

                        handle: Rectangle {
                            x: opacitySlider.leftPadding + opacitySlider.visualPosition * (opacitySlider.availableWidth - width)
                            y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                            width: s(14)
                            height: s(14)
                            radius: s(7)
                            color: Theme.base
                            border.width: 2
                            border.color: Theme.accent
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(opacitySlider.value) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: Theme.text
                    }
                }

                // ---- clear all (two-pulse confirm) ----
                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    width: s(96)
                    height: s(30)
                    hoverEnabled: true
                    enabled: true
                    onClicked: root.clearAll()

                    background: Rectangle {
                        radius: s(8)
                        border.width: 1
                        border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                        color: {
                            if (!parent.enabled)
                                return Theme.surface0;

                            if (parent.down)
                                return Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.4);

                            return parent.hovered ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.3) : Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.16);
                        }
                    }

                    contentItem: Text {
                        text: root.clearArmed ? "Sure? Clear" : "Clear all"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(10)
                        color: parent.enabled ? Theme.red : Theme.overlay1
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    // ---- bottom hint ------------------------------------------------------------
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: s(14)
        z: 10
        width: hintText.implicitWidth + s(24)
        height: hintText.implicitHeight + s(8)
        radius: s(10)
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.8)

        Text {
            id: hintText

            anchors.centerIn: parent
            text: "Drag to move · pull handles to resize · snap: 20 px grid / monitor center / other widgets · ESC to finish"
            font.family: Theme.fontFamily
            font.pixelSize: s(10)
            color: Theme.overlay0
        }
    }

    // === hidden probe workspace (face constraint probing, never rendered) ==========
    Item {
        id: probeWorkspace

        visible: false
        z: -100

        Loader {
            id: probeLoader
        }
    }

    // === image picker overlay ========================================================
    Item {
        visible: root.pickerOpen
        anchors.fill: parent
        z: 20

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePicker()
        }

        Rectangle {
            id: pickerPanel

            anchors.centerIn: parent
            width: Math.min(s(760), root.width - 2 * s(24))
            height: Math.min(s(500), root.height - 2 * s(24))
            radius: s(16)
            color: Theme.base
            border.width: 1
            border.color: Theme.surface1
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: s(14)
                spacing: s(10)

                // header
                Row {
                    width: parent.width
                    height: s(24)
                    spacing: s(8)

                    Rectangle {
                        width: s(24)
                        height: s(24)
                        radius: s(8)
                        color: Theme.surface0

                        Text {
                            anchors.centerIn: parent
                            text: "󰋩"
                            font.family: Theme.fontFamily
                            font.pixelSize: s(14)
                            color: Theme.text
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Image widget — pick a picture"
                        font.family: Theme.fontFamily
                        font.pixelSize: s(14)
                        font.weight: Font.Bold
                        color: Theme.text
                    }
                }

                // gallery grid
                Item {
                    width: parent.width
                    height: s(300)

                    GridView {
                        id: galleryView

                        anchors.fill: parent
                        cellWidth: s(150)
                        cellHeight: s(140)
                        clip: true
                        model: root.imageCandidates
                        highlightFollowsCurrentItem: true

                        highlight: Rectangle {
                            color: "transparent"
                            border.width: 2
                            border.color: Theme.accent
                            radius: s(10)
                        }

                        delegate: Item {
                            required property var modelData
                            required property int index

                            width: galleryView.cellWidth
                            height: galleryView.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: s(4)
                                radius: s(10)
                                color: Theme.surface0
                                border.width: 1
                                border.color: Theme.surface1
                                clip: true

                                Image {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: nameTag.top
                                    source: modelData.thumb
                                    sourceSize: Qt.size(220, 220)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    id: nameTag

                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: s(20)
                                    color: Theme.base

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: s(9)
                                        elide: Text.ElideMiddle
                                        color: Theme.overlay0
                                        width: parent.width - s(8)
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    galleryView.currentIndex = index;
                                    root.pickerPath = modelData.full;
                                    root.validatePickerPath();
                                }
                                onDoubleClicked: {
                                    root.pickerPath = modelData.full;
                                    root.validatePickerPath();
                                    root.applyPickerPath();
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.imageCandidates.length === 0
                        anchors.centerIn: parent
                        text: "No images in " + root.wallpapersDir
                        font.family: Theme.fontFamily
                        font.pixelSize: s(12)
                        color: Theme.overlay1
                    }
                }

                // manual path + validation
                Row {
                    width: parent.width
                    height: s(30)
                    spacing: s(8)

                    TextField {
                        id: pathField

                        width: parent.width - s(76) - s(76) - (root.pickerStatusText !== "" ? s(96) : 0) - s(24)
                        height: s(28)
                        text: root.pickerPath
                        font.family: Theme.fontFamily
                        font.pixelSize: s(11)
                        color: Theme.text
                        selectByMouse: true
                        placeholderText: "Absolute path to an image (jpg/jpeg/png/gif/webp) or empty to clear"
                        placeholderTextColor: Theme.overlay1
                        onTextChanged: {
                            root.pickerPath = pathField.text;
                            root.validatePickerPath();
                        }
                        onAccepted: root.applyPickerPath()

                        background: Rectangle {
                            radius: s(8)
                            color: Theme.surface0
                            border.width: 1
                            border.color: root.pickerPathValid ? Theme.surface2 : Theme.red
                        }
                    }

                    Text {
                        width: s(96)
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.pickerStatusText
                        font.family: Theme.fontFamily
                        font.pixelSize: s(9)
                        wrapMode: Text.WordWrap
                        color: Theme.red
                        visible: root.pickerStatusText !== ""
                    }

                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(76)
                        height: s(30)
                        hoverEnabled: true
                        enabled: root.pickerPathValid && (root.pickerPath === "" || pickerProbe.status === Image.Ready)
                        onClicked: root.applyPickerPath()

                        background: Rectangle {
                            radius: s(8)
                            border.width: 1
                            border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                            color: parent.enabled ? Theme.accent : Theme.surface0
                        }

                        contentItem: Text {
                            text: "Apply"
                            font.family: Theme.fontFamily
                            font.pixelSize: s(10)
                            color: parent.enabled ? Theme.base : Theme.overlay1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        width: s(76)
                        height: s(30)
                        hoverEnabled: true
                        enabled: true
                        onClicked: root.closePicker()

                        background: Rectangle {
                            radius: s(8)
                            border.width: 1
                            border.color: parent.enabled ? Theme.surface2 : Theme.surface1
                            color: {
                                if (!parent.enabled)
                                    return Theme.surface0;

                                return parent.down || parent.hovered ? Theme.surface2 : Theme.surface1;
                            }
                        }

                        contentItem: Text {
                            text: "Cancel"
                            font.family: Theme.fontFamily
                            font.pixelSize: s(10)
                            color: parent.enabled ? Theme.text : Theme.overlay1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // file probe for the manual path field
        Image {
            id: pickerProbe

            visible: false
            onStatusChanged: {
                if (pickerProbe.source === "")
                    return;

                if (pickerProbe.status === Image.Ready) {
                    root.pickerPathValid = true;
                    root.pickerStatusText = "";
                } else if (pickerProbe.status === Image.Error) {
                    root.pickerPathValid = false;
                    root.pickerStatusText = "File not readable as an image";
                }
            }
        }
    }

    // === folder models backing the image gallery ==================================
    FolderListModel {
        id: wallpaperFolder

        folder: "file://" + root.wallpapersDir
        nameFilters: root.imageFilters
        showDirs: false
        sortField: FolderListModel.Name
        onStatusChanged: root.rebuildImageGallery()
        onCountChanged: root.rebuildImageGallery()
    }

    FolderListModel {
        id: thumbFolder

        folder: "file://" + root.thumbsDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
        onStatusChanged: root.syncThumbMap()
        onCountChanged: root.syncThumbMap()
    }
}
