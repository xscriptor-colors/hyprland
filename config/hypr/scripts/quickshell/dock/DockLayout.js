.pragma library

// ============================================================================
// DockLayout — generic, position-agnostic dock engine.
//
// The bar is now a "dock": a set of ZONES laid out along the dock's main axis
// (start → center → end). Zones are pure data — adding / renaming / removing /
// re-aligning a zone is a JSON edit, never a code change. Each zone carries
// its own visual options (unify, border) so new zones get full styling for
// free.
//
//   dock: {
//     position: "top" | "bottom" | "left" | "right",
//     palette:  "x",
//     thickness: 48,          // height (top/bottom) or width (left/right)
//     edgeGap: 8,             // distance from the screen edge
//     roundness: 1.0,
//     pillBg: true,
//     pillSolid: false,
//     borderWidth: 0, borderColor: "surface1",
//     zones: [
//       { id, align: "start"|"center"|"end",
//         unify: false, borderWidth: 0, borderColor: "surface1",
//         modules: [ { id, enabled }, ... ] }
//     ]
//   }
//
// Legacy "topbar" settings (the old {left, center, right} model) are migrated
// automatically on first load.
// ============================================================================

// --- module catalog (keep in sync with the modules under topbar/modules/) -----
var MODULES = [
    { id: "help",       label: "Help",        icon: "󰅖", component: "topbar/modules/HelpModule.qml" },
    { id: "search",     label: "Search",      icon: "󰍉", component: "topbar/modules/SearchModule.qml" },
    { id: "settings",   label: "Settings",    icon: "",  component: "topbar/modules/SettingsModule.qml" },
    { id: "update",     label: "Updates",     icon: "󰚰", component: "topbar/modules/UpdateModule.qml" },
    { id: "time",       label: "Clock",       icon: "󰅐", component: "topbar/modules/TimeModule.qml" },
    { id: "date",       label: "Date",        icon: "󰃭", component: "topbar/modules/DateModule.qml" },
    { id: "media",      label: "Media",       icon: "󰎈", component: "topbar/modules/MediaModule.qml" },
    { id: "workspaces", label: "Workspaces",  icon: "󰽿", component: "topbar/modules/WorkspacesModule.qml" },
    { id: "tray",       label: "System tray", icon: "󱊖", component: "topbar/modules/TrayModule.qml" },
    { id: "keyboard",   label: "Keyboard",    icon: "󰌌", component: "topbar/modules/KeyboardModule.qml" },
    { id: "wifi",       label: "Network",     icon: "󰤨", component: "topbar/modules/WifiModule.qml" },
    { id: "bluetooth",  label: "Bluetooth",   icon: "󰂯", component: "topbar/modules/BluetoothModule.qml" },
    { id: "sysmon",     label: "Resources",   icon: "󰍛", component: "topbar/modules/SysmonModule.qml" },
    { id: "volume",     label: "Volume",      icon: "󰕾", component: "topbar/modules/VolumeModule.qml" },
    { id: "battery",    label: "Battery",     icon: "󰁹", component: "topbar/modules/BatteryModule.qml" },
    { id: "recording",  label: "Recording",   icon: "",  component: "topbar/modules/RecordingModule.qml" }
];

var POSITIONS = ["top", "bottom", "left", "right"];
var ALIGNS = ["start", "center", "end"];

// Arrays that cross the QML <-> JS boundary through `property var` can arrive
// as QVariantList, which breaks `Array.isArray`. Length-based checks are safe.
function isList(x) {
    return x !== null && x !== undefined && typeof x.length === "number";
}

function getModule(id) {
    for (let i = 0; i < MODULES.length; i++) {
        if (MODULES[i].id === id) return MODULES[i];
    }
    return null;
}

function cloneModules(list) {
    let out = [];
    if (!isList(list)) return out;
    for (let i = 0; i < list.length; i++) {
        let e = list[i];
        if (typeof e === "string") out.push({ id: e, enabled: true });
        else if (e && e.id) out.push({ id: e.id, enabled: e.enabled !== false });
    }
    return out;
}

// --- defaults -------------------------------------------------------------------
function defaultZone(id, align, modules) {
    return {
        id: id,
        align: align,
        unify: false,
        borderWidth: 0,
        borderColor: "surface1",
        modules: cloneModules(modules || [])
    };
}

