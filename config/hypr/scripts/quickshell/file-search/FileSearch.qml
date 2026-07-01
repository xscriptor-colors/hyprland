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
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color green: _theme.green || "#a6e3a1"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    property string searchQuery: ""
    property int resultCount: 0

    ListModel { id: fileModel }

    Process {
        id: searcher
        stdout: StdioCollector {
            onStreamFinished: {
                fileModel.clear()
                if (!this.text || this.text.trim().length === 0) {
                    window.resultCount = 0
                    return
                }
                let lines = this.text.trim().split('\n')
                for (let i = 0; i < lines.length; i++) {
                    let path = lines[i].trim()
                    if (path.length > 0) {
                        let parts = path.split('/')
                        fileModel.append({ path: path, name: parts[parts.length - 1] })
                    }
                }
                window.resultCount = fileModel.count
            }
        }
    }

    function startSearch() {
        if (window.searchQuery.trim().length < 2) {
            fileModel.clear(); window.resultCount = 0; return
        }
        searcher.command = ["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/file-search/fetch.sh", window.searchQuery.trim()]
        searcher.running = false
        searcher.running = true
    }

    Timer { id: searchTimer; interval: 200; onTriggered: startSearch() }

    Rectangle {
        anchors.fill: parent; color: window.base; radius: s(16)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: s(20); spacing: s(10)

            RowLayout {
                Layout.fillWidth: true; spacing: s(10)
                Text { text: "\uF002"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.mauve }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    background: Item {}
                    color: window.text
                    font.family: "Hack Nerd Font"; font.pixelSize: s(14)
                    placeholderText: "Search files..."; placeholderTextColor: window.overlay0
                    focus: true
                    onTextChanged: {
                        window.searchQuery = text
                        searchTimer.restart()
                    }
                    Keys.onEscapePressed: {
                        searchInput.text = ""
                        event.accepted = true
                    }
                }

                Text {
                    text: window.resultCount > 0 ? window.resultCount + " files" : ""
                    font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(1); color: window.surface1; opacity: 0.3 }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: s(4)
                model: fileModel

                ScrollBar.vertical: ScrollBar {
                    active: true; policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { implicitWidth: s(4); radius: s(2); color: window.surface2; opacity: 0.5 }
                }

                delegate: Rectangle {
                    width: parent ? parent.width : 0; height: s(48); radius: s(8)
                    color: ma.containsMouse ? window.surface0 : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: s(10); spacing: s(10)

                        Text { text: "\uF016"; font.family: "Hack Nerd Font"; font.pixelSize: s(14); color: window.blue }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: s(2)
                            Text {
                                text: model.name; font.family: "Hack Nerd Font"; font.pixelSize: s(12)
                                color: window.text; elide: Text.ElideRight
                            }
                            Text {
                                text: model.path; font.family: "Hack Nerd Font"; font.pixelSize: s(9)
                                color: window.overlay0; elide: Text.ElideLeft
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: s(28); Layout.preferredHeight: s(28); radius: s(7)
                            color: window.green; opacity: 0.2
                            Text { anchors.centerIn: parent; text: "\uF061"; font.family: "Hack Nerd Font"; font.pixelSize: s(11); color: window.green }
                        }
                    }

                    MouseArea {
                        id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.path) {
                                Quickshell.execDetached(["xdg-open", model.path])
                            }
                        }
                    }
                }
            }
        }
    }
}
