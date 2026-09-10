// ═══════════════════════════════════════════════════════════════════════════
// SearchIndex.js — índice puro del buscador global del panel Settings.
//
// Migrado de settings/SettingsPopup.qml: el MISMO array de 12 cards (con
// `page` en vez de `tab`, mapeo 0→s_general · 1→s_weather · 2→s_keyboard ·
// 4→s_startup), el matcher label+desc y el matcher de keybinds.
// Añade pageEntries(): los ajustes de las páginas del editor (d_*) para que el
// buscador también los alcance, con una `y` aproximada de scroll (px lógicos;
// el overlay la escala con bar.s()).
// Puro (sin tipos QML) y testeable.
// ═══════════════════════════════════════════════════════════════════════════
.pragma library

// ── Cards de las tabs compartidas de settings (12, mismo orden que el popup) ──
function cards() {
    return [
        { page: "s_general", boxIndex: 0, label: "Guide on startup", desc: "Launch on login", icon: "󰑊", color: "peach" },
        { page: "s_general", boxIndex: 1, label: "Help icon", desc: "Show button in topbar", icon: "󰋖", color: "blue" },
        { page: "s_general", boxIndex: 2, label: "UI Scale", desc: "Base size scalar", icon: "󰁦", color: "sapphire" },
        { page: "s_general", boxIndex: 3, label: "Keyboard layouts", desc: "Matches hyprland.conf", icon: "󰌌", color: "green" },
        { page: "s_general", boxIndex: 4, label: "Layout shortcut", desc: "Toggle combination", icon: "󰯍", color: "teal" },
        { page: "s_general", boxIndex: 5, label: "Wallpaper directory", desc: "Absolute source path", icon: "󰋩", color: "mauve" },
        { page: "s_general", boxIndex: 6, label: "Workspaces", desc: "Static count in topbar", icon: "󰽿", color: "red" },
        { page: "s_weather", boxIndex: 1, label: "API Key", desc: "OpenWeather API key", icon: "󰌆", color: "blue" },
        { page: "s_weather", boxIndex: 2, label: "City ID", desc: "OpenWeather city ID", icon: "󰖐", color: "blue" },
        { page: "s_weather", boxIndex: 3, label: "Temperature Unit", desc: "Celsius / Fahrenheit / K", icon: "󰔄", color: "blue" },
        { page: "s_general", boxIndex: 7, label: "App scale", desc: "Scale GTK / Electron apps", icon: "", color: "sapphire" }
    ];
}

// ── Matcher de cards: substring case-insensitive sobre label + desc
// (port de SettingsPopup.globalSearchMatches). ──
function matches(card, query) {
    if (!query || query.trim() === "") return false;
    let q = query.trim().toLowerCase();
    return String(card.label).toLowerCase().indexOf(q) !== -1
        || String(card.desc).toLowerCase().indexOf(q) !== -1;
}