function defaultDock() {
    let zones = [];
    for (let i = 0; i < ALIGNS.length; i++) {
        let align = ALIGNS[i];
        let mods = [];
        for (let m = 0; m < MODULES.length; m++) {
            // workspaces is the only center module historically; split the rest
            // left/right by catalog order.
            if (align === "center" && MODULES[m].id === "workspaces") mods.push(MODULES[m].id);
            else if (align === "start" && ["help","search","settings","update","time","date","media"].indexOf(MODULES[m].id) !== -1) mods.push(MODULES[m].id);
            else if (align === "end" && ["tray","keyboard","wifi","bluetooth","sysmon","volume","battery","recording"].indexOf(MODULES[m].id) !== -1) mods.push(MODULES[m].id);
        }
        zones.push(defaultZone(align, align, mods));
    }
    return {
        position: "top",
        palette: "x",
        thickness: 48,
        edgeGap: 8,
        roundness: 1.0,
        pillBg: true,
        pillSolid: false,
        borderWidth: 0,
        borderColor: "surface1",
        zones: zones
    };
}

// --- normalization ---------------------------------------------------------------
// Turns whatever sits under settings.json's "dock" key into a safe, complete
// config. Unknown zone/module ids are dropped; missing zones/modules are re-added
// from the catalog so nothing silently disappears.
function normalizeDock(raw) {
    let def = defaultDock();
    if (!raw || typeof raw !== "object") return def;

    let out = {
        position: POSITIONS.indexOf(raw.position) !== -1 ? raw.position : def.position,
        palette: (raw.palette && String(raw.palette).trim() !== "") ? String(raw.palette).toLowerCase() : def.palette,
        thickness: (typeof raw.thickness === "number" && raw.thickness >= 24) ? raw.thickness : def.thickness,
        edgeGap: (typeof raw.edgeGap === "number" && raw.edgeGap >= 0) ? raw.edgeGap : def.edgeGap,
        roundness: (typeof raw.roundness === "number") ? Math.max(0, Math.min(1, raw.roundness)) : def.roundness,
        pillBg: raw.pillBg !== undefined ? (raw.pillBg === true) : def.pillBg,
        pillSolid: raw.pillSolid !== undefined ? (raw.pillSolid === true) : def.pillSolid,
        borderWidth: (typeof raw.borderWidth === "number") ? raw.borderWidth : def.borderWidth,
        borderColor: (typeof raw.borderColor === "string" && raw.borderColor !== "") ? raw.borderColor : def.borderColor,
        zones: []
    };

    let seen = {};
    let list = isList(raw.zones) ? raw.zones : [];
    for (let i = 0; i < list.length; i++) {
        let z = list[i];
        if (!z || typeof z !== "object" || !z.id || seen[z.id]) continue;
        seen[z.id] = true;
        out.zones.push(defaultZone(
            z.id,
            ALIGNS.indexOf(z.align) !== -1 ? z.align : (z.align || "start"),
            z.modules
        ));
        let zi = out.zones.length - 1;
        out.zones[zi].unify = z.unify === true;
        out.zones[zi].borderWidth = (typeof z.borderWidth === "number") ? z.borderWidth : out.borderWidth;
        out.zones[zi].borderColor = (typeof z.borderColor === "string" && z.borderColor !== "") ? z.borderColor : out.borderColor;
        // drop unknown / duplicate module ids
        let clean = [];
        let mseen = {};
        for (let m = 0; m < out.zones[zi].modules.length; m++) {
            let mid = out.zones[zi].modules[m].id;
            if (!getModule(mid) || mseen[mid]) continue;
            mseen[mid] = true;
            clean.push(out.zones[zi].modules[m]);
        }
        out.zones[zi].modules = clean;
    }

    // Re-add any catalog module missing from the config so it never silently
    // vanishes from the user's bar after an update.
    let allSeen = {};
    for (let z = 0; z < out.zones.length; z++) {
        for (let m = 0; m < out.zones[z].modules.length; m++) allSeen[out.zones[z].modules[m].id] = true;
    }
    let missingByAlign = { "start": [], "center": [], "end": [] };
    for (let m = 0; m < MODULES.length; m++) {
        if (allSeen[MODULES[m].id]) continue;
        if (MODULES[m].id === "workspaces") missingByAlign["center"].push(MODULES[m].id);
        else if (["help","search","settings","update","time","date","media"].indexOf(MODULES[m].id) !== -1) missingByAlign["start"].push(MODULES[m].id);
        else missingByAlign["end"].push(MODULES[m].id);
    }
    for (let align in missingByAlign) {
        if (missingByAlign[align].length === 0) continue;
        let target = null;
        for (let z = 0; z < out.zones.length; z++) {
            if (out.zones[z].align === align) { target = z; break; }
        }
        if (target === null) {
            out.zones.push(defaultZone(align, align, missingByAlign[align]));
        } else {
            for (let m = 0; m < missingByAlign[align].length; m++) {
                out.zones[target].modules.push({ id: missingByAlign[align][m], enabled: true });
            }
        }
    }

    return out;
}

