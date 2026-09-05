import QtQuick

// ============================================================================
// WidgetRegistry — catalog of desktop-widget types, variants and face files.
//
// Deliberately NOT a singleton: each consumer (widgets/Widgets.qml and the
// future redactor) instantiates its own copy, so component caches never leak
// across subsystems. No dependency on I18n/Scaler/reusables/ThemeBackend:
// icons are raw Nerd Font glyphs and labels are plain English.
//
// Types (id -> metadata):
//   visualizer (bars | continuous), time (digital | analog | minimal),
//   music (full | round), weather (compact | full | round),
//   image (rect | rounded | round) — requiresFilePicker.
//
// API:
//   faceFile(type, variant)                       -> resolved URL or ""
//   faceComponent(type, variant)                  -> cached Component or null
//   variantList(type)                             -> [{id, file, icon, label}]
//   typeList()                                    -> [{id, name, icon, ...}]
//   allTypes()                                    -> [typeId, ...]
//   defaultVariant(type)                          -> variant id
//   defaultSize(type)                             -> {w, h}
//   allowsStretchWidth(type)                      -> bool (redactor toolbar)
// ============================================================================

QtObject {
    id: registry

    property var componentCache: ({})

    readonly property var types: ({
        "visualizer": {
            name: "Visualizer",
            icon: "󰎈",
            defaultWidth: 640,
            defaultHeight: 180,
            defaultVariant: "bars",
            stretchWidth: true,
            requiresFilePicker: false,
            variants: {
                "bars": { file: "faces/VisualizerFace.qml", icon: "1", label: "Bars" },
                "continuous": { file: "faces/VisualizerFaceContinuous.qml", icon: "2", label: "Continuous" }
            }
        },
        "time": {
            name: "Clock",
            icon: "󰥔",
            defaultWidth: 250,
            defaultHeight: 120,
            defaultVariant: "digital",
            stretchWidth: true,
            requiresFilePicker: false,
            variants: {
                "digital": { file: "faces/ClockFaceDigital.qml", icon: "1", label: "Digital" },
                "analog": { file: "faces/ClockFaceAnalog.qml", icon: "2", label: "Analog" },
                "minimal": { file: "faces/ClockFaceMinimal.qml", icon: "3", label: "Minimal" }
            }
        },
        "music": {
            name: "Music",
            icon: "󰝚",
            defaultWidth: 340,
            defaultHeight: 120,
            defaultVariant: "full",
            stretchWidth: true,
            requiresFilePicker: false,
            variants: {
                "full": { file: "faces/MusicFace.qml", icon: "1", label: "Full" },
                "round": { file: "faces/MusicFaceRound.qml", icon: "2", label: "Round" }
            }
        },
        "weather": {
            name: "Weather",
            icon: "󰖐",
            // Per-type default that all variants must survive:
            //   compact — free-ish aspect (0.7..2.2), min 90x90; 300x140
            //             (aspect ~2.14) fits inside its maxAspect.
            //   round   — fixed aspect 1: Widget.updateEffectiveSize() clamps
            //             the window to a square at instantiation.
            //   full    — locked aspect 1.6 with min 420x260: the Widget
            //             window clamps up to 420x260 when the variant is
            //             instantiated, so the type default below never needs
            //             to reach the full size itself.
            defaultWidth: 300,
            defaultHeight: 140,
            defaultVariant: "compact",
            stretchWidth: false,
            requiresFilePicker: false,
            variants: {
                "compact": { file: "faces/WeatherFaceCompact.qml", icon: "1", label: "Compact" },
                "full": { file: "faces/WeatherFaceFull.qml", icon: "2", label: "Full" },
                "round": { file: "faces/WeatherFaceRound.qml", icon: "3", label: "Round" }
            }
        },
        "image": {
            name: "Image",
            icon: "󰋩",
            defaultWidth: 300,
            defaultHeight: 200,
            defaultVariant: "rect",
            stretchWidth: false,
            requiresFilePicker: true,
            variants: {
                "rect": { file: "faces/ImageFaceRect.qml", icon: "1", label: "Rect" },
                "rounded": { file: "faces/ImageFaceRounded.qml", icon: "2", label: "Rounded" },
                "round": { file: "faces/ImageFaceRound.qml", icon: "3", label: "Round" }
            }
        }
    })

    // Face file URL for a type+variant (variant falls back to the type default).
    function faceFile(type, variant) {
        let t = registry.types[type];
        if (!t) return "";
        let v = t.variants[variant] || t.variants[t.defaultVariant];
        return v ? Qt.resolvedUrl(v.file) : "";
    }

    // Cached face Component for a type+variant (used by the redactor proxies).
    function faceComponent(type, variant) {
        let t = registry.types[type];
        if (!t) return null;
        let vKey = (variant && t.variants && t.variants[variant]) ? variant : t.defaultVariant;
        let cacheKey = type + "_" + vKey;
        if (registry.componentCache[cacheKey]) {
            return registry.componentCache[cacheKey];
        }
        let fileUrl = registry.faceFile(type, vKey);
        if (!fileUrl) return null;
        let comp = Qt.createComponent(fileUrl);
        if (comp) {
            registry.componentCache[cacheKey] = comp;
        }
        return comp;
    }

    function variantList(type) {
        let t = registry.types[type];
        if (!t || !t.variants) return [];
        return Object.keys(t.variants).map(k => Object.assign({ id: k }, t.variants[k]));
    }

    function typeList() {
        return Object.keys(registry.types).map(k => Object.assign({ id: k }, registry.types[k]));
    }

    // All type ids in catalog order (keyboard iteration order is insertion order).
    function allTypes() {
        return Object.keys(registry.types);
    }

    function defaultVariant(type) {
        return registry.types[type] ? registry.types[type].defaultVariant : "";
    }

    function defaultSize(type) {
        let t = registry.types[type];
        if (!t) return { w: 250, h: 120 };
        return {
            w: t.defaultWidth || 250,
            h: t.defaultHeight || 120
        };
    }

    // Whether the redactor may stretch this type horizontally.
    function allowsStretchWidth(type) {
        let t = registry.types[type];
        return t ? (t.stretchWidth === true) : false;
    }
}
