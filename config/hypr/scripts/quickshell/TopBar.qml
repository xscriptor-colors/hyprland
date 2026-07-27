import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "topbar/TopbarLayout.js" as TopbarLayout

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: barWindow
            property bool pendingReload: false
            
	    Caching { id: paths }

	    Component.onCompleted: {
 	        console.log("runDir:", paths.runDir)
 	        console.log("manual path:", paths.runDir + "/workspaces")
 	        console.log("env test:", Quickshell.env("QS_RUN_WORKSPACES"))
 	        console.log("wsPath:", paths.getRunDir("workspaces"))
	    }	     	
        
            IpcHandler {
                target: "topbar"
                function forceReload() {
                    Quickshell.reload(true) 
                }
                function queueReload() {
                    if (!barWindow.isSettingsOpen) {
                        Quickshell.reload(true)
                    } else {
                        barWindow.pendingReload = true
                    }
                }
                function reloadColors() {
                    mocha.forceRefresh();
                }
                function toggleUpdate() {
                    barWindow.forceUpdateShow = !barWindow.forceUpdateShow
                }
            }

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            Scaler {
                id: scaler
                currentWidth: barWindow.width
            }

            property real baseScale: scaler.baseScale

            function s(val) { 
                return scaler.s(val); 
            }

            property int barHeight: s(48)
            property int pillHeight: s(36)

            // 1.0 = fully rounded pills, 0.0 = square corners.
            property real islandRoundness: 1.0
            function pillRadius(h) { return Math.round(h * 0.5 * islandRoundness); }

            // Whether island pills show a background fill.
            property bool topbarPillBg: true

            // Merge every module in a zone into one continuous pill.
            property bool topbarUnifyLeft: false
            property bool topbarUnifyCenter: false
            property bool topbarUnifyRight: false

            // Configurable border around island pills.
            property string topbarBorderMode: "unified"
            property real topbarBorderWidth: 0
            property string topbarBorderColor: "surface1"
            property real topbarBorderWidthLeft: 0
            property string topbarBorderColorLeft: "surface1"
            property real topbarBorderWidthCenter: 0
            property string topbarBorderColorCenter: "surface1"
            property real topbarBorderWidthRight: 0
            property string topbarBorderColorRight: "surface1"

            // Width of the settings panel, which docks to the left screen edge.
            // Bar content shifts right by this much so nothing sits underneath it.
            property int settingsPanelWidth: s(450)

            height: barHeight
            margins { top: s(8); bottom: 0; left: s(4); right: s(4) }
            exclusiveZone: barHeight 
            color: "transparent"

            MatugenColors {
                id: mocha
            }

            property bool showHelpIcon: true
            property bool isRecording: false
            
            property bool updateAvailable: false
            property bool forceUpdateShow: false
            property bool isUpdateVisible: updateAvailable || forceUpdateShow
            
            property int workspaceCount: 8

            property var topbarLayout: TopbarLayout.defaultLayout()
            readonly property var leftModules: TopbarLayout.zoneModel(topbarLayout, "left")
            readonly property var centerModules: TopbarLayout.zoneModel(topbarLayout, "center")
            readonly property var rightModules: TopbarLayout.zoneModel(topbarLayout, "right")

            property string activeWidget: ""
            property bool isSettingsOpen: activeWidget === "settings"

            property real settingsSlideProgress: isSettingsOpen ? 1.0 : 0.0
            Behavior on settingsSlideProgress { 
                enabled: barWindow.startupCascadeFinished
                NumberAnimation { duration: 600; easing.type: Easing.OutExpo } 
            }

            onIsSettingsOpenChanged: {
                if (!barWindow.isSettingsOpen && barWindow.pendingReload) {
                    barWindow.pendingReload = false;
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
                        if (barWindow.activeWidget !== txt) barWindow.activeWidget = txt;
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
                        barWindow.isRecording = (this.text.trim() === "1");
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
	                barWindow.updateAvailable = (this.text.trim() === "1");
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
	                
            Process {
                id: settingsReader
                command: ["bash", "-c", "cat ~/.config/hypr/settings.json 2>/dev/null || echo '{}'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                                let parsed = JSON.parse(this.text);
                                
                                if (parsed.topbarHelpIcon !== undefined && barWindow.showHelpIcon !== parsed.topbarHelpIcon) {
                                    barWindow.showHelpIcon = parsed.topbarHelpIcon;
                                }
                                
                                if (parsed.topbarRoundness !== undefined && barWindow.islandRoundness !== parsed.topbarRoundness) {
                                    barWindow.islandRoundness = parsed.topbarRoundness;
                                }

                                if (parsed.topbarPillBg !== undefined && barWindow.topbarPillBg !== parsed.topbarPillBg) {
                                    barWindow.topbarPillBg = parsed.topbarPillBg;
                                }

                                if (parsed.topbarUnifyLeft !== undefined && barWindow.topbarUnifyLeft !== parsed.topbarUnifyLeft)
                                    barWindow.topbarUnifyLeft = parsed.topbarUnifyLeft;
                                if (parsed.topbarUnifyCenter !== undefined && barWindow.topbarUnifyCenter !== parsed.topbarUnifyCenter)
                                    barWindow.topbarUnifyCenter = parsed.topbarUnifyCenter;
                                if (parsed.topbarUnifyRight !== undefined && barWindow.topbarUnifyRight !== parsed.topbarUnifyRight)
                                    barWindow.topbarUnifyRight = parsed.topbarUnifyRight;

                                if (parsed.topbarBorderWidth !== undefined && barWindow.topbarBorderWidth !== parsed.topbarBorderWidth) {
                                    barWindow.topbarBorderWidth = parsed.topbarBorderWidth;
                                }
                                if (parsed.topbarBorderColor !== undefined && barWindow.topbarBorderColor !== parsed.topbarBorderColor) {
                                    barWindow.topbarBorderColor = parsed.topbarBorderColor;
                                }
                                if (parsed.topbarBorderMode !== undefined && barWindow.topbarBorderMode !== parsed.topbarBorderMode) {
                                    barWindow.topbarBorderMode = parsed.topbarBorderMode;
                                }

                                if (parsed.topbarBorderWidthLeft !== undefined && barWindow.topbarBorderWidthLeft !== parsed.topbarBorderWidthLeft)
                                    barWindow.topbarBorderWidthLeft = parsed.topbarBorderWidthLeft;
                                if (parsed.topbarBorderColorLeft !== undefined && barWindow.topbarBorderColorLeft !== parsed.topbarBorderColorLeft)
                                    barWindow.topbarBorderColorLeft = parsed.topbarBorderColorLeft;
                                if (parsed.topbarBorderWidthCenter !== undefined && barWindow.topbarBorderWidthCenter !== parsed.topbarBorderWidthCenter)
                                    barWindow.topbarBorderWidthCenter = parsed.topbarBorderWidthCenter;
                                if (parsed.topbarBorderColorCenter !== undefined && barWindow.topbarBorderColorCenter !== parsed.topbarBorderColorCenter)
                                    barWindow.topbarBorderColorCenter = parsed.topbarBorderColorCenter;
                                if (parsed.topbarBorderWidthRight !== undefined && barWindow.topbarBorderWidthRight !== parsed.topbarBorderWidthRight)
                                    barWindow.topbarBorderWidthRight = parsed.topbarBorderWidthRight;
                                if (parsed.topbarBorderColorRight !== undefined && barWindow.topbarBorderColorRight !== parsed.topbarBorderColorRight)
                                    barWindow.topbarBorderColorRight = parsed.topbarBorderColorRight;

                                if (parsed.workspaceCount !== undefined && barWindow.workspaceCount !== parsed.workspaceCount) {
                                    barWindow.workspaceCount = parsed.workspaceCount;
                                    wsDaemon.running = false;
                                    wsDaemon.running = true;
                                }

                                // Only reassign when the layout really changed, so writes to
                                // unrelated keys don't tear down and rebuild every module.
                                let nextLayout = TopbarLayout.normalize(parsed.topbar);
                                if (JSON.stringify(nextLayout) !== JSON.stringify(barWindow.topbarLayout)) {
                                    barWindow.topbarLayout = nextLayout;
                                }
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
            
            property bool isDesktop: false
            property string ethStatus: "Ethernet"

            Process {
                id: chassisDetector
                running: true
                command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        barWindow.isDesktop = (this.text.trim() === "desktop");
                    }
                }
            }

            property bool isStartupReady: false
            Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
            
            property bool startupCascadeFinished: false
            Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
            
            property bool fastPollerLoaded: false
            property bool isDataReady: fastPollerLoaded
            Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
            
            property string timeStr: ""
            property string fullDateStr: ""
            property int typeInIndex: 0
            property string dateStr: fullDateStr.substring(0, typeInIndex)

            property string weatherIcon: ""
            property string weatherTemp: "--°"
            property string weatherHex: mocha.yellow
            
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

            // Exposed to topbar modules, which cannot reach ids in this file.
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

            property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
            property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
            property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
            property bool showEthernet: barWindow.ethStatus === "Connected" || (barWindow.isDesktop && !barWindow.isWifiOn)
            
            property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
            property int batCap: parseInt(barWindow.batPercent) || 0
            property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"
            
            property color batDynamicColor: {
                if (isCharging) return mocha.green;
                if (batCap <= 20) return mocha.red;
                return mocha.text; 
            }

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

            Process {
                id: musicForceRefresh
                running: true
                command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee " + paths.getRunDir("music") + "/music_info.json"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "") {
                            try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                        }
                    }
                }
            }

            Timer {
                interval: 1000
                running: barWindow.musicData !== null && barWindow.musicData.status === "Playing"
                repeat: true
                onTriggered: {
                    if (!barWindow.musicData || barWindow.musicData.status !== "Playing") return;
                    if (!barWindow.musicData.timeStr || barWindow.musicData.timeStr === "") return;

                    let parts = barWindow.musicData.timeStr.split(" / ");
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

                    let newData = Object.assign({}, barWindow.musicData);
                    newData.timeStr = newPosStr + " / " + parts[1];
                    newData.positionStr = newPosStr;
                    if (lenSecs > 0) newData.percent = (posSecs / lenSecs) * 100;
                    
                    barWindow.musicData = newData;
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
                running: barWindow.displayArtUrl && barWindow.displayArtUrl.indexOf("placeholder_blank.png") !== -1
                onTriggered: {
                    musicForceRefresh.running = false;
                    musicForceRefresh.running = true;
                }
            }

            Process {
                id: kbPoller; running: true
                command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/kb_fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        let txt = this.text.trim();
                        if (txt !== "" && barWindow.kbLayout !== txt) barWindow.kbLayout = txt;
                        kbWaiter.running = false;
                        kbWaiter.running = true;
                        barWindow.fastPollerLoaded = true; 
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
                                if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
                                if (barWindow.volIcon !== data.icon) barWindow.volIcon = data.icon;
                                let newMuted = (data.is_muted === "true");
                                if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;
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
                                if (barWindow.wifiStatus !== data.status) barWindow.wifiStatus = data.status;
                                if (barWindow.wifiIcon !== data.icon) barWindow.wifiIcon = data.icon;
                                if (barWindow.wifiSsid !== data.ssid) barWindow.wifiSsid = data.ssid;
                                if (barWindow.ethStatus !== data.eth_status) barWindow.ethStatus = data.eth_status;
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
                                if (barWindow.btStatus !== data.status) barWindow.btStatus = data.status;
                                if (barWindow.btIcon !== data.icon) barWindow.btIcon = data.icon;
                                if (barWindow.btDevice !== data.connected) barWindow.btDevice = data.connected;
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
                                if (barWindow.batPercent !== newBat) barWindow.batPercent = newBat;
                                if (barWindow.batIcon !== data.icon) barWindow.batIcon = data.icon;
                                if (barWindow.batStatus !== data.status) barWindow.batStatus = data.status;
                            } catch(e) {}
                        }
                        batteryWaiter.running = false;
                        batteryWaiter.running = true;
                    }
                }
            }
            Process { id: batteryWaiter; command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/watchers/battery_wait.sh"]; onExited: { batteryPoller.running = false; batteryPoller.running = true; } }

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
                            barWindow.weatherIcon = lines[0];
                            barWindow.weatherTemp = lines[1];
                            barWindow.weatherHex = lines[2] || mocha.yellow;
                        }
                    }
                }
            }
            Timer { interval: 150000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherPoller.running = false; weatherPoller.running = true; } }

            Process {
                id: sysmonPoller; running: true
                command: ["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/system-monitor/fetch.sh"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (this.text && this.text.trim().length > 0) {
                                let d = JSON.parse(this.text.trim())
                                barWindow.cpuPercent = (d.cpu || 0) + "%"
                                barWindow.ramPercent = (d.ram_pct || 0) + "%"
                                barWindow.sysDataReady = true
                            }
                        } catch(e) {}
                    }
                }
            }
            Timer { interval: 8000; running: true; repeat: true; triggeredOnStart: false; onTriggered: { sysmonPoller.running = false; sysmonPoller.running = true } }

            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: {
                    let d = new Date();
                    barWindow.timeStr = Qt.formatDateTime(d, "HH:mm:ss");
                    barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
                    if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                        barWindow.typeInIndex = barWindow.fullDateStr.length;
                    }
                }
            }

            Timer {
                id: typewriterTimer
                interval: 40
                running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
                repeat: true
                onTriggered: barWindow.typeInIndex += 1
            }

            Item {
                id: barContent
                anchors.fill: parent

                // The settings panel docks to the left screen edge, so slide the whole
                // bar out of its way instead of hiding individual modules.
                anchors.leftMargin: barWindow.settingsSlideProgress * barWindow.settingsPanelWidth

                // ── Left zone ───────────────────────────────────────────────
                Item {
                    id: leftWrapper
                    anchors.left: parent.left
                    anchors.leftMargin: barWindow.s(10)
                    height: parent.height
                    width: leftZone.width + (barWindow.topbarUnifyLeft ? barWindow.s(12) : 0)

                    Rectangle {
                        anchors.fill: parent
                        radius: barWindow.pillRadius(barWindow.pillHeight)
                        color: barWindow.topbarUnifyLeft && barWindow.topbarPillBg
                            ? Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.5)
                            : "transparent"
                        border.width: barWindow.topbarUnifyLeft ? barWindow.topbarBorderWidth : 0
                        border.color: mocha[barWindow.topbarBorderColor] || mocha.surface1
                        visible: barWindow.topbarUnifyLeft
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Row {
                        id: leftZone
                        anchors.left: parent.left
                        anchors.leftMargin: barWindow.topbarUnifyLeft ? barWindow.s(6) : 0
                        height: parent.height
                        spacing: barWindow.topbarUnifyLeft ? 0 : barWindow.s(8)

                        property bool showLayout: false
                        Timer {
                            running: barWindow.isStartupReady
                            interval: 10
                            onTriggered: leftZone.showLayout = true
                        }

                        opacity: showLayout ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        transform: Translate {
                            x: leftZone.showLayout ? 0 : barWindow.s(-200)
                            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                        }

                        Repeater {
                            model: barWindow.leftModules
                            delegate: Loader {
                                required property string modelData
                                required property int index
                                width: item ? item.implicitWidth : 0
                                height: leftZone.height
                                Component.onCompleted: {
                                    let mod = TopbarLayout.getModule(modelData);
                                    if (!mod) return;
                                    setSource(mod.component, {
                                        "bar": barWindow,
                                        "colors": mocha,
                                        "zoneReady": Qt.binding(() => leftZone.showLayout),
                                        "slotIndex": index,
                                        "effectiveBorderWidth": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderWidth : barWindow.topbarBorderWidthLeft),
                                        "effectiveBorderColor": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderColor : barWindow.topbarBorderColorLeft),
                                        "unified": Qt.binding(() => barWindow.topbarUnifyLeft)
                                    });
                                }
                            }
                        }
                    }
                }

                // ── Center zone ─────────────────────────────────────────────
                Item {
                    id: centerWrapper
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.height
                    width: centerZone.width + (barWindow.topbarUnifyCenter ? barWindow.s(12) : 0)

                    Rectangle {
                        anchors.fill: parent
                        radius: barWindow.pillRadius(barWindow.pillHeight)
                        color: barWindow.topbarUnifyCenter && barWindow.topbarPillBg
                            ? Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.5)
                            : "transparent"
                        border.width: barWindow.topbarUnifyCenter ? barWindow.topbarBorderWidth : 0
                        border.color: mocha[barWindow.topbarBorderColor] || mocha.surface1
                        visible: barWindow.topbarUnifyCenter
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Row {
                        id: centerZone
                        anchors.centerIn: parent
                        height: parent.height
                        spacing: barWindow.topbarUnifyCenter ? 0 : barWindow.s(12)

                        property bool showLayout: false
                        Timer {
                            running: barWindow.isStartupReady
                            interval: 150
                            onTriggered: centerZone.showLayout = true
                        }

                        opacity: showLayout ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        transform: Translate {
                            y: centerZone.showLayout ? 0 : barWindow.s(-30)
                            Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                        }

                        Repeater {
                            model: barWindow.centerModules
                            delegate: Loader {
                                required property string modelData
                                required property int index
                                width: item ? item.implicitWidth : 0
                                height: centerZone.height
                                Component.onCompleted: {
                                    let mod = TopbarLayout.getModule(modelData);
                                    if (!mod) return;
                                    setSource(mod.component, {
                                        "bar": barWindow,
                                        "colors": mocha,
                                        "zoneReady": Qt.binding(() => centerZone.showLayout),
                                        "slotIndex": index,
                                        "effectiveBorderWidth": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderWidth : barWindow.topbarBorderWidthCenter),
                                        "effectiveBorderColor": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderColor : barWindow.topbarBorderColorCenter),
                                        "unified": Qt.binding(() => barWindow.topbarUnifyCenter)
                                    });
                                }
                            }
                        }
                    }
                }

                // ── Right zone ──────────────────────────────────────────────
                Item {
                    id: rightWrapper
                    anchors.right: parent.right
                    anchors.rightMargin: barWindow.s(10)
                    height: parent.height
                    width: rightZone.width + (barWindow.topbarUnifyRight ? barWindow.s(12) : 0)

                    Rectangle {
                        anchors.fill: parent
                        radius: barWindow.pillRadius(barWindow.pillHeight)
                        color: barWindow.topbarUnifyRight && barWindow.topbarPillBg
                            ? Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.5)
                            : "transparent"
                        border.width: barWindow.topbarUnifyRight ? barWindow.topbarBorderWidth : 0
                        border.color: mocha[barWindow.topbarBorderColor] || mocha.surface1
                        visible: barWindow.topbarUnifyRight
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Row {
                        id: rightZone
                        anchors.right: parent.right
                        anchors.rightMargin: barWindow.topbarUnifyRight ? barWindow.s(6) : 0
                        height: parent.height
                        spacing: barWindow.topbarUnifyRight ? 0 : barWindow.s(8)

                        property bool showLayout: false
                        Timer {
                            running: barWindow.isStartupReady && barWindow.isDataReady
                            interval: 250
                            onTriggered: rightZone.showLayout = true
                        }

                        opacity: showLayout ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        transform: Translate {
                            x: rightZone.showLayout ? 0 : barWindow.s(30)
                            Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                        }

                        Repeater {
                            model: barWindow.rightModules
                            delegate: Loader {
                                required property string modelData
                                required property int index
                                width: item ? item.implicitWidth : 0
                                height: rightZone.height
                                Component.onCompleted: {
                                    let mod = TopbarLayout.getModule(modelData);
                                    if (!mod) return;
                                    setSource(mod.component, {
                                        "bar": barWindow,
                                        "colors": mocha,
                                        "zoneReady": Qt.binding(() => rightZone.showLayout),
                                        "slotIndex": index,
                                        "effectiveBorderWidth": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderWidth : barWindow.topbarBorderWidthRight),
                                        "effectiveBorderColor": Qt.binding(() => barWindow.topbarBorderMode === "unified" ? barWindow.topbarBorderColor : barWindow.topbarBorderColorRight),
                                        "unified": Qt.binding(() => barWindow.topbarUnifyRight)
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
