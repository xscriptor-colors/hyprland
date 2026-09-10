import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".."
import "../.."
import "SearchIndex.js" as SearchIndex

// ═══════════════════════════════════════════════════════════════════════════
// SearchOverlay — buscador global del panel Settings (estilo Guide).
//
// Migrado de settings/SettingsPopup.qml: barra de búsqueda arriba + resultados
// agrupados en "Settings" (cards de las tabs compartidas + ajustes de las
// páginas del editor) y "Keybinds". Cubre la stage de contenido de BarEditor.
//
// API:
//   property var bar      → root de BarEditor (gotoPage/pageLoader/s/colores)
//   signal closed()       → el panel devuelve el foco a su root
//   open() / close()      → abrir/cerrar (close emite closed())
//   handleKey(event)      → ↑/↓/Enter/Esc (lo llaman el TextField y el root)
//
// Activación (misma semántica que el popup):
//   card  (s_*) → gotoPage + highlightSettingsBox + scrollToBox(approxY)
//   page  (d_*) → gotoPage + flickable.contentY = s(y)
//   keybind     → gotoPage("s_keyboard") + scrollToBox(targetBox·s(56)+s(120))
//
// El overlay NO se instancia tipado: BarEditor lo carga con
// searchLoader.setSource("editor/SearchOverlay.qml", { bar: root }) para no
// provocar el burst de null-bar de la Fase 3 (ver cabecera de BarEditor.qml).
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root

    // ── API ──
    property var bar: null
    property bool opened: false
    property string query: ""
    // Resultados: [{kind:"card",card} | {kind:"page",entry}] y [{kind:"keybind",kbIndex}]
    property var settingsResults: []
    property var keybindResults: []
    property int highlight: -1

    signal closed()

    anchors.fill: parent
    visible: opened || opacity > 0.001
    opacity: opened ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

    // Paleta propia (mismo patrón que SettingsPopup: Colors local) — el overlay
    // es un componente autónomo y no depende de que `bar` ya exista.
    Colors { id: themeColors }

    readonly property int settingsCount: settingsResults.length
    readonly property int totalCount: settingsResults.length + keybindResults.length

    function s(val) { return bar ? bar.s(val) : val; }

    // ── Abrir / cerrar ────────────────────────────────────────────────────
    function open() {
        opened = true;
        query = "";
        rebuild();
        resultsFlick.contentY = 0;
        Qt.callLater(() => searchInput.forceActiveFocus());
    }
    function close() {
        if (!opened) return;
        opened = false;
        closed();
    }

    // ── Índice de resultados ──────────────────────────────────────────────
    function rebuild() {
        let set = [];
        let kbs = [];
        rowItems = [];
        if (bar && query.trim() !== "") {
            let cards = SearchIndex.cards();
            for (let i = 0; i < cards.length; i++)
                if (SearchIndex.matches(cards[i], query)) set.push({ kind: "card", card: cards[i] });
            let entries = SearchIndex.pageEntries();
            for (let i = 0; i < entries.length; i++)
                if (SearchIndex.matches(entries[i], query)) set.push({ kind: "page", entry: entries[i] });
            let idx = SearchIndex.keybindMatches(Config.keybindsData, query);
            for (let i = 0; i < idx.length; i++) kbs.push({ kind: "keybind", kbIndex: idx[i] });
        }
        settingsResults = set;
        keybindResults = kbs;
        highlight = (set.length + kbs.length) > 0 ? 0 : -1;
    }

    // ── Navegación por teclado ────────────────────────────────────────────
    function moveHighlight(delta) {
        let n = totalCount;
        if (n === 0) return;
        highlight = (highlight + delta + n) % n;
        scrollHighlightIntoView();
    }
    function activate(index) {
        if (!bar || index < 0 || index >= totalCount) return;
        let mode = "";
        let page = "";
        let box = -1;
        let y = 0;
        if (index < settingsCount) {
            let r = settingsResults[index];
            if (r.kind === "card") {
                mode = "card"; page = r.card.page; box = r.card.boxIndex;
                y = approxY(page, box);
            } else {
                mode = "page"; page = r.entry.page; box = -1; y = r.entry.y;
            }
        } else {
            let r = keybindResults[index - settingsCount];
            mode = "keybind"; page = "s_keyboard"; box = r.kbIndex;
            y = box * s(56) + s(120);
        }
        // Las páginas del grupo Dock/Bar (colapsable) no están en
        // navForEngine() cuando el grupo está cerrado y gotoPage las
        // ignoraría: expandirlo antes de navegar.
        if (page.indexOf("d_") === 0 && root.bar.dockGroupExpanded === false)
            root.bar.dockGroupExpanded = true;
        bar.gotoPage(page);
        jumpTimer.mode = mode;
        jumpTimer.page = page;
        jumpTimer.boxIndex = box;
        jumpTimer.y = y;
        jumpTimer.start();
        close();
    }
    function handleKey(event) {
        if (event.key === Qt.Key_Escape) { close(); event.accepted = true; return; }
        if (event.key === Qt.Key_Down) { moveHighlight(1); event.accepted = true; return; }
        if (event.key === Qt.Key_Up) { moveHighlight(-1); event.accepted = true; return; }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activate(highlight);
            event.accepted = true;
        }
    }

    // approxY de las cards: MISMO cálculo que SettingsPopup.jumpToSettingTimer
    // (box 7 = App scale lo añadía el popup con 0; aquí se apunta abajo).
    function approxY(page, box) {
        if (page === "s_general") {
            if (box <= 1) return 0;
            if (box === 2) return s(120);
            if (box === 3 || box === 4) return s(240);
            if (box === 5) return s(400);
            if (box === 6) return s(520);
            return s(640);
        }
        if (page === "s_weather") {
            if (box === 1) return s(140);
            if (box === 2) return s(240);
            if (box === 3) return s(340);
            return 0;
        }
        if (page === "s_startup") return box * s(56) + s(20);
        return 0;
    }

    function pageLabel(id) {
        switch (id) {
        case "s_general": return "General";
        case "s_weather": return "Weather";
        case "s_keyboard": return "Keyboard";
        case "s_monitors": return "Monitors";
        case "s_startup": return "Startup";
        case "d_launcher": return "Launcher";
        case "d_engine": return "Engine";
        case "d_position": return "Position";
        case "d_style": return "Style";
        case "d_palette": return "Palette";
        case "d_zones": return "Zones";
        case "d_workspaces": return "Workspaces";
        case "d_serp": return "Serp Bar";
        case "d_hyprland": return "Hyprland";
        case "d_idle": return "Idle";
        case "d_gpu": return "GPU";
        case "d_notifications": return "Notifications";
        case "d_animations": return "Animations";
        case "d_input": return "Input";
        }
        return id;
    }

    // ── Registro de filas para el scroll del highlight ────────────────────
    property var rowItems: []
    function registerRow(i, item) { rowItems[i] = item; }
    function scrollHighlightIntoView() {
        let it = rowItems[highlight];
        if (!it) return;
        let viewH = resultsFlick.height;
        let top = resultsFlick.contentY;
        let y = it.y;
        if (y < top + s(8)) resultsFlick.contentY = Math.max(0, y - s(8));
        else if (y + it.height > top + viewH - s(8))
            resultsFlick.contentY = y + it.height - viewH + s(8);
    }

    // Espera a que la página destino esté instanciada (Loader lazy) y aplica
    // highlight + scroll. El popup usaba un Timer de 100 ms; aquí 160 ms.
    Timer {
        id: jumpTimer
        interval: 160
        repeat: false
        property string mode: ""
        property string page: ""
        property int boxIndex: -1
        property real y: 0
        onTriggered: {
            if (!root.bar) return;
            let loader = root.bar.pageLoader(jumpTimer.page);
            let item = loader ? loader.item : null;
            if (jumpTimer.mode === "card") {
                if (root.bar.highlightSettingsBox) root.bar.highlightSettingsBox(jumpTimer.boxIndex);
                if (item) {
                    if (item.scrollToBox) item.scrollToBox(jumpTimer.y);
                    else if (item.scrollTo) item.scrollTo(jumpTimer.y);
                }
            } else if (jumpTimer.mode === "page") {
                if (item && item.flickable && jumpTimer.y > 0)
                    item.flickable.contentY = root.s(jumpTimer.y);
            } else if (jumpTimer.mode === "keybind") {
                if (item) {
                    if (item.scrollToBox) item.scrollToBox(jumpTimer.y);
                    else if (item.scrollTo) item.scrollTo(jumpTimer.y);
                }
            }
        }
    }

    // ── Fondo (click fuera = cerrar) ──────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(themeColors.base, 0.97)
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ── Barra de búsqueda ─────────────────────────────────────────────────
    Rectangle {
        id: searchBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: s(14)
        height: s(46)
        radius: s(13)
        color: Qt.alpha(themeColors.surface0, 0.4)
        border.width: 1
        border.color: searchInput.activeFocus ? themeColors.sapphire : themeColors.surface1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: s(13)
            anchors.rightMargin: s(8)
            spacing: s(9)

            Text {
                text: "󰍉"
                font.family: "Hack Nerd Font"
                font.pixelSize: s(15)
                color: searchInput.activeFocus ? themeColors.sapphire : themeColors.subtext0
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: "Search settings…"
                placeholderTextColor: Qt.alpha(themeColors.subtext0, 0.5)
                color: themeColors.text
                font.family: "Hack Nerd Font"
                font.pixelSize: s(15)
                background: null
                selectByMouse: true
                onTextChanged: {
                    root.query = text;
                    root.rebuild();
                    resultsFlick.contentY = 0;
                }
                Keys.onPressed: root.handleKey(event)
            }
            // Limpiar
            Rectangle {
                width: s(24)
                height: s(24)
                radius: s(12)
                visible: searchInput.text !== ""
                color: clearMa.containsMouse ? Qt.alpha(themeColors.surface1, 0.9) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(11)
                    color: themeColors.subtext0
                }
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        searchInput.text = "";
                        searchInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    // ── Resultados ────────────────────────────────────────────────────────
    Flickable {
        id: resultsFlick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBar.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: s(14)
        anchors.rightMargin: s(14)
        anchors.topMargin: s(10)
        anchors.bottomMargin: s(14)
        contentWidth: width
        contentHeight: resultsCol.implicitHeight + s(10)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: resultsCol
            width: parent.width
            spacing: s(8)

            // ── Estado vacío ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: s(150)
                visible: root.query.trim() === ""
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: s(8)
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰍉"
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(30)
                        color: Qt.alpha(themeColors.subtext0, 0.25)
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Type to search settings & keybinds..."
                        font.family: "Hack Nerd Font"
                        font.pixelSize: s(12)
                        color: Qt.alpha(themeColors.subtext0, 0.35)
                    }
                }
            }
            // ── Sin resultados ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: s(90)
                visible: root.query.trim() !== "" && root.totalCount === 0
                Text {
                    anchors.centerIn: parent
                    text: "No results for \"" + root.query + "\""
                    font.family: "Hack Nerd Font"
                    font.pixelSize: s(12)
                    color: Qt.alpha(themeColors.subtext0, 0.5)
                }
            }

            // ── Sección Settings (cards de tabs + páginas del editor) ──
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: s(4)
                Layout.topMargin: s(2)
                visible: root.settingsCount > 0
                text: "SETTINGS"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: s(10)
                color: Qt.alpha(themeColors.subtext0, 0.7)
            }
            Repeater {
                model: root.settingsResults
                delegate: Rectangle {
                    id: setRow
                    required property var modelData
                    required property int index

                    readonly property var entry: modelData.kind === "card" ? modelData.card : modelData.entry
                    readonly property int globalIndex: index
                    readonly property bool isHighlighted: root.highlight === globalIndex
                    readonly property color rowAccent: themeColors[entry.color] !== undefined
                        ? themeColors[entry.color] : themeColors.mauve

                    Layout.fillWidth: true
                    Layout.preferredHeight: s(52)
                    radius: s(13)
                    color: isHighlighted
                        ? Qt.alpha(themeColors.mauve, 0.12)
                        : (rowMa.containsMouse ? Qt.alpha(rowAccent, 0.10) : Qt.alpha(themeColors.surface0, 0.35))
                    border.width: 1
                    border.color: isHighlighted
                        ? themeColors.mauve
                        : (rowMa.containsMouse ? rowAccent : themeColors.surface1)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Component.onCompleted: root.registerRow(globalIndex, setRow)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: s(10)
                        spacing: s(10)
                        Rectangle {
                            width: s(30)
                            height: s(30)
                            radius: s(15)
                            color: Qt.alpha(setRow.rowAccent, 0.15)
                            border.color: Qt.alpha(setRow.rowAccent, 0.3)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: setRow.entry.icon
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(14)
                                color: setRow.rowAccent
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: s(1)
                            Text {
                                Layout.fillWidth: true
                                text: setRow.entry.label
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Medium
                                font.pixelSize: s(13)
                                color: setRow.isHighlighted ? themeColors.mauve : themeColors.text
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: setRow.entry.desc
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(11)
                                color: themeColors.subtext0
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            text: root.pageLabel(setRow.entry.page)
                            font.family: "Hack Nerd Font"
                            font.pixelSize: s(10)
                            color: themeColors.overlay1
                        }
                    }
                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.highlight = setRow.globalIndex;
                            root.activate(setRow.globalIndex);
                        }
                    }
                }
            }

            // ── Sección Keybinds ──
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: s(4)
                Layout.topMargin: s(2)
                visible: root.keybindResults.length > 0
                text: "KEYBINDS"
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: s(10)
                color: Qt.alpha(themeColors.peach, 0.8)
            }
            Repeater {
                model: root.keybindResults
                delegate: Rectangle {
                    id: kbRow
                    required property var modelData
                    required property int index

                    readonly property var kbItem: Config.keybindsData[modelData.kbIndex]
                    readonly property int globalIndex: root.settingsCount + index
                    readonly property bool isHighlighted: root.highlight === globalIndex

                    Layout.fillWidth: true
                    Layout.preferredHeight: s(56)
                    radius: s(13)
                    color: isHighlighted
                        ? Qt.alpha(themeColors.peach, 0.12)
                        : (kbMa.containsMouse ? Qt.alpha(themeColors.peach, 0.10) : Qt.alpha(themeColors.surface0, 0.35))
                    border.width: 1
                    border.color: isHighlighted
                        ? themeColors.peach
                        : (kbMa.containsMouse ? themeColors.peach : themeColors.surface1)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Component.onCompleted: root.registerRow(globalIndex, kbRow)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: s(10)
                        spacing: s(10)
                        Rectangle {
                            width: s(30)
                            height: s(30)
                            radius: s(15)
                            color: Qt.alpha(themeColors.peach, 0.15)
                            border.color: Qt.alpha(themeColors.peach, 0.3)
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "󰌌"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(14)
                                color: themeColors.peach
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: s(3)
                            RowLayout {
                                spacing: s(4)
                                Rectangle {
                                    height: s(18)
                                    width: modsT.implicitWidth + s(8)
                                    radius: s(18)
                                    color: themeColors.surface1
                                    border.color: themeColors.surface2
                                    border.width: 1
                                    visible: kbRow.kbItem && kbRow.kbItem.mods !== ""
                                    Text {
                                        id: modsT
                                        anchors.centerIn: parent
                                        text: kbRow.kbItem ? kbRow.kbItem.mods : ""
                                        font.family: "Hack Nerd Font"
                                        font.weight: Font.Bold
                                        font.pixelSize: s(8)
                                        color: themeColors.peach
                                    }
                                }
                                Text {
                                    text: "+"
                                    visible: kbRow.kbItem && kbRow.kbItem.mods !== "" && kbRow.kbItem.key !== ""
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: s(9)
                                    color: themeColors.overlay0
                                }
                                Rectangle {
                                    height: s(18)
                                    width: keyT.implicitWidth + s(8)
                                    radius: s(18)
                                    color: themeColors.surface1
                                    border.color: themeColors.surface2
                                    border.width: 1
                                    visible: kbRow.kbItem && kbRow.kbItem.key !== ""
                                    Text {
                                        id: keyT
                                        anchors.centerIn: parent
                                        text: kbRow.kbItem ? kbRow.kbItem.key : ""
                                        font.family: "Hack Nerd Font"
                                        font.weight: Font.Bold
                                        font.pixelSize: s(8)
                                        color: themeColors.peach
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: kbRow.kbItem ? (kbRow.kbItem.dispatcher + " " + kbRow.kbItem.command).trim() : ""
                                font.family: "Hack Nerd Font"
                                font.pixelSize: s(9)
                                color: themeColors.subtext0
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            text: "Keybinds"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: s(10)
                            color: Qt.alpha(themeColors.peach, 0.8)
                        }
                    }
                    MouseArea {
                        id: kbMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.highlight = kbRow.globalIndex;
                            root.activate(kbRow.globalIndex);
                        }
                    }
                }
            }
        }
    }
}
