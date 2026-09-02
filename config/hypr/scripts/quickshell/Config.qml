pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "topbar/TopbarLayout.js" as TopbarLayout

Item {
    id: config

    Caching { id: paths }

    // =========================================================================
    // Core Paths & Environment
    // =========================================================================
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string hyprDir: homeDir + "/.config/hypr"
    readonly property string qsScriptsDir: hyprDir + "/scripts/quickshell"
    readonly property string cacheDir: paths.cacheDir
    
    readonly property string settingsJsonPath: hyprDir + "/settings.json"
    readonly property string weatherEnvPath: qsScriptsDir + "/calendar/.env"

    // State Tracking
    property bool dataReady: false
    property var rawSettings: ({})
    property var rawEnvs: ({})

    // =========================================================================
    // Generic Utilities (Use these in ANY widget!)
    // =========================================================================

    // Execute a background bash command easily
    function sh(cmd) {
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    // --- JSON Operations ---
    function getSetting(key, fallbackValue) {
        return rawSettings.hasOwnProperty(key) ? rawSettings[key] : fallbackValue;
    }

    // Uses a unique temp file per call (mktemp) so concurrent saves never
    // overwrite each other's temp file, preventing JSON corruption.
    function setSetting(key, value) {
        rawSettings[key] = value;
        let safeValue = typeof value === "string" ? `"${value}"` : value;
        if (typeof value === "object") safeValue = JSON.stringify(value).replace(/'/g, "'\\''");

        let cmd = `mkdir -p "$(dirname '${settingsJsonPath}')" && ` +
                  `[ ! -f '${settingsJsonPath}' ] && echo '{}' > '${settingsJsonPath}'; ` +
                  `tmp=$(mktemp '${settingsJsonPath}'.tmp.XXXXXX) && ` +
                  `jq '. + {"${key}": ${safeValue}}' '${settingsJsonPath}' > "$tmp" && ` +
                  `mv "$tmp" '${settingsJsonPath}'`;
        sh(cmd);
    }

    function updateJsonBulk(dataObj) {
        let jsonStr = JSON.stringify(dataObj).replace(/'/g, "'\\''");
        let cmd = `mkdir -p "$(dirname '${settingsJsonPath}')" && ` +
                  `[ ! -f '${settingsJsonPath}' ] && echo '{}' > '${settingsJsonPath}'; ` +
                  `tmp=$(mktemp '${settingsJsonPath}'.tmp.XXXXXX) && ` +
                  `jq '. + ${jsonStr}' '${settingsJsonPath}' > "$tmp" && ` +
                  `mv "$tmp" '${settingsJsonPath}'`;
        sh(cmd);

        for (let key in dataObj) rawSettings[key] = dataObj[key];
    }

    // --- Env Operations ---
    function getEnv(key, fallbackValue) {
        return rawEnvs.hasOwnProperty(key) ? rawEnvs[key] : fallbackValue;
    }

    function updateEnvBulk(filePath, envDict) {
        let cmds = [`mkdir -p "$(dirname '${filePath}')"`, `touch '${filePath}'`];
        for (let key in envDict) {
            rawEnvs[key] = envDict[key];
            let safeVal = envDict[key].toString().replace(/'/g, "'\\''");
            cmds.push(`if grep -q "^${key}=" '${filePath}'; then ` +
                      `sed -i "s|^${key}=.*|${key}='${safeVal}'|" '${filePath}'; ` +
                      `else echo "${key}='${safeVal}'" >> '${filePath}'; fi`);
        }
        sh(cmds.join(" && "));
    }

    // =========================================================================
    // Legacy Specific Properties (Bound to Settings.qml)
    // =========================================================================
    property real uiScale: 1.0
    property bool openGuideAtStartup: true
    property bool topbarHelpIcon: true
    property real topbarRoundness: 1.0
    property bool topbarPillBg: true
    property bool topbarPillSolid: false
    property bool topbarUnifyLeft: false
    property bool topbarUnifyCenter: false
    property bool topbarUnifyRight: false
    property string topbarBorderMode: "unified"
    property real topbarBorderWidth: 0
    property string topbarBorderColor: "surface1"
    property real topbarBorderWidthLeft: 0
    property string topbarBorderColorLeft: "surface1"
    property real topbarBorderWidthCenter: 0
    property string topbarBorderColorCenter: "surface1"
    property real topbarBorderWidthRight: 0
    property string topbarBorderColorRight: "surface1"
    property real appScale: 1.0
    property int workspaceCount: 8
    property int initialWorkspaceCount: 8
    property string wallpaperDir: {
        const saved = getSetting("wallpaperDir", "");
        return saved !== "" ? saved : (Quickshell.env("WALLPAPER_DIR") || homeDir + "/.config/hypr/wallpapers");
    }
    property string language: ""
    property string kbOptions: "grp:alt_shift_toggle"

    property string weatherUnit: "metric"
    property string weatherApiKey: ""
    property string weatherCityId: ""

    property var keybindsData: []
    signal keybindsLoaded()

    property var startupData: []
    signal startupLoaded()

    property var topbarLayout: TopbarLayout.defaultLayout()
    signal topbarLayoutLoaded()

    // =========================================================================
    // Settings Save Functions
    // =========================================================================
    function saveAppSettings() {
        let configObj = {
            "uiScale": config.uiScale,
            "openGuideAtStartup": config.openGuideAtStartup,
            "topbarHelpIcon": config.topbarHelpIcon,
            "appScale": config.appScale,
            "wallpaperDir": config.wallpaperDir,
            "language": config.language,
            "kbOptions": config.kbOptions,
            "workspaceCount": config.workspaceCount
        };

        config.updateJsonBulk(configObj);
        sh("notify-send 'Quickshell' 'Settings Applied Successfully!'");

        if (config.workspaceCount !== config.initialWorkspaceCount) {
            sh(`qs -p "${qsScriptsDir}/dock/Dock.qml" ipc call topbar queueReload`);
            config.initialWorkspaceCount = config.workspaceCount;
        }
    }

    function saveWeatherConfig() {
        let envs = {
            "OPENWEATHER_KEY": config.weatherApiKey,
            "OPENWEATHER_CITY_ID": config.weatherCityId,
            "OPENWEATHER_UNIT": config.weatherUnit
        };
        
        config.updateEnvBulk(config.weatherEnvPath, envs);
        sh(`rm -rf "${paths.getCacheDir('weather')}"`);
        sh("notify-send 'Weather' 'API configuration saved successfully!'");
    }

    function saveAllKeybinds(bindsArray) {
        config.keybindsData = bindsArray;
        config.setSetting("keybinds", bindsArray);

        // Hyprland 0.55+ loads keybinds from Lua, not from settings.json.
        // Generate ~/.config/hypr/config/user-keybinds.lua and reload.
        let lines = [];
        lines.push("-- Auto-generated by the QuickShell settings panel.");
        lines.push("-- Bound to SUPER+SHIFT+S -> Keybindings. Do not edit manually.");
        lines.push("");
        for (let i = 0; i < bindsArray.length; i++) {
            let b = bindsArray[i];
            if (!b.key || !b.dispatcher) continue;
            let flags = [];
            if (b.type === "bindl") flags.push("locked = true");
            else if (b.type === "bindel") { flags.push("locked = true"); flags.push("repeating = true"); }
            else if (b.type === "bindm") flags.push("mouse = true");
            let keys = (b.mods ? b.mods.replace(/&/g, " ").trim() + " + " : "") + b.key;
            let dsp = config.luaDispatcherFor(b.dispatcher, b.command);
            if (!dsp) {
                lines.push("-- [skipped] " + b.dispatcher + " " + (b.command || "") + " (no Lua equivalent)");
                continue;
            }
            if (flags.length > 0) {
                lines.push("hl.bind(\"" + keys + "\", " + dsp + ", { " + flags.join(", ") + " })");
            } else {
                lines.push("hl.bind(\"" + keys + "\", " + dsp + ")");
            }
        }
        lines.push("");
        let lua = lines.join("\n");
        config.sh("mkdir -p ~/.config/hypr/config && cat > ~/.config/hypr/config/user-keybinds.lua << 'LUAEOF'\n" + lua + "LUAEOF\nhyprctl reload");
        sh("notify-send 'Quickshell' 'Keybinds Saved Successfully!'");
    }

    // Maps the settings panel's legacy dispatcher names to the Lua API.
    function luaDispatcherFor(dispatcher, command) {
        command = (command || "").trim();
        let dir = { "l": "l", "r": "r", "u": "u", "d": "d" };
        switch (dispatcher) {
            case "exec":
            case "exec-once":
                return "hl.dsp.exec_cmd(" + JSON.stringify(command) + ")";
            case "workspace":
                return "hl.dsp.focus({ workspace = " + JSON.stringify(command) + " })";
            case "movetoworkspace":
                return "hl.dsp.window.move({ workspace = " + JSON.stringify(command) + " })";
            case "movewindow":
                return dir[command] ? "hl.dsp.window.move({ direction = \"" + command + "\" })" : "hl.dsp.window.move({ monitor = " + JSON.stringify(command) + " })";
            case "movefocus":
                return "hl.dsp.focus({ direction = \"" + (dir[command] || "l") + "\" })";
            case "resizeactive": {
                let parts = command.split(/[\s,]+/);
                let x = parseInt(parts[0]) || 0, y = parseInt(parts[1]) || 0;
                return "hl.dsp.window.resize({ x = " + x + ", y = " + y + ", relative = true })";
            }
            case "togglefloating":
                return "hl.dsp.window.float({ action = \"toggle\" })";
            case "killactive":
                return "hl.dsp.window.kill()";
            default:
                return null;
        }
    }

    function saveAllStartup(startupArray) {
        config.startupData = startupArray;
        config.setSetting("startup", startupArray);

        // Hyprland 0.55+ runs startup entries from Lua (autostart.lua).
        let lines = [];
        lines.push("-- Auto-generated by the QuickShell settings panel.");
        lines.push("-- Extra startup commands run once at session start.");
        lines.push("");
        lines.push("hl.on(\"hyprland.start\", function()");
        for (let i = 0; i < startupArray.length; i++) {
            let s = startupArray[i];
            if (!s.command || !s.command.trim()) continue;
            lines.push("    hl.exec_cmd(" + JSON.stringify(s.command.trim()) + ")");
        }
        lines.push("end)");
        lines.push("");
        config.sh("mkdir -p ~/.config/hypr/config && cat > ~/.config/hypr/config/user-startup.lua << 'LUAEOF'\n" + lines.join("\n") + "LUAEOF\nhyprctl reload");
        sh("notify-send 'Quickshell' 'Startup entries saved!'");
    }

    function saveTopbarRoundness(value) {
        config.topbarRoundness = value;
        config.setSetting("topbarRoundness", value);
    }

    function saveTopbarPillBg(value) {
        config.topbarPillBg = value;
        config.setSetting("topbarPillBg", value);
    }

    function saveTopbarPillSolid(value) {
        config.topbarPillSolid = value;
        config.setSetting("topbarPillSolid", value);
    }

    function saveTopbarUnifyLeft(value) {
        config.topbarUnifyLeft = value;
        config.setSetting("topbarUnifyLeft", value);
    }
    function saveTopbarUnifyCenter(value) {
        config.topbarUnifyCenter = value;
        config.setSetting("topbarUnifyCenter", value);
    }
    function saveTopbarUnifyRight(value) {
        config.topbarUnifyRight = value;
        config.setSetting("topbarUnifyRight", value);
    }

    function saveTopbarBorderWidth(value) {
        config.topbarBorderWidth = value;
        config.setSetting("topbarBorderWidth", value);
    }

    function saveTopbarBorderColor(value) {
        config.topbarBorderColor = value;
        config.setSetting("topbarBorderColor", value);
    }

    function saveTopbarBorderMode(value) {
        config.topbarBorderMode = value;
        config.setSetting("topbarBorderMode", value);
    }

    function saveTopbarBorderWidthLeft(value) {
        config.topbarBorderWidthLeft = value;
        config.setSetting("topbarBorderWidthLeft", value);
    }
    function saveTopbarBorderColorLeft(value) {
        config.topbarBorderColorLeft = value;
        config.setSetting("topbarBorderColorLeft", value);
    }
    function saveTopbarBorderWidthCenter(value) {
        config.topbarBorderWidthCenter = value;
        config.setSetting("topbarBorderWidthCenter", value);
    }
    function saveTopbarBorderColorCenter(value) {
        config.topbarBorderColorCenter = value;
        config.setSetting("topbarBorderColorCenter", value);
    }
    function saveTopbarBorderWidthRight(value) {
        config.topbarBorderWidthRight = value;
        config.setSetting("topbarBorderWidthRight", value);
    }
    function saveTopbarBorderColorRight(value) {
        config.topbarBorderColorRight = value;
        config.setSetting("topbarBorderColorRight", value);
    }

    // No notification here on purpose: the topbar tab edits live and the bar
    // itself is the feedback, so a toast per keystroke would only be noise.
    function saveTopbarLayout(layoutObj) {
        config.topbarLayout = TopbarLayout.normalize(layoutObj);
        config.setSetting("topbar", config.topbarLayout);
    }

    // =========================================================================
    // Monitor Management
    // =========================================================================
    property alias monitorsModel: _monitorsModel
    ListModel { id: _monitorsModel }
    property int monActiveEditIndex: 0
    property real monUiScale: 0.10
    property int monOriginalOriginX: 0
    property int monOriginalOriginY: 0

    function monIsOverlapping(ax, ay, aw, ah, bx, by, bw, bh) {
        return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
    }

    function monIsOverlappingAny(x, y, w, h, skipIdx) {
        for (let i = 0; i < monitorsModel.count; i++) {
            if (i === skipIdx) continue;
            let m = monitorsModel.get(i);
            let isP = m.transform === 1 || m.transform === 3;
            let mW = ((isP ? m.resH : m.resW) / m.sysScale) * config.monUiScale;
            let mH = ((isP ? m.resW : m.resH) / m.sysScale) * config.monUiScale;
            if (config.monIsOverlapping(x, y, w, h, m.uiX, m.uiY, mW, mH)) return true;
        }
        return false;
    }

    function monGetPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH },
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH },
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH },
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }
        ];
        let bestX = pX, bestY = pY, minDist = 999999;
        for (let i = 0; i < 4; i++) {
            let e = edges[i];
            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));
            if (Math.abs(cx - sX) < snapT) cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            if (Math.abs(cy - sY) < snapT) cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;
            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) { minDist = dist; bestX = cx; bestY = cy; }
        }
        return { x: bestX, y: bestY };
    }

    function monForceLayoutUpdate() {
        if (monitorsModel.count < 2) return;
        let mIdx = config.monActiveEditIndex;
        let mModel = monitorsModel.get(mIdx);
        let isP = mModel.transform === 1 || mModel.transform === 3;
        let mW = ((isP ? mModel.resH : mModel.resW) / mModel.sysScale) * config.monUiScale;
        let mH = ((isP ? mModel.resW : mModel.resH) / mModel.sysScale) * config.monUiScale;
        let bestX = mModel.uiX, bestY = mModel.uiY, bestDist = 999999;
        for (let i = 0; i < monitorsModel.count; i++) {
            if (i === mIdx) continue;
            let sModel = monitorsModel.get(i);
            let sIsP = sModel.transform === 1 || sModel.transform === 3;
            let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * config.monUiScale;
            let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * config.monUiScale;
            let snapped = config.monGetPerimeterSnap(mModel.uiX, mModel.uiY, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);
            let dist = Math.hypot(snapped.x - mModel.uiX, snapped.y - mModel.uiY);
            if (dist < bestDist) { bestDist = dist; bestX = snapped.x; bestY = snapped.y; }
        }
        monitorsModel.setProperty(mIdx, "uiX", bestX);
        monitorsModel.setProperty(mIdx, "uiY", bestY);
    }

    function applyMonitors() {
        if (monitorsModel.count === 0) return;
        if (monitorsModel.count === 1) {
            let m = monitorsModel.get(0);
            // Hyprland 0.55+ has no `hyprctl keyword monitor`; use the Lua API.
            let lua = `hl.monitor({ output = \"${m.name}\", mode = \"${m.resW}x${m.resH}@${m.rate}\", position = \"0x0\", scale = ${m.sysScale}${m.transform !== 0 ? `, transform = ${m.transform}` : ""} })`;
            let jsonArr = [{ name: m.name, resW: m.resW, resH: m.resH, rate: parseInt(m.rate), x: 0, y: 0, scale: m.sysScale, transform: m.transform }];
            config.setSetting("monitors", jsonArr);
            config.sh(`hyprctl eval '${lua.replace(/'/g, "'\\''")}' ; pkill awww-daemon 2>/dev/null || true; awww-daemon & ; ~/.config/hypr/scripts/persist-display-config.sh > ~/.config/hypr/display-config 2>/dev/null`);
            Quickshell.execDetached(["notify-send", "Display Update", "Applied: " + m.resW + "x" + m.resH + " @ " + m.rate + "Hz"]);
        } else {
            let rects = [];
            for (let i = 0; i < monitorsModel.count; i++) {
                let m = monitorsModel.get(i);
                let isP = m.transform === 1 || m.transform === 3;
                let physW = Math.round((isP ? m.resH : m.resW) / m.sysScale);
                let physH = Math.round((isP ? m.resW : m.resH) / m.sysScale);
                rects.push({ x: m.uiX / config.monUiScale, y: m.uiY / config.monUiScale, w: physW, h: physH, resW: m.resW, resH: m.resH, name: m.name, rate: m.rate, sysScale: m.sysScale, transform: m.transform });
            }
            function getTightSnap(pX, pY, sX, sY, sW, sH, mW, mH, t) {
                let cx = pX; let cy = pY;
                if (Math.abs(cx - (sX - mW)) < t) cx = sX - mW;
                else if (Math.abs(cx - (sX + sW)) < t) cx = sX + sW;
                else if (Math.abs(cx - sX) < t) cx = sX;
                else if (Math.abs(cx - (sX + sW - mW)) < t) cx = sX + sW - mW;
                if (Math.abs(cy - (sY - mH)) < t) cy = sY - mH;
                else if (Math.abs(cy - (sY + sH)) < t) cy = sY + sH;
                else if (Math.abs(cy - sY) < t) cy = sY;
                else if (Math.abs(cy - (sY + sH - mH)) < t) cy = sY + sH - mH;
                return {x: cx, y: cy};
            }
            for (let i = 1; i < rects.length; i++) {
                let bestX = rects[i].x, bestY = rects[i].y, bestDist = 999999;
                for (let j = 0; j < i; j++) {
                    let r0 = rects[j];
                    let snapped = getTightSnap(rects[i].x, rects[i].y, r0.x, r0.y, r0.w, r0.h, rects[i].w, rects[i].h, 25);
                    let dist = Math.hypot(rects[i].x - snapped.x, rects[i].y - snapped.y);
                    if (dist < bestDist) { bestDist = dist; bestX = Math.round(snapped.x); bestY = Math.round(snapped.y); }
                }
                rects[i].x = bestX; rects[i].y = bestY;
            }
            let finalMinX = 999999, finalMinY = 999999;
            for (let i = 0; i < rects.length; i++) {
                if (rects[i].x < finalMinX) finalMinX = rects[i].x;
                if (rects[i].y < finalMinY) finalMinY = rects[i].y;
            }
            let evalCmds = [], summaryString = "", jsonArr = [];
            for (let i = 0; i < rects.length; i++) {
                let r = rects[i];
                r.x = Math.round(r.x - finalMinX);
                r.y = Math.round(r.y - finalMinY);
                // Hyprland 0.55+ has no `hyprctl keyword monitor`; use the Lua API.
                let lua = `hl.monitor({ output = \"${r.name}\", mode = \"${r.resW}x${r.resH}@${r.rate}\", position = \"${r.x}x${r.y}\", scale = ${r.sysScale}${r.transform !== 0 ? `, transform = ${r.transform}` : ""} })`;
                evalCmds.push(`hyprctl eval '${lua.replace(/'/g, "'\\''")}'`);
                summaryString += r.name + " ";
                jsonArr.push({ name: r.name, resW: r.resW, resH: r.resH, rate: parseInt(r.rate), x: r.x, y: r.y, scale: r.sysScale, transform: r.transform });
            }
            config.setSetting("monitors", jsonArr);
            config.sh(evalCmds.join(" ; ") + " ; pkill awww-daemon 2>/dev/null || true; awww-daemon & ; ~/.config/hypr/scripts/persist-display-config.sh > ~/.config/hypr/display-config 2>/dev/null");
            Quickshell.execDetached(["notify-send", "Display Update", "Applied layout for: " + summaryString.trim()]);
        }
    }

    // Removes the persisted layout (~/.config/hypr/display-config) and sends all
    // monitors back to the wildcard auto-arrangement. Useful for machines that
    // never saved a layout, or to start over: with the file gone, restore-
    // monitors.sh has nothing to reconcile and Hyprland's "auto" rule applies.
    function resetMonitorsToAuto() {
        config.sh(`rm -f "$HOME/.config/hypr/display-config" && hyprctl reload ; hyprctl eval 'hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })'`);
        Quickshell.execDetached(["notify-send", "Display Layout", "Saved layout deleted - monitors now auto-arrange"]);
    }

    property alias monDelayedLayoutUpdate: _monDelayedLayoutUpdate
    Timer {
        id: _monDelayedLayoutUpdate
        interval: 10; running: false; repeat: false
        onTriggered: config.monForceLayoutUpdate()
    }

    property alias displayPoller: _displayPoller
    Process {
        id: _displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    config.monitorsModel.clear();
                    let minX = 999999, minY = 999999;
                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x;
                        if (data[i].y < minY) minY = data[i].y;
                    }
                    config.monOriginalOriginX = minX !== 999999 ? minX : 0;
                    config.monOriginalOriginY = minY !== 999999 ? minY : 0;
                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let tf = data[i].transform !== undefined ? data[i].transform : 0;
                        let normalizedX = (data[i].x - minX) * config.monUiScale;
                        let normalizedY = (data[i].y - minY) * config.monUiScale;
                        config.monitorsModel.append({
                            name: data[i].name, resW: data[i].width, resH: data[i].height,
                            sysScale: scl, rate: Math.round(data[i].refreshRate).toString(),
                            uiX: normalizedX, uiY: normalizedY, transform: tf,
                            availableModes: JSON.stringify(data[i].availableModes || [])
                        });
                        if (data[i].focused) config.monActiveEditIndex = i;
                    }
                    config.monForceLayoutUpdate();
                } catch(e) {}
            }
        }
    }

    // =========================================================================
    // Boot Initialization (Runs once on start)
    // =========================================================================
    Component.onCompleted: {
        settingsReader.running = true;
        envReader.running = true;
    }

    Process {
        id: envReader
        command: ["bash", "-c", `cat "${config.weatherEnvPath}" 2>/dev/null || echo ''`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text ? this.text.trim().split('\n') : [];
                for (let line of lines) {
                    line = line.trim();
                    let parts = line.split("=");
                    if (parts.length >= 2) {
                        let key = parts[0].trim();
                        let val = parts.slice(1).join("=").replace(/^['"]|['"]$/g, '').trim();
                        config.rawEnvs[key] = val;
                        
                        if (key === "OPENWEATHER_KEY") config.weatherApiKey = val;
                        else if (key === "OPENWEATHER_CITY_ID") config.weatherCityId = val;
                        else if (key === "OPENWEATHER_UNIT") config.weatherUnit = val;
                    }
                }
            }
        }
    }

    Process {
        id: settingsReader
        command: ["bash", "-c", `cat "${config.settingsJsonPath}" 2>/dev/null || echo '{}'`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0 && this.text.trim() !== "{}") {
                        config.rawSettings = JSON.parse(this.text);
                        
                        // Map explicitly defined properties
                        if (config.rawSettings.uiScale !== undefined) config.uiScale = config.rawSettings.uiScale;
                        if (config.rawSettings.openGuideAtStartup !== undefined) config.openGuideAtStartup = config.rawSettings.openGuideAtStartup;
                        if (config.rawSettings.topbarHelpIcon !== undefined) config.topbarHelpIcon = config.rawSettings.topbarHelpIcon;
                        if (config.rawSettings.topbarRoundness !== undefined) config.topbarRoundness = config.rawSettings.topbarRoundness;
                        if (config.rawSettings.topbarPillBg !== undefined) config.topbarPillBg = config.rawSettings.topbarPillBg;
                        if (config.rawSettings.topbarPillSolid !== undefined) config.topbarPillSolid = config.rawSettings.topbarPillSolid;
                        if (config.rawSettings.topbarUnifyLeft !== undefined) config.topbarUnifyLeft = config.rawSettings.topbarUnifyLeft;
                        if (config.rawSettings.topbarUnifyCenter !== undefined) config.topbarUnifyCenter = config.rawSettings.topbarUnifyCenter;
                        if (config.rawSettings.topbarUnifyRight !== undefined) config.topbarUnifyRight = config.rawSettings.topbarUnifyRight;
                        if (config.rawSettings.topbarBorderMode !== undefined) config.topbarBorderMode = config.rawSettings.topbarBorderMode;
                        if (config.rawSettings.topbarBorderWidth !== undefined) config.topbarBorderWidth = config.rawSettings.topbarBorderWidth;
                        if (config.rawSettings.topbarBorderColor !== undefined) config.topbarBorderColor = config.rawSettings.topbarBorderColor;
                        if (config.rawSettings.topbarBorderWidthLeft !== undefined) config.topbarBorderWidthLeft = config.rawSettings.topbarBorderWidthLeft;
                        if (config.rawSettings.topbarBorderColorLeft !== undefined) config.topbarBorderColorLeft = config.rawSettings.topbarBorderColorLeft;
                        if (config.rawSettings.topbarBorderWidthCenter !== undefined) config.topbarBorderWidthCenter = config.rawSettings.topbarBorderWidthCenter;
                        if (config.rawSettings.topbarBorderColorCenter !== undefined) config.topbarBorderColorCenter = config.rawSettings.topbarBorderColorCenter;
                        if (config.rawSettings.topbarBorderWidthRight !== undefined) config.topbarBorderWidthRight = config.rawSettings.topbarBorderWidthRight;
                        if (config.rawSettings.topbarBorderColorRight !== undefined) config.topbarBorderColorRight = config.rawSettings.topbarBorderColorRight;
                        if (config.rawSettings.appScale !== undefined) config.appScale = config.rawSettings.appScale;
                        if (config.rawSettings.wallpaperDir !== undefined) config.wallpaperDir = config.rawSettings.wallpaperDir;
                        if (config.rawSettings.language !== undefined && config.rawSettings.language !== "") config.language = config.rawSettings.language;
                        if (config.rawSettings.kbOptions !== undefined) config.kbOptions = config.rawSettings.kbOptions;
                        if (config.rawSettings.workspaceCount !== undefined) {
                            config.workspaceCount = config.rawSettings.workspaceCount;
                            config.initialWorkspaceCount = config.rawSettings.workspaceCount; 
                        }
                        
                        // Map Keybinds
                        if (config.rawSettings.keybinds !== undefined && Array.isArray(config.rawSettings.keybinds)) {
                            let tempBinds = [];
                            for (let k of config.rawSettings.keybinds) {
                                tempBinds.push({
                                    type: k.type || "bind",
                                    mods: k.mods || "",
                                    key: k.key || "",
                                    dispatcher: k.dispatcher || "exec",
                                    command: k.command || "",
                                    isEditing: false
                                });
                            }
                            config.keybindsData = tempBinds;
                        } else {
                            config.keybindsData = [];
                        }

                        // Map Startups
                        if (config.rawSettings.startup !== undefined && Array.isArray(config.rawSettings.startup)) {
                            let tempStartup = [];
                            for (let s of config.rawSettings.startup) {
                                tempStartup.push({ command: s.command || "" });
                            }
                            config.startupData = tempStartup;
                        } else {
                            config.startupData = [];
                        }

                        // Map Topbar layout
                        config.topbarLayout = TopbarLayout.normalize(config.rawSettings.topbar);
                    } else {
                        config.saveAppSettings();
                        config.keybindsData = [];
                        config.saveAllKeybinds([]);
                        config.startupData = [];
                        config.topbarLayout = TopbarLayout.defaultLayout();
                    }
                } catch (e) {
                    console.log("Error parsing global settings:", e);
                    // Overwrite the corrupted file with a fresh empty object so
                    // the bar can start and jq saves will work going forward.
                    config.sh("echo '{}' > '" + config.settingsJsonPath + "'");
                    config.rawSettings = {};
                    config.keybindsData = [];
                    config.startupData = [];
                    config.topbarLayout = TopbarLayout.defaultLayout();
                }
                config.keybindsLoaded();
                config.startupLoaded();
                config.topbarLayoutLoaded();
                config.dataReady = true;
            }
        }
    }
}