// --- legacy migration --------------------------------------------------------------
// Old settings.json "topbar" = { left, center, right } + topbarBorder*/Unify*/Roundness.
function migrateFromTopbar(raw) {
    if (!raw || typeof raw.topbar !== "object") return null;

    let t = raw.topbar;
    let zoneOrder = ["left", "center", "right"];
    let alignOf = { "left": "start", "center": "center", "right": "end" };
    let zones = [];
    for (let i = 0; i < zoneOrder.length; i++) {
        let key = zoneOrder[i];
        let entries = isList(t[key]) ? t[key] : [];
        let mods = [];
        for (let m = 0; m < entries.length; m++) {
            let e = entries[m];
            let id = (typeof e === "string") ? e : (e ? e.id : "");
            if (id && getModule(id)) mods.push({ id: id, enabled: e && e.enabled !== false });
        }
        let cap = key.charAt(0).toUpperCase() + key.slice(1);
        zones.push(defaultZone(key, alignOf[key] || "start", mods));
        let zi = zones.length - 1;
        zones[zi].unify = raw["topbarUnify" + cap] === true;
        zones[zi].borderWidth = (typeof raw["topbarBorderWidth" + cap] === "number") ? raw["topbarBorderWidth" + cap] : 0;
        zones[zi].borderColor = (typeof raw["topbarBorderColor" + cap] === "string") ? raw["topbarBorderColor" + cap] : "surface1";
    }

    return {
        position: "top",
        palette: "x",
        thickness: 48,
        edgeGap: 8,
        roundness: (typeof raw.topbarRoundness === "number") ? raw.topbarRoundness : 1.0,
        pillBg: raw.topbarPillBg !== undefined ? raw.topbarPillBg === true : true,
        pillSolid: raw.topbarPillSolid !== undefined ? raw.topbarPillSolid === true : false,
        borderWidth: (typeof raw.topbarBorderWidth === "number") ? raw.topbarBorderWidth : 0,
        borderColor: (typeof raw.topbarBorderColor === "string") ? raw.topbarBorderColor : "surface1",
        zones: zones
    };
}

// Main entry: raw = parsed settings.json. Returns a complete dock config.
function getDock(raw) {
    if (raw && typeof raw.dock === "object" && raw.dock !== null) return normalizeDock(raw.dock);
    let migrated = migrateFromTopbar(raw);
    return migrated ? normalizeDock(migrated) : defaultDock();
}

// --- zone helpers ------------------------------------------------------------------
function zoneIndex(dock, zoneId) {
    if (!dock || !isList(dock.zones)) return -1;
    for (let i = 0; i < dock.zones.length; i++) {
        if (dock.zones[i] && dock.zones[i].id === zoneId) return i;
    }
    return -1;
}

function zoneModel(zone) {
    let out = [];
    if (!zone || !isList(zone.modules)) return out;
    for (let i = 0; i < zone.modules.length; i++) {
        if (zone.modules[i] && zone.modules[i].enabled) out.push(zone.modules[i].id);
    }
    return out;
}

function isEnabled(dock, id) {
    if (!dock || !isList(dock.zones)) return false;
    for (let z = 0; z < dock.zones.length; z++) {
        let zone = dock.zones[z];
        if (!zone || !isList(zone.modules)) continue;
        for (let m = 0; m < zone.modules.length; m++) {
            if (zone.modules[m] && zone.modules[m].id === id) return zone.modules[m].enabled === true;
        }
    }
    return false;
}

// Pure helpers — always return a new object, never mutate the input.
function cloneDock(dock) {
    let out = JSON.parse(JSON.stringify(dock));
    return out;
}

function setEnabled(dock, id, value) {
    let out = cloneDock(dock);
    for (let z = 0; z < out.zones.length; z++) {
        for (let m = 0; m < out.zones[z].modules.length; m++) {
            if (out.zones[z].modules[m].id === id) out.zones[z].modules[m].enabled = value === true;
        }
    }
    return out;
}

function toggleEnabled(dock, id) {
    return setEnabled(dock, id, !isEnabled(dock, id));
}

