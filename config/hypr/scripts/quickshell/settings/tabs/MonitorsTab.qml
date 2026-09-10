// ═══════════════════════════════════════════════════════════════════════════
// MonitorsTab — pestaña "Monitors" de SettingsPopup, extraída del Component
// inline para poder compartirla (popup de settings + BarEditor).
//
// `host` = root de SettingsPopup: el cuerpo del tab quedó intacto y usa
// root.s(), root.<rol>, etc. mediante el bloque de forwarding de abajo.
// ═══════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../.."

Item {
    id: root

    // ════ Forwarding al host (SettingsPopup) ════
    // El cuerpo de este tab quedó intacto y sigue usando root.s(),
    // root.<rol>… vía estos proxies.
    property var host: null
    readonly property color base: host ? host.base : "#363537"
    readonly property color crust: host ? host.crust : "#363537"
    readonly property color green: host ? host.green : "#7bd88f"
    readonly property color mantle: host ? host.mantle : "#363537"
    readonly property color overlay0: host ? host.overlay0 : "#f7f1ff"
    readonly property color red: host ? host.red : "#fc618d"
    readonly property color subtext0: host ? host.subtext0 : "#f7f1ff"
    readonly property color surface0: host ? host.surface0 : "#363537"
    readonly property color surface1: host ? host.surface1 : "#363537"
    readonly property color surface2: host ? host.surface2 : "#363537"
    readonly property color text: host ? host.text : "#f7f1ff"
    readonly property color pink: host ? host.pink : "#948ae3"
    readonly property color mauve: host ? host.mauve : "#948ae3"
    readonly property color blue: host ? host.blue : "#5ad4e6"
    readonly property color teal: host ? host.teal : "#5ad4e6"
    readonly property color yellow: host ? host.yellow : "#fce566"
    readonly property color peach: host ? host.peach : "#fd9353"
    readonly property color sapphire: host ? host.sapphire : "#5ad4e6"
    function s(val) { return host ? host.s(val) : val; }

    // ════ Movidos desde SettingsPopup.qml (exclusivos de este tab) ════

    property color monSelectedResAccent: mauve
    property color monSelectedRateAccent: blue
    property int monChangeTrigger: 0
    property var monResAccentColors: [root.pink, root.mauve, root.blue, root.teal, root.yellow, root.peach, root.green, root.red, root.sapphire, root.sky, root.lavender, root.flamingo]
    
    function getResLabel(w, h) {
        if (w === 7680 && h === 4320) return "8K UHD";
        if (w === 5120 && h === 2880) return "5K";
        if (w === 5120 && h === 1440) return "DQHD";
        if (w === 4096 && h === 2160) return "DCI 4K";
        if (w === 3840 && h === 2160) return "4K UHD";
        if (w === 3840 && h === 1600) return "UW4K";
        if (w === 3440 && h === 1440) return "UWQHD";
        if (w === 2560 && h === 1440) return "QHD";
        if (w === 2560 && h === 1080) return "UWFHD";
        if (w === 1920 && h === 1200) return "WUXGA";
        if (w === 1920 && h === 1080) return "FHD";
        if (w === 1680 && h === 1050) return "WSXGA+";
        if (w === 1600 && h === 900)  return "HD+";
        if (w === 1440 && h === 900)  return "WXGA+";
        if (w === 1366 && h === 768)  return "FWXGA";
        if (w === 1280 && h === 1024) return "SXGA";
        if (w === 1280 && h === 800)  return "WXGA";
        if (w === 1280 && h === 720)  return "HD";
        if (w === 1024 && h === 768)  return "XGA";
        if (w === 800  && h === 600)  return "SVGA";
        return w + "×" + h;
    }
    property var monAvailableResolutions: {
        let _ = monChangeTrigger + Config.monActiveEditIndex;
        if (Config.monitorsModel.count === 0) return [];
        try {
            let modes = JSON.parse(Config.monitorsModel.get(Config.monActiveEditIndex).availableModes || "[]");
            let seen = {}, list = [];
            for (let m of modes) {
                let match = m.match(/^(\d+)x(\d+)@/);
                if (!match) continue;
                let key = match[1] + "x" + match[2];
                if (!seen[key]) { seen[key] = true; list.push({w: parseInt(match[1]), h: parseInt(match[2])}); }
            }
            list.sort((a, b) => (b.w * b.h) - (a.w * a.h));
            return list;
        } catch(e) { return []; }
    }
    property var monAvailableRates: {
        let _ = monChangeTrigger + Config.monActiveEditIndex;
        if (Config.monitorsModel.count === 0) return [];
        try {
            let mon = Config.monitorsModel.get(Config.monActiveEditIndex);
            let modes = JSON.parse(mon.availableModes || "[]");
            let rates = [], seen = {};
            let prefix = Math.round(mon.resW) + "x" + Math.round(mon.resH) + "@";
            for (let m of modes) {
                if (m.startsWith(prefix)) {
                    let r = Math.round(parseFloat(m.slice(prefix.length).replace("Hz", "")));
                    if (!isNaN(r) && !seen[r]) { seen[r] = true; rates.push(r); }
                }
            }
            rates.sort((a,b) => a-b);
            return rates;
        } catch(e) { return []; }
    }
    property int monCurrentTransform: {
        let _ = monChangeTrigger;
        return Config.monitorsModel.count > 0 ? Config.monitorsModel.get(Config.monActiveEditIndex).transform : 0;
    }
    property bool monCurrentIsPortrait: monCurrentTransform === 1 || monCurrentTransform === 3
    property real monCurrentSimW: {
        if (Config.monitorsModel.count === 0) return 1920;
        let mon = Config.monitorsModel.get(Config.monActiveEditIndex);
        return monCurrentIsPortrait ? mon.resH : mon.resW;
    }
    property real monCurrentSimH: {
        if (Config.monitorsModel.count === 0) return 1080;
        let mon = Config.monitorsModel.get(Config.monActiveEditIndex);
        return monCurrentIsPortrait ? mon.resW : mon.resH;
    }

    // ════ Cuerpo original del tab ════
    Flickable {
        id: monFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: monCol.implicitHeight + root.s(40)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ColumnLayout {
            id: monCol
            width: parent.width
            spacing: root.s(12)

            // ── Single Monitor Preview ──────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(220)
                visible: Config.monitorsModel.count <= 1

                Item {
                    id: singleMonPreview
                    anchors.centerIn: parent
                    width: root.s(270)
                    height: root.s(200)

                    property real baseScale: Math.min(1.0, Math.min(1800 / root.monCurrentSimW, 1100 / Math.max(1, root.monCurrentSimH)))
                    scale: baseScale
                    Behavior on baseScale { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

                    Rectangle {
                        width: parent.width * 0.88
                        height: root.s(10)
                        radius: root.s(7)
                        anchors.top: monStandBase.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.mantle
                        border.color: root.surface0
                        border.width: 1
                    }
                    Rectangle {
                        id: monStandBase
                        width: root.s(100)
                        height: root.s(7)
                        radius: root.s(18)
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: root.s(12)
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.surface1
                    }
                    Rectangle {
                        id: monStandNeck
                        width: root.s(26)
                        height: root.s(52)
                        anchors.bottom: monStandBase.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.surface0
                        Rectangle {
                            width: root.s(8)
                            height: root.s(20)
                            radius: root.s(18)
                            anchors.centerIn: parent
                            color: root.base
                        }
                    }
                    Rectangle {
                        id: monScreenBezel
                        width: root.s(270) * (root.monCurrentSimW / 1920.0)
                        height: root.s(270) * (root.monCurrentSimH / 1920.0)
                        anchors.bottom: monStandNeck.top
                        anchors.bottomMargin: root.s(-8)
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: root.s(13)
                        color: root.crust
                        border.color: root.surface2
                        border.width: root.s(2)
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                        Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: root.s(8)
                            radius: root.s(7)
                            color: root.surface0
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                gradient: Gradient {
                                    orientation: Gradient.Vertical
                                    GradientStop { position: 0.0; color: Qt.tint(root.surface0, Qt.alpha(root.monSelectedResAccent, 0.18)); Behavior on color { ColorAnimation { duration: 400 } } }
                                    GradientStop { position: 1.0; color: Qt.tint(root.surface0, Qt.alpha(root.monSelectedRateAccent, 0.12)); Behavior on color { ColorAnimation { duration: 400 } } }
                                }
                                Grid {
                                    anchors.centerIn: parent
                                    rows: 7; columns: 11; spacing: root.s(18)
                                    Repeater { model: 77; Rectangle { width: root.s(2); height: root.s(2); radius: root.s(1); color: Qt.alpha(root.text, 0.08) } }
                                }
                            }

                            Item {
                                anchors.centerIn: parent
                                width: root.s(140)
                                height: root.s(90)
                                property real counterScale: 1.0 / singleMonPreview.scale
                                property real maxPhysicalScale: root.monCurrentIsPortrait
                                    ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width)
                                    : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                scale: Math.min(counterScale, maxPhysicalScale)

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: root.s(4)
                                    rotation: root.monCurrentTransform * 90
                                    Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                    Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.pixelSize: root.s(32); color: root.monSelectedResAccent; text: "󰍹"; Behavior on color { ColorAnimation { duration: 400 } } }
                                    Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(13); color: root.text; text: Config.monitorsModel.count > 0 ? Config.monitorsModel.get(0).name : "—" }
                                    Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.pixelSize: root.s(11); color: root.subtext0; text: root.monCurrentSimW + "\xd7" + root.monCurrentSimH + " @ " + (Config.monitorsModel.count > 0 ? Config.monitorsModel.get(0).rate : "60") + "Hz" }
                                }
                            }
                        }
                    }
                }
            }

            // ── Multi-Monitor Drag Canvas ───────────────────────────────
            Item {
                id: multiMonContainer
                Layout.fillWidth: true
                Layout.preferredHeight: root.s(240)
                visible: Config.monitorsModel.count > 1
                clip: true

                // Background dot grid
                Grid {
                    anchors.centerIn: parent
                    rows: 11; columns: 19; spacing: root.s(18)
                    Repeater { model: 209; Rectangle { width: root.s(2); height: root.s(2); radius: root.s(1); color: Qt.alpha(root.text, 0.07) } }
                }

                // Compute layout scale/offset to fit all monitors in the canvas
                property real targetScale: {
                    let _ = root.monChangeTrigger;
                    if (Config.monitorsModel.count < 2) return 1.0;
                    let minX = 999999, minY = 999999, maxX = -999999, maxY = -999999;
                    for (let i = 0; i < Config.monitorsModel.count; i++) {
                        let m = Config.monitorsModel.get(i);
                        let isP = m.transform === 1 || m.transform === 3;
                        let w = ((isP ? m.resH : m.resW) / m.sysScale) * Config.monUiScale;
                        let h = ((isP ? m.resW : m.resH) / m.sysScale) * Config.monUiScale;
                        minX = Math.min(minX, m.uiX); minY = Math.min(minY, m.uiY);
                        maxX = Math.max(maxX, m.uiX + w); maxY = Math.max(maxY, m.uiY + h);
                    }
                    let requiredW = (maxX - minX) + root.s(60);
                    let requiredH = (maxY - minY) + root.s(60);
                    return Math.min(root.s(multiMonContainer.width - root.s(20)) / requiredW,
                                    root.s(200) / requiredH,
                                    1.8);
                }
                property real offsetX: {
                    let _ = root.monChangeTrigger;
                    if (Config.monitorsModel.count < 2) return 0;
                    let minX = 999999, maxX = -999999;
                    for (let i = 0; i < Config.monitorsModel.count; i++) {
                        let m = Config.monitorsModel.get(i);
                        let isP = m.transform === 1 || m.transform === 3;
                        let w = ((isP ? m.resH : m.resW) / m.sysScale) * Config.monUiScale;
                        minX = Math.min(minX, m.uiX); maxX = Math.max(maxX, m.uiX + w);
                    }
                    return (multiMonContainer.width / 2) - ((minX + (maxX - minX) / 2) * targetScale);
                }
                property real offsetY: {
                    let _ = root.monChangeTrigger;
                    if (Config.monitorsModel.count < 2) return 0;
                    let minY = 999999, maxY = -999999;
                    for (let i = 0; i < Config.monitorsModel.count; i++) {
                        let m = Config.monitorsModel.get(i);
                        let isP = m.transform === 1 || m.transform === 3;
                        let h = ((isP ? m.resW : m.resH) / m.sysScale) * Config.monUiScale;
                        minY = Math.min(minY, m.uiY); maxY = Math.max(maxY, m.uiY + h);
                    }
                    return (multiMonContainer.height / 2) - ((minY + (maxY - minY) / 2) * targetScale);
                }

                Item {
                    id: monTransformNode
                    x: multiMonContainer.offsetX
                    y: multiMonContainer.offsetY
                    scale: multiMonContainer.targetScale
                    transformOrigin: Item.TopLeft
                    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                    Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                    Repeater {
                        model: Config.monitorsModel
                        delegate: Item {
                            id: monDelegateItem
                            property bool isActive: Config.monActiveEditIndex === index
                            property bool isPortrait: model.transform === 1 || model.transform === 3
                            property real cardW: (isPortrait ? model.resH : model.resW) / model.sysScale * Config.monUiScale
                            property real cardH: (isPortrait ? model.resW : model.resH) / model.sysScale * Config.monUiScale

                            // Visible card
                            Rectangle {
                                id: monCard
                                x: model.uiX
                                y: model.uiY
                                width: monDelegateItem.cardW
                                height: monDelegateItem.cardH
                                radius: root.s(18)
                                color: isActive ? root.surface1 : root.crust
                                border.color: isActive ? root.monSelectedResAccent : root.surface2
                                border.width: isActive ? root.s(2) : root.s(1)
                                z: isActive ? 5 : 0
                                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                Behavior on border.color { ColorAnimation { duration: 300 } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                                Item {
                                    anchors.centerIn: parent
                                    width: root.s(110)
                                    height: root.s(80)
                                    property real idealScale: 1.2 / monTransformNode.scale
                                    property real maxPhysicalScale: isPortrait
                                        ? Math.min((parent.width * 0.9) / height, (parent.height * 0.9) / width)
                                        : Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                    scale: Math.min(idealScale, maxPhysicalScale)

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: root.s(2)
                                        rotation: model.transform * 90
                                        Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.pixelSize: root.s(26); color: isActive ? root.monSelectedResAccent : root.text; text: "󰍹"; Behavior on color { ColorAnimation { duration: 300 } } }
                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: root.s(10); color: root.text; text: model.name }
                                        Text { Layout.alignment: Qt.AlignHCenter; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9); color: root.subtext0; text: model.resW + "\xd7" + model.resH + "@" + model.rate }
                                    }
                                }
                            }

                            // Invisible ghost dragger — sits on top, handles drag
                            Item {
                                id: ghostDrag
                                x: model.uiX
                                y: model.uiY
                                width: monDelegateItem.cardW
                                height: monDelegateItem.cardH
                                z: isActive ? 10 : 1

                                MouseArea {
                                    id: ghostMa
                                    anchors.fill: parent
                                    drag.target: ghostDrag
                                    drag.axis: Drag.XAndYAxis
                                    cursorShape: Qt.SizeAllCursor

                                    onPressed: {
                                        Config.monActiveEditIndex = index;
                                        ghostDrag.x = model.uiX;
                                        ghostDrag.y = model.uiY;
                                    }

                                    onPositionChanged: {
                                        if (!drag.active || Config.monitorsModel.count < 2) return;

                                        let mW = monDelegateItem.cardW;
                                        let mH = monDelegateItem.cardH;
                                        let padding = root.s(40);

                                        // Compute drag bounds from all other monitors
                                        let boundMinX = 999999, boundMinY = 999999;
                                        let boundMaxX = -999999, boundMaxY = -999999;
                                        for (let j = 0; j < Config.monitorsModel.count; j++) {
                                            if (j === index) continue;
                                            let sModel = Config.monitorsModel.get(j);
                                            let sIsP = sModel.transform === 1 || sModel.transform === 3;
                                            let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * Config.monUiScale;
                                            let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * Config.monUiScale;
                                            boundMinX = Math.min(boundMinX, sModel.uiX - mW - padding);
                                            boundMinY = Math.min(boundMinY, sModel.uiY - mH - padding);
                                            boundMaxX = Math.max(boundMaxX, sModel.uiX + sW + padding);
                                            boundMaxY = Math.max(boundMaxY, sModel.uiY + sH + padding);
                                        }
                                        ghostDrag.x = Math.max(boundMinX, Math.min(ghostDrag.x, boundMaxX));
                                        ghostDrag.y = Math.max(boundMinY, Math.min(ghostDrag.y, boundMaxY));

                                        // Perimeter snap against each other monitor
                                        let bestX = ghostDrag.x, bestY = ghostDrag.y, bestDist = 999999;
                                        for (let j = 0; j < Config.monitorsModel.count; j++) {
                                            if (j === index) continue;
                                            let sModel = Config.monitorsModel.get(j);
                                            let sIsP = sModel.transform === 1 || sModel.transform === 3;
                                            let sW = ((sIsP ? sModel.resH : sModel.resW) / sModel.sysScale) * Config.monUiScale;
                                            let sH = ((sIsP ? sModel.resW : sModel.resH) / sModel.sysScale) * Config.monUiScale;
                                            let snapped = Config.monGetPerimeterSnap(
                                                ghostDrag.x, ghostDrag.y,
                                                sModel.uiX, sModel.uiY, sW, sH, mW, mH, root.s(20)
                                            );
                                            let dist = Math.hypot(ghostDrag.x - snapped.x, ghostDrag.y - snapped.y);
                                            if (dist < bestDist) { bestDist = dist; bestX = snapped.x; bestY = snapped.y; }
                                        }

                                        if (!Config.monIsOverlappingAny(bestX, bestY, mW, mH, index)) {
                                            Config.monitorsModel.setProperty(index, "uiX", bestX);
                                            Config.monitorsModel.setProperty(index, "uiY", bestY);
                                        }
                                    }

                                    onReleased: {
                                        // Snap ghost back to model position
                                        ghostDrag.x = model.uiX;
                                        ghostDrag.y = model.uiY;
                                        root.monChangeTrigger++;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Resolution Grid ─────────────────────────────────────────
            GridLayout {
                id: resGrid
                Layout.fillWidth: true
                columns: 2
                columnSpacing: root.s(8)
                rowSpacing: root.s(8)

                Repeater {
                    model: root.monAvailableResolutions
                    delegate: Rectangle {
                        property var md: root.monAvailableResolutions[index]
                        property string resLabel: md ? root.getResLabel(md.w, md.h) : ""
                        property color accent: root.monResAccentColors[index % root.monResAccentColors.length]
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.s(40)
                        radius: root.s(13)
                        property bool isSel: {
                            let _ = root.monChangeTrigger;
                            if (!md || Config.monitorsModel.count === 0) return false;
                            let a = Config.monitorsModel.get(Config.monActiveEditIndex);
                            return a.resW === md.w && a.resH === md.h;
                        }
                        color: isSel ? Qt.alpha(accent, 0.15) : (rMa.containsMouse ? root.surface0 : root.mantle)
                        border.color: isSel ? accent : (rMa.containsMouse ? root.surface1 : "transparent")
                        border.width: isSel ? root.s(2) : root.s(1)
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        scale: rMa.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(6)
                            Text {
                                font.family: "Hack Nerd Font"; font.weight: isSel ? Font.Black : Font.Bold; font.pixelSize: root.s(13)
                                color: isSel ? accent : root.text; text: resLabel
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                font.family: "Hack Nerd Font"; font.pixelSize: root.s(10)
                                color: isSel ? root.text : root.overlay0
                                text: md ? (md.w + "×" + md.h) : ""
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            id: rMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!md || Config.monitorsModel.count === 0) return;
                                root.monSelectedResAccent = accent;
                                Config.monitorsModel.setProperty(Config.monActiveEditIndex, "resW", md.w);
                                Config.monitorsModel.setProperty(Config.monActiveEditIndex, "resH", md.h);

                                // Auto-select highest compatible refresh rate
                                let mon = Config.monitorsModel.get(Config.monActiveEditIndex);
                                let modes = JSON.parse(mon.availableModes || "[]");
                                let prefix = md.w + "x" + md.h + "@";
                                let validRates = [];
                                for (let m of modes) {
                                    if (m.startsWith(prefix)) {
                                        let r = Math.round(parseFloat(m.slice(prefix.length).replace("Hz", "")));
                                        if (!isNaN(r)) validRates.push(r);
                                    }
                                }
                                if (validRates.length > 0) {
                                    validRates.sort((a, b) => b - a);
                                    let currentRate = Math.round(parseFloat(mon.rate));
                                    let closest = validRates[0];
                                    let minDiff = 99999;
                                    for (let r of validRates) {
                                        let diff = Math.abs(r - currentRate);
                                        if (diff < minDiff) { minDiff = diff; closest = r; }
                                    }
                                    Config.monitorsModel.setProperty(Config.monActiveEditIndex, "rate", closest.toString());
                                }
                                root.monChangeTrigger++;
                                Config.monDelayedLayoutUpdate.restart();
                            }
                        }
                    }
                }
            }

            // ── Rotation Dial + Refresh Rate Slider ─────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(16)

                // Rotation dial
                Rectangle {
                    id: monDial
                    Layout.preferredWidth: root.s(120)
                    Layout.preferredHeight: root.s(120)
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: root.surface0
                    border.color: root.surface1
                    border.width: root.s(2)

                    Repeater {
                        model: 12
                        Item {
                            anchors.fill: parent
                            rotation: index * 30
                            Rectangle {
                                width: index % 3 === 0 ? root.s(3) : root.s(2)
                                height: index % 3 === 0 ? root.s(8) : root.s(4)
                                radius: width / 2
                                color: index % 3 === 0 ? root.subtext0 : root.surface2
                                anchors.top: parent.top
                                anchors.topMargin: root.s(6)
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        property int tf: {
                            let _ = root.monChangeTrigger;
                            return Config.monitorsModel.count > 0 ? Config.monitorsModel.get(Config.monActiveEditIndex).transform : 0;
                        }
                        rotation: tf * 90
                        Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                        Rectangle {
                            width: root.s(4)
                            height: parent.height / 2 - root.s(22)
                            radius: root.s(8)
                            color: root.monSelectedResAccent
                            anchors.bottom: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Rectangle {
                            width: root.s(18); height: root.s(18); radius: root.s(19)
                            color: root.base
                            border.color: root.monSelectedResAccent
                            border.width: root.s(4)
                            anchors.centerIn: parent
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function updateAngle(mx, my) {
                            if (Config.monitorsModel.count === 0) return;
                            let cx = width / 2; let cy = height / 2;
                            let dx = mx - cx; let dy = my - cy;
                            if (Math.hypot(dx, dy) < root.s(18)) return;
                            let tf = Config.monitorsModel.get(Config.monActiveEditIndex).transform;
                            let angle = tf * Math.PI / 2;
                            let rdx = dx * Math.cos(-angle) - dy * Math.sin(-angle);
                            let rdy = dx * Math.sin(-angle) + dy * Math.cos(-angle);
                            let rawSnap = Math.abs(rdx) > Math.abs(rdy) ? (rdx > 0 ? 1 : 3) : (rdy > 0 ? 2 : 0);
                            let snap = (rawSnap + tf) % 4;
                            Config.monitorsModel.setProperty(Config.monActiveEditIndex, "transform", snap);
                            root.monChangeTrigger++;
                            Config.monDelayedLayoutUpdate.restart();
                        }
                        onPressed: (mouse) => updateAngle(mouse.x, mouse.y)
                        onPositionChanged: (mouse) => { if (pressed) updateAngle(mouse.x, mouse.y) }
                    }
                }

                // Refresh rate slider
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: root.s(6)

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Refresh Rate"
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                            color: root.subtext0; Layout.fillWidth: true
                        }
                        Text {
                            text: {
                                let _ = root.monChangeTrigger;
                                if (Config.monitorsModel.count === 0) return "—";
                                if (rateSlider.numRates > 0) return rateSlider.rates[rateSlider.curIdx] + " Hz";
                                return Math.round(parseFloat(Config.monitorsModel.get(Config.monActiveEditIndex).rate) || 60) + " Hz";
                            }
                            font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(13)
                            color: root.monSelectedRateAccent
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Item {
                        id: rateSlider
                        Layout.fillWidth: true
                        property var rates: root.monAvailableRates
                        property int numRates: rates ? rates.length : 0
                        Layout.preferredHeight: numRates > 1 ? root.s(50) : 0
                        opacity: numRates > 1 ? 1.0 : 0.0
                        visible: Layout.preferredHeight > 0
                        clip: true
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        property int curIdx: {
                            let _ = root.monChangeTrigger;
                            if (Config.monitorsModel.count === 0 || numRates === 0) return 0;
                            let rawRate = Config.monitorsModel.get(Config.monActiveEditIndex).rate;
                            let val = Math.round(parseFloat(rawRate));
                            if (isNaN(val)) val = rates[rates.length - 1];
                            let best = 0, minDiff = 99999;
                            for (let i = 0; i < numRates; i++) {
                                let diff = Math.abs(rates[i] - val);
                                if (diff < minDiff) { minDiff = diff; best = i; }
                            }
                            return best;
                        }
                        property real tLeft: root.s(8)
                        property real tW: Math.max(1, width - root.s(16))
                        property real knobX: numRates <= 1 ? tLeft : tLeft + (curIdx / (numRates - 1)) * tW

                        Rectangle {
                            id: rTrack
                            x: rateSlider.tLeft; width: rateSlider.tW
                            y: root.s(8); height: root.s(6); radius: root.s(4)
                            color: root.mantle; border.color: root.surface1; border.width: 1

                            Rectangle {
                                width: Math.max(0, rKnob.x - rateSlider.tLeft + rKnob.width / 2)
                                height: parent.height; radius: parent.radius
                                color: root.monSelectedRateAccent
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }
                        Rectangle {
                            id: rKnob
                            width: root.s(16); height: root.s(16); radius: root.s(18)
                            color: rateMa.containsPress ? root.monSelectedRateAccent : root.text
                            y: rTrack.y + rTrack.height / 2 - height / 2
                            x: rateSlider.knobX - width / 2
                            Behavior on x { enabled: !rateMa.pressed; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        Repeater {
                            model: rateSlider.numRates
                            Item {
                                x: rateSlider.numRates <= 1 ? rateSlider.tLeft : rateSlider.tLeft + (index / (rateSlider.numRates - 1)) * rateSlider.tW
                                y: rTrack.y + rTrack.height + root.s(3)
                                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: root.s(1); height: root.s(3); color: rateSlider.curIdx === index ? root.monSelectedRateAccent : root.overlay0 }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter; y: root.s(4)
                                    text: rateSlider.rates[index]
                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(8)
                                    font.weight: rateSlider.curIdx === index ? Font.Bold : Font.Normal
                                    color: rateSlider.curIdx === index ? root.monSelectedRateAccent : root.overlay0
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                        MouseArea {
                            id: rateMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            function doSnap(mx) {
                                if (Config.monitorsModel.count === 0 || rateSlider.numRates === 0) return;
                                let pct = (mx - rateSlider.tLeft) / rateSlider.tW;
                                pct = Math.max(0, Math.min(1, pct));
                                let idx = Math.round(pct * (rateSlider.numRates - 1));
                                Config.monitorsModel.setProperty(Config.monActiveEditIndex, "rate", rateSlider.rates[idx].toString());
                                root.monChangeTrigger++;
                            }
                            onPressed: (mouse) => doSnap(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) doSnap(mouse.x) }
                        }
                    }
                }
            }

            // ── Layout actions (persist beyond this session) ───────────
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: root.s(8)

                // Apply the arrangement above AND save it permanently to
                // ~/.config/hypr/display-config (restore-monitors.sh will
                // restore this exact layout after reboots/re-docks).
                Rectangle {
                    Layout.preferredHeight: root.s(28)
                    Layout.preferredWidth: monSaveRow.implicitWidth + root.s(16)
                    radius: root.s(22)
                    color: monSaveMa.containsMouse ? root.green : root.surface1
                    border.color: monSaveMa.containsMouse ? root.green : root.surface2
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        id: monSaveRow; anchors.centerIn: parent; spacing: root.s(5)
                        Text { text: "󰸞"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: monSaveMa.containsMouse ? root.base : root.green; Behavior on color { ColorAnimation { duration: 150 } } }
                        Text { text: "Apply & save permanently"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: monSaveMa.containsMouse ? root.base : root.green; Behavior on color { ColorAnimation { duration: 150 } } }
                    }
                    MouseArea {
                        id: monSaveMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Config.monitorsModel.count === 0) return;
                            Config.applyMonitors();
                        }
                    }
                }

                // Forget the saved layout: from now on monitors are laid out
                // automatically (handy on machines that never saved one).
                Rectangle {
                    Layout.preferredHeight: root.s(28)
                    Layout.preferredWidth: monResetRow.implicitWidth + root.s(16)
                    radius: root.s(22)
                    color: monResetMa.containsMouse ? root.red : root.surface1
                    border.color: monResetMa.containsMouse ? root.red : root.surface2
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    RowLayout {
                        id: monResetRow; anchors.centerIn: parent; spacing: root.s(5)
                        Text { text: "󰆴"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: monResetMa.containsMouse ? root.base : root.red; Behavior on color { ColorAnimation { duration: 150 } } }
                        Text { text: "Reset to auto"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: monResetMa.containsMouse ? root.base : root.red; Behavior on color { ColorAnimation { duration: 150 } } }
                    }
                    MouseArea {
                        id: monResetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Config.resetMonitorsToAuto();
                    }
                }
            }

            Item { Layout.preferredHeight: root.s(16) }
        }
    }
}
