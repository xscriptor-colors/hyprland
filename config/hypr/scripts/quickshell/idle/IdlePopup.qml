import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"
import "../dock"

Item {
    id: window

    Colors { id: _theme }

    readonly property color base: _theme.base
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0 || "#6c7086"
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1 || "#313244"
    readonly property color surface2: _theme.surface2 || "#45475a"
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color yellow: _theme.yellow || "#f9e2af"
    readonly property color peach: _theme.peach || "#fab387"
    readonly property color sapphire: _theme.sapphire || "#74c7ec"
    readonly property color red: _theme.red || "#f38ba8"
    readonly property color mantle: _theme.mantle || "#181825"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    property string mode: "normal"
    property bool stateLoaded: false

    // Swallow clicks so the master overlay doesn't close us accidentally
    MouseArea { anchors.fill: parent }

    function setMode(m) {
        if (window.mode === m) return
        window.mode = m
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/idle-mode.sh", m])
    }

    Process {
        id: stateReader
        running: true
        command: ["bash", "-c", `cat "${Quickshell.env("HOME")}/.config/hypr/idle-settings.json" 2>/dev/null || printf '{"idleMode":"normal"}'`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(this.text.trim())
                    window.mode = d.idleMode === "awake" ? "awake" : "normal"
                } catch(e) {}
                window.stateLoaded = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: s(28)
        color: window.base
        border.color: window.surface2
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: s(20)
            spacing: s(14)

            // ── Header ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: s(12)
                Item {
                    Layout.preferredWidth: s(40); Layout.preferredHeight: s(40)
                    Rectangle {
                        anchors.fill: parent; radius: s(14)
                        color: window.mauve
                        Text {
                            anchors.centerIn: parent
                            text: "󰐪"; font.family: "Hack Nerd Font"; font.pixelSize: s(21)
                            color: window.base
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: s(2)
                    Text {
                        text: "Idle & sleep"; font.family: "Inter"; font.weight: Font.Bold
                        font.pixelSize: s(15); color: window.text; Layout.fillWidth: true
                    }
                    Text {
                        text: "Auto lock/suspend control"; font.family: "Inter"
                        font.pixelSize: s(11); color: window.subtext0; Layout.fillWidth: true
                    }
                }
                Rectangle {
                    Layout.preferredWidth: s(30); Layout.preferredHeight: s(30); radius: s(10)
                    color: (window.mode === "awake" ? window.green : window.mauve)
                    opacity: window.stateLoaded ? 1 : 0.4
                    Text {
                        anchors.centerIn: parent
                        text: window.mode === "awake" ? "󰁕" : "󰁔"
                        font.family: "Hack Nerd Font"; font.pixelSize: s(15); font.weight: Font.Bold
                        color: window.base
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom; anchors.topMargin: s(3)
                        text: window.mode === "awake" ? "Awake" : "Auto"
                        font.family: "Inter"; font.pixelSize: s(9); font.weight: Font.Medium
                        color: window.mode === "awake" ? window.green : window.mauve
                    }
                }
            }

            // ── Mode cards ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: s(12)

                Rectangle {
                    id: awakeCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: s(150)
                    radius: s(20)
                    color: window.mode === "awake" ? Qt.alpha(window.green, 0.12) : window.surface0
                    border.color: window.mode === "awake" ? window.green : window.surface2
                    border.width: window.mode === "awake" ? s(2) : 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: s(14)
                        spacing: s(6)
                        RowLayout {
                            Layout.fillWidth: true; spacing: s(8)
                            Text {
                                text: window.mode === "awake" ? "󰛓" : "󰂯"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(19)
                                color: window.mode === "awake" ? window.green : window.overlay0
                            }
                            Text {
                                text: "Keep awake"; font.family: "Inter"; font.weight: Font.Bold
                                font.pixelSize: s(13)
                                color: window.mode === "awake" ? window.green : window.text
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Never dims, locks or suspends by itself."
                            font.family: "Inter"; font.pixelSize: s(10.5)
                            color: window.mode === "awake" ? Qt.alpha(window.green, 0.9) : window.subtext0
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Lock anytime with SUPER+L"
                            font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                            color: window.overlay0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: window.setMode("awake")
                    }
                }

                Rectangle {
                    id: autoCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: s(150)
                    radius: s(20)
                    color: window.mode === "normal" ? Qt.alpha(window.mauve, 0.12) : window.surface0
                    border.color: window.mode === "normal" ? window.mauve : window.surface2
                    border.width: window.mode === "normal" ? s(2) : 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: s(14)
                        spacing: s(6)
                        RowLayout {
                            Layout.fillWidth: true; spacing: s(8)
                            Text {
                                text: window.mode === "normal" ? "󰅶" : "󰅶"
                                font.family: "Hack Nerd Font"; font.pixelSize: s(19)
                                color: window.mode === "normal" ? window.mauve : window.overlay0
                            }
                            Text {
                                text: "Auto"; font.family: "Inter"; font.weight: Font.Bold
                                font.pixelSize: s(13)
                                color: window.mode === "normal" ? window.mauve : window.text
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Dim 5m - lock 10m - display off 15m - suspend 30m"
                            font.family: "Inter"; font.pixelSize: s(10.5)
                            color: window.mode === "normal" ? Qt.alpha(window.mauve, 0.9) : window.subtext0
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "hypridle timers active"
                            font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                            color: window.overlay0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: window.setMode("normal")
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // ── Manual actions ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: s(10)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: s(42)
                    radius: s(14)
                    color: lockMa.containsMouse ? window.green : window.surface0
                    border.color: lockMa.containsMouse ? window.green : window.surface2
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: s(8)
                        Text {
                            text: "󰌾"; font.family: "Hack Nerd Font"; font.pixelSize: s(15)
                            color: lockMa.containsMouse ? window.base : window.green
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Lock now  (SUPER+L)"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); font.weight: Font.Medium
                            color: lockMa.containsMouse ? window.base : window.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        id: lockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"])
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: s(42)
                    radius: s(14)
                    color: suspMa.containsMouse ? window.sapphire : window.surface0
                    border.color: suspMa.containsMouse ? window.sapphire : window.surface2
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        anchors.centerIn: parent; spacing: s(8)
                        Text {
                            text: "󰤄"; font.family: "Hack Nerd Font"; font.pixelSize: s(15)
                            color: suspMa.containsMouse ? window.base : window.sapphire
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Text {
                            text: "Suspend  (SUPER+CTRL+L)"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); font.weight: Font.Medium
                            color: suspMa.containsMouse ? window.base : window.text
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea {
                        id: suspMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: s(8)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "SUPER+P toggles this panel"; font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                    color: window.overlay0
                }
            }
        }
    }
}
