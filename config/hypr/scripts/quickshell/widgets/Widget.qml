import QtQuick
import Quickshell
import Quickshell.Wayland

// ============================================================================
// Widget — one floating desktop widget (Phase W3).
//
// A transparent, non-focusable PanelWindow on the Bottom layer, anchored to
// the screen's top-left corner through animated margins (x/y), hosting the
// selected face through a Loader. Window size follows the effective size
// produced by updateEffectiveSize(), which clamps the requested size with the
// loaded face's declared constraints (minWidth/maxWidth/minHeight/maxHeight/
// minAspect/maxAspect) — same algorithm as serpantinum widgets/Widget.qml.
//
// Visibility contract for faces: while the redactor is editing this screen,
// WidgetLoader sets visible:false on the window. Faces that need to pause
// work (timers, Cava consumers) declare `property bool windowShown: true`;
// the loader binds it to the window visibility (see faceLoader.onLoaded).
// ============================================================================

PanelWindow {
    id: root
    color: "transparent"

    property string wId: "0"
    property string wType: "time"
    property string wVariant: "digital"
    property string wImagePath: ""
    property real wX: 0
    property real wY: 0
    property real wWidth: 250
    property real wHeight: 120
    property real wOpacity: 1.0
    property real wRotation: 0
    // WidgetRegistry instance shared by the loader (face file lookup).
    property var registry: null

    property real animX: wX
    property real animY: wY
    Behavior on animX { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    Behavior on animY { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    property real effectiveWidth: wWidth
    property real effectiveHeight: wHeight

    onWWidthChanged: updateEffectiveSize()
    onWHeightChanged: updateEffectiveSize()
    onWVariantChanged: updateEffectiveSize()
    onWTypeChanged: updateEffectiveSize()

    WlrLayershell.namespace: "qs-widget-" + wType + "-" + wId
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    focusable: false

    anchors.top: true
    anchors.left: true
    margins.left: animX
    margins.top: animY

    implicitWidth: (Math.round(wRotation || 0) % 180 === 0) ? effectiveWidth : effectiveHeight
    implicitHeight: (Math.round(wRotation || 0) % 180 === 0) ? effectiveHeight : effectiveWidth

    Component.onDestruction: visible = false

    function registryOf() {
        if (!root.registry) {
            // Standalone fallback (same pattern as WidgetLoader).
            root.registry = Qt.createComponent("WidgetRegistry.qml").createObject(root);
        }
        return root.registry;
    }

    // Clamp requested size to the face's declared constraints, preserving
    // aspect when the face pins minAspect == maxAspect (algorithm port of
    // serpantinum widgets/Widget.qml updateEffectiveSize()).
    function updateEffectiveSize() {
        if (!faceLoader.item) {
            root.effectiveWidth = root.wWidth;
            root.effectiveHeight = root.wHeight;
            return;
        }
        let item = faceLoader.item;
        let c = {
            minW: item.minWidth !== undefined ? item.minWidth : 10,
            minH: item.minHeight !== undefined ? item.minHeight : 10,
            maxW: item.maxWidth !== undefined ? item.maxWidth : 9999,
            maxH: item.maxHeight !== undefined ? item.maxHeight : 9999,
            minA: item.minAspect !== undefined ? item.minAspect : 0,
            maxA: item.maxAspect !== undefined ? item.maxAspect : 9999
        };
        let w = Math.max(c.minW, Math.min(c.maxW, root.wWidth));
        let h = Math.max(c.minH, Math.min(c.maxH, root.wHeight));

        let ratio = w / h;
        if (ratio < c.minA && c.minA > 0) {
            let mA = c.minA;
            let hProj = (w * mA + h) / (mA * mA + 1);
            let hMin = Math.max(c.minH, c.minW / mA);
            let hMax = Math.min(c.maxH, c.maxW / mA);
            h = Math.max(hMin, Math.min(hMax, hProj));
            w = h * mA;
        } else if (ratio > c.maxA && c.maxA > 0) {
            let mA = c.maxA;
            let hProj = (w * mA + h) / (mA * mA + 1);
            let hMin = Math.max(c.minH, c.minW / mA);
            let hMax = Math.min(c.maxH, c.maxW / mA);
            h = Math.max(hMin, Math.min(hMax, hProj));
            w = h * mA;
        }

        w = Math.max(c.minW, Math.min(c.maxW, w));
        h = Math.max(c.minH, Math.min(c.maxH, h));

        root.effectiveWidth = w;
        root.effectiveHeight = h;
    }

    Loader {
        id: faceLoader
        // Expose the widget image path under every name the image faces accept.
        property string wImagePath: root.wImagePath
        property string imagePath: root.wImagePath
        property string path: root.wImagePath
        source: root.registryOf().faceFile(root.wType, root.wVariant)
        width: root.effectiveWidth
        height: root.effectiveHeight
        anchors.centerIn: parent
        rotation: root.wRotation || 0
        opacity: root.wOpacity
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        onLoaded: {
            if (item) {
                if (item.imagePath !== undefined) {
                    item.imagePath = Qt.binding(() => root.wImagePath);
                }
                if (item.wImagePath !== undefined) {
                    item.wImagePath = Qt.binding(() => root.wImagePath);
                }
                if (item.path !== undefined) {
                    item.path = Qt.binding(() => root.wImagePath);
                }
                if (item.source !== undefined && typeof item.source === "string") {
                    item.source = Qt.binding(() => root.wImagePath);
                }
                // Faces that declare `property bool windowShown: true` are
                // told whether their PanelWindow is actually on screen. The
                // loader hides the window (visible:false) during redactor
                // sessions; Items inside the window do NOT see that flag, so
                // it is propagated here for faces to gate timers / Cava
                // consumer registration while the widget is being edited.
                if (item.windowShown !== undefined) {
                    item.windowShown = Qt.binding(() => root.visible);
                }
            }
            root.updateEffectiveSize();
        }
    }
}
