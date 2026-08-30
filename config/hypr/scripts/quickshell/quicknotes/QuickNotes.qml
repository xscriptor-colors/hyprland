import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    readonly property color surface1: _theme.surface1
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color green: _theme.green || "#a6e3a1"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    property string noteContent: ""
    property bool isDirty: false
    readonly property string notesFile: Quickshell.env("HOME") + "/.cache/quickshell/quicknotes.txt"

    Process {
        id: loadProcess
        command: ["bash", "-c", "cat " + window.notesFile + " 2>/dev/null || echo ''"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) noteText.text = this.text
            }
        }
    }

    Process {
        id: saveProcess
        stdinEnabled: true
        stdout: StdioCollector {
            onStreamFinished: {
                window.isDirty = false
            }
        }
    }

    Timer {
        id: saveTimer; interval: 800
        onTriggered: {
            saveProcess.command = ["bash", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.cache/quickshell && cat > " + window.notesFile]
            saveProcess.write(noteText.text)
            saveProcess.running = true
        }
    }

    Rectangle {
        anchors.fill: parent; color: window.base; radius: s(16)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: s(20); spacing: s(15)

            RowLayout {
                Layout.fillWidth: true; spacing: s(10)
                Text { text: "\uF4AD"; font.family: "Hack Nerd Font"; font.pixelSize: s(18); color: window.mauve }
                Text { Layout.fillWidth: true; text: "Quick Notes"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text }
                Rectangle { width: s(8); height: s(8); radius: s(4); color: window.isDirty ? window.green : "transparent"; anchors.verticalCenter: parent.verticalCenter; Behavior on color { ColorAnimation { duration: 300 } } }
                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; radius: s(10); color: window.crust; clip: true
                ScrollView {
                    anchors.fill: parent; anchors.margins: s(8)
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.contentItem.opacity: 0.4
                    TextArea {
                        id: noteText
                        font.family: "Hack Nerd Font"; font.pixelSize: s(13)
                        color: window.text; wrapMode: TextEdit.Wrap
                        background: null
                        placeholderText: "Write something..."; placeholderTextColor: window.overlay0
                        focus: true
                        onTextChanged: {
                            window.isDirty = true
                            saveTimer.restart()
                        }
                    }
                }
            }

            Text {
                text: window.isDirty ? "Unsaved changes" : "Auto-saved"
                font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
