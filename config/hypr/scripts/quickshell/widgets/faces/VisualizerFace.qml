import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// VisualizerFace — mirrored vertical bar spectrum over Cava.barLevels.
// Bars are sampled from the 64 cava bins with a center-weighted mapping and
// a smooth edge taper (port of serpantinum VisualizerFace). Registers a Cava
// consumer while visible, so cava only runs when a widget needs it.
//
// Visibility gating: the Widget window binds `windowShown` to the real window
// visibility (false during redactor sessions). The consumer exists only while
// `windowShown && visible`, i.e. never while the widget is hidden for
// editing; registration is tracked so pairs can never double-count and
// onDestruction always releases an active consumer.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 50
    property real minHeight: 50
    property real maxWidth: 99999
    property real maxHeight: 99999
    property real minAspect: 0
    property real maxAspect: 99999
    property bool isRound: false

    property bool windowShown: true
    property bool isVisVisible: root.visible && root.windowShown
    property bool cavaConsumerActive: false

    function syncCavaConsumer() {
        let want = root.isVisVisible;
        if (want === root.cavaConsumerActive) return;
        if (want) Cava.registerConsumer();
        else Cava.unregisterConsumer();
        root.cavaConsumerActive = want;
    }

    onIsVisVisibleChanged: root.syncCavaConsumer()

    Component.onCompleted: root.syncCavaConsumer()

    Component.onDestruction: {
        if (root.cavaConsumerActive) {
            Cava.unregisterConsumer();
            root.cavaConsumerActive = false;
        }
    }

    property real barSpacing: Math.max(2, Math.min(6, root.width * 0.005))
    property real minBarWidth: 4
    property int activeBars: Math.max(4, Math.min(96, Math.floor((root.width + root.barSpacing) / (root.minBarWidth + root.barSpacing))))
    property real actualBarWidth: (root.width - (root.activeBars - 1) * root.barSpacing) / root.activeBars

    property var processedBars: {
        let source = Cava.barLevels;
        let count = root.activeBars;
        let out = [];

        if (!source || source.length === 0) {
            for (let i = 0; i < count; i++) out.push(0.0);
            return out;
        }

        let srcLen = source.length;
        let half = (count - 1) / 2;

        for (let i = 0; i < count; i++) {
            let distFromCenter = Math.abs(i - half);
            let norm = half > 0 ? (distFromCenter / half) : 0;
            let pos = Math.pow(norm, 1.25) * (srcLen - 1);
            let idx0 = Math.floor(pos);
            let idx1 = Math.min(srcLen - 1, idx0 + 1);
            let frac = pos - idx0;

            let v0 = source[idx0] || 0.0;
            let v1 = source[idx1] || 0.0;
            let rawVal = v0 + (v1 - v0) * frac;

            let val = rawVal < 0.03 ? 0.0 : Math.pow((rawVal - 0.03) / 0.97, 1.15);
            val = Math.max(0.0, Math.min(1.0, val));

            let edgeNorm = Math.sin((i / Math.max(1, count - 1)) * Math.PI);
            let edgeFactor = Math.min(1.0, edgeNorm * 2.0);
            edgeFactor = edgeFactor * edgeFactor * (3.0 - 2.0 * edgeFactor);
            val *= edgeFactor;

            out.push(val);
        }

        return out;
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        spacing: root.barSpacing

        Repeater {
            model: root.activeBars
            delegate: Rectangle {
                width: root.actualBarWidth
                height: Math.max(3, level * parent.height * 0.96)
                radius: width * 0.35
                color: Theme.mauve
                opacity: (0.3 + (level * 0.7)) * edgeFactor
                anchors.bottom: parent.bottom

                property real level: (root.processedBars && index < root.processedBars.length) ? root.processedBars[index] : 0.0
                property real edgeNorm: Math.sin((index / Math.max(1, root.activeBars - 1)) * Math.PI)
                property real rawEdgeFactor: Math.min(1.0, edgeNorm * 2.0)
                property real edgeFactor: rawEdgeFactor * rawEdgeFactor * (3.0 - 2.0 * rawEdgeFactor)

                Behavior on height {
                    NumberAnimation {
                        duration: 75
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 75
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
