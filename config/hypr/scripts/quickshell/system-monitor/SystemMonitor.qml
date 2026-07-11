import QtQuick
import QtQuick.Layouts
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
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color blue: _theme.blue || "#89b4fa"
    readonly property color yellow: _theme.yellow || "#f9e2af"
    readonly property color peach: _theme.peach || "#fab387"
    readonly property color sapphire: _theme.sapphire || "#74c7ec"

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(val) { return scaler.s(val) }

    property string cpuVal: "--"
    property string ramVal: "--"
    property string diskVal: "--"
    property string tempVal: "--"
    property string procVal: "--"
    property string uptimeVal: "--"
    property string netStr: ""

    function fetchData() {
        runner.running = false
        runner.running = true
    }

    property string debugText: "waiting..."

    readonly property int historyLen: 30
    ListModel { id: cpuHistoryModel }
    ListModel { id: ramHistoryModel }

    Process {
        id: runner
        running: true
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/system-monitor/fetch.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!this.text || this.text.trim().length === 0) return
                    let d = JSON.parse(this.text.trim())
                    let rawCpu = d.cpu || 0
                    let rawRam = d.ram_pct || 0
                    window.cpuVal = rawCpu + "%"
                    window.ramVal = rawRam + "%"

                    while (cpuHistoryModel.count >= window.historyLen) cpuHistoryModel.remove(0);
                    cpuHistoryModel.append({ pct: Math.min(rawCpu, 100) })
                    while (ramHistoryModel.count >= window.historyLen) ramHistoryModel.remove(0);
                    ramHistoryModel.append({ pct: Math.min(rawRam, 100) })
                    window.diskVal = (d.disk_pct || 0) + "%"
                    window.tempVal = (d.temp || 0) + "\u00B0C"
                    window.procVal = String(d.procs || 0)
                    window.uptimeVal = d.uptime || "--"
                    window.netStr = (d.iface || "none") + "  RX " + window.formatBytes(d.rx_bytes) + "  TX " + window.formatBytes(d.tx_bytes)
                    window.debugText = "OK: CPU=" + d.cpu + " RAM=" + d.ram_pct
                } catch(e) {
                    window.debugText = "ERROR: " + e
                    console.log("sysmon parse:", e)
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (!bytes || bytes === 0) return "0 B"
        let u = ["B", "KB", "MB", "GB"]; let i = 0; let v = bytes
        while (v >= 1024 && i < 3) { v /= 1024; i++ }
        return v.toFixed(i < 2 ? 0 : 1) + " " + u[i]
    }

    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: false; onTriggered: { runner.running = false; runner.running = true } }

    function card(label, icon, value, color, pct) {
        return Qt.createQmlObject('
            import QtQuick; import QtQuick.Layouts;
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    width: parent.width * Math.min(' + (pct || 0) + ', 1); height: s(3); radius: s(2)
                    color: "' + color + '"; opacity: 0.6
                    Behavior on width { NumberAnimation { duration: 600 } }
                }
                RowLayout {
                    anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                    Rectangle {
                        Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10)
                        color: Qt.rgba(' + color + '.r, ' + color + '.g, ' + color + '.b, 0.15)
                        Text { anchors.centerIn: parent; text: "' + icon + '"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: "' + color + '" }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: s(2)
                        Text { text: "' + label + '"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                        Text { text: ' + value + '; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text }
                    }
                }
            }
        ', parent)
    }

    Rectangle {
        anchors.fill: parent; color: window.base; radius: s(16)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: s(20); spacing: s(12)
            Text { text: "\uF109  System Monitor"; font.family: "Hack Nerd Font"; font.pixelSize: s(15); font.weight: Font.Bold; color: window.text }

            GridLayout {
                columns: 2; columnSpacing: s(10); rowSpacing: s(10); Layout.fillWidth: true

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: parent.width * Math.min(parseInt(window.cpuVal) / 100, 1); height: s(3); radius: s(2); color: window.mauve; opacity: 0.6; Behavior on width { NumberAnimation { duration: 600 } } }
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uF0E4"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.mauve } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "CPU"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.cpuVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                        Item { Layout.preferredWidth: s(56); Layout.preferredHeight: s(28); Layout.alignment: Qt.AlignVCenter; clip: true
                            Row { anchors.fill: parent; spacing: 2; layoutDirection: Qt.RightToLeft
                                Repeater { model: cpuHistoryModel
                                    delegate: Rectangle { width: 2; height: Math.max(2, parent.height * model.pct / 100); radius: 1; color: window.mauve; opacity: 0.7; anchors.bottom: parent.bottom } } } }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: parent.width * Math.min(parseInt(window.ramVal) / 100, 1); height: s(3); radius: s(2); color: window.blue; opacity: 0.6; Behavior on width { NumberAnimation { duration: 600 } } }
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.blue.r, window.blue.g, window.blue.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uF538"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.blue } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "RAM"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.ramVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                        Item { Layout.preferredWidth: s(56); Layout.preferredHeight: s(28); Layout.alignment: Qt.AlignVCenter; clip: true
                            Row { anchors.fill: parent; spacing: 2; layoutDirection: Qt.RightToLeft
                                Repeater { model: ramHistoryModel
                                    delegate: Rectangle { width: 2; height: Math.max(2, parent.height * model.pct / 100); radius: 1; color: window.blue; opacity: 0.7; anchors.bottom: parent.bottom } } } }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: parent.width * Math.min(parseInt(window.diskVal) / 100, 1); height: s(3); radius: s(2); color: window.green; opacity: 0.6; Behavior on width { NumberAnimation { duration: 600 } } }
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.green.r, window.green.g, window.green.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uF0A0"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.green } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "Disk"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.diskVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: parent.width * Math.min(parseInt(window.tempVal) / 100, 1); height: s(3); radius: s(2); color: window.peach; opacity: 0.6; Behavior on width { NumberAnimation { duration: 600 } } }
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.peach.r, window.peach.g, window.peach.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uF2C7"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.peach } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "Temp"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.tempVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.sapphire.r, window.sapphire.g, window.sapphire.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uE60B"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.sapphire } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "Processes"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.procVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: s(78); radius: s(10); color: window.crust; clip: true
                    RowLayout { anchors.fill: parent; anchors.margins: s(12); spacing: s(10)
                        Rectangle { Layout.preferredWidth: s(36); Layout.preferredHeight: s(36); radius: s(10); color: Qt.rgba(window.yellow.r, window.yellow.g, window.yellow.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uF253"; font.family: "Hack Nerd Font"; font.pixelSize: s(16); color: window.yellow } }
                        ColumnLayout { Layout.fillWidth: true; spacing: s(2)
                            Text { text: "Uptime"; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0 }
                            Text { text: window.uptimeVal; font.family: "Hack Nerd Font"; font.pixelSize: s(16); font.weight: Font.Bold; color: window.text } }
                    }
                }
            }

            Text { text: window.netStr; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.overlay0; horizontalAlignment: Text.AlignRight }
            Text { text: window.debugText; font.family: "Hack Nerd Font"; font.pixelSize: s(10); color: window.peach; horizontalAlignment: Text.AlignRight }
        }
    }
}
