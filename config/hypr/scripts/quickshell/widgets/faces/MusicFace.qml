import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// MusicFace — wide music card: cover, marquee title/artist, live progress bar
// and a slim Cava bar strip at the bottom.
//
// Data source: $XDG_RUNTIME_DIR/quickshell/music/music_info.json (override
// with the QS_RUN_MUSIC env var, same convention as the dock scripts) — the
// JSON that the dock already writes through music/music_info.sh (status
// Playing / Paused / Stopped, title, artist, timeStr "mm:ss / mm:ss",
// percent, artUrl). The file is re-read on inotify events (the dock rewrites
// it on every MPRIS change) and a local timer advances the position each
// second while Playing. Without music the face renders a placeholder disc and
// empty texts.
//
// Cava consumer contract: the bottom bar strip registers a consumer ONLY
// while it is actually rendered — window shown (windowShown, false during
// redactor sessions), tall enough for the strip, and media Playing/Paused.
// The Stopped/idle state never holds a consumer.
//
// Cover-art refresh is owned by the dock (musicForceRefresh rewrites the JSON
// and downloads the art); the local artRetryTimer only re-reads the JSON a
// bounded number of times (~3) when the JSON still points at the placeholder,
// then stops on its own — see artRetryTimer below.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 150
    property real minHeight: 64
    property real maxWidth: 800
    property real maxHeight: 300
    property real minAspect: 2.4
    property real maxAspect: 3.2
    property bool isRound: false

    property real dynMargin: Math.max(6, Math.min(18, root.height * 0.1))
    property real dynSpacing: Math.max(4, Math.min(16, root.width * 0.02))
    property real titleSize: Math.max(9, Math.min(22, root.height * 0.16))
    property real subSize: Math.max(8, Math.min(15, root.height * 0.11))

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
    // (false while the redactor hides this widget); timers and the Cava
    // consumer pause while it is false. Default true keeps standalone
    // (non-widget) usage working.
    property bool windowShown: true

    // --- cover / placeholder -----------------------------------------------------
    property real artSize: Math.max(36, Math.min(root.height - root.dynMargin * 2, root.width * 0.24))
    property bool showArt: root.artSize >= 42 && root.width >= 190

    property string artUrl: root.musicData && root.musicData.artUrl ? String(root.musicData.artUrl) : ""
    property bool hasUsableArt: root.artUrl !== ""
        && root.artUrl.indexOf("placeholder_blank.png") === -1
        && root.musicData && root.musicData.artUrl !== ""

    // --- timing ------------------------------------------------------------------
    property int posSecs: 0
    property int lenSecs: 0
    property int displayPercent: 0

    property string positionText: "0:00"
    property string lengthText: "0:00"

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function fmtClock(secs) {
        secs = Math.max(0, Math.floor(secs || 0));
        let m = Math.floor(secs / 60);
        let s = secs % 60;
        return m + ":" + root.pad2(s);
    }

    // "m:ss / m:ss" or "h:mm:ss / mm:ss" -> seconds (lenient, dock format).
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
            root.positionText = "--:--";
            root.lengthText = "--:--";
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
        root.positionText = root.fmtClock(root.posSecs);
        root.lengthText = root.fmtClock(root.lenSecs);
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

    // 1-second tick while Playing (position advances locally, same as the
    // dock); paused while the window is hidden (redactor session).
    Timer {
        id: tickTimer
        interval: 1000
        running: root.isPlaying && root.windowShown
        repeat: true
        onTriggered: {
            if (!root.isPlaying || root.lenSecs <= 0) return;
            root.posSecs = Math.min(root.posSecs + 1, root.lenSecs);
            root.displayPercent = Math.round((root.posSecs / root.lenSecs) * 100);
            root.positionText = root.fmtClock(root.posSecs);
        }
    }

    // --- JSON reader + watcher -----------------------------------------------------
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
    // Cover art is downloaded and written by the DOCK (music_info.sh via the
    // dock's musicForceRefresh cycle), which rewrites music_info.json on every
    // MPRIS event. While the JSON still points at placeholder_blank.png the
    // dock is still fetching. This local timer re-reads the JSON a few times
    // in case a rewrite races our inotify watcher, then STOPS on its own
    // after ~3 attempts per track. It never loops forever: further refresh is
    // exclusively the dock's job, and a new track / artUrl identity (see
    // onMusicDataChanged) resets the attempt counter.
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

    // --- Cava consumer (bottom bar strip) -------------------------------------------
    // The consumer exists only while the strip is actually rendered: window
    // shown (windowShown — false during redactor sessions), tall enough for
    // the strip (showBars) AND media active (Playing or Paused). The
    // Stopped/idle state never holds a consumer. Registration is tracked via
    // syncCavaConsumer so pairs can never double-count, and onDestruction
    // always releases an active consumer (variant switches destroy the face
    // while the gate may still be true).
    property bool showBars: root.height >= 52
    property bool isVisVisible: root.visible && root.windowShown && root.showBars
    property bool visGate: root.isVisVisible && root.isMediaActive
    property bool cavaConsumerActive: false

    function syncCavaConsumer() {
        let want = root.visGate;
        if (want === root.cavaConsumerActive) return;
        if (want) Cava.registerConsumer();
        else Cava.unregisterConsumer();
        root.cavaConsumerActive = want;
    }

    onVisGateChanged: root.syncCavaConsumer()

    Component.onCompleted: {
        root.syncCavaConsumer();
        musicReader.running = true;
    }

    Component.onDestruction: {
        if (root.cavaConsumerActive) {
            Cava.unregisterConsumer();
            root.cavaConsumerActive = false;
        }
    }

    property int activeBars: 24
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
            let norm = half > 0 ? distFromCenter / half : 0;
            let pos = Math.pow(norm, 1.25) * (srcLen - 1);
            let idx0 = Math.floor(pos);
            let idx1 = Math.min(srcLen - 1, idx0 + 1);
            let frac = pos - idx0;
            let v0 = source[idx0] || 0.0;
            let v1 = source[idx1] || 0.0;
            let rawVal = v0 + (v1 - v0) * frac;
            let val = rawVal < 0.03 ? 0.0 : Math.pow((rawVal - 0.03) / 0.97, 1.15);
            out.push(Math.max(0.0, Math.min(1.0, val)));
        }
        return out;
    }

    // --- visuals ---------------------------------------------------------------------
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: Theme.surface0
        radius: Theme.clampedBorderRadius
        clip: true

        // Background placeholder disc (also the fallback behind the cover).
        Rectangle {
            id: artPlaceholder
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.dynMargin
            anchors.topMargin: root.dynMargin
            width: root.artSize
            height: width
            radius: Theme.clampedBorderRadius
            color: Theme.surface1
            border.width: 1
            border.color: root.isMediaActive ? Theme.surface2 : Theme.surface1
            visible: root.showArt

            Text {
                anchors.centerIn: parent
                text: "󰎈"
                font.family: Theme.fontFamily
                font.pixelSize: parent.width * 0.35
                color: Theme.subtext0
                visible: !root.isMediaActive || !root.hasUsableArt
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: parent.radius
                color: "white"
                antialiasing: true
                visible: false
                layer.enabled: true
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
                maskSource: artMask
                visible: root.hasUsableArt && artImg.status === Image.Ready
            }
        }

        // Main row: texts + progress + controls-free column.
        Item {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: barsStrip.top
            anchors.leftMargin: root.showArt ? (root.artSize + root.dynMargin * 2 + root.dynSpacing) : root.dynMargin
            anchors.rightMargin: root.dynMargin
            anchors.topMargin: root.dynMargin * 0.8
            anchors.bottomMargin: 0

            // Empty state: disc glyph + nothing playing.
            Item {
                anchors.centerIn: parent
                width: childrenRect.width
                height: childrenRect.height
                visible: !root.isMediaActive

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰎈"
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.min(parent.width, parent.height) * 0.6
                    color: Theme.overlay1
                }
            }

            ColumnLayout {
                anchors.fill: parent
                visible: root.isMediaActive
                spacing: Math.max(1, root.dynSpacing * 0.25)

                Item {
                    id: titleClip
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    implicitHeight: titleTextMain.implicitHeight
                    clip: true

                    property int marqueeSpacing: 30
                    property real scrollProgress: 0.0

                    Item {
                        height: parent.height
                        x: titleTextMain.implicitWidth > titleClip.width
                            ? -titleClip.scrollProgress * (titleTextMain.implicitWidth + titleClip.marqueeSpacing)
                            : 0

                        Row {
                            spacing: titleClip.marqueeSpacing
                            Text {
                                id: titleTextMain
                                text: root.isMediaActive ? (root.musicData.title || "Unknown Track") : ""
                                font.family: Theme.fontFamily
                                font.weight: Font.Black
                                font.pixelSize: root.titleSize
                                color: Theme.text
                                onTextChanged: titleClip.scrollProgress = 0.0
                            }

                            Text {
                                id: titleTextClone
                                text: titleTextMain.text
                                font.family: Theme.fontFamily
                                font.weight: Font.Black
                                font.pixelSize: root.titleSize
                                color: Theme.text
                                visible: titleTextMain.implicitWidth > titleClip.width
                            }
                        }
                    }

                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: root.isMediaActive && titleTextMain.implicitWidth > titleClip.width
                        PauseAnimation { duration: 3000 }
                        NumberAnimation {
                            target: titleClip
                            property: "scrollProgress"
                            from: 0.0
                            to: 1.0
                            duration: (titleTextMain.implicitWidth + titleClip.marqueeSpacing) * 25
                        }
                        PropertyAction { target: titleClip; property: "scrollProgress"; value: 0.0 }
                    }
                }

                Text {
                    text: root.musicData && root.musicData.artist ? String(root.musicData.artist) : ""
                    font.family: Theme.fontFamily
                    font.weight: Font.Medium
                    font.pixelSize: root.subSize
                    color: Theme.subtext1
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    elide: Text.ElideRight
                    visible: root.isMediaActive
                }

                Row {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 4
                    visible: root.isMediaActive

                    Text {
                        text: root.positionText + " / " + root.lengthText
                        font.family: Theme.fontFamily
                        font.weight: Font.Bold
                        font.pixelSize: root.subSize
                        color: Theme.subtext0
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: Math.max(3, root.height * 0.03)
                    Layout.minimumHeight: 2
                    visible: root.isMediaActive

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(2, parent.height * 0.6)
                        radius: height / 2
                        color: Theme.surface1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * (root.displayPercent / 100.0)
                            height: parent.height
                            radius: height / 2
                            color: Theme.mauve
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                }
            }
        }

        // Slim Cava strip at the bottom edge.
        Item {
            id: barsStrip
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(4, Math.min(14, parent.height * 0.11))
            anchors.leftMargin: root.dynMargin
            anchors.rightMargin: root.dynMargin
            anchors.bottomMargin: Math.max(2, parent.radius * 0.4)
            visible: root.isVisVisible && root.isMediaActive

            Row {
                anchors.fill: parent
                spacing: Math.max(1, width * 0.004)
                Repeater {
                    model: root.activeBars
                    delegate: Rectangle {
                        width: (parent.width - (root.activeBars - 1) * parent.spacing) / root.activeBars
                        height: Math.max(1.5, level * parent.height)
                        radius: width / 2
                        color: Theme.mauve
                        opacity: 0.25 + level * 0.55
                        anchors.bottom: parent.bottom

                        property real level: (root.processedBars && index < root.processedBars.length) ? root.processedBars[index] : 0.0

                        Behavior on height {
                            NumberAnimation { duration: 75; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 75; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
