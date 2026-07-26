.pragma library

// Canonical catalog of every topbar module.
// The array order combined with `zone` defines the factory default layout, which
// reproduces the bar exactly as it was before it became user-configurable.
// `label` and `icon` are only consumed by the settings panel module list.
var MODULES = [
    { id: "help",       label: "Help",        icon: "󰅖", zone: "left",   component: "topbar/modules/HelpModule.qml" },
    { id: "search",     label: "Search",      icon: "󰍉", zone: "left",   component: "topbar/modules/SearchModule.qml" },
    { id: "settings",   label: "Settings",    icon: "",  zone: "left",   component: "topbar/modules/SettingsModule.qml" },
    { id: "update",     label: "Updates",     icon: "󰚰", zone: "left",   component: "topbar/modules/UpdateModule.qml" },
    { id: "time",       label: "Clock",       icon: "󰅐", zone: "left",   component: "topbar/modules/TimeModule.qml" },
    { id: "date",       label: "Date",        icon: "󰃭", zone: "left",   component: "topbar/modules/DateModule.qml" },
    { id: "media",      label: "Media",       icon: "󰎈", zone: "left",   component: "topbar/modules/MediaModule.qml" },
    { id: "workspaces", label: "Workspaces",  icon: "󰽿", zone: "center", component: "topbar/modules/WorkspacesModule.qml" },
    { id: "tray",       label: "System tray", icon: "󱊖", zone: "right",  component: "topbar/modules/TrayModule.qml" },
    { id: "keyboard",   label: "Keyboard",    icon: "󰌌", zone: "right",  component: "topbar/modules/KeyboardModule.qml" },
    { id: "wifi",       label: "Network",     icon: "󰤨", zone: "right",  component: "topbar/modules/WifiModule.qml" },
    { id: "bluetooth",  label: "Bluetooth",   icon: "󰂯", zone: "right",  component: "topbar/modules/BluetoothModule.qml" },
    { id: "sysmon",     label: "Resources",   icon: "󰍛", zone: "right",  component: "topbar/modules/SysmonModule.qml" },
    { id: "volume",     label: "Volume",      icon: "󰕾", zone: "right",  component: "topbar/modules/VolumeModule.qml" },
    { id: "battery",    label: "Battery",     icon: "󰁹", zone: "right",  component: "topbar/modules/BatteryModule.qml" },
    { id: "recording",  label: "Recording",   icon: "",  zone: "right",  component: "topbar/modules/RecordingModule.qml" }
];

var ZONES = ["left", "center", "right"];

function getModule(id) {
    for (let i = 0; i < MODULES.length; i++) {
        if (MODULES[i].id === id) return MODULES[i];
    }
    return null;
}

function defaultLayout() {
    let out = { left: [], center: [], right: [] };
    for (let i = 0; i < MODULES.length; i++) {
        out[MODULES[i].zone].push({ id: MODULES[i].id, enabled: true });
    }
    return out;
}

// Turns whatever sits under settings.json's "topbar" key into a layout that is
// always safe to render: known ids only, no duplicates, every zone present.
function normalize(raw) {
    if (!raw || typeof raw !== "object") return defaultLayout();

    // Accept the current shape ({left: [{id, enabled}]}) and also a nested
    // "layout" object holding plain id strings, so hand-written or older
    // settings.json files keep working instead of blanking the bar.
    let src = (raw.layout !== undefined && typeof raw.layout === "object") ? raw.layout : raw;

    let out = { left: [], center: [], right: [] };
    let seen = {};

    for (let z = 0; z < ZONES.length; z++) {
        let zone = ZONES[z];
        let entries = Array.isArray(src[zone]) ? src[zone] : [];
        for (let i = 0; i < entries.length; i++) {
            let entry = entries[i];
            let id = (typeof entry === "string") ? entry : (entry ? entry.id : "");
            if (!id || seen[id] || !getModule(id)) continue;
            seen[id] = true;
            out[zone].push({
                id: id,
                enabled: (entry && entry.enabled !== undefined) ? (entry.enabled === true) : true
            });
        }
    }

    // Modules missing from the file (fresh install, or added by an update) fall
    // back to their catalog zone so they never silently vanish from the bar.
    for (let i = 0; i < MODULES.length; i++) {
        if (!seen[MODULES[i].id]) {
            out[MODULES[i].zone].push({ id: MODULES[i].id, enabled: true });
        }
    }

    return out;
}

