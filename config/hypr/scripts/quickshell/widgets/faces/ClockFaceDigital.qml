import QtQuick
import QtQuick.Layouts
import "../../"

// ============================================================================
// ClockFaceDigital — card clock with big HH:MM(:SS) + date badge.
// 24h fixed time (no 12h option in this shell). Date badge follows a simple
// configurable format (default "ddd, MMM d"; tokens: ddd, dddd, MMM, MMMM,
// d, dd and any literal text).
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 120
    property real minHeight: 120
    property real maxWidth: 800
    property real maxHeight: 800
    property real minAspect: 0.8
    property real maxAspect: 2.8
    property bool isRound: false

    property string dateFormat: "ddd, MMM d"
    readonly property bool isStacked: (width / height) < 1.25

    property var currentTime: new Date()
    readonly property string hh: root.pad2(root.currentTime.getHours())
    readonly property string mm: root.pad2(root.currentTime.getMinutes())
    readonly property string ss: root.pad2(root.currentTime.getSeconds())

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function formatDate(fmt, d) {
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        let dayShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        let monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        let monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        let out = "";
        let tokens = String(fmt || "ddd, MMM d").split(/(dddd|ddd|MMMM|MMM|dd|d)/);
        for (let i = 0; i < tokens.length; i++) {
            let t = tokens[i];
            if (t === "dddd") out += dayNames[d.getDay()];
            else if (t === "ddd") out += dayShort[d.getDay()];
            else if (t === "MMMM") out += monthNames[d.getMonth()];
            else if (t === "MMM") out += monthShort[d.getMonth()];
            else if (t === "dd") out += root.pad2(d.getDate());
            else if (t === "d") out += String(d.getDate());
            else out += t;
        }
        return out;
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: Theme.surface0
        radius: Theme.clampedBorderRadius
        antialiasing: true

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Math.min(parent.width, parent.height) * 0.08
            width: Math.min(parent.width, parent.height) * 0.55
            height: width
            radius: width * 0.4
            color: Theme.surface1
            opacity: 0.45
            antialiasing: true
        }

        Item {
            anchors.fill: parent
            anchors.margins: Math.min(parent.width, parent.height) * 0.12

            ColumnLayout {
                visible: root.isStacked
                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.hh
                    font.family: Theme.fontFamily
                    font.pixelSize: height
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                    font.weight: Font.Normal
                    color: Theme.text
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.mm
                    font.family: Theme.fontFamily
                    font.pixelSize: height
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                    font.weight: Font.Black
                    color: Theme.mauve
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(18, parent.height * 0.22)
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        anchors.centerIn: parent
                        // Explicit size bindings: the badge must not rely on
                        // implicit-size auto-follow inside an anchored, non
                        // layout-managed parent (it can stay 0x0 there).
                        width: implicitWidth
                        height: implicitHeight
                        implicitWidth: Math.max(secondsText.implicitWidth + 24, 46)
                        implicitHeight: Math.max(secondsText.implicitHeight + 6, 18)
                        radius: height / 2
                        color: Theme.surface2

                        Text {
                            id: secondsText
                            anchors.centerIn: parent
                            text: root.ss
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.min(13, parent.height * 0.55)
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                            color: Theme.subtext0
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        // Explicit size bindings — see the seconds badge above.
                        width: implicitWidth
                        height: implicitHeight
                        implicitWidth: dateBadgeStacked.implicitWidth + 20
                        implicitHeight: Math.max(dateBadgeStacked.implicitHeight + 8, 18)
                        radius: height / 2
                        color: Theme.surface2

                        Text {
                            id: dateBadgeStacked
                            anchors.centerIn: parent
                            text: root.formatDate(root.dateFormat, root.currentTime)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Theme.subtext0
                        }
                    }
                }
            }

            RowLayout {
                visible: !root.isStacked
                anchors.fill: parent
                spacing: Math.min(parent.width, parent.height) * 0.04

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: root.hh + ":" + root.mm
                    font.family: Theme.fontFamily
                    font.pixelSize: height
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                    font.weight: Font.Black
                    color: Theme.text
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.max(64, dateBadgeWide.implicitWidth + 24)
                    spacing: 4

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Math.max(secondsWide.implicitWidth + 18, 38)
                        implicitHeight: Math.max(secondsWide.implicitHeight + 5, 18)
                        radius: height / 2
                        color: Theme.surface2

                        Text {
                            id: secondsWide
                            anchors.centerIn: parent
                            text: root.ss
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Theme.mauve
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Math.max(dateBadgeWide.implicitWidth + 20, 48)
                        implicitHeight: Math.max(dateBadgeWide.implicitHeight + 10, 22)
                        radius: height / 2
                        color: Theme.surface2

                        Text {
                            id: dateBadgeWide
                            anchors.centerIn: parent
                            text: root.formatDate(root.dateFormat, root.currentTime)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                            color: Theme.subtext0
                        }
                    }
                }
            }
        }
    }
}
