import QtQuick
import Quickshell

// ============================================================================
// ModulePill — the shared island pill every dock module is built from.
//
// Handles ALL the visual plumbing the old modules each re-implemented by hand:
//   • pill background (standard surface / accent solid fill / transparent),
//   • orientation-aware rounding, border, hover scale,
//   • entrance cascade (zoneReady + slotIndex),
//   • collapse/expand (showState), click / right-click / wheel signals,
//   • compact mode: in a vertical dock the pill becomes a narrow vertical
//     island and each module decides what reduced content to show.
//
// A module is just:  ModulePill { ...props...; content: <Item> }
// ============================================================================

Item {
    id: root

    // Children of ModulePill land here (default property).
    default property alias content: contentHost.data

    // --- contract injected by Zone ---
    required property var bar
    required property var colors
    required property bool zoneReady
    required property int slotIndex
    required property real effectiveBorderWidth
    required property string effectiveBorderColor
    required property bool unified

    // "horizontal" unless the bar explicitly says otherwise, so these modules
    // also render correctly under the legacy TopBar (which has no orientation).
    readonly property bool horizontal: bar.orientation === undefined || bar.orientation === "horizontal"
    readonly property bool compact: !horizontal

    // --- visuals -------------------------------------------------------------
    // accentRole: a colors.* role. When accentActive, the pill becomes a solid
    // accent island and content is drawn in colors.base (wifi/bt/vol/batt style).
    property string accentRole: ""
    property color accentColor: "transparent"   // direct color override (e.g. dynamic battery)
    property bool accentActive: true
    property bool pulse: false                   // pulsing ring behind content

    // bgRole/bgHoverRole: standard island tones. Use "base" for the softer
    // look (date/recording used colors.base).
    property string bgRole: "surface0"
    property string bgHoverRole: "surface1"

    // text roles
    property string idleRole: "text"
    property string hoverRole: ""
    // Flat-mode icon tinting (bar.accentTintMode, serp solid/fill styles):
    // keep the module's state color as the CONTENT color even when the island
    // fill is disabled — colored icon on the strip, no double fill.
    readonly property bool accentTint: bar && bar.accentTintMode === true
    readonly property color contentColor: {
        if (accentVisible) return colors.base;
        if (root.accentTint && accentRole !== "") {
            return root.hasAccentColor ? root.accentColor : (colors[accentRole] || colors.text);
        }
        if (hovered) return colors[hoverRole !== "" ? hoverRole : idleRole] || colors.text;
        return colors[idleRole] || colors.text;
    }

    // accentColor is a QColor, so it can never equal the string "transparent".
    // Detect "unset" via alpha == 0 (transparent black).
    readonly property bool hasAccentColor: accentColor !== undefined && accentColor.a !== 0

    property bool fullHeight: false        // use bar.barHeight instead of pillHeight
    property bool showState: true          // collapse the pill when false
    property bool noFill: false            // force transparent background (media/tray)
    property int padH: bar.s(12)
    property int padV: bar.s(8)

    readonly property bool accentVisible: accentRole !== "" && accentActive && bar.topbarPillBg
    readonly property bool hovered: pillMouse.containsMouse
    // While the dock is reordering islands live (bar.dragBusy), suppress every
    // pill transition so model rewrites never cascade into flicker/entrance
    // replays. The wrapper slot handles the "lifted" look of the dragged pill.
    readonly property bool dragSuppress: bar && bar.dragBusy === true

    signal clicked()
    signal rightClicked()
    signal wheelUp()
    signal wheelDown()

    // --- entrance cascade ------------------------------------------------------
    property bool initAnimTrigger: false
    Timer {
        running: root.zoneReady && !root.initAnimTrigger && !root.dragSuppress
        interval: root.slotIndex * 50
        onTriggered: root.initAnimTrigger = true
    }
    onDragSuppressChanged: {
        if (root.dragSuppress) root.initAnimTrigger = true;
    }

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill
        anchors.centerIn: parent

        property bool isHovered: pillMouse.containsMouse

        // background
        readonly property color idleBg: {
            if (root.noFill || root.unified || !bar.topbarPillBg) return "transparent";
            if (accentVisible) return root.hasAccentColor ? root.accentColor : (colors[root.accentRole] || colors.surface1);
            // barBg: standard islands become transparent and float on the bar strip.
            if (bar.barBg) return "transparent";
            let role = root.bgRole;
            let c = colors[role] || colors.surface0;
            return Qt.rgba(c.r, c.g, c.b, bar.topbarPillSolid ? 1.0 : (role === "surface0" ? 0.4 : 0.6));
        }
        readonly property color hoverBg: {
            if (root.noFill || root.unified || !bar.topbarPillBg) return "transparent";
            if (accentVisible) return root.hasAccentColor ? root.accentColor : (colors[root.accentRole] || colors.surface1);
            if (bar.barBg) {
                // subtle hover highlight floating on the bar strip
                let c = colors.surface1;
                return Qt.rgba(c.r, c.g, c.b, 0.28);
            }
            let role = root.bgHoverRole;
            let c = colors[role] || colors.surface1;
            return Qt.rgba(c.r, c.g, c.b, bar.topbarPillSolid ? 1.0 : (role === "surface1" ? 0.6 : 0.9));
        }
        color: isHovered ? hoverBg : idleBg
        Behavior on color { ColorAnimation { duration: 200 } }

        radius: root.unified ? 0 : (root.horizontal
            ? bar.pillRadius(root.fullHeight ? bar.barHeight : bar.pillHeight)
            : bar.pillRadius(bar.pillWidth))
        border.width: root.unified ? 0 : root.effectiveBorderWidth
        border.color: root.unified ? "transparent" : (colors[root.effectiveBorderColor] || colors.surface1)
        clip: true

        // size
        width: root.horizontal
            ? (root.showState ? contentHost.width + root.padH * 2 : 0)
            : (root.showState ? bar.pillWidth : 0)
        height: root.horizontal
            ? (root.fullHeight ? bar.barHeight : bar.pillHeight)
            : (root.showState ? Math.max(contentHost.height + root.padV * 2, bar.s(34)) : 0)

        Behavior on width { enabled: !root.dragSuppress; NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
        Behavior on height { enabled: !root.dragSuppress; NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
        Behavior on opacity { enabled: !root.dragSuppress; NumberAnimation { duration: 300 } }

        scale: (!root.dragSuppress && isHovered) ? 1.05 : 1.0
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        // entrance
        opacity: root.initAnimTrigger ? (root.showState ? 1 : 0) : 0
        transform: Translate {
            y: root.initAnimTrigger ? 0 : bar.s(15)
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
        }
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        // Content host. An Item never auto-sizes to its children, so we measure
        // the VISIBLE children (modules toggle horizontal/compact branches) and
        // center the block in the pill ourselves (no anchors — avoid loops).
        Item {
            id: contentHost
            width: contentW
            height: contentH
            x: (pill.width - width) / 2
            y: (pill.height - height) / 2

            property real contentW: 0
            property real contentH: 0

            function recalc() {
                var w = 0, h = 0;
                var kids = contentHost.data;
                for (var i = 0; i < kids.length; i++) {
                    var c = kids[i];
                    if (!c) continue;
                    var vis = true;
                    try { vis = c.visible !== false; } catch (e) {}
                    if (!vis) continue;
                    var iw = 0, ih = 0;
                    try {
                        iw = c.implicitWidth > 0 ? c.implicitWidth : c.width;
                        ih = c.implicitHeight > 0 ? c.implicitHeight : c.height;
                    } catch (e) {}
                    if (iw > w) w = iw;
                    if (ih > h) h = ih;
                }
                contentW = w;
                contentH = h;
            }

            onChildrenChanged: Qt.callLater(contentHost.recalc)
            Component.onCompleted: Qt.callLater(contentHost.recalc)

            // Content sizes settle asynchronously after load (fonts, images,
            // data). Re-measure briefly after startup; orientation changes
            // rebuild modules so this re-runs on every fresh instance.
            Timer {
                interval: 120
                repeat: true
                running: true
                property int ticks: 0
                onTriggered: {
                    contentHost.recalc();
                    ticks++;
                    if (ticks > 25) running = false;
                }
            }
        }

        // Pulsing ring (update available / recording live).
        Rectangle {
            id: pulseRing
            anchors.fill: parent
            radius: parent.radius
            color: root.hasAccentColor ? root.accentColor : (colors[root.accentRole] || colors.surface1)
            visible: root.pulse && root.accentVisible && !pillMouse.containsMouse
            z: -1

            SequentialAnimation on scale {
                running: root.pulse && root.accentVisible && !pillMouse.containsMouse
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.25; duration: 1800; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: root.pulse && root.accentVisible && !pillMouse.containsMouse
                loops: Animation.Infinite
                NumberAnimation { from: 0.25; to: 0.0; duration: 1800; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) { root.rightClicked(); return; }
                // After a real island drag the propagated release fires this
                // click too — swallow exactly one of them (see Zone slotDragArea).
                if (bar && bar.consumeNextModuleClick === true) {
                    bar.consumeNextModuleClick = false;
                    return;
                }
                root.clicked()
            }
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) root.wheelUp()
                else if (wheel.angleDelta.y < 0) root.wheelDown()
            }
        }
    }
}
