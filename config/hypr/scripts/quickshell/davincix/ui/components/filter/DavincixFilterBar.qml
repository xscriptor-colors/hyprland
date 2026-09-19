// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/filter — DavincixFilterBar
//
// Top bar: status notification + spinner, multi-monitor selector, quick
// controls (transition / rounded corners / palette preview), the color filter
// chips and the search control. Pure view over `ctx` state; the picker root
// owns the models and the search/apply orchestration.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Rectangle {
    id: filterBarBackground

    required property var ctx        // picker root
    required property var theme      // Colors instance
    required property var monitors   // ListModel (monitors)
    required property var settings   // Settings (search state)

    anchors.top: parent.top
    anchors.topMargin: ctx.isReady ? ctx.s(40) : ctx.s(-100)
    opacity: ctx.isReady ? 1.0 : 0.0
    Behavior on anchors.topMargin { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    anchors.horizontalCenter: parent.horizontalCenter
    z: 20
    height: ctx.s(56)
    width: filterRow.width + ctx.s(24)
    radius: ctx.s(18)

    color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.90)
    border.color: theme.surface2
    border.width: 1

    Row {
        id: filterRow
        anchors.centerIn: parent
        spacing: ctx.s(12)

        // ── Status notification + spinner ──────────────────────────────────
        Rectangle {
            id: notifDrawer
            height: ctx.s(44)
            property real paddingLeft: ctx.showSpinner ? ctx.s(40) : ctx.s(16)
            property real targetWidth: ctx.showNotification ? Math.min(notifTextDrawer.implicitWidth + paddingLeft + ctx.s(20), ctx.s(300)) : 0
            width: targetWidth
            visible: width > 0.1
            radius: ctx.s(13)
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            color: ctx.showNotification ? theme.surface2 : "transparent"
            border.color: ctx.showNotification ? theme.surface1 : "transparent"
            border.width: 1

            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            Behavior on color { ColorAnimation { duration: 400 } }
            Behavior on border.color { ColorAnimation { duration: 400 } }

            Item {
                visible: ctx.showSpinner
                width: ctx.s(44)
                height: ctx.s(44)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Canvas {
                    id: notifSpinner
                    width: ctx.s(14)
                    height: ctx.s(14)
                    anchors.centerIn: parent
                    property real scaleTrigger: ctx.s(1)
                    onScaleTriggerChanged: requestPaint()

                    onPaint: {
                        var c = getContext("2d");
                        c.reset();
                        c.lineWidth = ctx.s(2);
                        c.strokeStyle = Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.3);
                        c.beginPath();
                        c.arc(ctx.s(7), ctx.s(7), ctx.s(5), 0, Math.PI * 2);
                        c.stroke();

                        c.strokeStyle = Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.9);
                        c.beginPath();
                        c.arc(ctx.s(7), ctx.s(7), ctx.s(5), 0, Math.PI * 0.5);
                        c.stroke();
                    }
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0; to: 360
                        duration: 800
                        running: ctx.showSpinner && ctx.showNotification
                    }
                }
            }

            Text {
                id: notifTextDrawer
                anchors.left: parent.left
                anchors.leftMargin: ctx.showSpinner ? ctx.s(40) : ctx.s(16)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, ctx.s(300) - anchors.leftMargin - ctx.s(16))
                text: ctx.currentNotification
                color: theme.text
                font.family: "Hack Nerd Font"
                font.pixelSize: ctx.s(14)
                font.bold: true
                elide: Text.ElideRight

                opacity: ctx.showNotification ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }
                Behavior on anchors.leftMargin { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            }
        }

        // ── Multi-monitor selector ─────────────────────────────────────────
        DavincixMonitors {
            ctx: filterBarBackground.ctx
            theme: filterBarBackground.theme
            monitors: filterBarBackground.monitors
        }

        // ── Quick controls: transition, corners, palette preview ───────────
        Row {
            spacing: ctx.s(6)
            anchors.verticalCenter: parent.verticalCenter

            // Transition selector — click to cycle through xwww transitions.
            Rectangle {
                id: transBtn
                width: transLabel.implicitWidth + ctx.s(30)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: transMouse.containsMouse ? theme.surface1 : theme.surface0
                border.color: theme.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.centerIn: parent
                    spacing: ctx.s(6)
                    Text { text: "󰜯"; font.family: "Hack Nerd Font"; font.pixelSize: ctx.s(13); color: theme.text; anchors.verticalCenter: parent.verticalCenter }
                    Text { id: transLabel; text: ctx.transition; font.family: "Hack Nerd Font"; font.pixelSize: ctx.s(11); color: theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: transMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let i = ctx.transitions.indexOf(ctx.transition);
                        ctx.transition = ctx.transitions[(i + 1) % ctx.transitions.length];
                    }
                }
            }

            // Thumbnail corners: rounded / square toggle.
            Rectangle {
                width: ctx.s(36)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: cornersMouse.containsMouse ? theme.surface1 : theme.surface0
                border.color: theme.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: ctx.roundedThumbs ? "◍" : "▣"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: ctx.s(15)
                    color: theme.text
                }
                MouseArea {
                    id: cornersMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctx.roundedThumbs = !ctx.roundedThumbs
                }
            }

            // Grid orientation: horizontal ⇄ vertical (persisted).
            Rectangle {
                width: ctx.s(36)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: orientMouse.containsMouse ? theme.surface1 : theme.surface0
                border.color: theme.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: ctx.gridOrientation === "vertical" ? "\uF07D" : "\uF07E"  // fa-arrows-v / fa-arrows-h
                    font.family: "Hack Nerd Font"
                    font.pixelSize: ctx.s(14)
                    color: theme.text
                }
                MouseArea {
                    id: orientMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctx.setOrientation(ctx.gridOrientation === "vertical" ? "horizontal" : "vertical")
                }
            }

            // Card shape: rect / square / circle (persisted).
            Rectangle {
                width: ctx.s(36)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: shapeMouse.containsMouse ? theme.surface1 : theme.surface0
                border.color: theme.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: ctx.cardShape === "circle" ? "◯" : (ctx.cardShape === "square" ? "◻" : "▭")
                    font.family: "Hack Nerd Font"
                    font.pixelSize: ctx.s(14)
                    color: theme.text
                }
                MouseArea {
                    id: shapeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let i = ctx.shapeOrder.indexOf(ctx.cardShape);
                        ctx.setCardShape(ctx.shapeOrder[(i + 1) % ctx.shapeOrder.length]);
                    }
                }
            }

            // Slideshow: rotates the wallpaper every N minutes.
            Rectangle {
                width: ctx.s(36)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: ctx.slideshowOn
                    ? Qt.alpha(theme.mauve, 0.35)
                    : (slideMouse.containsMouse ? theme.surface1 : theme.surface0)
                border.color: ctx.slideshowOn ? theme.mauve : theme.surface1
                border.width: ctx.slideshowOn ? ctx.s(2) : 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uF01E"  // fa-repeat
                    font.family: "Hack Nerd Font"
                    font.pixelSize: ctx.s(14)
                    color: ctx.slideshowOn ? theme.mauve : theme.text
                }
                MouseArea {
                    id: slideMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctx.toggleSlideshow()
                }
            }

            // Active palette preview (base + accent swatches).
            Rectangle {
                width: ctx.s(58)
                height: ctx.s(36)
                radius: ctx.s(13)
                anchors.verticalCenter: parent.verticalCenter
                color: theme.surface0
                border.color: theme.surface1
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: ctx.s(5)
                    Rectangle { width: ctx.s(13); height: ctx.s(13); radius: ctx.s(4); color: theme.base; border.color: theme.surface1; border.width: 1 }
                    Rectangle { width: ctx.s(13); height: ctx.s(13); radius: ctx.s(4); color: theme.accent }
                }
            }
        }

        // ── Color filter chips ─────────────────────────────────────────────
        Repeater {
            model: ctx.filterData

            delegate: Item {
                visible: modelData.name !== "Search"
                width: !visible ? 0 : ((modelData.name === "Video" || modelData.name === "All") ? ctx.s(44) : (modelData.hex === "" ? filterText.contentWidth + ctx.s(24) : ctx.s(36)))
                height: !visible ? 0 : ctx.s(36)
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: ctx.s(13)
                    color: modelData.hex === ""
                        ? (ctx.currentFilter === modelData.name ? theme.surface2 : "transparent")
                        : modelData.hex

                    border.color: ctx.currentFilter === modelData.name ? theme.text : theme.surface1
                    border.width: ctx.currentFilter === modelData.name ? ctx.s(2) : 1
                    scale: ctx.currentFilter === modelData.name ? 1.15 : (filterMouse.containsMouse ? 1.08 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Text {
                        id: filterText
                        visible: modelData.hex === "" && modelData.name !== "Video" && modelData.name !== "All"
                        text: modelData.label
                        anchors.centerIn: parent
                        color: ctx.currentFilter === modelData.name ? theme.text : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                        font.family: "Hack Nerd Font"
                        font.pixelSize: ctx.s(14)
                        font.bold: ctx.currentFilter === modelData.name
                        Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
                    }

                    Canvas {
                        visible: modelData.name === "Video"
                        width: ctx.s(14)
                        height: ctx.s(16)
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: ctx.s(2)
                        property string activeColor: ctx.currentFilter === modelData.name ? theme.text : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                        onActiveColorChanged: requestPaint()
                        property real scaleTrigger: ctx.s(1)
                        onScaleTriggerChanged: requestPaint()

                        onPaint: {
                            var c = getContext("2d");
                            c.reset();
                            c.fillStyle = activeColor;
                            c.beginPath();
                            c.moveTo(0, 0);
                            c.lineTo(ctx.s(14), ctx.s(8));
                            c.lineTo(0, ctx.s(16));
                            c.closePath();
                            c.fill();
                        }
                    }

                    Canvas {
                        visible: modelData.name === "All"
                        width: ctx.s(14)
                        height: ctx.s(14)
                        anchors.centerIn: parent
                        property string activeColor: ctx.currentFilter === modelData.name ? theme.text : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                        onActiveColorChanged: requestPaint()
                        property real scaleTrigger: ctx.s(1)
                        onScaleTriggerChanged: requestPaint()

                        onPaint: {
                            var c = getContext("2d");
                            c.reset();
                            c.fillStyle = activeColor;
                            c.fillRect(0, 0, ctx.s(6), ctx.s(6));
                            c.fillRect(ctx.s(8), 0, ctx.s(6), ctx.s(6));
                            c.fillRect(0, ctx.s(8), ctx.s(6), ctx.s(6));
                            c.fillRect(ctx.s(8), ctx.s(8), ctx.s(6), ctx.s(6));
                        }
                    }
                }

                MouseArea {
                    id: filterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !ctx.isApplying
                    onClicked: ctx.currentFilter = modelData.name
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // ── Search control ────────────────────────────────────────────────
        DavincixSearch {
            id: search
            ctx: filterBarBackground.ctx
            theme: filterBarBackground.theme
            settings: filterBarBackground.settings
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