// Move a module by delta slots inside its zone; at a zone edge hop into the
// neighbouring zone (ordered by alignment order start → center → end).
function moduleMove(dock, id, delta) {
    let out = cloneDock(dock);
    let zi = -1, idx = -1;
    for (let z = 0; z < out.zones.length && zi === -1; z++) {
        for (let m = 0; m < out.zones[z].modules.length; m++) {
            if (out.zones[z].modules[m].id === id) { zi = z; idx = m; break; }
        }
    }
    if (zi === -1) return out;

    let mods = out.zones[zi].modules;
    let next = idx + delta;
    if (next >= 0 && next < mods.length) {
        let tmp = mods[idx];
        mods[idx] = mods[next];
        mods[next] = tmp;
        return out;
    }

    // hop to the neighbouring zone
    let ordered = [];
    for (let z = 0; z < out.zones.length; z++) ordered.push(z);
    ordered.sort((a, b) => ALIGNS.indexOf(out.zones[a].align) - ALIGNS.indexOf(out.zones[b].align));
    let ziOrder = ordered.indexOf(zi);
    let tzOrder = ziOrder + delta;
    if (tzOrder < 0 || tzOrder >= ordered.length) return out;
    let tz = ordered[tzOrder];
    let entry = mods.splice(idx, 1)[0];
    if (delta > 0) out.zones[tz].modules.unshift(entry);
    else out.zones[tz].modules.push(entry);
    return out;
}

// --- zone CRUD (used by the settings editor) ---------------------------------------
function addZone(dock, align, afterZoneId) {
    let out = cloneDock(dock);
    let id = "zone" + (Date.now() % 100000);
    let zi = zoneIndex(out, afterZoneId);
    let z = defaultZone(id, ALIGNS.indexOf(align) !== -1 ? align : "start", []);
    if (zi === -1) out.zones.push(z);
    else out.zones.splice(zi + 1, 0, z);
    return out;
}

function removeZone(dock, zoneId) {
    let out = cloneDock(dock);
    if (out.zones.length <= 1) return out; // keep at least one zone
    let zi = zoneIndex(out, zoneId);
    if (zi === -1) return out;
    // move orphaned modules to the first zone instead of dropping them
    let orphans = out.zones[zi].modules;
    out.zones.splice(zi, 1);
    if (orphans.length > 0 && out.zones.length > 0) {
        out.zones[0].modules = out.zones[0].modules.concat(orphans);
    }
    return out;
}

function renameZone(dock, zoneId, newId) {
    let out = cloneDock(dock);
    let zi = zoneIndex(out, zoneId);
    if (zi === -1) return out;
    let clean = String(newId || "").trim().toLowerCase().replace(/[^a-z0-9_-]/g, "");
    if (clean === "" || zoneIndex(out, clean) !== -1) return out;
    out.zones[zi].id = clean;
    return out;
}

function setZoneAlign(dock, zoneId, align) {
    let out = cloneDock(dock);
    let zi = zoneIndex(out, zoneId);
    if (zi === -1 || ALIGNS.indexOf(align) === -1) return out;
    out.zones[zi].align = align;
    return out;
}

function setZoneUnify(dock, zoneId, value) {
    let out = cloneDock(dock);
    let zi = zoneIndex(out, zoneId);
    if (zi === -1) return out;
    out.zones[zi].unify = value === true;
    return out;
}

function setZoneBorder(dock, zoneId, width, color) {
    let out = cloneDock(dock);
    let zi = zoneIndex(out, zoneId);
    if (zi === -1) return out;
    if (typeof width === "number") out.zones[zi].borderWidth = width;
    if (typeof color === "string" && color !== "") out.zones[zi].borderColor = color;
    return out;
}

// Flat list of every module for the settings editor, tagged with zone info.
function flatten(dock) {
    let out = [];
    if (!dock || !isList(dock.zones)) return out;
    for (let z = 0; z < dock.zones.length; z++) {
        let zone = dock.zones[z];
        if (!zone || !isList(zone.modules)) continue;
        for (let m = 0; m < zone.modules.length; m++) {
            let mod = getModule(zone.modules[m].id);
            if (!mod) continue;
            out.push({
                id: mod.id, label: mod.label, icon: mod.icon,
                zone: zone.id, zoneAlign: zone.align,
                enabled: zone.modules[m].enabled === true,
                isFirst: m === 0, isLast: m === zone.modules.length - 1
            });
        }
    }
    return out;
}
