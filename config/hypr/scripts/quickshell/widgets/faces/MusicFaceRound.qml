import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// MusicFaceRound — circular music widget.
//
// Visual language decision (documented for maintainers): the progress is a
// Canvas ring (two arcs: surface1 track + mauve progress, round line caps)
// because Qt has no native conic gradient and rotated-rectangle rings need
// dozens of triggers; a Canvas repaint per percent change is trivial.
// The cover art is a centered disc masked by a circular layer (same MultiEffect
// pattern the codebase already uses in MusicPopup.qml). Radial Cava bars were
// deliberately NOT ported — with a square aspect they fight the ring for the
// same annulus; the horizontal MusicFace keeps the spectrum instead. This
// face therefore registers no Cava consumer (its visualizer gate is
// effectively "never", which satisfies the consumer-only-with-bars contract).
//
// Data plumbing is identical to MusicFace (music_info.json + inotify + 1s
// local tick while Playing). Data path honours QS_RUN_MUSIC (see musicFilePath
// below). Cover-art refresh is owned by the dock; the local artRetryTimer is
// bounded (~3 attempts per track) — see the timer comment.
//
// Visibility gating: windowShown mirrors the real window visibility (false
// during redactor sessions); the tick and art-retry timers pause while
// hidden. Without music it renders a glyph disc.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 150
    property real minHeight: 150
    property real maxWidth: 1000
    property real maxHeight: 1000
    property real minAspect: 1.0
    property real maxAspect: 1.0
    property bool isRound: true

    // Env override helper: QS_RUN_MUSIC points at the music run DIRECTORY
    // (the dock writes music_info.json into it); default matches the dock:
    // $XDG_RUNTIME_DIR/quickshell/music (fallback /tmp/quickshell/music).
    function envOr(name, fallback) {
        let v = Quickshell.env(name);
        return v !== "" ? v : fallback;
    }

    readonly property string musicFilePath: root.envOr("QS_RUN_MUSIC",
        root.envOr("XDG_RUNTIME_DIR", "/tmp") + "/quickshell/music") + "/music_info.json"

    property var musicData: null
    property string status: ""
    property bool isMediaActive: root.status === "Playing" || root.status === "Paused"
    property bool isPlaying: root.status === "Playing"

    // windowShown is bound by the Widget window to the real window visibility
    // (false while the redactor hides this widget); the tick and art-retry
    // timers pause while it is false. Default true keeps standalone
    // (non-widget) usage working.
    property bool windowShown: true

    property string artUrl: root.musicData && root.musicData.artUrl ? String(root.musicData.artUrl) : ""
    property bool hasUsableArt: root.artUrl !== ""
        && root.artUrl.indexOf("placeholder_blank.png") === -1
        && root.musicData && root.musicData.artUrl !== ""

    property int posSecs: 0
    property int lenSecs: 0
    property int displayPercent: 0

    function clockSecs(str) {
        if (!str) return -1;
        let parts = String(str).trim().split(":");
        if (parts.length < 2) return -1;
        let total = 0;
        for (let i = 0; i < parts.length; i++) {
            let n = parseInt(parts[i], 10);
            if (isNaN(n)) return -1;
            total = total * 60 + n;
        }
        return total;
    }

    function updateDisplay() {
        let data = root.musicData;
        if (!data) {
            root.posSecs = 0;
            root.lenSecs = 0;
            root.displayPercent = 0;
            return;
        }
        let timeStr = data.timeStr || "";
        let parts = String(timeStr).split("/");
        let pos = -1;
        let len = -1;
        if (parts.length === 2) {
            pos = root.clockSecs(parts[0]);
            len = root.clockSecs(parts[1]);
        }
        if (pos === -1 || len === -1) {
            pos = parseInt(data.position, 10);
            len = parseInt(data.length, 10);
            if (isNaN(pos)) pos = 0;
            if (isNaN(len)) len = 0;
        }
        root.posSecs = Math.max(0, Math.min(pos, len > 0 ? len : pos));
        root.lenSecs = Math.max(0, len);
        root.displayPercent = root.lenSecs > 0 ? Math.round((root.posSecs / root.lenSecs) * 100) : 0;
    }

    function applyMusicJson(text) {
        let txt = text ? text.trim() : "";
        if (txt === "") return;
        try {
            root.musicData = JSON.parse(txt);
        } catch (e) { return; }
        root.status = root.musicData && root.musicData.status ? String(root.musicData.status) : "";
        root.updateDisplay();
    }

    onMusicDataChanged: {
        root.status = root.musicData && root.musicData.status ? String(root.musicData.status) : "";
        root.updateDisplay();
        // New track / art identity => allow a fresh (bounded) art retry
        // window. Identical re-reads (triggered by the retry timer itself)
        // must NOT reset the counter, otherwise the ~3-attempt cap would
        // never trigger.
        let data = root.musicData || {};
        let key = String(data.artist || "") + "|" + String(data.title || "") + "|" + String(data.artUrl || "");
        if (key !== root.musicTrackKey) {
            root.musicTrackKey = key;
            root.artRetryCount = 0;
        }
    }

    Timer {
        id: tickTimer
        interval: 1000
        // Paused while the window is hidden (redactor session).
        running: root.isPlaying && root.windowShown
        repeat: true
        onTriggered: {
            if (!root.isPlaying || root.lenSecs <= 0) return;
            root.posSecs = Math.min(root.posSecs + 1, root.lenSecs);
            root.displayPercent = Math.round((root.posSecs / root.lenSecs) * 100);
        }
    }

    Process {
        id: musicReader
        command: ["bash", "-c", "cat '" + root.musicFilePath + "' 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyMusicJson(this.text)
        }
    }

    Process {
        id: musicWatcher
        command: ["bash", "-c", "while [ ! -f '" + root.musicFilePath + "' ]; do sleep 1; done; inotifywait -qq -e modify,close_write '" + root.musicFilePath + "'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                musicReader.running = false;
                musicReader.running = true;
                musicWatcher.running = false;
                musicWatcher.running = true;
            }
        }
    }

    // --- cover-art retry (bounded — no competing loop with the dock) --------------
    // Same contract as MusicFace: the dock owns cover-art refresh (it rewrites
    // music_info.json on every MPRIS event). This timer re-reads the JSON a
    // few times when it still points at placeholder_blank.png (in case a
    // rewrite races the inotify watcher), then stops on its own after ~3
    // attempts per track; a new track / artUrl identity resets the counter
    // (see onMusicDataChanged).
    property int artRetryCount: 0
    property string musicTrackKey: ""

    Timer {
        id: artRetryTimer
        interval: 800
        running: root.windowShown && root.isMediaActive
            && root.artUrl.indexOf("placeholder_blank.png") !== -1
            && root.artRetryCount < 3
        repeat: true
        onTriggered: {
            root.artRetryCount++;
            musicReader.running = false;
            musicReader.running = true;
        }
    }

    Component.onCompleted: musicReader.running = true

    // --- ring geometry ----------------------------------------------------------
    property real ringStroke: Math.max(4, Math.min(14, (Math.min(root.width, root.height) / 2) * 0.09))
    property real ringPad: 6
    property real ringRadius: (Math.min(root.width, root.height) / 2) - ringStroke / 2 - ringPad
    property real discRadius: ringRadius - ringStroke - 4

    onDisplayPercentChanged: progressRing.requestPaint()

    Canvas {
        id: progressRing
        anchors.centerIn: parent
        width: root.ringRadius * 2 + root.ringStroke
        height: width
        onPaint: {
            let ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            let cx = width / 2;
            let cy = height / 2;
            let r = cx - root.ringStroke / 2;

            ctx.lineWidth = root.ringStroke;
            ctx.lineCap = "round";

            // Track
            ctx.strokeStyle = Theme.hexOf(Theme.surface1);
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();

            // Progress (from 12 o'clock, clockwise)
            if (root.displayPercent > 0) {
                let sweep = (Math.max(0, Math.min(100, root.displayPercent)) / 100.0) * Math.PI * 2;
                ctx.strokeStyle = Theme.hexOf(root.isMediaActive ? Theme.mauve : Theme.surface2);
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + sweep, false);
                ctx.stroke();
            }
        }
    }

    // --- center disc (cover or placeholder) ---------------------------------------
    Item {
        anchors.centerIn: parent
        width: root.discRadius * 2
        height: width

        Rectangle {
            id: discBase
            anchors.fill: parent
            radius: width / 2
            color: Theme.surface1
            border.width: 1
            border.color: root.isMediaActive ? Theme.surface2 : Theme.surface1

            Text {
                anchors.centerIn: parent
                text: "󰎈"
                font.family: Theme.fontFamily
                font.pixelSize: parent.width * 0.3
                color: Theme.subtext0
                visible: !root.hasUsableArt
            }

            Rectangle {
                id: discMask
                anchors.fill: parent
                radius: width / 2
                color: "white"
                antialiasing: true
                visible: false
                layer.enabled: true
                layer.smooth: true
            }

            Image {
                id: artImg
                anchors.fill: parent
                source: root.hasUsableArt
                    ? (root.artUrl.indexOf("file://") === 0 ? root.artUrl : "file://" + root.artUrl)
                    : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
                sourceSize: Qt.size(1024, 1024)
                visible: false // rendered through the masked effect below
            }

            MultiEffect {
                anchors.fill: parent
                source: artImg
                autoPaddingEnabled: false
                maskEnabled: true
                maskSource: discMask
                visible: root.hasUsableArt && artImg.status === Image.Ready
            }
        }
    }
}
