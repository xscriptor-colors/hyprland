// ═══════════════════════════════════════════════════════════════════════════
// LauncherLayout.js — geometría pura del widget applauncher (SUPER+D).
//
// El launcher es configurable desde el panel del editor (settings.json key
// "launcher"): posición (center/top/bottom/left/right), ancho, nº de apps
// visibles y margen, con anti-solape opcional contra la barra (dock).
//
// Todas las funciones son puras (sin tipos QML) y testeables con node:
//   defaults()                       → configuración por defecto
//   normalize(raw)                   → clamps + keys desconocidas ignoradas
//   panelSize(cfg, scale, count)     → tamaño del panel para N apps
//   geometry(cfg, screenW, screenH, panelW, panelH, scale, dock)
//                                    → x/y/w/h + dirección de la intro
// ═══════════════════════════════════════════════════════════════════════════
.pragma library

var POSITIONS = ["center", "top", "bottom", "left", "right"];

// ── Configuración por defecto ─────────────────────────────────────────────
// center + 800px + 8 apps + 24px de margen + evitar la barra.
function defaults() {
    return { position: "center", width: 800, maxApps: 8, margin: 24, avoidBar: true, showIcons: true };
}

function _clamp(v, lo, hi) {
    return Math.min(hi, Math.max(lo, v));
}

// ── Normalización ─────────────────────────────────────────────────────────
// Acepta cualquier objeto (o null) y devuelve SIEMPRE una config válida:
//   position ∈ {center,top,bottom,left,right}
//   width    480..1600   · maxApps 4..20 · margin 0..200 · avoidBar bool
// Keys desconocidas se ignoran; valores no numéricos caen a los defaults.
function normalize(raw) {
    var d = defaults();
    if (!raw || typeof raw !== "object") return d;

    var pos = String(raw.position === undefined ? d.position : raw.position);
    if (POSITIONS.indexOf(pos) === -1) pos = d.position;

    var width = Number(raw.width);
    if (!isFinite(width)) width = d.width;
    var maxApps = Number(raw.maxApps);
    if (!isFinite(maxApps)) maxApps = d.maxApps;
    var margin = Number(raw.margin);
    if (!isFinite(margin)) margin = d.margin;

    return {
        position: pos,
        width: _clamp(Math.round(width), 480, 1600),
        maxApps: _clamp(Math.round(maxApps), 4, 20),
        margin: _clamp(Math.round(margin), 0, 200),
        avoidBar: raw.avoidBar === undefined ? d.avoidBar : !!raw.avoidBar,
        // Solo se acepta un booleano real; cualquier otra cosa cae al default.
        showIcons: typeof raw.showIcons === "boolean" ? raw.showIcons : d.showIcons
    };
}

// ── Tamaño del panel ──────────────────────────────────────────────────────
// Réplica exacta del cálculo histórico del widget (search 65 + separador 1 +
// márgenes 20 + filas de 60 con spacing 4), ahora limitado por cfg.maxApps.
//   w = ancho configurado · h = search + sep + márgenes + lista
function panelSize(cfg, scale, count) {
    var r = Math.round;
    var itemH = r(60 * scale);
    var spacing = r(4 * scale);
    var searchH = r(65 * scale);
    var sep = r(1 * scale);

    var n = Math.max(0, Math.floor(count || 0));
    var listH = n === 0 ? 0
        : Math.min(n * itemH + (n - 1) * spacing,
                   cfg.maxApps * itemH + (cfg.maxApps - 1) * spacing);
    var margins = n > 0 ? r(20 * scale) : 0;

    return { w: r(cfg.width * scale), h: searchH + sep + margins + listH };
}

// ── Geometría en pantalla ─────────────────────────────────────────────────
// Calcula la caja del morph (x/y/w/h) según la posición, con:
//   · margen cfg.margin escalado,
//   · anti-solape: si cfg.avoidBar y la barra está en ese lado, se suma
//     (thickness + edgeGap) del dock,
//   · clamps para que la caja nunca salga de la pantalla,
//   · searchAtBottom (la barra de búsqueda va abajo en modo bottom),
//   · origin = extremo del que "sale" el panel (para el transformOrigin de la
//     escala de entrada: top/bottom/left/right/center),
//   · slideX/slideY = offset de entrada para la intro direccional.
// En "center" el eje Y se calcula con el alto histórico de 700px para
// preservar exactamente la posición actual por defecto.
function geometry(cfg, screenW, screenH, panelW, panelH, scale, dock) {
    var r = Math.round;
    var d = dock || {};
    var thickness = (d.thickness === undefined || d.thickness === null) ? 48 : d.thickness;
    var edgeGap = (d.edgeGap === undefined || d.edgeGap === null) ? 8 : d.edgeGap;

    function barOffset(side) {
        return (cfg.avoidBar && d.position === side) ? r((thickness + edgeGap) * scale) : 0;
    }

    var m = r(cfg.margin * scale);
    var slide = r(90 * scale);

    var out = {
        x: 0, y: 0,
        w: panelW, h: panelH,
        searchAtBottom: false,
        origin: "center",
        slideX: 0,
        slideY: 0
    };

    if (cfg.position === "top") {
        out.x = r((screenW - panelW) / 2);
        out.y = m + barOffset("top");
        out.origin = "top";
        out.slideY = -slide;
    } else if (cfg.position === "bottom") {
        out.x = r((screenW - panelW) / 2);
        out.y = screenH - panelH - m - barOffset("bottom");
        out.searchAtBottom = true;
        out.origin = "bottom";
        out.slideY = slide;
    } else if (cfg.position === "left") {
        out.x = m + barOffset("left");
        out.y = r((screenH - panelH) / 2);
        out.origin = "left";
        out.slideX = -slide;
    } else if (cfg.position === "right") {
        out.x = screenW - panelW - m - barOffset("right");
        out.y = r((screenH - panelH) / 2);
        out.origin = "right";
        out.slideX = slide;
    } else {
        // center (default): X centrado, Y como la caja histórica de 700px.
        out.x = r((screenW - panelW) / 2);
        out.y = r((screenH - r(700 * scale)) / 2);
        out.origin = "center";
        out.slideY = -slide;
    }

    out.x = _clamp(out.x, 0, Math.max(0, screenW - panelW));
    out.y = _clamp(out.y, 0, Math.max(0, screenH - panelH));
    return out;
}
