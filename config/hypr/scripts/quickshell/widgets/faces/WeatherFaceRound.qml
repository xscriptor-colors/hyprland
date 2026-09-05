import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// ============================================================================
// WeatherFaceRound — diamond-shaped (45° rotated pill) weather face.
// Icon sits at the top of the diamond, temperature at the bottom; the
// containers counter-rotate so glyphs and digits stay upright (geometry port
// of serpantinum WeatherFaceRound). Reads the shared weather cache exactly
// like WeatherFaceCompact (QS_CACHE_WEATHER env var honoured).
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 90
    property real minHeight: 90
    property real maxWidth: 600
    property real maxHeight: 600
    property real minAspect: 1.0
    property real maxAspect: 1.0
    property bool isRound: true

    property real faceSize: Math.min(root.width, root.height)
    property real pillLength: root.faceSize * 0.94
    property real pillWidth: root.faceSize * 0.54
    property real pillRadius: root.pillWidth / 2
    property real iconHorizontalOffset: -12

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

    property string tempNumber: {
        let raw = root.currentTemp.trim();
        if (raw === "") return "--";
        let num = Math.round(parseFloat(raw));
        return isNaN(num) ? "--" : String(num);
    }

    property string formattedTemp: root.tempNumber + "°"

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
        id: pillBackground
        anchors.centerIn: parent
        width: root.pillWidth
        height: root.pillLength
        radius: root.pillRadius
        rotation: 45
        color: Theme.surface0
        antialiasing: true

        Item {
            anchors.fill: parent

            Item {
                id: iconContainer
                width: root.pillWidth * 0.68
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.top
                anchors.verticalCenterOffset: root.pillRadius
                rotation: -45

                Text {
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.iconHorizontalOffset
                    text: root.currentIcon !== "" ? root.currentIcon : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: parent.height * 0.76
                    color: root.accentColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 8
                }
            }

            Item {
                id: tempContainer
                width: root.pillWidth * 0.68
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.bottom
                anchors.verticalCenterOffset: -root.pillRadius
                rotation: -45

                Item {
                    anchors.centerIn: parent
                    width: tempNumberText.implicitWidth
                    height: tempNumberText.implicitHeight

                    Text {
                        id: tempNumberText
                        anchors.centerIn: parent
                        text: root.tempNumber
                        font.family: Theme.fontFamily
                        font.weight: Font.Black
                        color: Theme.text
                        font.pixelSize: tempContainer.height * 0.58
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        id: degreeText
                        anchors.left: tempNumberText.right
                        anchors.leftMargin: 1
                        anchors.top: tempNumberText.top
                        anchors.topMargin: tempContainer.height * 0.04
                        text: "°"
                        font.family: Theme.fontFamily
                        font.weight: Font.Bold
                        color: Theme.text
                        font.pixelSize: tempContainer.height * 0.30
                    }
                }
            }
        }
    }
}
