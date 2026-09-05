import QtQuick
import "../../"

// ============================================================================
// ClockFaceMinimal — enormous time-only face (24h, HH:MM).
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 80
    property real minHeight: 40
    property real maxWidth: 1200
    property real maxHeight: 600
    property real minAspect: 1.2
    property real maxAspect: 5.0
    property bool isRound: false

    property var currentTime: new Date()
    property string timeText: root.pad2(root.currentTime.getHours()) + ":" + root.pad2(root.currentTime.getMinutes())

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
            root.timeText = root.pad2(root.currentTime.getHours()) + ":" + root.pad2(root.currentTime.getMinutes());
        }
    }

    Text {
        anchors.fill: parent
        anchors.margins: Math.min(parent.width, parent.height) * 0.05
        text: root.timeText
        font.family: Theme.fontFamily
        font.pixelSize: height
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        font.weight: Font.Black
        color: Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
