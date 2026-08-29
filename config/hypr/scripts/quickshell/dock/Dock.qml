import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../WindowRegistry.js" as LayoutMath
import "DockLayout.js" as DockLayout

// ============================================================================
// Dock — the position-agnostic bar.
//
// Replaces the old top-only TopBar.qml. The same island-pill aesthetic and all
// module/data machinery are preserved, but the dock can sit on any screen edge:
//
//   position: "top" | "bottom" | "left" | "right"
//   orientation: derived from position (horizontal / vertical)
//
// The visual + layout config lives in settings.json under "dock" (see
// DockLayout.js). Old "topbar" settings are migrated on first load. Colors
// come from the Matugen-free palette system (dock/Colors.qml).
//
// Data plumbing (watchers/pollers) is centralized here; modules read state
// through the `bar` object — same contract as the old TopBar, so existing
// modules keep working untouched while we migrate them to ModulePill.
// ============================================================================

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: dockWindow

            required property var modelData
            screen: modelData

            // Inline replica of the parent dir's Caching.qml so this component
            // stays self-contained inside dock/.
            QtObject {
                id: paths
                readonly property string home: Quickshell.env("HOME")
                readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")
                readonly property string cacheDir: home + "/.cache/quickshell"
                readonly property string stateDir: home + "/.local/state/quickshell"
                readonly property string runDir: (xdgRuntimeDir !== "" ? xdgRuntimeDir : "/tmp") + "/quickshell"
                readonly property string logDir: runDir + "/logs"
                function getCacheDir(name) {
                    let envPath = Quickshell.env("QS_CACHE_" + name.toUpperCase());
                    let p = envPath ? envPath : (cacheDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getStateDir(name) {
                    let envPath = Quickshell.env("QS_STATE_" + name.toUpperCase());
                    let p = envPath ? envPath : (stateDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getRunDir(name) {
                    let envPath = Quickshell.env("QS_RUN_" + name.toUpperCase());
                    let p = envPath ? envPath : (runDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
                function getLogDir(name) {
                    let envPath = Quickshell.env("QS_LOG_" + name.toUpperCase());
                    let p = envPath ? envPath : (logDir + "/" + name);
                    Quickshell.execDetached(["mkdir", "-p", p]);
                    return p;
                }
            }

            // ================================================================
            // SCALING (inlined — avoids importing Scaler.qml from the parent dir)
            // ================================================================
            property real uiScale: 1.0
            readonly property real baseScale: LayoutMath.getScale(
                dockWindow.screen ? dockWindow.screen.width : 1920,
                dockWindow.screen ? dockWindow.screen.height : 1080,
                dockWindow.uiScale)
            function s(val) { return LayoutMath.s(val, baseScale); }

            // ================================================================
            // THEME COLORS (Matugen-free)
            // ================================================================
            Colors {
                id: dockColors
            }
            // Exposed as a property so modules/zones can use `colors.<role>`
            // exactly like they did with the old MatugenColors component.
            readonly property var colors: dockColors

            // ================================================================
            // DOCK CONFIG (settings.json "dock" key)
            //
            // CUSTOMIZATION HOOK: every visual/layout value the mega menu edits
            // lands here. `syncDockConfig()` copies the parsed dockConfig into
            // plain properties in ONE synchronous pass so orientation/geometry/
            // zones always stay consistent (readonly binding chains evaluate
            // lazily and caused stale orientation bugs).
            // ================================================================
            property var dockConfig: DockLayout.defaultDock()
            property var zones: dockConfig.zones
            // Becomes true only after settings.json has been read AND the dock
            // config synced, so uiScale/baseScale are final before any module
            // renders (bar.s() is a function, so QML can't reactively rescale).
            property bool configReady: false
            property string position: "top"
            property string orientation: "horizontal"
            property string paletteName: "x"
            property real thickness: 48
            property real edgeGap: 8
            property real roundness: 1.0
            property bool pillBg: true
            property bool pillSolid: false
            property real borderWidth: 0
            property string borderColor: "surface1"

            onDockConfigChanged: syncDockConfig()
            Component.onCompleted: syncDockConfig()

            function syncDockConfig() {
                if (!dockConfig) return;
                dockWindow.position = dockConfig.position || "top";
                dockWindow.orientation = (dockWindow.position === "top" || dockWindow.position === "bottom") ? "horizontal" : "vertical";
                dockWindow.paletteName = dockConfig.palette || "x";
                dockWindow.thickness = dockConfig.thickness;
                dockWindow.edgeGap = dockConfig.edgeGap;
                dockWindow.roundness = dockConfig.roundness;
                dockWindow.pillBg = dockConfig.pillBg;
                dockWindow.pillSolid = dockConfig.pillSolid;
                dockWindow.borderWidth = dockConfig.borderWidth;
                dockWindow.borderColor = dockConfig.borderColor;
                dockWindow.zones = dockConfig.zones;
                applyPosition();
            }

            // Legacy aliases so pre-ModulePill modules keep working unchanged.
            property real topbarRoundness: roundness
            property bool topbarPillBg: pillBg
            property bool topbarPillSolid: pillSolid
            onRoundnessChanged: topbarRoundness = roundness
            onPillBgChanged: topbarPillBg = pillBg
            onPillSolidChanged: topbarPillSolid = pillSolid

            // ================================================================
            // GEOMETRY
            // ================================================================
            property int barHeight: s(thickness)
            // Vertical docks need extra width (~50px physical) to fit compact
            // islands and the HH:mm clock comfortably.
            property int barWidth: orientation === "horizontal" ? s(thickness) : Math.max(s(thickness), s(70))
            property int pillHeight: orientation === "horizontal" ? barHeight - s(12) : barWidth - s(8)
            property int pillWidth: orientation === "horizontal" ? barHeight - s(12) : barWidth - s(8)
            function pillRadius(h) { return Math.round(h * 0.5 * roundness); }

            // The settings panel occupies the edge opposite a left/right dock.
            property bool panelFromLeft: position !== "left"

            implicitHeight: orientation === "horizontal" ? barHeight : (dockWindow.screen ? dockWindow.screen.height : 1080)
            implicitWidth: orientation === "horizontal" ? (dockWindow.screen ? dockWindow.screen.width : 1920) : barWidth

            margins {
                top: orientation === "vertical" ? s(4) : (position === "top" ? s(edgeGap) : s(4))
                bottom: orientation === "vertical" ? s(4) : (position === "bottom" ? s(edgeGap) : s(4))
                left: orientation === "horizontal" ? s(4) : (position === "left" ? s(edgeGap) : s(4))
                right: orientation === "horizontal" ? s(4) : (position === "right" ? s(edgeGap) : s(4))
            }
            exclusiveZone: orientation === "horizontal" ? barHeight : barWidth
            color: "transparent"

            function applyPosition() {
                dockWindow.anchors.top = undefined;
                dockWindow.anchors.bottom = undefined;
                dockWindow.anchors.left = undefined;
                dockWindow.anchors.right = undefined;
                if (position === "top") { dockWindow.anchors.top = true; dockWindow.anchors.left = true; dockWindow.anchors.right = true; }
                else if (position === "bottom") { dockWindow.anchors.bottom = true; dockWindow.anchors.left = true; dockWindow.anchors.right = true; }
                else if (position === "left") { dockWindow.anchors.left = true; dockWindow.anchors.top = true; dockWindow.anchors.bottom = true; }
                else { dockWindow.anchors.right = true; dockWindow.anchors.top = true; dockWindow.anchors.bottom = true; }
            }
            onPositionChanged: applyPosition()

            // ================================================================
            // IPC (same target as before so qs_manager / Config keep working)
            // ================================================================
            IpcHandler {
                target: "topbar"
                function forceReload() { Quickshell.reload(true) }
                function queueReload() {
                    if (!dockWindow.isSettingsOpen) Quickshell.reload(true)
                    else dockWindow.pendingReload = true
                }
                function reloadColors() { dockColors.forceRefresh() }
                function toggleUpdate() { dockWindow.forceUpdateShow = !dockWindow.forceUpdateShow }
            }

            // ================================================================
            // WIDGET / RECORDING / UPDATE POLLERS
            // ================================================================
            property bool pendingReload: false
            property string activeWidget: ""
            property bool isSettingsOpen: activeWidget === "settings"
            property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
            Behavior on settingsSlideProgress {
                enabled: dockWindow.startupCascadeFinished
                NumberAnimation { duration: 600; easing.type: Easing.OutExpo }
            }
            onIsSettingsOpenChanged: {
                if (!dockWindow.isSettingsOpen && dockWindow.pendingReload) {
                    dockWindow.pendingReload = false;
                    Quickshell.reload(true);
                }
            }

            Process {
                id: widgetPoller
                command: ["bash", "-c", "cat " + paths.runDir + "/current_widget 2>/dev/null || echo ''"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (dockWindow.activeWidget !== txt) dockWindow.activeWidget = txt;
                    }
                }
            }
            Process {
                id: widgetWatcher
                command: ["bash", "-c", "while [ ! -f " + paths.runDir + "/current_widget ]; do sleep 1; done; inotifywait -qq -e modify,close_write " + paths.runDir + "/current_widget"]
                running: true
                onExited: {
                    widgetPoller.running = false;
                    widgetPoller.running = true;
                    running = false;
                    running = true;
                }
            }

            Process {
                id: recPoller
                command: ["bash", "-c", "if [ -s " + paths.getCacheDir("recording") + "/rec_pid ] && kill -0 $(cat " + paths.getCacheDir("recording") + "/rec_pid) 2>/dev/null; then echo '1'; else echo '0'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.isRecording = (this.text.trim() === "1");
                    }
                }
            }
            Process {
                id: recWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e create,delete,modify,close_write " + paths.getCacheDir("recording") + "/ 2>/dev/null || sleep 2"]
                onExited: {
                    recPoller.running = false;
                    recPoller.running = true;
                    running = false;
                    running = true;
                }
            }

            Process {
                id: updatePoller
                command: ["bash", "-c", "if [ -f " + paths.getCacheDir("updater") + "/update_pending ]; then echo '1'; else echo '0'; fi"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.updateAvailable = (this.text.trim() === "1");
                    }
                }
            }
            Process {
                id: updateWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e create,delete,close_write " + paths.getCacheDir("updater") + "/ 2>/dev/null || sleep 5"]
                onExited: {
                    updatePoller.running = false;
                    updatePoller.running = true;
                    running = false;
                    running = true;
                }
            }

            // ================================================================
            // SETTINGS READER (dock config)
            // ================================================================
            Process {
                id: settingsReader
                command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                                let parsed = JSON.parse(this.text);
                                let next = DockLayout.getDock(parsed);
                                if (JSON.stringify(next) !== JSON.stringify(dockWindow.dockConfig)) {
                                    dockWindow.dockConfig = next;
                                }
                                if (parsed.uiScale !== undefined && dockWindow.uiScale !== parsed.uiScale) {
                                    dockWindow.uiScale = parsed.uiScale;
                                }
                                if (parsed.topbarHelpIcon !== undefined && dockWindow.showHelpIcon !== parsed.topbarHelpIcon) {
                                    dockWindow.showHelpIcon = parsed.topbarHelpIcon;
                                }
                                if (parsed.workspaceCount !== undefined && dockWindow.workspaceCount !== parsed.workspaceCount) {
                                    dockWindow.workspaceCount = parsed.workspaceCount;
                                    wsDaemon.running = false;
                                    wsDaemon.running = true;
                                }
                                // uiScale + dockConfig are now final: safe to build modules.
                                dockWindow.configReady = true;
                            }
                        } catch (e) {}
                    }
                }
            }
            Process {
                id: settingsWatcher
                command: ["bash", "-c", "while [ ! -f ~/.config/hypr/settings.json ]; do sleep 1; done; inotifywait -qq -e modify,close_write ~/.config/hypr/settings.json"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        settingsReader.running = false;
                        settingsReader.running = true;
                        settingsWatcher.running = false;
                        settingsWatcher.running = true;
                    }
                }
            }

            // ================================================================
            // SYSTEM STATE
            // ================================================================
            property bool showHelpIcon: true
            property bool isRecording: false
            property bool updateAvailable: false
            property bool forceUpdateShow: false
            property bool isUpdateVisible: updateAvailable || forceUpdateShow
            property int workspaceCount: 8

            property bool isDesktop: false
            property string ethStatus: "Ethernet"

            Process {
                id: chassisDetector
                running: true
                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        dockWindow.isDesktop = (this.text.trim() === "desktop");
                    }
                }
            }

            property bool isStartupReady: false
            Timer { interval: 10; running: true; onTriggered: dockWindow.isStartupReady = true }
            property bool startupCascadeFinished: false
            Timer { interval: 1000; running: true; onTriggered: dockWindow.startupCascadeFinished = true }
            property bool fastPollerLoaded: false
            property bool isDataReady: false
            Timer { interval: 600; running: true; onTriggered: dockWindow.isDataReady = true }

            property string timeStr: ""
            property string fullDateStr: ""
            property int typeInIndex: 0
            property string dateStr: fullDateStr.substring(0, typeInIndex)

            property string weatherIcon: ""
            property string weatherTemp: "--°"
            property string weatherHex: colors.yellow

            property string cpuPercent: "--"
            property string ramPercent: "--"
            property bool sysDataReady: false

            property string wifiStatus: "Off"
            property string wifiIcon: "󰤮"
            property string wifiSsid: ""
            property string btStatus: "Off"
            property string btIcon: "󰂲"
            property string btDevice: ""
            property string volPercent: "0%"
            property string volIcon: "󰕾"
            property bool isMuted: false
            property string batPercent: "100%"
            property string batIcon: "󰁹"
            property string batStatus: "Unknown"
            property string kbLayout: "us"

            ListModel {
                id: workspacesModel
                property int activeIndex: 0
            }
            readonly property var wsModel: workspacesModel
            function refreshMusic() { musicForceRefresh.running = true; }

            property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }
            property string displayTitle: ""
            property string displayTime: ""
            property string displayArtUrl: ""
            onMusicDataChanged: {
                if (musicData && musicData.status !== "Stopped" && musicData.title !== "") {
                    displayTitle = musicData.title;
                    displayTime = musicData.timeStr;
                    displayArtUrl = musicData.artUrl;
                }
            }

            property bool isMediaActive: dockWindow.musicData.status !== "Stopped" && dockWindow.musicData.title !== ""
            property bool isWifiOn: dockWindow.wifiStatus.toLowerCase() === "enabled" || dockWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn: dockWindow.btStatus.toLowerCase() === "enabled" || dockWindow.btStatus.toLowerCase() === "on"
            property bool showEthernet: dockWindow.ethStatus === "Connected" || (dockWindow.isDesktop && !dockWindow.isWifiOn)
            property bool isSoundActive: !dockWindow.isMuted && parseInt(dockWindow.volPercent) > 0
            property int batCap: parseInt(dockWindow.batPercent) || 0
            property bool isCharging: dockWindow.batStatus === "Charging" || dockWindow.batStatus === "Full"
            property color batDynamicColor: {
                if (isCharging) return colors.green;
                if (batCap <= 20) return colors.red;
                return colors.text;
            }

            // ================================================================
            // WORKSPACES
            // ================================================================
            Process {
                id: wsDaemon
                command: ["bash", "-c", "~/.config/hypr/scripts/workspaces.sh"]
                running: true
            }
            Process {
                id: wsReader
                running: true
                command: ["cat", paths.getRunDir("workspaces") + "/workspaces.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let newData = JSON.parse(txt);
                                while (workspacesModel.count < newData.length) {
                                    workspacesModel.append({ "wsId": "", "wsState": "", "wsClasses": "" });
                                }
                                while (workspacesModel.count > newData.length) {
                                    workspacesModel.remove(workspacesModel.count - 1);
                                }
                                let newActive = -1;
                                for (let i = 0; i < newData.length; i++) {
                                    if (newData[i].state === "active") newActive = i;
                                    if (workspacesModel.get(i).wsState !== newData[i].state) {
                                        workspacesModel.setProperty(i, "wsState", newData[i].state);
                                    }
                                    if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                        workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                    }
                                    if (newData[i].classes != undefined && workspacesModel.get(i).wsClasses !== newData[i].classes) {
                                        workspacesModel.setProperty(i, "wsClasses", newData[i].classes);
                                    }
                                }
                                if (newActive !== -1 && workspacesModel.activeIndex !== newActive) {
                                    workspacesModel.activeIndex = newActive;
                                }
                            } catch(e) {}
                        }
                    }
                }
            }
            Process {
                id: wsWatcher
                running: true
                command: ["bash", "-c", "inotifywait -qq -e close_write,modify " + paths.getRunDir("workspaces") + "/workspaces.json"]
                onExited: {
                    wsReader.running = false;
                    wsReader.running = true;
                    running = false;
                    running = true;
                }
            }
            // Fallback: if the model is still empty (the JSON existed before we
            // started, so no inotify event fires), poll until data arrives.
            Timer {
                interval: 2500
                running: true
                repeat: true
                onTriggered: {
                    if (workspacesModel.count === 0) {
                        wsReader.running = false;
                        wsReader.running = true;
                    }
                }
            }

            // ================================================================
            // MUSIC / MPRIS
            // ================================================================
            Process {
                id: musicForceRefresh
                running: true
                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee " + paths.getRunDir("music") + "/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { dockWindow.musicData = JSON.parse(txt); } catch(e) {}
                        }
                    }
                }
            }
            Timer {
                interval: 1000
                running: dockWindow.musicData !== null && dockWindow.musicData.status === "Playing"
                repeat: true
                onTriggered: {
                    if (!dockWindow.musicData || dockWindow.musicData.status !== "Playing") return;
                    if (!dockWindow.musicData.timeStr || dockWindow.musicData.timeStr === "") return;
                    let parts = dockWindow.musicData.timeStr.split(" / ");
                    if (parts.length !== 2) return;
                    let posParts = parts[0].split(":").map(Number);
                    let lenParts = parts[1].split(":").map(Number);
                    let posSecs = (posParts.length === 3)
                        ? (posParts[0] * 3600 + posParts[1] * 60 + posParts[2])
                        : (posParts[0] * 60 + posParts[1]);
                    let lenSecs = (lenParts.length === 3)
                        ? (lenParts[0] * 3600 + lenParts[1] * 60 + lenParts[2])
                        : (lenParts[0] * 60 + lenParts[1]);
                    if (isNaN(posSecs) || isNaN(lenSecs)) return;
                    posSecs++;
                    if (posSecs > lenSecs) posSecs = lenSecs;
                    let newPosStr = "";
                    if (posParts.length === 3) {
                        let h = Math.floor(posSecs / 3600);
                        let m = Math.floor((posSecs % 3600) / 60);
                        let s = posSecs % 60;
                        newPosStr = h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    } else {
                        let m = Math.floor(posSecs / 60);
                        let s = posSecs % 60;
                        newPosStr = (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
                    }
                    let newData = Object.assign({}, dockWindow.musicData);
                    newData.timeStr = newPosStr + " / " + parts[1];
                    newData.positionStr = newPosStr;
                    if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
                    dockWindow.musicData = newData;
                }
            }
            Process {
                id: mprisWatcher
                running: true
                command: ["bash", "-c", "dbus-monitor --session \"type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.mpris.MediaPlayer2.Player'\" \"type='signal',interface='org.mpris.MediaPlayer2.Player',member='Seeked'\" 2>/dev/null | grep -m 1 'member=' > /dev/null || sleep 2"]
                onExited: {
                    musicForceRefresh.running = false;
                    musicForceRefresh.running = true;
                    running = false;
                    running = true;
                }
            }
            Timer {
                id: artRetryTimer
                interval: 500
                repeat: true
                running: dockWindow.displayArtUrl && dockWindow.displayArtUrl.indexOf("placeholder_blank.png") !== -1
                onTriggered: {
                    musicForceRefresh.running = false;
                    musicForceRefresh.running = true;
                }
            }

            // ================================================================
            // KEYBOARD / AUDIO / NETWORK / BT / BATTERY
            // ================================================================
            Process {
                id: kbPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "" && dockWindow.kbLayout !== txt) dockWindow.kbLayout = txt;
                        kbWaiter.running = false;
                        kbWaiter.running = true;
                        dockWindow.fastPollerLoaded = true;
                    }
                }
            }
            Process { id: kbWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_wait.sh"]; onExited: { kbPoller.running = false; kbPoller.running = true; } }

            Process {
                id: audioPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newVol = data.volume.toString() + "%";
                                if (dockWindow.volPercent !== newVol) dockWindow.volPercent = newVol;
                                if (dockWindow.volIcon !== data.icon) dockWindow.volIcon = data.icon;
                                let newMuted = (data.is_muted === "true");
                                if (dockWindow.isMuted !== newMuted) dockWindow.isMuted = newMuted;
                            } catch(e) {}
                        }
                        audioWaiter.running = false;
                        audioWaiter.running = true;
                    }
                }
            }
            Process { id: audioWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/audio_wait.sh"]; onExited: { audioPoller.running = false; audioPoller.running = true; } }

            Process {
                id: networkPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (dockWindow.wifiStatus !== data.status) dockWindow.wifiStatus = data.status;
                                if (dockWindow.wifiIcon !== data.icon) dockWindow.wifiIcon = data.icon;
                                if (dockWindow.wifiSsid !== data.ssid) dockWindow.wifiSsid = data.ssid;
                                if (dockWindow.ethStatus !== data.eth_status) dockWindow.ethStatus = data.eth_status;
                            } catch(e) {}
                        }
                        networkWaiter.running = false;
                        networkWaiter.running = true;
                    }
                }
            }
            Process { id: networkWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/network_wait.sh"]; onExited: { networkPoller.running = false; networkPoller.running = true; } }

            Process {
                id: btPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                if (dockWindow.btStatus !== data.status) dockWindow.btStatus = data.status;
                                if (dockWindow.btIcon !== data.icon) dockWindow.btIcon = data.icon;
                                if (dockWindow.btDevice !== data.connected) dockWindow.btDevice = data.connected;
                            } catch(e) {}
                        }
                        btWaiter.running = false;
                        btWaiter.running = true;
                    }
                }
            }
            Process { id: btWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/bt_wait.sh"]; onExited: { btPoller.running = false; btPoller.running = true; } }

            Process {
                id: batteryPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try {
                                let data = JSON.parse(txt);
                                let newBat = data.percent.toString() + "%";
                                if (dockWindow.batPercent !== newBat) dockWindow.batPercent = newBat;
                                if (dockWindow.batIcon !== data.icon) dockWindow.batIcon = data.icon;
                                if (dockWindow.batStatus !== data.status) dockWindow.batStatus = data.status;
                            } catch(e) {}
                        }
                        batteryWaiter.running = false;
                        batteryWaiter.running = true;
                    }
                }
            }
            Process { id: batteryWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]; onExited: { batteryPoller.running = false; batteryPoller.running = true; } }

            // ================================================================
            // WEATHER
            // ================================================================
            Process {
                id: weatherPoller
                command: ["bash", "-c", `
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
                    echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
                `]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let lines = this.text.trim().split("\n");
                        if (lines.length >= 3) {
                            dockWindow.weatherIcon = lines[0];
                            dockWindow.weatherTemp = lines[1];
                            dockWindow.weatherHex = lines[2] || colors.yellow;
                        }
                    }
                }
            }
            Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }

            // ================================================================
            // SYSTEM MONITOR
            // ================================================================
            Process {
                id: sysmonPoller; running: true
                command: ["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/system-monitor/fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0) {
                                let d = JSON.parse(this.text.trim());
                                dockWindow.cpuPercent = (d.cpu || 0) + "%";
                                dockWindow.ramPercent = (d.ram_pct || 0) + "%";
                                dockWindow.sysDataReady = true;
                            }
                        } catch(e) {}
                    }
                }
            }
            Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: false; onTriggered: { sysmonPoller.running = false; sysmonPoller.running = true; } }

            // ================================================================
            // CLOCK + TYPEWRITER DATE
            // ================================================================
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    dockWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
                    dockWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    if (dockWindow.typeInIndex >= dockWindow.fullDateStr.length) {
                        dockWindow.typeInIndex = dockWindow.fullDateStr.length;
                    }
                }
            }
            Timer {
                id: typewriterTimer
                interval: 40
                running: dockWindow.isStartupReady && dockWindow.typeInIndex < dockWindow.fullDateStr.length
                repeat: true
                onTriggered: dockWindow.typeInIndex += 1
            }

            // ================================================================
            // ZONES
            // ================================================================
            Item {
                id: barContent
                anchors.fill: parent

                // Settings panel occupies an edge while open; shift the dock
                // content so nothing sits underneath it.
                anchors.leftMargin: settingsSlideProgress * (dockWindow.panelFromLeft ? s(450) : 0)
                anchors.rightMargin: settingsSlideProgress * (dockWindow.panelFromLeft ? 0 : s(450))

                // Zones only build once uiScale/baseScale are final (bar.s() is a
                // function, so modules can't reactively rescale after creation).
                visible: dockWindow.configReady
                Repeater {
                    model: dockWindow.zones
                    delegate: Zone {
                        required property var modelData
                        required property int index
                        bar: dockWindow
                        colors: dockWindow.colors
                        zoneData: modelData
                        zoneIndex: index
                    }
                }
            }
        }
    }
}
