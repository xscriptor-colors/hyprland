// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/lib — constants
//
// Pure data shared by the picker UI: filter definitions, xwww transitions and
// the filter cycling order. No QML context, no side effects.
// ═══════════════════════════════════════════════════════════════════════════
.pragma library

var FILTERS = [
    { name: "All", hex: "", label: "All" },
    { name: "Video", hex: "", label: "Vid" },
    { name: "Favorites", hex: "", label: "\uF005" },
    { name: "Red", hex: "#FF4500", label: "" },
    { name: "Orange", hex: "#FFA500", label: "" },
    { name: "Yellow", hex: "#FFD700", label: "" },
    { name: "Green", hex: "#32CD32", label: "" },
    { name: "Blue", hex: "#1E90FF", label: "" },
    { name: "Purple", hex: "#8A2BE2", label: "" },
    { name: "Pink", hex: "#FF69B4", label: "" },
    { name: "Monochrome", hex: "#A9A9A9", label: "" },
    { name: "Search", hex: "", label: "Search" }
];

var TRANSITIONS = ["simple", "fade", "left", "right", "top", "bottom", "wipe", "grow", "center", "outer", "random", "wave", "glitch", "decrypt", "dissolve", "clock", "zoom"];

var FILTER_ORDER = ["All", "Video", "Favorites", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Monochrome"];

// Modos de vista + slideshow.
var ORIENTATIONS = ["horizontal", "vertical"];
var SHAPES = ["rect", "square", "circle"];
var SLIDESHOW_INTERVAL = 300;

// Fuentes de búsqueda (proveedor del kernel + etiqueta + tipo).
var SEARCH_SOURCES = [
    { id: "ddg", label: "DDG", kind: "image" },
    { id: "wallhaven", label: "WH", kind: "image" },
    { id: "pexels", label: "PEX", kind: "video" },
    { id: "pixabay", label: "PIX", kind: "video" }
];
