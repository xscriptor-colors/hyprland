import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// WeatherFaceCompact — compact weather chip: glyph + temperature.
// Reads the cached weather.json written by calendar/weather.sh
// (~/.cache/quickshell/weather/weather.json; directory overridable with the
// QS_CACHE_WEATHER env var, same convention as the scripts) with a plain
// `cat` and refreshes every 150 s. No network calls; while no data is
// available it shows a generic glyph and "--°".
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 90
    property real minHeight: 90
    property real maxWidth: 600
    property real maxHeight: 600
    property real minAspect: 0.7
    property real maxAspect: 2.2
    property bool isRound: false

    property real dynMargin: Math.max(6, Math.min(16, Math.min(root.width, root.height) * 0.08))
    property real dynSpacing: Math.max(2, Math.min(8, Math.min(root.width, root.height) * 0.04))

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

    property string tempText: {
        let raw = root.currentTemp.trim();
        if (raw === "") return "--°";
        let num = Math.round(parseFloat(raw));
        return isNaN(num) ? "--°" : num + "°";
    }

    function applyWeather(text) {
        let txt = text ? text.trim() : "";
        if (txt === "") return;
        try {
            root.weatherData = JSON.parse(txt);
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

    Timer {
        interval: 150000
        running: true
        repeat: true
        onTriggered: {
            weatherReader.running = false;
            weatherReader.running = true;
        }
    }

    Component.onCompleted: weatherReader.running = true

    Rectangle {
        anchors.fill: parent
        color: Theme.surface0
        radius: Theme.clampedBorderRadius * 2
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: root.dynMargin
        property bool isHorizontal: root.width > root.height * 1.15
        columns: isHorizontal ? 2 : 1
        rows: isHorizontal ? 1 : 2
        columnSpacing: root.dynSpacing
        rowSpacing: root.dynSpacing

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.isHorizontal ? parent.width * 0.5 : parent.width
            Layout.preferredHeight: parent.isHorizontal ? parent.height : parent.height * 0.5

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -6
                text: root.currentIcon !== "" ? root.currentIcon : ""
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(parent.width, parent.height) * 0.65
                color: root.accentColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: parent.isHorizontal ? parent.width * 0.5 : parent.width
            Layout.preferredHeight: parent.isHorizontal ? parent.height : parent.height * 0.5

            Text {
                anchors.centerIn: parent
                text: root.tempText
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(parent.width, parent.height) * 0.45
                font.weight: Font.Black
                color: Theme.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
