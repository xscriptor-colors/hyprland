import QtQuick
import Quickshell
import ".."

// ============================================================================
// Widgets — root component of the desktop-widget subsystem.
//
// Instantiated once from Shell.qml (after Floating). Creates one shared
// WidgetRegistry and one WidgetLoader per screen through Variants; each
// loader self-registers with the WidgetSync singleton and manages the
// persisted layout of its own screen (~/.local/state/quickshell/widgets/).
// ============================================================================

Item {
    id: widgetsRoot

    // Shared catalog instance (WidgetLoader delegates read face files/sizes
    // from here; the redactor creates its own copy later).
    WidgetRegistry {
        id: registry
    }

    // Reference to the editing bus (convenience for shell-level wiring).
    readonly property var sync: WidgetSync

    // Screen geometry helper for redactor/callers that need physical bounds.
    function geometryForScreen(screen) {
        let s = screen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
        if (!s) return { x: 0, y: 0, width: 1920, height: 1080 };
        return {
            x: s.x !== undefined ? s.x : 0,
            y: s.y !== undefined ? s.y : 0,
            width: s.width !== undefined ? s.width : 1920,
            height: s.height !== undefined ? s.height : 1080
        };
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            WidgetLoader {
                required property var modelData
                screen: modelData
                registry: registry
            }
        }
    }
}
