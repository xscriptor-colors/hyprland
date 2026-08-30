import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"
import "../dock"

Item {
    id: window
    focus: true

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val);
    }

    // -------------------------------------------------------------------------
    // COLORS (Expanded Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    Colors { id: _theme }

    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0 || "#6c7086"
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2

    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // -------------------------------------------------------------------------
    // STATE & LOGIC
    // -------------------------------------------------------------------------
    // Kept in step with the ladder in scripts/scale-menu.sh, which only lists
    // scales that divide the panel into whole pixels.
    readonly property var ladder: [0.8, 1.0, 1.25, 1.5, 2.0]

    property real currentScale: 1.0
    property int monWidth: 1920
    property int monHeight: 1080

    property bool isKeyboardNav: false
    Timer {
        id: keyboardNavTimer
        interval: 250
        onTriggered: window.isKeyboardNav = false
    }

    ListModel { id: scaleModel }

    function rebuild() {
        scaleModel.clear();
        for (let i = 0; i < window.ladder.length; i++) {
            let sc = window.ladder[i];
            scaleModel.append({
                factor: sc,
                pct: Math.round(sc * 100) + "%",
                logical: Math.round(window.monWidth / sc) + " × " + Math.round(window.monHeight / sc),
                isCurrent: Math.abs(sc - window.currentScale) < 0.01
            });
        }
        // Land on the active rung so Enter without moving is a no-op.
        for (let i = 0; i < scaleModel.count; i++) {
            if (scaleModel.get(i).isCurrent) { scaleList.currentIndex = i; return; }
        }
        scaleList.currentIndex = 0;
    }

    Process {
        id: monFetcher
        command: ["bash", "-c", "hyprctl -j monitors | jq -r '.[0] | \"\\(.scale)\\t\\(.width)\\t\\(.height)\"'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("\t");
                if (parts.length >= 3) {
                    window.currentScale = parseFloat(parts[0]) || 1.0;
                    window.monWidth = parseInt(parts[1]) || 1920;
                    window.monHeight = parseInt(parts[2]) || 1080;
                }
                window.rebuild();
            }
        }
    }

    function applyScale(factor) {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/scale-menu.sh", factor.toString()]);
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    function closeSelf() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    Keys.onUpPressed: (event) => {
        window.isKeyboardNav = true;
        keyboardNavTimer.restart();
        if (scaleList.currentIndex > 0) scaleList.currentIndex--;
        event.accepted = true;
    }
    Keys.onDownPressed: (event) => {
        window.isKeyboardNav = true;
        keyboardNavTimer.restart();
        if (scaleList.currentIndex < scaleModel.count - 1) scaleList.currentIndex++;
        event.accepted = true;
    }
    Keys.onReturnPressed: (event) => {
        if (scaleList.currentIndex >= 0) window.applyScale(scaleModel.get(scaleList.currentIndex).factor);
        event.accepted = true;
    }
    Keys.onEnterPressed: (event) => {
        if (scaleList.currentIndex >= 0) window.applyScale(scaleModel.get(scaleList.currentIndex).factor);
        event.accepted = true;
    }
    Keys.onEscapePressed: (event) => {
        window.closeSelf();
        event.accepted = true;
    }

    property real introPhase: 0
    NumberAnimation on introPhase {
        from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Rectangle {
        id: mainBg
        width: parent.width

        property real headerHeight: window.s(65)
        property real separatorHeight: 1
        property real itemHeight: window.s(60)
        property real listSpacing: window.s(4)
        property real listHeight: (scaleModel.count * itemHeight) + ((scaleModel.count - 1) * listSpacing)
        property real margins: scaleModel.count > 0 ? window.s(20) : 0

        height: headerHeight + separatorHeight + margins + listHeight

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        radius: window.s(21)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
        border.color: window.surface1
        border.width: 1
        clip: true

        transform: Translate { y: (window.introPhase - 1) * window.s(60) }
        opacity: window.introPhase

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --- HEADER ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.headerHeight
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: window.s(15)
                    anchors.leftMargin: window.s(20)
                    anchors.rightMargin: window.s(20)
                    spacing: window.s(15)

                    Text {
                        text: "󰍹"
                        font.family: "Hack Nerd Font"
                        font.pixelSize: window.s(18)
                        color: window.mauve
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Display scale"
                        color: window.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: window.s(16)
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: window.monWidth + "×" + window.monHeight
                        color: window.subtext0
                        font.family: "Hack Nerd Font"
                        font.pixelSize: window.s(12)
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // --- SEPARATOR ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.separatorHeight
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
            }

            // --- SCALE LIST ---
            ListView {
                id: scaleList
                Layout.fillWidth: true
                Layout.preferredHeight: mainBg.listHeight
                Layout.topMargin: mainBg.margins / 2
                Layout.bottomMargin: mainBg.margins / 2
                Layout.leftMargin: window.s(10)
                Layout.rightMargin: window.s(10)

                model: scaleModel
                spacing: mainBg.listSpacing
                interactive: false
                highlightFollowsCurrentItem: false

                // --- MATTE MORPHING HIGHLIGHT ---
                highlight: Item {
                    z: 0

                    Rectangle {
                        x: 0
                        width: scaleList.width
                        radius: window.s(10)
                        color: window.mauve

                        property int prevIdx: 0
                        property int curIdx: scaleList.currentIndex

                        onCurIdxChanged: {
                            if (curIdx === -1) return;
                            if (curIdx > prevIdx) {
                                bottomAnim.duration = 250; topAnim.duration = 450;
                            } else if (curIdx < prevIdx) {
                                topAnim.duration = 250; bottomAnim.duration = 450;
                            }
                            prevIdx = curIdx;
                        }

                        property real targetTop: scaleList.currentItem ? scaleList.currentItem.y : 0
                        property real targetBottom: scaleList.currentItem ? (scaleList.currentItem.y + scaleList.currentItem.height) : 0

                        property real actualTop: targetTop
                        property real actualBottom: targetBottom

                        Behavior on actualTop {
                            enabled: window.isKeyboardNav
                            NumberAnimation { id: topAnim; easing.type: Easing.OutExpo }
                        }
                        Behavior on actualBottom {
                            enabled: window.isKeyboardNav
                            NumberAnimation { id: bottomAnim; easing.type: Easing.OutExpo }
                        }

                        y: actualTop
                        height: actualBottom - actualTop

                        opacity: scaleList.count > 0 && scaleList.currentIndex >= 0 ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }

                delegate: Item {
                    width: ListView.view.width
                    height: mainBg.itemHeight
                    z: 1

                    transformOrigin: Item.Center

                    Rectangle {
                        anchors.fill: parent
                        radius: window.s(10)
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            radius: window.s(10)
                            color: window.surface0
                            opacity: ma.containsMouse && index !== scaleList.currentIndex ? 0.4 : 0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: window.s(10)
                            anchors.leftMargin: window.s(12)
                            spacing: window.s(15)

                            // --- TINTED PERCENTAGE MATTE BOX ---
                            Rectangle {
                                Layout.preferredWidth: window.s(40)
                                Layout.preferredHeight: window.s(40)
                                radius: window.s(16)

                                color: index === scaleList.currentIndex ? window.crust : window.surface0
                                border.width: 0
                                clip: true

                                property real activeScale: index === scaleList.currentIndex ? 1.15 : 1
                                scale: activeScale
                                Behavior on activeScale {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰊤"
                                    color: model.isCurrent ? window.green : window.subtext0
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: window.s(16)
                                    font.weight: Font.Bold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: model.pct
                                    color: index === scaleList.currentIndex ? window.crust : window.text
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: window.s(15)
                                    font.weight: Font.Bold
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                                Text {
                                    text: model.logical
                                    color: index === scaleList.currentIndex ? Qt.alpha(window.crust, 0.7) : window.subtext0
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: window.s(11)
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Marks the scale that is already active.
                            Rectangle {
                                visible: model.isCurrent
                                Layout.preferredWidth: window.s(58)
                                Layout.preferredHeight: window.s(22)
                                radius: window.s(11)
                                color: index === scaleList.currentIndex
                                    ? Qt.alpha(window.crust, 0.18)
                                    : Qt.alpha(window.green, 0.15)
                                border.width: 1
                                border.color: index === scaleList.currentIndex
                                    ? Qt.alpha(window.crust, 0.35)
                                    : Qt.alpha(window.green, 0.4)

                                Text {
                                    anchors.centerIn: parent
                                    text: "active"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: window.s(10)
                                    font.weight: Font.Bold
                                    color: index === scaleList.currentIndex ? window.crust : window.green
                                }
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                window.isKeyboardNav = false;
                                scaleList.currentIndex = index;
                            }
                            onClicked: window.applyScale(model.factor)
                        }
                    }
                }
            }
        }
    }
}
