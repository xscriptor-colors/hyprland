// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/filter — DavincixMonitors
//
// Multi-monitor selector: an icon that expands into a row of monitor chips.
// Selection is stored on the passed-in ListModel (`monitors`); the picker
// reads the selected set via ctx.getMonitorOutputs() when applying.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Rectangle {
    id: monitorDrawer

    required property var ctx        // picker root
    required property var theme      // Colors instance
    required property var monitors   // ListModel { name, selected }

    visible: monitors.count > 1
    height: ctx.s(44)

    property real expandedWidth: ctx.s(44) + monitorListRow.width + ctx.s(8)
    width: visible ? (ctx.isMonitorSelectorOpen ? expandedWidth : ctx.s(44)) : 0

    radius: ctx.s(13)
    clip: true
    anchors.verticalCenter: parent.verticalCenter

    color: ctx.isMonitorSelectorOpen ? theme.surface2 : "transparent"
    border.color: ctx.isMonitorSelectorOpen ? theme.text : theme.surface1
    border.width: ctx.isMonitorSelectorOpen ? ctx.s(2) : 1

    Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
    Behavior on color { ColorAnimation { duration: 400 } }
    Behavior on border.color { ColorAnimation { duration: 400 } }

    MouseArea {
        id: monitorIconMouse
        width: ctx.s(44)
        height: ctx.s(44)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        hoverEnabled: true
        enabled: !ctx.isApplying
        cursorShape: Qt.PointingHandCursor
        onClicked: ctx.isMonitorSelectorOpen = !ctx.isMonitorSelectorOpen
    }

    Canvas {
        id: monitorIcon
        width: ctx.s(18)
        height: ctx.s(18)
        anchors.centerIn: monitorIconMouse
        property string activeColor: ctx.isMonitorSelectorOpen ? theme.text
            : (monitorIconMouse.containsMouse ? theme.text
               : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7))
        onActiveColorChanged: requestPaint()
        property real scaleTrigger: ctx.s(1)
        onScaleTriggerChanged: requestPaint()

        onPaint: {
            var c = getContext("2d");
            c.reset();
            c.lineWidth = ctx.s(2);
            c.strokeStyle = activeColor;
            c.lineJoin = "round";
            c.lineCap = "round";

            c.beginPath();
            c.rect(ctx.s(2), ctx.s(3), ctx.s(14), ctx.s(9));
            c.stroke();

            c.beginPath();
            c.moveTo(ctx.s(9), ctx.s(12));
            c.lineTo(ctx.s(9), ctx.s(16));
            c.moveTo(ctx.s(5), ctx.s(16));
            c.lineTo(ctx.s(13), ctx.s(16));
            c.stroke();
        }
    }

    Row {
        id: monitorListRow
        anchors.left: monitorIconMouse.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: ctx.s(8)

        opacity: ctx.isMonitorSelectorOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Repeater {
            model: monitors
            delegate: Item {
                width: monitorText.contentWidth + ctx.s(16)
                height: ctx.s(32)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: ctx.s(8)
                    color: model.selected ? theme.text : theme.surface1
                    border.color: model.selected ? theme.text : theme.surface2
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 250 } }
                    Behavior on border.color { ColorAnimation { duration: 250 } }

                    Text {
                        id: monitorText
                        text: model.name
                        anchors.centerIn: parent
                        color: model.selected ? theme.base : theme.text
                        font.family: "Hack Nerd Font"
                        font.pixelSize: ctx.s(12)
                        font.bold: model.selected
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: ctx.isMonitorSelectorOpen && !ctx.isApplying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (model.selected) {
                            let activeCount = 0;
                            for (let i = 0; i < monitors.count; i++) {
                                if (monitors.get(i).selected) activeCount++;
                            }
                            if (activeCount > 1) {
                                monitors.setProperty(index, "selected", false);
                            }
                        } else {
                            monitors.setProperty(index, "selected", true);
                        }
                    }
                }
            }
        }
    }
}
