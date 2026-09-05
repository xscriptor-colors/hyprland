pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ============================================================================
// Cava — single-instance audio visualizer backend for desktop widgets.
//
// Port of serpantinum singletons/Cava.qml adapted to this shell:
//   - No MPRIS gate: the process runs while at least one consumer exists
//     (faces register/unregister through registerConsumer()).
//   - barLevels holds 64 normalized 0..1 levels refreshed from cava's raw
//     ascii output (process substitution, one frame per line, ";" delimiter).
//   - A 2s data watchdog restarts the process when a consumer exists but no
//     frame arrived.
//   - If cava is not installed (or dies instantly) the Process exits and is
//     restarted with EXPONENTIAL backoff (500 ms -> 1 s -> 2 s ... capped at
//     30 s) so a missing binary does not cause a fork loop. The backoff
//     resets to 500 ms on the first received frame and whenever the consumer
//     count changes, so a fresh session always starts at the base delay.
// ============================================================================

Item {
    id: root

    property int barCount: 64
    property var barLevels: {
        let arr = [];
        for (let i = 0; i < root.barCount; i++) arr.push(0.0);
        return arr;
    }
    property int activeConsumers: 0
    property bool isRestarting: false
    property bool processEnabled: root.activeConsumers > 0 && !root.isRestarting

    // --- restart backoff ----------------------------------------------------------
    // Base delay between restart attempts; doubles on every attempt while the
    // process keeps dying before producing a frame (missing/broken cava) up to
    // retryMaxMs. Reset on the first received frame and on consumer-count
    // changes so a healthy session never accumulates an artificial delay.
    property int retryBaseMs: 500
    property int retryMaxMs: 30000
    property int retryDelayMs: 500

    function resetRetryBackoff() {
        if (root.retryDelayMs !== root.retryBaseMs) {
            root.retryDelayMs = root.retryBaseMs;
        }
    }

    function registerConsumer() {
        root.activeConsumers++;
    }

    function unregisterConsumer() {
        root.activeConsumers = Math.max(0, root.activeConsumers - 1);
    }

    function resetBars() {
        let empty = [];
        for (let i = 0; i < root.barCount; i++) {
            empty.push(0.0);
        }
        root.barLevels = empty;
    }

    function restartCava() {
        if (!root.processEnabled) return;
        root.isRestarting = true;
        restartTimer.interval = root.retryDelayMs;
        // Grow the delay for the NEXT attempt (capped); a received frame or
        // a consumer change resets it via resetRetryBackoff().
        root.retryDelayMs = Math.min(root.retryMaxMs, root.retryDelayMs * 2);
        restartTimer.restart();
    }

    onProcessEnabledChanged: {
        if (!root.processEnabled) {
            root.resetBars();
        }
    }

    onActiveConsumersChanged: {
        // A fresh session starts at the base delay: an instantly-dying cava
        // must not inherit a backoff grown by an earlier missing-binary run.
        root.resetRetryBackoff();
        if (root.activeConsumers === 0) {
            root.resetBars();
        }
    }

    Timer {
        id: restartTimer
        interval: 500
        repeat: false
        onTriggered: root.isRestarting = false
    }

    // No data for 2s while running with consumers -> restart cava.
    Timer {
        id: dataWatchdog
        interval: 2000
        running: cavaProcess.running && root.activeConsumers > 0
        repeat: false
        onTriggered: root.restartCava()
    }

    Process {
        id: cavaProcess
        running: root.processEnabled
        onExited: root.restartCava()
        command: [
            "bash", "-c",
            "cava -p <(printf '[general]\\nbars = %d\\nframerate = 60\\nsensitivity = 150\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 1000\\nbar_delimiter = 59\\n' " + root.barCount + ")"
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.processEnabled) return;
                dataWatchdog.restart();
                // A live frame proves the process works: restart backoff from base.
                root.resetRetryBackoff();
                let str = String(data).trim();
                if (str.length === 0) return;
                let parts = str.split(";");
                let count = Math.min(parts.length, root.barCount);
                let newLevels = [];
                for (let i = 0; i < root.barCount; i++) {
                    let val = i < count ? (parseInt(parts[i]) || 0) : 0;
                    newLevels.push(Math.max(0.0, Math.min(1.0, val / 1000.0)));
                }
                root.barLevels = newLevels;
            }
        }
    }
}