// ── Entradas de las páginas del editor (grupo Dock/Bar + System). ──
// y = offset aproximado de scroll en px lógicos (0 = arriba / desconocido).
// Iconos: copiados de las páginas reales (dock/editor/*.qml) o de los navGroups
// de BarEditor.qml — no inventar glifos nuevos.
function pageEntries() {
    return [
        // Launcher (d_launcher)
        { page: "d_launcher", label: "Position",          desc: "Launcher position: Center / Top / Bottom / Left / Right", icon: "◎", color: "mauve",    y: 64 },
        { page: "d_launcher", label: "Width",             desc: "Launcher panel width in px",             icon: "↔", color: "blue",     y: 204 },
        { page: "d_launcher", label: "Visible apps",      desc: "Launcher max rows before scrolling",     icon: "󰀻", color: "green",    y: 260 },
        { page: "d_launcher", label: "Margin",            desc: "Launcher screen margin (negative pushes out)", icon: "󰒓", color: "peach",    y: 316 },
        { page: "d_launcher", label: "Row height",        desc: "Launcher app row density in px",         icon: "󰒓", color: "sapphire", y: 372 },
        { page: "d_launcher", label: "Content alignment", desc: "Launcher left / center / right",         icon: "⇤", color: "teal",     y: 800 },
        { page: "d_launcher", label: "Show icons",        desc: "App icons in the launcher list",         icon: "󰈈", color: "mauve",    y: 660 },
        { page: "d_launcher", label: "Avoid bar",         desc: "Keep the launcher clear of the dock/bar", icon: "󰀻", color: "blue",    y: 716 },
        { page: "d_launcher", label: "Borders",           desc: "Launcher border width, radius and color", icon: "󰏘", color: "green",   y: 428 },
        // Hyprland (d_hyprland) — mismos iconos que los sliders de la página
        { page: "d_hyprland", label: "Active opacity",    desc: "Focused window opacity",                 icon: "\uF06E", color: "mauve",    y: 128 },
        { page: "d_hyprland", label: "Inactive opacity",  desc: "Unfocused window opacity",               icon: "\uF070", color: "blue",     y: 184 },
        { page: "d_hyprland", label: "Rounding",          desc: "Window corner radius",                   icon: "\uF192", color: "green",    y: 268 },
        { page: "d_hyprland", label: "Blur size",         desc: "Decoration blur size",                   icon: "\uF0EB", color: "peach",    y: 352 },
        { page: "d_hyprland", label: "Blur passes",       desc: "Decoration blur passes",                 icon: "\uF2C8", color: "sapphire", y: 408 },
        { page: "d_hyprland", label: "Gaps in",           desc: "Gaps between windows",                   icon: "\uF239", color: "mauve",    y: 492 },
        { page: "d_hyprland", label: "Gaps out",          desc: "Gaps to screen edges",                   icon: "\uF7A4", color: "blue",     y: 548 },
        { page: "d_hyprland", label: "Border width",      desc: "Window border size",                     icon: "\uF358", color: "peach",    y: 604 },
        { page: "d_hyprland", label: "Shadow range",      desc: "Shadow size",                            icon: "\uF042", color: "peach",    y: 688 },
        { page: "d_hyprland", label: "Shadow power",      desc: "Shadow strength",                        icon: "\uF0E7", color: "sapphire", y: 744 },
        { page: "d_hyprland", label: "Shadow offsets",    desc: "Shadow offset X / Y",                    icon: "\uF061", color: "mauve",    y: 800 },
        // Idle (d_idle) — iconos de IdlePage
        { page: "d_idle", label: "Auto",                  desc: "hypridle active (auto-dim/lock/suspend)", icon: "󰒲", color: "mauve",   y: 128 },
        { page: "d_idle", label: "Awake",                 desc: "Stops hypridle (manual lock/suspend)",   icon: "󰛓", color: "blue",     y: 128 },
        // GPU (d_gpu) — iconos de GpuPage
        { page: "d_gpu", label: "Integrated",             desc: "Optimus mode: integrated GPU only",      icon: "󰁹", color: "green",    y: 128 },
        { page: "d_gpu", label: "Hybrid",                 desc: "Optimus mode: hybrid (default)",         icon: "󰚰", color: "blue",     y: 128 },
        { page: "d_gpu", label: "NVIDIA",                 desc: "Optimus mode: NVIDIA only",              icon: "󰓅", color: "red",      y: 128 },
        // Animations (d_animations) — iconos de AnimationsPage
        { page: "d_animations", label: "Animations",        desc: "Enable or disable animations",           icon: "\uF0E7", color: "mauve",    y: 70 },
        { page: "d_animations", label: "Animation speed",   desc: "Snappy / Fast / Normal / Slow + fine",   icon: "\uF021", color: "sapphire", y: 150 },
        // Input (d_input) — iconos de InputPage
        { page: "d_input", label: "Sensitivity",           desc: "Pointer sensitivity",                    icon: "\uF245", color: "blue",     y: 70 },
        { page: "d_input", label: "Accel profile",         desc: "Adaptive or flat pointer accel",         icon: "\uF0E7", color: "green",    y: 130 },
        { page: "d_input", label: "Tap to click",          desc: "Touchpad tap click",                     icon: "\uF245", color: "peach",    y: 200 },
        { page: "d_input", label: "Natural scroll",        desc: "Touchpad natural scrolling",             icon: "\uF7A4", color: "mauve",    y: 240 },
        { page: "d_input", label: "Disable while typing",  desc: "Touchpad off while typing",              icon: "\uF11C", color: "sapphire", y: 280 },
        // Notifications (d_notifications)
        { page: "d_notifications", label: "Do Not Disturb", desc: "Silences notification popups",         icon: "󰂛", color: "mauve",    y: 60 },
        // Páginas de barra (resumen; y = 0 → arriba). Iconos = navGroups.
        { page: "d_engine",     label: "Engine",     desc: "Dock or Serpantinum bar",          icon: "󰮯", color: "mauve",    y: 0 },
        { page: "d_position",   label: "Position",   desc: "Bar position on screen",           icon: "󱂬", color: "blue",     y: 0 },
        { page: "d_style",      label: "Style",      desc: "Bar look and window borders",      icon: "󰏘", color: "green",    y: 0 },
        { page: "d_palette",    label: "Palette",    desc: "Shared color palette",             icon: "✦", color: "peach",    y: 0 },
        { page: "d_zones",      label: "Zones",      desc: "Dock zones and modules",           icon: "󰮯", color: "sapphire", y: 0 },
        { page: "d_workspaces", label: "Workspaces", desc: "Empty workspace marker",           icon: "󰠰", color: "teal",     y: 0 },
        { page: "d_serp",       label: "Serp Bar",   desc: "Classic bar sections and actions", icon: "󰹑", color: "mauve",    y: 0 }
    ];
}

// ── Matcher de keybinds (port de SettingsPopup.getMatchingKeybindIndices):
// recibe Config.keybindsData (array de {type,mods,key,dispatcher,command}) y
// devuelve los ÍNDICES que casan con la query. ──
function keybindMatches(cardsData, query) {
    if (!query || query.trim() === "") return [];
    let results = [];
    let data = cardsData || [];
    try {
        let re = new RegExp(query, "i");
        for (let i = 0; i < data.length; i++) {
            let item = data[i];
            if (re.test(item.mods) || re.test(item.key) || re.test(item.dispatcher)
                || re.test(item.command) || re.test(item.type)) {
                results.push(i);
            }
        }
    } catch (e) {
        let q = query.trim().toLowerCase();
        for (let i = 0; i < data.length; i++) {
            let item = data[i];
            if ((item.mods && item.mods.toLowerCase().indexOf(q) !== -1)
                || (item.key && item.key.toLowerCase().indexOf(q) !== -1)
                || (item.dispatcher && item.dispatcher.toLowerCase().indexOf(q) !== -1)
                || (item.command && item.command.toLowerCase().indexOf(q) !== -1)) {
                results.push(i);
            }
        }
    }
    return results;
}