// Repeater model for a zone: enabled module ids, in user order.
function zoneModel(layout, zone) {
    let out = [];
    let entries = (layout && Array.isArray(layout[zone])) ? layout[zone] : [];
    for (let i = 0; i < entries.length; i++) {
        if (entries[i].enabled) out.push(entries[i].id);
    }
    return out;
}

function zoneOf(layout, id) {
    for (let z = 0; z < ZONES.length; z++) {
        let entries = (layout && Array.isArray(layout[ZONES[z]])) ? layout[ZONES[z]] : [];
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === id) return ZONES[z];
        }
    }
    return "";
}

// =============================================================================
// Mutation helpers used by the settings panel. All pure: they return a new
// layout and never touch the argument.
// =============================================================================

function clone(layout) {
    let out = { left: [], center: [], right: [] };
    for (let z = 0; z < ZONES.length; z++) {
        let entries = (layout && Array.isArray(layout[ZONES[z]])) ? layout[ZONES[z]] : [];
        for (let i = 0; i < entries.length; i++) {
            out[ZONES[z]].push({ id: entries[i].id, enabled: entries[i].enabled === true });
        }
    }
    return out;
}

// Flat left -> center -> right list backing the settings panel list view.
function flatten(layout) {
    let out = [];
    for (let z = 0; z < ZONES.length; z++) {
        let zone = ZONES[z];
        let entries = (layout && Array.isArray(layout[zone])) ? layout[zone] : [];
        for (let i = 0; i < entries.length; i++) {
            let mod = getModule(entries[i].id);
            if (!mod) continue;
            out.push({
                id: mod.id, label: mod.label, icon: mod.icon, zone: zone,
                enabled: entries[i].enabled === true,
                isFirst: i === 0, isLast: i === entries.length - 1
            });
        }
    }
    return out;
}

function isEnabled(layout, id) {
    for (let z = 0; z < ZONES.length; z++) {
        let entries = (layout && Array.isArray(layout[ZONES[z]])) ? layout[ZONES[z]] : [];
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === id) return entries[i].enabled === true;
        }
    }
    return false;
}

function setEnabled(layout, id, value) {
    let out = clone(layout);
    for (let z = 0; z < ZONES.length; z++) {
        for (let i = 0; i < out[ZONES[z]].length; i++) {
            if (out[ZONES[z]][i].id === id) out[ZONES[z]][i].enabled = value === true;
        }
    }
    return out;
}

function toggleEnabled(layout, id) {
    return setEnabled(layout, id, !isEnabled(layout, id));
}

// Moves a module one slot inside its zone. At a zone edge it hops into the
// neighbouring zone instead, so every position is reachable with two keys.
function move(layout, id, delta) {
    let out = clone(layout);
    let zi = -1, idx = -1;
    for (let z = 0; z < ZONES.length && zi === -1; z++) {
        for (let i = 0; i < out[ZONES[z]].length; i++) {
            if (out[ZONES[z]][i].id === id) { zi = z; idx = i; break; }
        }
    }
    if (zi === -1) return out;

    let zone = out[ZONES[zi]];
    let next = idx + delta;
    if (next >= 0 && next < zone.length) {
        let tmp = zone[idx];
        zone[idx] = zone[next];
        zone[next] = tmp;
        return out;
    }

    let tz = zi + delta;
    if (tz < 0 || tz >= ZONES.length) return out;
    let entry = zone.splice(idx, 1)[0];
    if (delta > 0) out[ZONES[tz]].unshift(entry);
    else out[ZONES[tz]].push(entry);
    return out;
}
