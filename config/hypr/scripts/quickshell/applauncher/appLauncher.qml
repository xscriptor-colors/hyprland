import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"
import "../dock"
import "LauncherLayout.js" as LauncherLayout

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
    // LAUNCHER CONFIG (settings.json key "launcher", editable desde el panel)
    // -------------------------------------------------------------------------
    // lcfg: configuración normalizada (posición, ancho, nº de apps, margen y
    // anti-solape con la barra). Es reactiva a Config y sobrescribible en tests.
    property var lcfg: LauncherLayout.normalize(Config.rawSettings.launcher || ({}))
    property var dockCfg: Config.rawSettings.dock || ({})
    // Misma escala que el resto del widget (Scaler con currentWidth=Screen.width).
    readonly property real layoutScale: scaler.baseScale
    // Tamaño del panel para el nº de apps actual (crece/decrece al filtrar).
    property var panelSize: LauncherLayout.panelSize(lcfg, layoutScale, appModel.count)
    // Caja en pantalla (x/y/w/h) + dirección de entrada de la intro.
    property var geo: LauncherLayout.geometry(lcfg, Screen.width, Screen.height,
                                              panelSize.w, panelSize.h, layoutScale, dockCfg)

    // Main lee targetMaster* al abrir el widget; para que el panel siga
    // creciendo/decreciendo EN VIVO (filtrar) y la posición se recalcule,
    // empujamos la caja al master cuando cambia (mismo patrón que
    // CalendarPopup; guard por si el widget se carga aislado en tests).
    property real targetMasterWidth: geo.w
    property real targetMasterHeight: geo.h
    property real targetMasterX: geo.x
    property real targetMasterY: geo.y

    function syncMasterBox() {
        if (typeof masterWindow === "undefined") return;
        masterWindow.animW = window.targetMasterWidth;
        masterWindow.targetW = window.targetMasterWidth;
        masterWindow.animH = window.targetMasterHeight;
        masterWindow.targetH = window.targetMasterHeight;
        masterWindow.animX = window.targetMasterX;
        masterWindow.animY = window.targetMasterY;
    }
    onTargetMasterWidthChanged: syncMasterBox()
    onTargetMasterHeightChanged: syncMasterBox()
    onTargetMasterXChanged: syncMasterBox()
    onTargetMasterYChanged: syncMasterBox()

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
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color teal: _theme.teal
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    // -------------------------------------------------------------------------
    // STATE & LOGIC
    // -------------------------------------------------------------------------
    property var allApps: []

    Process {
        id: appFetcher
        running: true
        command: ["bash", "-c", "python3 " + Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/applauncher/app_fetcher.py"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (this.text && this.text.trim().length > 0) {
                        window.allApps = JSON.parse(this.text);
                        filterApps("");
                    }
                } catch(e) {
                    console.log("Error parsing apps list: ", e);
                }
            }
        }
    }

    ListModel {
        id: appModel
    }

    // --- KEYBOARD NAV TRACKING (For Smart Highlight Morphing) ---
    property bool isKeyboardNav: false
    Timer {
        id: keyboardNavTimer
        interval: 500
        repeat: false
        onTriggered: window.isKeyboardNav = false
    }

    // --- SMART DIFFING FILTER ---
    function filterApps(query) {
        // Disable morphing behavior so the highlight box sticks to the flying item
        window.isKeyboardNav = false;
        if (keyboardNavTimer.running) keyboardNavTimer.stop();

        appList.currentIndex = -1;
        appList.positionViewAtBeginning();

        let q = query.toLowerCase();
        let filtered = [];
        
        for (let i = 0; i < allApps.length; i++) {
            let app = allApps[i];

            if (app.name.toLowerCase().includes(q)) { filtered.push(app); continue; }
            if (app.exec.toLowerCase().includes(q)) { filtered.push(app); continue; }
            if (app.generic_name && app.generic_name.toLowerCase().includes(q)) { filtered.push(app); continue; }
            if (app.comment && app.comment.toLowerCase().includes(q)) { filtered.push(app); continue; }
            if (app.categories && app.categories.toLowerCase().includes(q)) { filtered.push(app); continue; }
            if (app.keywords && app.keywords.toLowerCase().includes(q)) { filtered.push(app); continue; }
        }

        for (let i = appModel.count - 1; i >= 0; i--) {
            let currentName = appModel.get(i).name;
            let keep = false;
            for (let j = 0; j < filtered.length; j++) {
                if (filtered[j].name === currentName) {
                    keep = true;
                    break;
                }
            }
            if (!keep) {
                appModel.remove(i);
            }
        }

        for (let i = 0; i < filtered.length; i++) {
            let targetApp = filtered[i];
            
            if (i < appModel.count) {
                if (appModel.get(i).name !== targetApp.name) {
                    let foundIdx = -1;
                    for (let j = i + 1; j < appModel.count; j++) {
                        if (appModel.get(j).name === targetApp.name) {
                            foundIdx = j;
                            break;
                        }
                    }
                    if (foundIdx !== -1) {
                        appModel.move(foundIdx, i, 1);
                    } else {
                        appModel.insert(i, targetApp);
                    }
                }
            } else {
                appModel.append(targetApp);
            }
        }
        
        if (appModel.count > 0) {
            appList.currentIndex = 0;
        }
    }

    function launchApp(execStr) {
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.cache/quickshell && USAGE=\"$HOME/.cache/quickshell/applauncher_usage.json\"; [ ! -f \"$USAGE\" ] && echo '{}' > \"$USAGE\"; KEY=$(printf '%s' \"$1\" | base64 -w0); COUNT=$(jq -r \".[\\\"$KEY\\\"].count // 0\" \"$USAGE\"); LAST=$(date +%s); jq \".[\\\"$KEY\\\"] = {\\\"count\\\": ($COUNT + 1), \\\"last_used\\\": $LAST}\" \"$USAGE\" > \"$USAGE.tmp\" && mv \"$USAGE.tmp\" \"$USAGE\"", "bash", execStr]);
        // Hyprland 0.55+ has no `hyprctl dispatch exec`; use the Lua API.
        let luaCmd = "hl.dispatch(hl.dsp.exec_cmd(\"" + execStr.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + "\"))";
        Quickshell.execDetached(["bash", "-c", "hyprctl eval '" + luaCmd.replace(/'/g, "'\\''") + "'"]);
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    // --- AGGRESSIVE FOCUS MANAGEMENT ---
    Timer {
        id: focusTimer
        interval: 50
        running: true
        repeat: false
        onTriggered: searchInput.forceActiveFocus()
    }

    Connections {
        target: window
        function onVisibleChanged() {
            if (window.visible) {
                focusTimer.restart();
                introPhaseAnim.restart();
            }
        }
    }

    Keys.onEscapePressed: {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
        event.accepted = true;
    }

    // --- MAIN INTRO ANIMATION ---
    property real introPhase: 0
    NumberAnimation on introPhase {
        id: introPhaseAnim
        from: 0; to: 1; duration: 600; easing.type: Easing.OutExpo; running: true
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Rectangle {
        id: mainBg
        // Launcher configurable: el panel llena el morph exacto (Main fija su
        // tamaño/posición desde panelSize/geo del root; crece/decrece al filtrar).
        anchors.fill: parent

        // --- MÉTRICAS INTERNAS (mismas constantes que LauncherLayout.panelSize) ---
        property real searchHeight: window.s(65)
        property real separatorHeight: 1
        property real itemHeight: window.s(window.lcfg.rowHeight)
        property real listSpacing: window.s(4)

        property real targetMargins: appModel.count > 0 ? window.s(20) : 0

        // Morphing interno de los márgenes de la lista (filas).
        property real animatedMargins: targetMargins
        Behavior on animatedMargins { 
            NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
        }

        // Bordes configurables (radius/borderWidth/borderColor de la paleta).
        radius: window.s(window.lcfg.radius)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 1.0)
        border.color: window[window.lcfg.borderColor] !== undefined ? window[window.lcfg.borderColor] : window.surface1
        border.width: window.s(window.lcfg.borderWidth)
        clip: true

        // Intro direccional (600 ms OutExpo): el panel "sale" de su extremo
        // anclado — escala desde ese borde (transformOrigin) + deslizamiento
        // (slideX/slideY) + el clip del morph.
        scale: 0.94 + 0.06 * window.introPhase
        transformOrigin: window.geo.origin === "top" ? Item.Top
                       : window.geo.origin === "bottom" ? Item.Bottom
                       : window.geo.origin === "left" ? Item.Left
                       : window.geo.origin === "right" ? Item.Right
                       : Item.Center
        transform: Translate {
            x: (1 - window.introPhase) * window.geo.slideX
            y: (1 - window.introPhase) * window.geo.slideY
        }
        opacity: window.introPhase

        // --- SEARCH BAR (arriba o abajo según la posición) ---
        Rectangle {
            id: searchBox
            x: 0
            width: parent.width
            height: mainBg.searchHeight
            y: window.geo.searchAtBottom ? parent.height - height : 0
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: window.s(15)
                anchors.leftMargin: window.s(20)
                anchors.rightMargin: window.s(20)
                spacing: window.s(15)

                Text {
                    text: ""
                    font.family: "Hack Nerd Font"
                    font.pixelSize: window.s(18)
                    color: searchInput.activeFocus ? window.mauve : window.subtext0
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Item {} 
                    color: window.text
                    font.family: "Hack Nerd Font"
                    font.pixelSize: window.s(16)

                    placeholderText: "Search..."
                    placeholderTextColor: window.subtext0 

                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: window.lcfg.align === "center" ? TextInput.AlignHCenter
                                       : (window.lcfg.align === "right" ? TextInput.AlignRight : TextInput.AlignLeft)
                    focus: true

                    onTextChanged: filterApps(text)

                    Keys.onDownPressed: {
                        window.isKeyboardNav = true;
                        keyboardNavTimer.restart();
                        if (appList.currentIndex < appModel.count - 1) {
                            appList.currentIndex++;
                        }
                        event.accepted = true;
                    }
                    Keys.onUpPressed: {
                        window.isKeyboardNav = true;
                        keyboardNavTimer.restart();
                        if (appList.currentIndex > 0) {
                            appList.currentIndex--;
                        }
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: {
                        if (appList.currentIndex >= 0 && appList.currentIndex < appModel.count) {
                            launchApp(appModel.get(appList.currentIndex).exec);
                        }
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: {
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                        event.accepted = true;
                    }
                }
            }
        }

        // --- SEPARATOR (bajo el search, o sobre él en modo bottom) ---
        Rectangle {
            id: separator
            x: 0
            width: parent.width
            height: mainBg.separatorHeight
            y: window.geo.searchAtBottom ? searchBox.y - height : searchBox.y + searchBox.height
            color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
        }

        // --- APPLICATION LIST ---
        ListView {
            id: appList
            x: window.s(10)
            width: parent.width - window.s(20)

            // Borde superior de la lista (0 si el search va abajo).
            property real topEdge: window.geo.searchAtBottom ? 0 : separator.y + separator.height
            y: topEdge + mainBg.animatedMargins / 2
            height: (window.geo.searchAtBottom ? separator.y : parent.height - topEdge) - mainBg.animatedMargins

            // clip: true is critical — it masks items that are outside the
            // visible list area so they cannot bleed through during transitions.
            clip: true
            model: appModel
            spacing: mainBg.listSpacing
            currentIndex: 0
            boundsBehavior: Flickable.StopAtBounds

            highlightFollowsCurrentItem: false

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }
            }

            // --- LIST ITEM TRANSITIONS ---
            // Key fix: NO z-layer tricks. The ListView's own clip:true handles
            // masking. Items animate only opacity + scale so they never visually
            // "hang" outside the clipped region. The displaced transition slides
            // existing items to their new positions without fighting the add/remove.

            populate: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 550; easing.type: Easing.OutExpo }
                    NumberAnimation { property: "scale"; from: 0.88; to: 1; duration: 600; easing.type: Easing.OutExpo }
                }
            }

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 380; easing.type: Easing.OutExpo }
                    NumberAnimation { property: "scale"; from: 0.88; to: 1; duration: 420; easing.type: Easing.OutExpo }
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 280; easing.type: Easing.OutExpo }
                    NumberAnimation { property: "scale"; to: 0.88; duration: 300; easing.type: Easing.OutExpo }
                }
            }

            // displaced runs for items that are already in the list and just
            // need to slide to a new position — keep it simple and fast so it
            // finishes well before (or together with) the add transition.
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 380; easing.type: Easing.OutExpo }
            }

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: window.s(4)
                    radius: window.s(3)
                    color: window.surface2
                    opacity: 0.5
                }
            }

            // --- MATTE MORPHING HIGHLIGHT ---
            highlight: Item {
                z: 0 

                Rectangle {
                    id: activeHighlight
                    x: 0
                    width: appList.width
                    radius: window.s(10)
                    color: window.mauve

                    property int prevIdx: 0
                    property int curIdx: appList.currentIndex

                    onCurIdxChanged: {
                        if (curIdx === -1) return; 

                        if (curIdx > prevIdx) {
                            bottomAnim.duration = 250; topAnim.duration = 450;
                        } else if (curIdx < prevIdx) {
                            topAnim.duration = 250; bottomAnim.duration = 450;
                        }
                        prevIdx = curIdx;
                    }

                    // Track the current item's ACTUAL coordinates so it sticks mid-flight
                    property real targetTop: appList.currentItem ? appList.currentItem.y : 0
                    property real targetBottom: appList.currentItem ? (appList.currentItem.y + appList.currentItem.height) : 0

                    property real actualTop: targetTop
                    property real actualBottom: targetBottom

                    // Only enable the morphed lagging behavior during keyboard navigation.
                    // During search/diffing, it will instantly track the moving item.
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

                    // Makes the highlight respect the item's pop-in scale animation
                    scale: appList.currentItem ? appList.currentItem.scale : 1

                    opacity: appList.count > 0 && appList.currentIndex >= 0 ? 1 : 0
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
                        opacity: ma.containsMouse && index !== appList.currentIndex ? 0.4 : 0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }
                    }

                    Item {
                        id: rowWrap
                        anchors.fill: parent
                        anchors.topMargin: window.s(10)
                        anchors.bottomMargin: window.s(10)
                        anchors.leftMargin: window.s(12)
                        anchors.rightMargin: window.s(10)

                        Row {
                            id: rowContent
                            anchors.verticalCenter: parent.verticalCenter
                            // Alineación configurable (left/center/right) del icono + nombre.
                            x: window.lcfg.align === "center" ? Math.max(0, (parent.width - width) / 2)
                             : (window.lcfg.align === "right" ? Math.max(0, parent.width - width) : 0)
                            // Sin iconos no debe quedar hueco a la izquierda.
                            spacing: window.lcfg.showIcons ? window.s(15) : 0

                            // --- TINTED ICON MATTE BOX (opcional: Show icons) ---
                            Rectangle {
                                id: iconBox
                                visible: window.lcfg.showIcons
                                // Tamaño proporcional a la fila: con rowHeight 60
                                // equivale al s(40) histórico (radio 16, font 16, img 24).
                                property real iconSize: Math.max(window.s(24), Math.min(window.s(40), mainBg.itemHeight - window.s(20)))
                                width: visible ? iconSize : 0
                                height: width
                                radius: iconSize * 0.4

                                color: index === appList.currentIndex ? window.crust : window.surface0
                                border.width: 0 
                                clip: true

                                property real activeScale: index === appList.currentIndex ? 1.15 : 1
                                scale: activeScale
                                Behavior on activeScale { 
                                    NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } 
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

                                Text {
                                    anchors.centerIn: parent
                                    text: model.name.charAt(0).toUpperCase()
                                    color: window.subtext0
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: iconBox.iconSize * 0.4
                                    font.weight: Font.Bold
                                }
                                Image {
                                    anchors.centerIn: parent
                                    width: iconBox.iconSize * 0.6
                                    height: width
                                    source: model.icon && model.icon.length > 0
                                        ? (model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon)
                                        : ""
                                    sourceSize: Qt.size(64, 64)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                    visible: source !== ""
                                }

                                // The Matugen Tint Overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: iconBox.radius

                                    color: window.mauve
                                    opacity: index === appList.currentIndex ? 0.25 : 0.08 

                                    Behavior on opacity { 
                                        NumberAnimation { duration: 300; easing.type: Easing.OutExpo } 
                                    }
                                }
                            }

                            Text {
                                id: launchItem
                                // El nombre se recorta al espacio libre (sin icono,
                                // todo el ancho disponible). height = alto de fila
                                // para que verticalAlignment centre el texto (un
                                // Row no centra a sus hijos verticalmente).
                                width: Math.min(implicitWidth, rowWrap.width - (iconBox.visible ? iconBox.width + rowContent.spacing : 0))
                                height: rowWrap.height
                                text: model.name
                                font.family: "Hack Nerd Font"
                                font.pixelSize: window.s(14)
                                font.weight: index === appList.currentIndex ? Font.Bold : Font.Medium
                                color: index === appList.currentIndex ? window.crust : window.text
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter

                                property real textShift: index === appList.currentIndex ? window.s(6) : 0
                                transform: Translate { x: launchItem.textShift }

                                Behavior on textShift { 
                                    NumberAnimation { duration: 500; easing.type: Easing.OutExpo } 
                                }
                                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }
                            }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            appList.currentIndex = index;
                            launchApp(model.exec);
                        }
                    }
                }
            }
        }
    }
}
