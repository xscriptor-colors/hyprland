import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// WeatherFaceFull — large weather card: current glyph + temperature +
// "feels like" + the next 4 hourly forecasts (time/temp/icon/hex).
//
// Reads the shared weather cache (~/.cache/quickshell/weather/weather.json,
// directory overridable with QS_CACHE_WEATHER, written by calendar/weather.sh)
// every 150 s with `cat`; forecast slots that may be missing (feels_like,
// hourly) fall back gracefully to current_temp / empty state.
//
// The "next 4 hours" picker anchors on the forecast entry whose date matches
// today, so a stale cache (generated on an earlier day) can never surface
// past hours as upcoming slots.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 420
    property real minHeight: 260
    property real maxWidth: 820
    property real maxHeight: 500
    property real minAspect: 1.6
    property real maxAspect: 1.6
    property bool isRound: false

    property real baseRef: Math.min(root.height, root.width * 0.6)
    property real dynMargin: Math.max(18, baseRef * 0.09)
    property real dynSpacing: Math.max(10, baseRef * 0.05)

    property real iconTop: Math.max(48, Math.min(78, baseRef * 0.42))
    property real tempHuge: Math.max(36, Math.min(64, baseRef * 0.28))
    property real textDesc: Math.max(12, Math.min(16, baseRef * 0.065))
    property real textFeels: Math.max(11, Math.min(14, baseRef * 0.055))
    property real forecastTemp: Math.max(13, Math.min(18, baseRef * 0.07))
    property real forecastIcon: Math.max(22, Math.min(32, baseRef * 0.14))
    property real forecastTime: Math.max(9, Math.min(13, baseRef * 0.05))

    // Env override helper: QS_CACHE_WEATHER points at the weather cache
    // DIRECTORY (weather.sh writes weather.json into it); default matches
    // the script: ~/.cache/quickshell/weather.
    function envOr(name, fallback) {
        let v = Quickshell.env(name);
        return v !== "" ? v : fallback;
    }

    readonly property string weatherFilePath: root.envOr("QS_CACHE_WEATHER",
        Quickshell.env("HOME") + "/.cache/quickshell/weather") + "/weather.json"

    property var weatherData: null

    property string currentTemp: root.weatherData && root.weatherData.current_temp !== undefined ? String(root.weatherData.current_temp) : ""
    property string currentIcon: (root.weatherData && root.weatherData.current_icon) ? String(root.weatherData.current_icon) : ""
    property string currentHex: (root.weatherData && root.weatherData.current_hex) ? String(root.weatherData.current_hex) : ""
    property color accentColor: root.currentHex.length === 7 ? root.currentHex : Theme.mauve

    property var hourlyList: []

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function hourOf(timeStr) {
        if (!timeStr) return -1;
        let s = String(timeStr).trim();
        if (s.indexOf(":") !== -1) {
            let h = parseInt(s.split(":")[0], 10);
            return isNaN(h) ? -1 : h;
        }
        let n = parseInt(s, 10);
        if (isNaN(n)) return -1;
        return n >= 100 ? Math.floor(n / 100) : n;
    }

    function formatHour(timeStr) {
        let h = root.hourOf(timeStr);
        if (h === -1) return timeStr || "";
        return root.pad2(h) + ":00";
    }

    function tempTextOf(value) {
        if (value === undefined || value === null || value === "") return "--°";
        let num = Math.round(parseFloat(value));
        return isNaN(num) ? "--°" : num + "°";
    }

    property string tempText: root.tempTextOf(root.currentTemp)

    // "feels like": forecast[0].feels_like when present, else current_temp.
    property string feelsLikeText: {
        let fl = null;
        if (root.weatherData && root.weatherData.forecast
            && root.weatherData.forecast.length > 0 && root.weatherData.forecast[0]) {
            fl = root.weatherData.forecast[0].feels_like;
        }
        if (fl !== undefined && fl !== null && String(fl).trim() !== "") {
            return root.tempTextOf(fl);
        }
        return root.tempText;
    }

    property string descText: (root.weatherData && root.weatherData.forecast
        && root.weatherData.forecast.length > 0 && root.weatherData.forecast[0]
        && root.weatherData.forecast[0].desc) ? String(root.weatherData.forecast[0].desc) : ""

    // Today's entry date as the cache writes it: zero-padded day + short month
    // (weather.sh uses `date "+%d %b"`, e.g. "05 Sep").
    function dayDateString(d) {
        let monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return root.pad2(d.getDate()) + " " + monthShort[d.getMonth()];
    }

    // Rebuild the "next 4 hours" list from the hourly forecasts. Hourly slots
    // carry only "HH:MM" but each forecast entry carries a "date" ("dd Mon"),
    // so we anchor on today's entry and only accept strictly-upcoming
    // absolute hours. With an OLD cache (written on a previous day) today's
    // entry is found further down the list and all earlier-day slots are
    // filtered out; with no entry dated today at all the list stays empty
    // (showing anything could surface past hours as "upcoming"). Caches
    // without per-day dates fall back to the legacy nearest-hour walk.
    function updateHourly() {
        root.hourlyList = [];
        let data = root.weatherData;
        if (!data || !data.forecast || !Array.isArray(data.forecast)) return;

        let hasDates = data.forecast.length > 0 && data.forecast[0]
            && String(data.forecast[0].date || "").trim() !== "";
        if (!hasDates) {
            let all = [];
            for (let d = 0; d < data.forecast.length; d++) {
                let day = data.forecast[d];
                if (day && day.hourly && Array.isArray(day.hourly)) all = all.concat(day.hourly);
            }
            if (all.length === 0) return;
            let nowHour = new Date().getHours();
            let best = 0;
            let minDiff = 999;
            for (let i = 0; i < all.length; i++) {
                let h = root.hourOf(all[i].time || "00:00");
                let diff = h >= 0 ? (h - nowHour + 24) % 24 : 999;
                if (diff === 0) diff = 24; // prefer strictly upcoming hours
                if (diff < minDiff) {
                    minDiff = diff;
                    best = i;
                }
            }
            root.hourlyList = all.slice(best, best + 4);
            return;
        }

        let now = new Date();
        let nowHour = now.getHours();
        let todayStr = root.dayDateString(now);
        let todayIdx = -1;
        for (let d = 0; d < data.forecast.length; d++) {
            if (String(data.forecast[d].date || "").trim() === todayStr) {
                todayIdx = d;
                break;
            }
        }
        if (todayIdx === -1) return; // stale cache: never show possibly-past slots
        let upcoming = [];
        for (let d = todayIdx; d < data.forecast.length && upcoming.length < 4; d++) {
            let day = data.forecast[d];
            if (!day || !day.hourly || !Array.isArray(day.hourly)) continue;
            for (let i = 0; i < day.hourly.length && upcoming.length < 4; i++) {
                let slot = day.hourly[i] || {};
                let h = root.hourOf(slot.time || "00:00");
                if (h < 0) continue;
                let absHour = (d - todayIdx) * 24 + h;
                if (absHour > nowHour) upcoming.push(slot);
            }
        }
        root.hourlyList = upcoming;
    }

    function applyWeather(text) {
        let txt = text ? text.trim() : "";
        if (txt === "") return;
        try {
            root.weatherData = JSON.parse(txt);
            root.updateHourly();
        } catch (e) {}
    }

    Process {
        id: weatherReader
        command: ["bash", "-c", "cat '" + root.weatherFilePath + "' 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyWeather(this.text)
        }
    }

    // Periodic refresh + re-window of hourly entries when the hour changes.
    Timer {
        interval: 150000
        running: true
        repeat: true
        onTriggered: {
            weatherReader.running = false;
            weatherReader.running = true;
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.updateHourly()
    }

    Component.onCompleted: weatherReader.running = true

    Rectangle {
        anchors.fill: parent
        color: Theme.surface0
        radius: Theme.clampedBorderRadius
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.dynMargin
            spacing: root.dynSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 0

                Text {
                    text: root.currentIcon !== "" ? root.currentIcon : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: root.iconTop
                    color: root.accentColor
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                }

                Item {
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                    spacing: 2

                    Text {
                        text: root.tempText
                        font.family: Theme.fontFamily
                        font.pixelSize: root.tempHuge
                        font.weight: Font.Black
                        color: Theme.text
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Feels like " + root.feelsLikeText
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textFeels
                        font.weight: Font.Medium
                        color: Theme.subtext0
                        elide: Text.ElideRight
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1.3
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    spacing: 2

                    Text {
                        text: root.descText
                        font.family: Theme.fontFamily
                        font.pixelSize: root.textDesc
                        font.weight: Font.Medium
                        color: Theme.subtext0
                        horizontalAlignment: Text.AlignRight
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    spacing: root.dynSpacing * 0.9

                    Repeater {
                        model: root.hourlyList
                        delegate: ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                            spacing: 4

                            Text {
                                text: {
                                    let v = modelData.temp;
                                    let n = Math.round(parseFloat(v));
                                    return isNaN(n) ? "--°" : n + "°";
                                }
                                color: Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: root.forecastTemp
                                font.weight: Font.Medium
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                transform: Translate { x: 2 }
                            }

                            Text {
                                text: modelData.icon || ""
                                color: (modelData.hex && String(modelData.hex).length === 7) ? modelData.hex : root.accentColor
                                font.family: Theme.fontFamily
                                font.pixelSize: root.forecastIcon
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                transform: Translate { x: -2 }
                            }

                            Text {
                                text: root.formatHour(modelData.time)
                                color: Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: root.forecastTime
                                font.weight: Font.Normal
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
