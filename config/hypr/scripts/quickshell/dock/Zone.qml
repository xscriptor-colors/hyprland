import QtQuick
import Quickshell
import "DockLayout.js" as DockLayout

// ============================================================================
// Zone — renders ONE zone of the dock.
//
// Zones are pure data (see DockLayout.js). This component turns a zone object
// into a row (horizontal dock) or column (vertical dock) of module pills,
// positioned by the zone's `align` (start → center → end along the main axis).
// It also draws the optional "unified" pill behind the whole zone and forwards
// per-zone border styling to the modules via the shared module contract
// (bar, colors, zoneReady, slotIndex, effectiveBorderWidth/Color, unified).
// ============================================================================

Item {
    id: zoneRoot

    required property var bar
    required property var colors
    required property var zoneData
    required property int zoneIndex

    readonly property bool isHorizontal: bar.orientation === "horizontal"
    readonly property bool unified: zoneData.unify === true

    // Main-axis alignment: start | center | end
    anchors.left: undefined
    anchors.right: undefined
    anchors.top: undefined
    anchors.bottom: undefined
    anchors.horizontalCenter: undefined
    anchors.verticalCenter: undefined

    property bool ready: false
    Timer {
        running: bar.isStartupReady
        interval: 80 + zoneIndex * 90
        onTriggered: zoneRoot.ready = true
    }

    // --- sizing / anchoring ------------------------------------------------
    height: isHorizontal ? parent.height : (ready ? flowV.implicitHeight : 0)
    width: isHorizontal ? (ready ? flowH.implicitWidth : 0) : parent.width

    // Entrance animation: fade + small slide from the dock edge.
    opacity: ready ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    transform: Translate {
        x: zoneRoot.isHorizontal ? (zoneRoot.slideX * (zoneRoot.ready ? 0 : 1)) : 0
        y: !zoneRoot.isHorizontal ? (zoneRoot.slideY * (zoneRoot.ready ? 0 : 1)) : 0
        Behavior on x { NumberAnimation { duration: 550; easing.type: Easing.OutExpo } }
        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.OutExpo } }
    }

    readonly property int slideX: zoneRoot.isHorizontal ? (zoneData.align === "end" ? bar.s(40) : zoneData.align === "start" ? -bar.s(40) : 0) : 0
    readonly property int slideY: !zoneRoot.isHorizontal ? (zoneData.align === "end" ? bar.s(40) : zoneData.align === "start" ? -bar.s(40) : 0) : 0

    function applyAnchors() {
        let p = zoneRoot.parent;
        if (!p) return;
        zoneRoot.anchors.left = undefined;
        zoneRoot.anchors.right = undefined;
        zoneRoot.anchors.top = undefined;
        zoneRoot.anchors.bottom = undefined;
        zoneRoot.anchors.horizontalCenter = undefined;
        zoneRoot.anchors.verticalCenter = undefined;
        if (zoneRoot.isHorizontal) {
            zoneRoot.anchors.verticalCenter = p.verticalCenter;
            if (zoneData.align === "start") zoneRoot.anchors.left = p.left;
            else if (zoneData.align === "end") zoneRoot.anchors.right = p.right;
            else zoneRoot.anchors.horizontalCenter = p.horizontalCenter;
        } else {
            zoneRoot.anchors.horizontalCenter = p.horizontalCenter;
            if (zoneData.align === "start") zoneRoot.anchors.top = p.top;
            else if (zoneData.align === "end") zoneRoot.anchors.bottom = p.bottom;
            else zoneRoot.anchors.verticalCenter = p.verticalCenter;
        }
    }

    onParentChanged: applyAnchors()
    onIsHorizontalChanged: Qt.callLater(() => applyAnchors())
    onZoneDataChanged: { zoneRoot.ready = false; Qt.callLater(() => applyAnchors()); }
    Component.onCompleted: applyAnchors()

    // --- unified pill behind the whole zone ---------------------------------
    Rectangle {
        id: unifyPill
        visible: zoneRoot.unified
        anchors.fill: parent
        radius: isHorizontal ? bar.pillRadius(bar.pillHeight) : bar.pillRadius(bar.pillWidth)
        color: colors.surface0
        border.width: zoneData.borderWidth || 0
        border.color: colors[zoneData.borderColor] || colors.surface1
        Behavior on border.width { NumberAnimation { duration: 200 } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // --- module flow (shared delegate) ---------------------------------------
    Component {
        id: moduleDelegate
        Loader {
            required property string modelData
            required property int index
            width: item ? item.implicitWidth : 0
            height: item ? item.implicitHeight : 0

            Component.onCompleted: {
                let mod = DockLayout.getModule(modelData);
                if (!mod) return;
                // Module components live in the quickshell root (one level up
                // from dock/), so resolve relative to this file.
                setSource(Qt.resolvedUrl("../" + mod.component), {
                    "bar": zoneRoot.bar,
                    "colors": zoneRoot.colors,
                    "zoneReady": Qt.binding(() => zoneRoot.ready),
                    "slotIndex": index,
                    "effectiveBorderWidth": Qt.binding(() => zoneRoot.unified ? 0 : (zoneRoot.zoneData.borderWidth || 0)),
                    "effectiveBorderColor": Qt.binding(() => zoneRoot.unified ? "surface1" : (zoneRoot.zoneData.borderColor || "surface1")),
                    "unified": Qt.binding(() => zoneRoot.unified)
                });
            }
        }
    }

    // Row (horizontal dock) OR Column (vertical dock) of modules.
    // Positioners default to their implicit main-axis size, so we only pin the
    // cross axis. (No anchors.fill here — it would create a circular width
    // dependency with zoneRoot's size.)
    Row {
        id: flowH
        visible: zoneRoot.isHorizontal && zoneRoot.ready
        x: zoneRoot.unified ? bar.s(6) : 0
        y: (zoneRoot.parent.height - height) / 2
        height: Math.min(parent.height, implicitHeight)
        spacing: zoneRoot.unified ? 0 : bar.s(8)
        Repeater {
            id: flowHRepeater
            model: DockLayout.zoneModel(zoneRoot.zoneData)
            delegate: moduleDelegate
        }
    }

    Column {
        id: flowV
        visible: !zoneRoot.isHorizontal && zoneRoot.ready
        x: (zoneRoot.parent.width - width) / 2
        y: zoneRoot.unified ? bar.s(6) : 0
        width: Math.min(parent.width, implicitWidth)
        spacing: zoneRoot.unified ? 0 : bar.s(8)
        Repeater {
            model: DockLayout.zoneModel(zoneRoot.zoneData)
            delegate: moduleDelegate
        }
    }
}
