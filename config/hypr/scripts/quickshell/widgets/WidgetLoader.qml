import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// ============================================================================
// WidgetLoader — per-screen manager of desktop widgets (Phase W3).
//
// Owns the ListModel of widgets for ONE screen and an Instantiator that
// materializes a Widget (PanelWindow) per row. Persists the layout to
// ~/.local/state/quickshell/widgets/<safeMonitorName>/layout.json with
// atomic writes (tmp + mv) debounced ~300 ms.
//
// The bus (WidgetSync singleton) dispatches redactor commands to the loader
// whose screen matches; this loader also answers redactor queries
// (redactorInfo / layoutForRedactor).
// ============================================================================

Item {
    id: loaderRoot

    required property var screen
    // Shared WidgetRegistry catalog (provided by widgets/Widgets.qml).
    property var registry: null

    // --- screen identity -------------------------------------------------------
    readonly property string monitorName: {
        if (loaderRoot.screen) {
            if (loaderRoot.screen.name && loaderRoot.screen.name !== "") return loaderRoot.screen.name;
            if (loaderRoot.screen.model && loaderRoot.screen.model !== "") return loaderRoot.screen.model;
        }
        return "default";
    }
    readonly property string safeMonitorName: monitorName.replace(/[^a-zA-Z0-9_-]/g, "_")
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/widgets/" + loaderRoot.safeMonitorName
    readonly property string stateFile: loaderRoot.stateDir + "/layout.json"

    property bool isRedacting: false

    function registryOf() {
        if (!loaderRoot.registry) {
            // Standalone fallback: never expected (Widgets.qml injects the
            // shared catalog) but keeps the loader usable in isolation.
            loaderRoot.registry = Qt.createComponent("WidgetRegistry.qml").createObject(loaderRoot);
        }
        return loaderRoot.registry;
    }

    ListModel {
        id: widgetsModel
    }

    // --- serialization helpers ----------------------------------------------------
    function itemToObject(index) {
        let item = widgetsModel.get(index);
        if (!item) return null;
        return {
            id: String(item.wId),
            type: item.wType || "time",
            variant: item.wVariant || registryOf().defaultVariant(item.wType || "time"),
            x: item.wX,
            y: item.wY,
            w: item.wWidth,
            h: item.wHeight,
            opacity: item.wOpacity !== undefined ? item.wOpacity : 1.0,
            rotation: item.wRotation !== undefined && !isNaN(item.wRotation) ? item.wRotation : 0,
            imagePath: item.wImagePath || ""
        };
    }

    // Serializable current list (excludes nothing; model rows are canonical).
    function snapshot() {
        let data = [];
        for (let i = 0; i < widgetsModel.count; i++) {
            let o = loaderRoot.itemToObject(i);
            if (o) data.push(o);
        }
        return data;
    }

    // JSON string of the current layout (consumed by the redactor).
    function layoutForRedactor() {
        return JSON.stringify(loaderRoot.snapshot());
    }

    // Info object the redactor reads: screen identity + current widgets.
    property var redactorInfo: ({
        screenName: loaderRoot.safeMonitorName,
        monitorName: loaderRoot.monitorName,
        widgets: []
    })

    function refreshRedactorInfo() {
        loaderRoot.redactorInfo = {
            screenName: loaderRoot.safeMonitorName,
            monitorName: loaderRoot.monitorName,
            widgets: loaderRoot.snapshot()
        };
    }

    // Model mutated: keep the redactor bus in sync and persist (debounced).
    // Every op* ends in changed(), so this is the single path that schedules
    // persistence — no caller may mutate the model without persisting.
    function changed() {
        loaderRoot.refreshRedactorInfo();
        WidgetSync.notifyWidgetsChanged();
        loaderRoot.scheduleSave();
    }

    // --- persistence (atomic write: printf base64 -> tmp, then mv) ----------------
    // saveNow() uses a per-write mktemp file inside the state dir (never a
    // fixed tmp name) so concurrent/torn writes cannot leave a stale tmp that
    // a later write would consume.
    function toBase64(str) {
        let bytes = [];
        for (let i = 0; i < str.length; i++) {
            let code = str.charCodeAt(i);
            if (code < 0x80) bytes.push(code);
            else if (code < 0x800) bytes.push(0xc0 | (code >> 6), 0x80 | (code & 0x3f));
            else if (code < 0xd800 || code >= 0xe000) bytes.push(0xe0 | (code >> 12), 0x80 | ((code >> 6) & 0x3f), 0x80 | (code & 0x3f));
            else {
                i++;
                let c = 0x10000 + (((code & 0x3ff) << 10) | (str.charCodeAt(i) & 0x3ff));
                bytes.push(0xf0 | (c >> 18), 0x80 | ((c >> 12) & 0x3f), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
            }
        }
        let map = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        let out = "";
        for (let i = 0; i < bytes.length; i += 3) {
            let b0 = bytes[i];
            let b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
            let b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
            out += map[b0 >> 2];
            out += map[((b0 & 3) << 4) | (b1 >> 4)];
            out += i + 1 < bytes.length ? map[((b1 & 15) << 2) | (b2 >> 6)] : "=";
            out += i + 2 < bytes.length ? map[b2 & 63] : "=";
        }
        return out;
    }

    function saveNow() {
        saveTimer.stop();
        let jsonStr;
        try {
            jsonStr = JSON.stringify(loaderRoot.snapshot());
        } catch (e) {
            return;
        }
        let b64 = loaderRoot.toBase64(jsonStr);
        let script = "mkdir -p '" + loaderRoot.stateDir + "' && "
            + "tmp=$(mktemp '" + loaderRoot.stateDir + "/layout.json.tmp.XXXXXX') && "
            + "printf '%s' '" + b64 + "' | base64 -d > \"$tmp\" && "
            + "mv -f \"$tmp\" '" + loaderRoot.stateFile + "'";
        Quickshell.execDetached(["bash", "-c", script]);
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: loaderRoot.saveNow()
    }

    function scheduleSave() {
        saveTimer.restart();
    }

    // --- model ops (called by the bus / redactor) -----------------------------------
    function uniqueId() {
        return "w_" + Date.now().toString(36) + "_" + Math.floor(Math.random() * 0xfffff).toString(36);
    }

    function findIndex(id) {
        let target = String(id);
        for (let i = 0; i < widgetsModel.count; i++) {
            if (String(widgetsModel.get(i).wId) === target) return i;
        }
        return -1;
    }

    function screenWidth() {
        return loaderRoot.screen && loaderRoot.screen.width ? loaderRoot.screen.width : 1920;
    }

    function screenHeight() {
        return loaderRoot.screen && loaderRoot.screen.height ? loaderRoot.screen.height : 1080;
    }

    // --- geometry sanitizer (initial load + opSetGeometry) -------------------------
    // NaN / non-positive numbers fall back to the type default size (or 16 for
    // positions), sizes are clamped to [16 .. screen extent] and positions are
    // clamped so the widget stays fully inside its screen. Fine clamping
    // against the face's declared constraints is done by Widget at render time
    // (Widget.updateEffectiveSize); here we only keep the persisted model
    // values non-degenerate and on-screen.
    function sanitizeGeometry(x, y, w, h, fbW, fbH) {
        let sw = loaderRoot.screenWidth();
        let sh = loaderRoot.screenHeight();
        let num = (v, fallback) => {
            let n = parseFloat(v);
            return isNaN(n) || n <= 0 ? fallback : n;
        };
        let nw = Math.max(16, Math.min(sw, Math.floor(num(w, fbW))));
        let nh = Math.max(16, Math.min(sh, Math.floor(num(h, fbH))));
        let nx = Math.min(Math.max(0, Math.floor(num(x, 16))), Math.max(0, sw - nw));
        let ny = Math.min(Math.max(0, Math.floor(num(y, 16))), Math.max(0, sh - nh));
        return { x: nx, y: ny, w: nw, h: nh };
    }

    // Random non-overlapping position for a new widget of the given size.
    function freePosition(w, h, gap) {
        let sw = loaderRoot.screenWidth();
        let sh = loaderRoot.screenHeight();
        let margin = 16;
        gap = gap !== undefined ? gap : 12;
        let maxX = Math.max(margin, sw - w - margin);
        let maxY = Math.max(margin, sh - h - margin);
        let last = { x: margin, y: margin };
        let overlaps = (x, y) => {
            for (let i = 0; i < widgetsModel.count; i++) {
                let o = widgetsModel.get(i);
                if (x < o.wX + o.wWidth + gap && o.wX < x + w + gap
                    && y < o.wY + o.wHeight + gap && o.wY < y + h + gap) return true;
            }
            return false;
        };
        for (let attempt = 0; attempt < 40; attempt++) {
            let x = margin + Math.random() * Math.max(1, maxX - margin);
            let y = margin + Math.random() * Math.max(1, maxY - margin);
            last = { x: Math.round(x), y: Math.round(y) };
            if (!overlaps(last.x, last.y)) return last;
        }
        return last;
    }

    function opAddWidget(type) {
        let reg = loaderRoot.registryOf();
        let def = reg.defaultSize(type);
        let pos = loaderRoot.freePosition(def.w, def.h);
        widgetsModel.append({
            wId: loaderRoot.uniqueId(),
            wType: type,
            wVariant: reg.defaultVariant(type),
            wX: pos.x,
            wY: pos.y,
            wWidth: def.w,
            wHeight: def.h,
            wOpacity: 1.0,
            wRotation: 0,
            wImagePath: ""
        });
        loaderRoot.changed();
    }

    function opRemoveWidget(id) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        widgetsModel.remove(idx, 1);
        loaderRoot.changed();
    }

    function opClearWidgets() {
        if (widgetsModel.count === 0) return;
        widgetsModel.clear();
        loaderRoot.changed();
    }

    function opBringToFront(id) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1 || idx >= widgetsModel.count - 1) return;
        // move() preserves row identity, so the Widget (PanelWindow) of that
        // row is NOT destroyed and recreated like a remove()+append() would.
        // Stacking note: the Instantiator materializes delegates in model row
        // order, and the compositor layers the resulting surfaces in that
        // (re)map order — i.e. model order defines the visual stacking of the
        // widgets. move() reorders the model cheaply; existing mapped
        // surfaces are not re-raised above already-mapped siblings (that is
        // a wl_surface property), which is fine for the redactor use case.
        widgetsModel.move(idx, widgetsModel.count - 1, 1);
        loaderRoot.changed();
    }

    function opSetVariant(id, variant) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        let item = widgetsModel.get(idx);
        let reg = loaderRoot.registryOf();
        let type = item.wType || "time";
        let t = reg.types[type];
        if (t && t.variants && !t.variants[variant]) return;
        if (!t && !variant) variant = reg.defaultVariant(type);
        widgetsModel.setProperty(idx, "wVariant", variant);
        loaderRoot.changed();
    }

    function opSetGeometry(id, x, y, w, h) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        let item = widgetsModel.get(idx);
        let reg = loaderRoot.registryOf();
        let def = reg.defaultSize(item.wType || "time");
        let g = loaderRoot.sanitizeGeometry(x, y, w, h, def.w, def.h);
        widgetsModel.setProperty(idx, "wX", g.x);
        widgetsModel.setProperty(idx, "wY", g.y);
        widgetsModel.setProperty(idx, "wWidth", g.w);
        widgetsModel.setProperty(idx, "wHeight", g.h);
        loaderRoot.changed();
    }

    function opSetOpacity(id, opacity) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        let o = parseFloat(opacity);
        // Clamp into [0,1]; NaN falls back to fully opaque.
        if (isNaN(o)) o = 1.0;
        widgetsModel.setProperty(idx, "wOpacity", Math.max(0.0, Math.min(1.0, o)));
        loaderRoot.changed();
    }

    function opSetRotation(id, rotation) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        let r = parseFloat(rotation);
        if (isNaN(r)) r = 0;
        widgetsModel.setProperty(idx, "wRotation", r);
        loaderRoot.changed();
    }

    function opSetImagePath(id, imagePath) {
        let idx = loaderRoot.findIndex(id);
        if (idx === -1) return;
        widgetsModel.setProperty(idx, "wImagePath", imagePath || "");
        loaderRoot.changed();
    }

    // Hide the real windows while the redactor for this screen is open.
    function opSetRedactMode(on) {
        loaderRoot.isRedacting = on;
        if (!on) {
            loaderRoot.saveNow(); // flush any pending debounced change
        }
    }

    // --- initial load -------------------------------------------------------------
    Process {
        id: loadProcess
        command: ["bash", "-c", "cat '" + loaderRoot.stateFile + "' 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let trimmed = this.text ? this.text.trim() : "";
                let data = [];
                let corrupt = false;
                if (trimmed !== "") {
                    try {
                        let parsed = JSON.parse(trimmed);
                        if (Array.isArray(parsed)) {
                            data = parsed;
                        } else {
                            corrupt = true; // valid JSON but not a layout list
                        }
                    } catch (e) {
                        corrupt = true;
                    }
                }
                if (corrupt) {
                    // Unreadable layout file: move it aside (bash mv, atomic)
                    // so the corruption is preserved for inspection but stops
                    // shadowing future saves, then continue with an empty
                    // layout — never leave the model silently empty with the
                    // broken file still in place. changed() below re-creates
                    // layout.json from the (empty) model.
                    let bak = loaderRoot.stateFile + ".bak";
                    Quickshell.execDetached(["bash", "-c", "if [ -f '" + loaderRoot.stateFile + "' ]; then mv -f '" + loaderRoot.stateFile + "' '" + bak + "'; fi"]);
                }
                let reg = loaderRoot.registryOf();
                let needSave = false;
                widgetsModel.clear();
                for (let i = 0; i < data.length; i++) {
                    let item = data[i] || {};
                    let itemId = item.id || item.wId;
                    if (!itemId) {
                        itemId = loaderRoot.uniqueId();
                        needSave = true;
                    }
                    let type = item.type || item.wType || "time";
                    let variant = item.variant || item.wVariant || reg.defaultVariant(type);
                    let defSize = reg.defaultSize(type);
                    let rawX = parseFloat(item.x !== undefined ? item.x : item.wX);
                    let rawY = parseFloat(item.y !== undefined ? item.y : item.wY);
                    let rawW = parseFloat(item.w !== undefined ? item.w : item.wWidth);
                    let rawH = parseFloat(item.h !== undefined ? item.h : item.wHeight);
                    // Clamp against the screen + a 16 px minimum; NaN values
                    // fall back to the type default size / 16. Face-level
                    // fine clamping happens in Widget.updateEffectiveSize().
                    let g = loaderRoot.sanitizeGeometry(rawX, rawY, rawW, rawH, defSize.w, defSize.h);
                    let op = parseFloat(item.opacity !== undefined ? item.opacity : item.wOpacity);
                    let rot = parseFloat(item.rotation !== undefined ? item.rotation : item.wRotation);
                    if (isNaN(rawX) || isNaN(rawY) || isNaN(rawW) || isNaN(rawH)
                        || rawX !== g.x || rawY !== g.y || rawW !== g.w || rawH !== g.h) needSave = true;
                    if (isNaN(op)) {
                        op = 1.0;
                        needSave = true;
                    } else {
                        op = Math.max(0.0, Math.min(1.0, op));
                        if (op !== parseFloat(item.opacity !== undefined ? item.opacity : item.wOpacity)) needSave = true;
                    }
                    if (isNaN(rot)) {
                        rot = 0;
                        needSave = true;
                    }
                    widgetsModel.append({
                        wId: String(itemId),
                        wType: type,
                        wVariant: variant,
                        wX: g.x,
                        wY: g.y,
                        wWidth: g.w,
                        wHeight: g.h,
                        wOpacity: op,
                        wRotation: rot,
                        wImagePath: String(item.imagePath || item.wImagePath || item.path || "")
                    });
                }
                // Persist the cleaned layout right away when anything was
                // normalized (missing ids, NaN/out-of-range values, off-screen
                // geometry) so the state file matches the running model.
                if (needSave) loaderRoot.saveNow();
                loaderRoot.changed();
            }
        }
    }

    // --- window instantiation ------------------------------------------------------
    Instantiator {
        id: widgetInstantiator
        model: widgetsModel
        delegate: Widget {
            screen: loaderRoot.screen
            registry: loaderRoot.registryOf()
            visible: !loaderRoot.isRedacting
            wId: model.wId
            wType: model.wType
            wVariant: model.wVariant
            wX: model.wX
            wY: model.wY
            wWidth: model.wWidth
            wHeight: model.wHeight
            wOpacity: model.wOpacity
            wRotation: model.wRotation
            wImagePath: model.wImagePath
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", loaderRoot.stateDir]);
        loaderRoot.refreshRedactorInfo();
        WidgetSync.registerLoader(loaderRoot);
        loadProcess.running = true;
    }

    Component.onDestruction: {
        WidgetSync.unregisterLoader(loaderRoot);
    }
}
