import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    MatugenColors { id: _theme }

    readonly property color base: _theme.base
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0 || "#6c7086"
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color peach: _theme.peach || "#fab387"
    readonly property color sapphire: _theme.sapphire || "#74c7ec"
    readonly property color red: _theme.red || "#f38ba8"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    // values
    property real activeOpacity: 0.85
    property real inactiveOpacity: 0.80
    property int blurSize: 8
    property int blurPasses: 3
    property real roundness: 20
    property int gapsIn: 16
    property int gapsOut: 25
    property int borderSize: 2

    property bool isDirty: false

    function setOpt(opt, val) {
        Quickshell.execDetached(["bash", "-c", "hyprctl keyword " + opt + " " + val])
    }

    function saveChanges() {
        setOpt("decoration:active_opacity", window.activeOpacity.toFixed(2))
        setOpt("decoration:inactive_opacity", window.inactiveOpacity.toFixed(2))
        setOpt("decoration:blur:size", Math.round(window.blurSize))
        setOpt("decoration:blur:passes", Math.round(window.blurPasses))
        setOpt("decoration:rounding", Math.round(window.roundness))
        setOpt("general:gaps_in", Math.round(window.gapsIn))
        setOpt("general:gaps_out", Math.round(window.gapsOut))
        setOpt("general:border_size", Math.round(window.borderSize))
        Quickshell.execDetached(["bash",
            Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/window-controls/persist.sh",
            window.activeOpacity.toFixed(2),
            window.inactiveOpacity.toFixed(2),
            String(Math.round(window.roundness)),
            String(Math.round(window.blurSize)),
            String(Math.round(window.blurPasses)),
            String(Math.round(window.gapsIn)),
            String(Math.round(window.gapsOut)),
            String(Math.round(window.borderSize)),
        ])
        window.isDirty = false
    }

    function resetDefaults() {
        activeOpacity = 0.85; inactiveOpacity = 0.80
        blurSize = 8; blurPasses = 3; roundness = 20
        window.isDirty = true
    }

    function markDirty() { window.isDirty = true }

    function loadCurrent() {
        reader.command = ["bash", "-c",
            "echo active_opacity=$(hyprctl getoption decoration:active_opacity | grep 'float:' | awk '{print $2}');" +
            "echo inactive_opacity=$(hyprctl getoption decoration:inactive_opacity | grep 'float:' | awk '{print $2}');" +
            "echo roundness=$(hyprctl getoption decoration:rounding | grep 'int:' | awk '{print $2}');" +
            "echo blur_size=$(hyprctl getoption decoration:blur:size | grep 'int:' | awk '{print $2}');" +
            "echo blur_passes=$(hyprctl getoption decoration:blur:passes | grep 'int:' | awk '{print $2}');" +
            "echo gaps_in=$(hyprctl getoption general:gaps_in | grep 'int:' | awk '{print $2}');" +
            "echo gaps_out=$(hyprctl getoption general:gaps_out | grep 'int:' | awk '{print $2}');" +
            "echo border_size=$(hyprctl getoption general:border_size | grep 'int:' | awk '{print $2}')"
        ]
        reader.running = true
    }

    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text) return
                    let lines = this.text.trim().split('\n')
                    for (let i = 0; i < lines.length; i++) {
                        let parts = lines[i].split('=')
                        if (parts.length < 2) continue
                        let v = parts[1].trim()
                        if (parts[0] === 'active_opacity') window.activeOpacity = parseFloat(v) || 0.85
                        else if (parts[0] === 'inactive_opacity') window.inactiveOpacity = parseFloat(v) || 0.80
                        else if (parts[0] === 'roundness') window.roundness = parseInt(v) || 20
                        else if (parts[0] === 'blur_size') window.blurSize = parseInt(v) || 8
                        else if (parts[0] === 'blur_passes') window.blurPasses = parseInt(v) || 3
                        else if (parts[0] === 'gaps_in') window.gapsIn = parseInt(v) || 16
                        else if (parts[0] === 'gaps_out') window.gapsOut = parseInt(v) || 25
                        else if (parts[0] === 'border_size') window.borderSize = parseInt(v) || 2
                    }
                } catch(e) {}
            }
        }
    }

    Timer { interval: 300; running: true; repeat: false; onTriggered: loadCurrent() }

    Rectangle {
        anchors.fill: parent; color: window.base; radius: s(16)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: s(16); spacing: s(8)

            RowLayout {
                Layout.fillWidth: true
                Text { text: "\uF2D0  Window Effects"; font.family: "Hack Nerd Font"; font.pixelSize: s(15); font.weight: Font.Bold; color: window.text }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: s(28); Layout.preferredHeight: s(28); radius: s(8)
                    color: window.red; opacity: window.isDirty ? 0.25 : 0.08
                    Text { anchors.centerIn: parent; text: "\uF0E2"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); color: window.red; opacity: window.isDirty ? 1.0 : 0.4 }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: resetDefaults() }
                }
                Rectangle {
                    Layout.preferredWidth: s(56); Layout.preferredHeight: s(28); radius: s(8)
                    color: window.green; opacity: window.isDirty ? 0.85 : 0.15
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    RowLayout { anchors.centerIn: parent; spacing: s(5)
                        Text { text: "\uF0C7"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); color: window.isDirty ? window.crust : window.green }
                        Text { text: "Save"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); font.weight: Font.Bold; color: window.isDirty ? window.crust : window.green }
                    }
                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (window.isDirty) saveChanges() }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.25 }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF06E"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.mauve; Layout.preferredWidth: s(20) }
                Text { text: "Active Opacity"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: aoDs; from: 0.3; to: 1.0; step: 0.05; initial: window.activeOpacity; barColor: window.mauve
                    onDragged: function(v) { window.activeOpacity = v; markDirty() }
                }
                Text { text: aoDs.current.toFixed(2); font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF070"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.blue; Layout.preferredWidth: s(20) }
                Text { text: "Inactive Opacity"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: ioDs; from: 0.3; to: 1.0; step: 0.05; initial: window.inactiveOpacity; barColor: window.blue
                    onDragged: function(v) { window.inactiveOpacity = v; markDirty() }
                }
                Text { text: ioDs.current.toFixed(2); font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.2 }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF192"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.green; Layout.preferredWidth: s(20) }
                Text { text: "Rounding"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: roDs; from: 0; to: 35; step: 1; initial: window.roundness; barColor: window.green
                    onDragged: function(v) { window.roundness = v; markDirty() }
                }
                Text { text: Math.round(roDs.current) + "px"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.2 }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF0EB"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.peach; Layout.preferredWidth: s(20) }
                Text { text: "Blur Size"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: bsDs; from: 0; to: 24; step: 1; initial: window.blurSize; barColor: window.peach
                    onDragged: function(v) { window.blurSize = v; markDirty() }
                }
                Text { text: Math.round(bsDs.current) + "px"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF2C8"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.sapphire; Layout.preferredWidth: s(20) }
                Text { text: "Blur Passes"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: bpDs; from: 0; to: 10; step: 1; initial: window.blurPasses; barColor: window.sapphire
                    onDragged: function(v) { window.blurPasses = v; markDirty() }
                }
                Text { text: Math.round(bpDs.current); font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.2 }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF239"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.mauve; Layout.preferredWidth: s(20) }
                Text { text: "Gaps In"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: giDs; from: 0; to: 50; step: 2; initial: window.gapsIn; barColor: window.mauve
                    onDragged: function(v) { window.gapsIn = v; markDirty() }
                }
                Text { text: Math.round(giDs.current) + "px"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF7A4"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.blue; Layout.preferredWidth: s(20) }
                Text { text: "Gaps Out"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: goDs; from: 0; to: 50; step: 2; initial: window.gapsOut; barColor: window.blue
                    onDragged: function(v) { window.gapsOut = v; markDirty() }
                }
                Text { text: Math.round(goDs.current) + "px"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }

            RowLayout { Layout.fillWidth: true; Layout.preferredHeight: s(44); spacing: s(10)
                Text { text: "\uF358"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.peach; Layout.preferredWidth: s(20) }
                Text { text: "Border Width"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.subtext0; Layout.preferredWidth: s(100) }
                DragSlider { id: bwDs; from: 0; to: 20; step: 1; initial: window.borderSize; barColor: window.peach
                    onDragged: function(v) { window.borderSize = v; markDirty() }
                }
                Text { text: Math.round(bwDs.current) + "px"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); font.weight: Font.Bold; color: window.text; Layout.preferredWidth: s(45); horizontalAlignment: Text.AlignRight }
            }
        }
    }

    component DragSlider: Rectangle {
        id: dslider
        property real from: 0; property real to: 1; property real step: 0.05
        property real initial: 0.5; property color barColor: window.mauve
        property real current: initial
        signal dragged(real val)

        Layout.fillWidth: true; Layout.preferredHeight: s(30)
        radius: s(6); color: window.surface1

        Rectangle {
            id: fillBar
            height: parent.height; radius: s(6)
            color: dslider.barColor; opacity: 0.5
            width: parent.width * ((dslider.current - dslider.from) / (dslider.to - dslider.from))
            Behavior on width { enabled: !dragArea.pressed; NumberAnimation { duration: 80 } }
        }

        Rectangle {
            id: knob
            y: (parent.height - height) / 2
            width: s(18); height: s(18); radius: s(9)
            color: dslider.barColor
            scale: dragArea.containsMouse || dragArea.pressed ? 1.2 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            x: Math.max(0, Math.min(parent.width - width, parent.width * ((dslider.current - dslider.from) / (dslider.to - dslider.from)) - width / 2))
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property real startX: 0
            property real startVal: 0

            onPressed: function(mouse) {
                startX = mouse.x
                startVal = dslider.current
                updateFromMouse(mouse.x)
            }
            onPositionChanged: function(mouse) {
                if (pressed) updateFromMouse(mouse.x)
            }
            function updateFromMouse(mx) {
                let frac = Math.max(0, Math.min(1, mx / parent.width))
                let range = dslider.to - dslider.from
                let raw = dslider.from + frac * range
                let stepped = Math.round(raw / dslider.step) * dslider.step
                stepped = Math.max(dslider.from, Math.min(dslider.to, stepped))
                dslider.current = stepped
                dslider.dragged(stepped)
            }
        }
    }
}
