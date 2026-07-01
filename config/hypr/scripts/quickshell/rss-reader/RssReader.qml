import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
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
    readonly property color surface2: _theme.surface2
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color red: _theme.red || "#f38ba8"
    readonly property color peach: _theme.peach || "#fab387"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    property var entries: []
    property string statusText: "Loading..."
    property string selectedFeed: ""

    property var feedNames: []
    property var feedCounts: ({})

    Process {
        id: fetcher; running: true
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/rss-reader/fetch.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        window.entries = JSON.parse(this.text.trim())
                        rebuildFeeds()
                    }
                } catch(e) {
                    window.statusText = "Error"
                }
            }
        }
    }

    Timer { interval: 600000; running: true; repeat: true; triggeredOnStart: false; onTriggered: { fetcher.running = false; fetcher.running = true } }

    function rebuildFeeds() {
        let names = []
        let counts = {}
        for (let i = 0; i < entries.length; i++) {
            let f = entries[i].feed
            if (!counts[f]) { counts[f] = 0; names.push(f) }
            counts[f]++
        }
        window.feedNames = names
        window.feedCounts = counts
        window.statusText = entries.length + " articles"
        rebuildModel()
    }

    ListModel { id: feedModel }

    function rebuildModel() {
        feedModel.clear()
        let filtered = window.selectedFeed === ""
            ? window.entries
            : window.entries.filter(function(e) { return e.feed === window.selectedFeed })
        for (let i = 0; i < filtered.length; i++) {
            feedModel.append(filtered[i])
        }
    }

    onSelectedFeedChanged: rebuildModel()

    Rectangle {
        anchors.fill: parent; color: window.base; radius: s(16)

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: s(52)
                radius: s(16); color: "transparent"

                RowLayout {
                    anchors.fill: parent; anchors.margins: s(16); anchors.leftMargin: s(20)
                    spacing: s(10)

                    Text { text: "\uF09E"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: window.mauve }
                    Text { text: "Feeds"; font.family: "Hack Nerd Font"; font.pixelSize: s(15); font.weight: Font.Bold; color: window.text }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: s(28); Layout.preferredHeight: s(28); radius: s(8)
                        color: window.mauve; opacity: 0.15
                        Text { anchors.centerIn: parent; text: "\uF021"; font.family: "Hack Nerd Font"; font.pixelSize: s(12); color: window.mauve }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { fetcher.running = false; fetcher.running = true }
                        }
                    }
                }
            }

            // Feed filter bar
            ListView {
                id: feedBar
                Layout.fillWidth: true; Layout.preferredHeight: s(36)
                orientation: ListView.Horizontal
                spacing: s(6); clip: true
                leftMargin: s(16); rightMargin: s(16)

                model: {
                    let items = [{ name: "All", count: window.entries.length }]
                    for (let i = 0; i < window.feedNames.length; i++) {
                        items.push({ name: window.feedNames[i], count: window.feedCounts[window.feedNames[i]] })
                    }
                    return items
                }

                delegate: Rectangle {
                    height: s(30); radius: s(8)
                    width: feedLabel.width + s(20)
                    color: modelData.name === window.selectedFeed || (modelData.name === "All" && window.selectedFeed === "")
                        ? window.mauve : window.surface0
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: feedLabel
                        anchors.centerIn: parent
                        text: {
                            let name = modelData.name
                            if (name === "All") return "\uF0E8 All"
                            let parts = name.replace(/^https?:\/\//, '').replace(/^www\./, '').split('/')[0]
                            return parts.substring(0, 18)
                        }
                        font.family: "Hack Nerd Font"; font.pixelSize: s(10)
                        color: (modelData.name === window.selectedFeed || (modelData.name === "All" && window.selectedFeed === ""))
                            ? window.crust : window.text
                    }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            window.selectedFeed = modelData.name === "All" ? "" : modelData.name
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.2; Layout.topMargin: s(6) }

            // Articles list
            ListView {
                id: feedList
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.topMargin: s(6); Layout.bottomMargin: s(6)
                clip: true; spacing: s(4)
                model: feedModel

                ScrollBar.vertical: ScrollBar {
                    active: true; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: s(4); radius: s(2); color: window.surface2; opacity: 0.5 }
                }

                delegate: Rectangle {
                    width: feedList.width; height: s(70); radius: s(8)
                    color: ma.containsMouse ? window.surface0 : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: s(10); spacing: s(10)

                        Rectangle {
                            Layout.preferredWidth: s(4); Layout.preferredHeight: s(40); radius: s(2)
                            color: window.mauve; opacity: 0.4
                        }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: s(3)
                            Text {
                                text: model.title; font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                                font.weight: Font.Medium; color: window.text
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.WordWrap
                            }
                            Text {
                                text: model.feed.replace(/^https?:\/\//, '').replace(/^www\./, '').split('/')[0]
                                font.family: "Hack Nerd Font"; font.pixelSize: s(9); color: window.overlay0
                            }
                            Text {
                                text: model.desc; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.subtext0
                                elide: Text.ElideRight; maximumLineCount: 1; visible: text !== ""
                            }
                        }

                        Text {
                            text: "\uF08E"; font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                            color: window.blue; opacity: ma.containsMouse ? 1 : 0.3
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.rightMargin: s(4)
                        }
                    }

                    MouseArea {
                        id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.link) Qt.openUrlExternally(model.link)
                        }
                    }
                }
            }

            // Status bar
            Text {
                Layout.fillWidth: true; Layout.leftMargin: s(20); Layout.rightMargin: s(20); Layout.bottomMargin: s(10)
                text: window.statusText + (window.selectedFeed ? " \u00B7 " + window.selectedFeed.replace(/^https?:\/\//, '').split('/')[0] : "")
                font.family: "Hack Nerd Font"; font.pixelSize: s(9); color: window.overlay0
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
