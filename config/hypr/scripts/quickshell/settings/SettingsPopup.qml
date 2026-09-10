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
    id: root
    focus: true

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    function s(val) { 
        return scaler.s(val); 
    }
    
    property bool isLayoutDropdownOpen: false

    property bool isSearchMode: false
    property string globalSearchQuery: ""

    property int highlightedBox: -1

    property int searchHighlightIndex: -1

    property var searchResultItems: []

    function rebuildSearchResultItems() {
        let items = [];
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            let card = root.allSettingsCards[i];
            if (root.globalSearchMatches(card, root.globalSearchQuery)) {
                items.push({ kind: "card", cardIndex: i, kbIndex: -1 });
            }
        }
        let kbIndices = root.matchingKeybindIndices;
        for (let j = 0; j < kbIndices.length; j++) {
            items.push({ kind: "keybind", cardIndex: -1, kbIndex: kbIndices[j] });
        }
        root.searchResultItems = items;
        if (root.searchHighlightIndex >= items.length) {
            root.searchHighlightIndex = items.length - 1;
        }
    }

    onGlobalSearchQueryChanged: {
        root.matchingKeybindIndices = root.getMatchingKeybindIndices(root.globalSearchQuery);
        root.rebuildSearchResultItems();
        root.searchHighlightIndex = -1;
    }

    onIsSearchModeChanged: {
        if (!root.isSearchMode) {
            root.searchHighlightIndex = -1;
        } else {
            root.rebuildSearchResultItems();
        }
    }

    function activateSearchHighlight() {
        if (root.searchHighlightIndex < 0 || root.searchHighlightIndex >= root.searchResultItems.length) return;
        let item = root.searchResultItems[root.searchHighlightIndex];
        if (item.kind === "card") {
            let card = root.allSettingsCards[item.cardIndex];
            jumpToSettingTimer.targetTab = card.tab;
            jumpToSettingTimer.targetBox = card.boxIndex;
            jumpToSettingTimer.start();
            root.currentTab = card.tab;
            if (card.tab === 0) root.tab0Loaded = true;
            else if (card.tab === 1) root.tab1Loaded = true;
            else if (card.tab === 2) root.tab2Loaded = true;
            else if (card.tab === 3) root.tab3Loaded = true;
            else if (card.tab === 5) root.tab5Loaded = true;
        } else {
            jumpToSettingTimer.targetTab = 2;
            jumpToSettingTimer.targetBox = item.kbIndex;
            jumpToSettingTimer.start();
            root.currentTab = 2;
            root.tab2Loaded = true;
        }
        root.isSearchMode = false;
        root.forceActiveFocus();
        globalSearchInput.text = "";
        root.globalSearchQuery = "";
    }

    function scrollSearchToHighlight(idx) {
        if (idx < 0 || idx >= root.searchResultItems.length) return;
        let nCards = 0;
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
        }
        let itemH = root.s(60) + root.s(10);
        let headerH = (root.matchingKeybindIndices.length > 0) ? root.s(32) + root.s(10) : 0;
        let approxY = 0;
        let it = root.searchResultItems[idx];
        if (it.kind === "card") {
            let pos = 0;
            for (let i = 0; i < root.allSettingsCards.length; i++) {
                if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) {
                    if (root.allSettingsCards[i] === root.allSettingsCards[item_cardIndex_from(idx)]) break;
                    pos++;
                }
            }
            approxY = pos * itemH;
        } else {
            approxY = nCards * itemH + headerH + (idx - nCards) * itemH;
        }
        let target = Math.max(0, approxY - root.s(20));
        searchResultsFlickable.contentY = Math.min(target, Math.max(0, searchResultsFlickable.contentHeight - searchResultsFlickable.height));
    }

    function item_cardIndex_from(idx) {
        let item = root.searchResultItems[idx];
        return item.cardIndex;
    }

    function clearHighlight() {
        root.highlightedBox = -1;
    }

    function maxHighlightForTab(tab) {
        if (tab === 0) return 7;
        if (tab === 1) return 3;
        if (tab === 2) return dynamicKeybindsModel.count - 1;
        if (tab === 4) return dynamicStartupModel.count - 1;
        return -1;
    }

    function activateHighlightedBox() {
        if (root.currentTab === 0) {
            if (root.highlightedBox === 0) {
                Config.openGuideAtStartup = !Config.openGuideAtStartup;
            } else if (root.highlightedBox === 1) {
                Config.topbarHelpIcon = !Config.topbarHelpIcon;
            } else if (root.highlightedBox === 2) {
            } else if (root.highlightedBox === 3) {
                if (generalLoader.item) generalLoader.item.focusLangInput();
            } else if (root.highlightedBox === 4) {
                root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
            } else if (root.highlightedBox === 5) {
                if (generalLoader.item) generalLoader.item.focusWpDirInput();
            } else if (root.highlightedBox === 6) {
            }
        } else if (root.currentTab === 1) {
            if (root.highlightedBox === 0) {
            } else if (root.highlightedBox === 1) {
                if (weatherLoader.item) weatherLoader.item.focusApiKey();
            } else if (root.highlightedBox === 2) {
                if (weatherLoader.item) weatherLoader.item.focusCityId();
            } else if (root.highlightedBox === 3) {
            }
        } else if (root.currentTab === 2) {
            if (root.highlightedBox >= 0 && root.highlightedBox < dynamicKeybindsModel.count) {
                let isEd = dynamicKeybindsModel.get(root.highlightedBox).isEditing;
                dynamicKeybindsModel.setProperty(root.highlightedBox, "isEditing", !isEd);
            }
        } else if (root.currentTab === 4) {
            if (root.highlightedBox >= 0 && root.highlightedBox < dynamicStartupModel.count) {
                let isEd = dynamicStartupModel.get(root.highlightedBox).isEditing;
                dynamicStartupModel.setProperty(root.highlightedBox, "isEditing", !isEd);
            }
        }
    }

    onHighlightedBoxChanged: {
        if (root.highlightedBox < 0) return;
        Qt.callLater(function() { root.scrollHighlightedIntoView(); });
    }

    function scrollHighlightedIntoView() {
        let box = root.highlightedBox;
        if (box < 0) return;
        if (root.currentTab === 0 && generalLoader.item) {
            let approxY = 0;
            if (box === 0 || box === 1) approxY = 0;
            else if (box === 2) approxY = root.s(120);
            else if (box === 3 || box === 4) approxY = root.s(240);
            else if (box === 5) approxY = root.s(400);
            else if (box === 6) approxY = root.s(520);
            else if (box === 7) approxY = root.s(640);
            generalLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 1 && weatherLoader.item) {
            let approxY = 0;
            if (box === 0) approxY = 0;
            else if (box === 1) approxY = root.s(140);
            else if (box === 2) approxY = root.s(240);
            else if (box === 3) approxY = root.s(340);
            weatherLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 2 && keybindLoader.item) {
            let approxY = box * root.s(56) + root.s(120);
            keybindLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 4 && startupLoader.item) {
            let approxY = box * root.s(56) + root.s(20);
            startupLoader.item.scrollToBox(approxY);
        } else if (root.currentTab === 5 && topbarLoader.item) {
            let approxY = box * root.s(64) + root.s(60);
            topbarLoader.item.scrollToBox(approxY);
        }
    }

    property int currentTab: 0

    // App scale is persisted by the General tab's Save button, matching how
    // every other setting on that tab behaves.
    function appScaleStep(dir) {
        let next = Math.max(0.75, Math.min(2.0, Config.appScale + dir * 0.25));
        Config.appScale = Math.round(next * 100) / 100;
    }

    // Opened straight onto a tab via `qs_manager.sh toggle settings <mode>`.
    property string activeMode: ""
    onActiveModeChanged: root.applyActiveMode()

    function applyActiveMode() {
        if (root.activeMode === "topbar") {
            root.tab5Loaded = true;
            activeModeTimer.start();
        }
    }

    // Switching tabs on a timer rather than immediately: the tab bar only
    // scrolls the selection into view on a real transition, and it needs its
    // layout resolved first or the scroll target clamps to zero.
    Timer {
        id: activeModeTimer
        interval: 220
        onTriggered: root.currentTab = 5
    }

    property var tabNames: ["General", "Weather", "Keyboard", "Monitors", "Startup", "Dock"]
    property var tabIcons: ["󰒓", "󰖐", "󰌌", "󰍹", "󰐥", ""]
    property var tabColors: ["teal", "blue", "peach", "green", "mauve", "sapphire"]

    property bool tab0Loaded: false
    property bool tab1Loaded: false
    property bool tab2Loaded: false
    property bool tab3Loaded: false
    property bool tab4Loaded: false
    property bool tab5Loaded: false

    onCurrentTabChanged: {
        root.clearHighlight();
        if (currentTab === 0) root.tab0Loaded = true;
        else if (currentTab === 1) root.tab1Loaded = true;
        else if (currentTab === 2) root.tab2Loaded = true;
        else if (currentTab === 3) root.tab3Loaded = true;
        else if (currentTab === 4) root.tab4Loaded = true;
        else if (currentTab === 5) root.tab5Loaded = true;
    }

    onTab3LoadedChanged: {
        if (tab3Loaded) Config.displayPoller.running = true;
    }

    Keys.onEscapePressed: {
        if (root.isSearchMode) {
            root.isSearchMode = false;
            root.globalSearchQuery = "";
            globalSearchInput.text = "";
            root.searchHighlightIndex = -1;
            event.accepted = true;
        } else if (root.isLayoutDropdownOpen) {
            root.isLayoutDropdownOpen = false;
            event.accepted = true;
        } else if (root.highlightedBox >= 0) {
            root.clearHighlight();
            event.accepted = true;
        } else {
            closeSequence.start();
            event.accepted = true;
        }
    }

    Keys.onTabPressed: (event) => {
        if (root.isSearchMode) return;
        root.currentTab = (root.currentTab + 1) % 6;
        event.accepted = true;
    }
    Keys.onBacktabPressed: (event) => {
        if (root.isSearchMode) return;
        root.currentTab = (root.currentTab + 5) % 6;
        event.accepted = true;
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) || 
            (event.key === Qt.Key_Slash && !root.isSearchMode)) {
            root.isSearchMode = true;
            globalSearchInput.forceActiveFocus();
            event.accepted = true;
            return;
        }

        if (root.isSearchMode) {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                root.forceActiveFocus();
                let total = root.searchResultItems.length;
                if (total === 0) { event.accepted = true; return; }
                if (event.key === Qt.Key_Down) {
                    if (root.searchHighlightIndex < total - 1) {
                        root.searchHighlightIndex++;
                    } else {
                        root.searchHighlightIndex = 0;
                    }
                } else {
                    if (root.searchHighlightIndex > 0) {
                        root.searchHighlightIndex--;
                    } else if (root.searchHighlightIndex === 0) {
                        root.searchHighlightIndex = total - 1;
                    } else {
                        root.searchHighlightIndex = total - 1;
                    }
                }
                root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                event.accepted = true;
                return;
            }
            return;
        }

        if (root.isLayoutDropdownOpen) {
            if (event.key === Qt.Key_Down) {
                if (generalLoader.item) generalLoader.item.layoutListIncrementIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                if (generalLoader.item) generalLoader.item.layoutListDecrementIndex();
                event.accepted = true;
            }
            return;
        }
        
        if (event.key === Qt.Key_Left) {
            if (root.currentTab === 0 && root.highlightedBox === 2) {
                Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1));
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 6) {
                Config.workspaceCount = Math.max(2, Config.workspaceCount - 1);
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 7) {
                root.appScaleStep(-1);
                event.accepted = true;
                return;
            }
        }
        if (event.key === Qt.Key_Right) {
            if (root.currentTab === 0 && root.highlightedBox === 2) {
                Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1));
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 6) {
                Config.workspaceCount = Math.min(10, Config.workspaceCount + 1);
                event.accepted = true;
                return;
            } else if (root.currentTab === 0 && root.highlightedBox === 7) {
                root.appScaleStep(1);
                event.accepted = true;
                return;
            }
        }

        if (event.key === Qt.Key_Down) {
            let maxIdx = root.maxHighlightForTab(root.currentTab);
            if (maxIdx < 0) { event.accepted = true; return; }
            if (root.highlightedBox < maxIdx) {
                root.highlightedBox = root.highlightedBox + 1;
            } else if (root.highlightedBox === maxIdx) {
                root.highlightedBox = -1;
            } else {
                root.highlightedBox = 0;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            let maxIdx = root.maxHighlightForTab(root.currentTab);
            if (maxIdx < 0) { event.accepted = true; return; }
            if (root.highlightedBox > 0) {
                root.highlightedBox = root.highlightedBox - 1;
            } else if (root.highlightedBox === 0) {
                root.highlightedBox = -1;
            } else {
                root.highlightedBox = maxIdx;
            }
            event.accepted = true;
        }
    }

    Keys.onReturnPressed: (event) => root.handleRootEnter(event)
    Keys.onEnterPressed: (event) => root.handleRootEnter(event)

    function handleRootEnter(event) {
        if (root.isSearchMode) {
            if (root.searchHighlightIndex >= 0) {
                root.activateSearchHighlight();
                event.accepted = true;
            }
            return;
        }
        if (root.isLayoutDropdownOpen) {
            if (generalLoader.item) generalLoader.item.acceptLayoutSelection();
            root.isLayoutDropdownOpen = false;
            event.accepted = true;
            return;
        }
        if (root.highlightedBox >= 0) {
            root.activateHighlightedBox();
            event.accepted = true;
            return;
        }
        if (root.currentTab === 0) Config.saveAppSettings();
        else if (root.currentTab === 1) Config.saveWeatherConfig();
        else if (root.currentTab === 2) root.saveAllKeybinds();
        else if (root.currentTab === 3) Config.applyMonitors();
        else if (root.currentTab === 4) root.saveAllStartup();
        event.accepted = true;
    }

    function scrollSearchHighlightIntoView(idx) {
        if (idx < 0 || idx >= root.searchResultItems.length) return;

        let nCards = 0;
        for (let i = 0; i < root.allSettingsCards.length; i++) {
            if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
        }
        let hasKbHeader = root.matchingKeybindIndices.length > 0;
        let itemH = root.s(60) + root.s(10);
        let headerH = hasKbHeader ? (root.s(32) + root.s(10)) : 0;

        let approxY = 0;
        let it = root.searchResultItems[idx];
        if (it.kind === "card") {
            let pos = 0;
            for (let i = 0; i < root.searchResultItems.length; i++) {
                if (i === idx) break;
                if (root.searchResultItems[i].kind === "card") pos++;
            }
            approxY = pos * itemH;
        } else {
            let kbPos = 0;
            for (let i = 0; i < root.searchResultItems.length; i++) {
                if (i === idx) break;
                if (root.searchResultItems[i].kind === "keybind") kbPos++;
            }
            approxY = nCards * itemH + headerH + kbPos * itemH;
        }

        let viewH = searchResultsFlickable.height;
        let contentH = searchResultsFlickable.contentHeight;
        let curY = searchResultsFlickable.contentY;
        let itemTop = approxY;
        let itemBottom = approxY + root.s(60);

        if (itemTop < curY + root.s(10)) {
            searchResultsFlickable.contentY = Math.max(0, itemTop - root.s(10));
        } else if (itemBottom > curY + viewH - root.s(10)) {
            searchResultsFlickable.contentY = Math.min(contentH - viewH, itemBottom - viewH + root.s(10));
        }
    }

    Colors { id: _theme }

    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay2: _theme.overlay2
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color teal: _theme.teal
    readonly property color green: _theme.green
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color red: _theme.red

    ListModel { id: dynamicKeybindsModel }

    // Alias para los tabs extraídos: los `id` no son accesibles desde otros
    // archivos, así que KeybindTab/StartupTab leen los modelos vía
    // host.kbModel / host.startupModel (ver settings/tabs/*.qml).
    property alias kbModel: dynamicKeybindsModel
    property alias startupModel: dynamicStartupModel
    
    Connections {
        target: Config
        // Triggers the very first time Config finishes reading the JSON
        function onKeybindsLoaded() {
            dynamicKeybindsModel.clear();
            for (let i = 0; i < Config.keybindsData.length; i++) {
                let k = Config.keybindsData[i];
                dynamicKeybindsModel.append({
                    type: k.type || "bind",
                    mods: k.mods || "",
                    key: k.key || "",
                    dispatcher: k.dispatcher || "exec",
                    command: k.command || "",
                    isEditing: false
                });
            }
        }
        // Triggers whenever you save and Config.keybindsData is overwritten
        function onKeybindsDataChanged() {
            dynamicKeybindsModel.clear();
            for (let i = 0; i < Config.keybindsData.length; i++) {
                let k = Config.keybindsData[i];
                dynamicKeybindsModel.append({
                    type: k.type || "bind",
                    mods: k.mods || "",
                    key: k.key || "",
                    dispatcher: k.dispatcher || "exec",
                    command: k.command || "",
                    isEditing: false
                });
            }
        }
        function onStartupLoaded() {
            dynamicStartupModel.clear();
            for (let s of Config.startupData) {
                dynamicStartupModel.append({ command: s.command || "", isEditing: false });
            }
        }
        function onStartupDataChanged() {
            dynamicStartupModel.clear();
            for (let s of Config.startupData) {
                dynamicStartupModel.append({ command: s.command || "", isEditing: false });
            }
        }
    }

    function saveAllKeybinds() {
        let bindsArray = [];
        for (let i = 0; i < dynamicKeybindsModel.count; i++) {
            let item = dynamicKeybindsModel.get(i);
            if (!item.key && !item.command) continue; 
            bindsArray.push({
                type: item.type,
                mods: item.mods,
                key: item.key,
                dispatcher: item.dispatcher,
                command: item.command,
                isEditing: false // CRITICAL: This prevents QML from dropping the role!
            });
        }
        Config.saveAllKeybinds(bindsArray);
    }

    ListModel { id: dynamicStartupModel }

    Connections {
        target: Config
        function onStartupLoaded() {
            dynamicStartupModel.clear();
            for (let s of Config.startupData) {
                dynamicStartupModel.append({ command: s.command || "", isEditing: false });
            }
        }
        function onStartupDataChanged() {
            dynamicStartupModel.clear();
            for (let s of Config.startupData) {
                dynamicStartupModel.append({ command: s.command || "", isEditing: false });
            }
        }
    }

    function saveAllStartup() {
        let startupArray = [];
        for (let i = 0; i < dynamicStartupModel.count; i++) {
            let cmd = dynamicStartupModel.get(i).command.trim();
            if (cmd.length > 0) startupArray.push({ command: cmd });
        }
        Config.saveAllStartup(startupArray);
    }

    Timer {
        id: scrollTimer
        interval: 50
        onTriggered: {
            if (keybindLoader.item) {
                keybindLoader.item.scrollToBottom();
            }
        }
    }

    Timer {
        id: startupScrollTimer
        interval: 50
        onTriggered: {
            if (startupLoader.item) {
                startupLoader.item.scrollToBottom();
            }
        }
    }

    Timer {
        id: jumpToSettingTimer
        interval: 100
        property int targetTab: 0
        property int targetBox: -1

        onTriggered: {
            if (targetBox >= 0) {
                root.highlightedBox = targetBox;
                
                let approxY = 0;

                if (targetTab === 0 && generalLoader.item) {
                    if (targetBox === 0 || targetBox === 1) approxY = 0;
                    else if (targetBox === 2) approxY = root.s(120);
                    else if (targetBox === 3 || targetBox === 4) approxY = root.s(240);
                    else if (targetBox === 5) approxY = root.s(400);
                    else if (targetBox === 6) approxY = root.s(520);
                    generalLoader.item.scrollTo(approxY);
                } else if (targetTab === 1 && weatherLoader.item) {
                    if (targetBox === 1) approxY = root.s(140);
                    else if (targetBox === 2) approxY = root.s(240);
                    else if (targetBox === 3) approxY = root.s(340);
                    weatherLoader.item.scrollTo(approxY);
                } else if (targetTab === 2 && keybindLoader.item) {
                    approxY = targetBox * (root.s(56)) + root.s(120);
                    keybindLoader.item.scrollTo(approxY);
                } else if (targetTab === 3 && startupLoader.item) {
                    approxY = targetBox * (root.s(56)) + root.s(20);
                    startupLoader.item.scrollTo(approxY);
                }

                targetBox = -1;
            }
        }
    }    

    property var allSettingsCards: [
        { tab: 0, boxIndex: 0, label: "Guide on startup",  desc: "Launch on login",        icon: "󰑊", color: "peach" },
        { tab: 0, boxIndex: 1, label: "Help icon",         desc: "Show button in topbar",  icon: "󰋖", color: "blue" },
        { tab: 0, boxIndex: 2, label: "UI Scale",          desc: "Base size scalar",       icon: "󰁦", color: "sapphire" },
        { tab: 0, boxIndex: 3, label: "Keyboard layouts",  desc: "Matches hyprland.conf",  icon: "󰌌", color: "green" },
        { tab: 0, boxIndex: 4, label: "Layout shortcut",   desc: "Toggle combination",     icon: "󰯍", color: "teal" },
        { tab: 0, boxIndex: 5, label: "Wallpaper directory",desc: "Absolute source path",  icon: "󰋩", color: "mauve" },
        { tab: 0, boxIndex: 6, label: "Workspaces",        desc: "Static count in topbar", icon: "󰽿", color: "red" },
        { tab: 1, boxIndex: 1, label: "API Key",           desc: "OpenWeather API key",    icon: "󰌆", color: "blue" },
        { tab: 1, boxIndex: 2, label: "City ID",           desc: "OpenWeather city ID",    icon: "󰖐", color: "blue" },
        { tab: 1, boxIndex: 3, label: "Temperature Unit",  desc: "Celsius / Fahrenheit / K", icon: "󰔄", color: "blue" },
        { tab: 5, boxIndex: 0, label: "Topbar modules",    desc: "Toggle and reorder the bar", icon: "", color: "sapphire" },
        { tab: 0, boxIndex: 7, label: "App scale",        desc: "Scale GTK / Electron apps", icon: "", color: "sapphire" }
    ]

    function getMatchingKeybindIndices(query) {
        if (query.trim() === "") return [];
        let results = [];
        try {
            let re = new RegExp(query, "i");
            for (let i = 0; i < dynamicKeybindsModel.count; i++) {
                let item = dynamicKeybindsModel.get(i);
                if (re.test(item.mods) || re.test(item.key) || re.test(item.dispatcher) || re.test(item.command) || re.test(item.type)) {
                    results.push(i);
                }
            }
        } catch(e) {
            let q = query.trim().toLowerCase();
            for (let i = 0; i < dynamicKeybindsModel.count; i++) {
                let item = dynamicKeybindsModel.get(i);
                if ((item.mods && item.mods.toLowerCase().includes(q)) ||
                    (item.key && item.key.toLowerCase().includes(q)) ||
                    (item.dispatcher && item.dispatcher.toLowerCase().includes(q)) ||
                    (item.command && item.command.toLowerCase().includes(q))) {
                    results.push(i);
                }
            }
        }
        return results;
    }

    property var matchingKeybindIndices: []

    function globalSearchMatches(card, query) {
        if (query.trim() === "") return false;
        let q = query.trim().toLowerCase();
        return card.label.toLowerCase().includes(q) || card.desc.toLowerCase().includes(q);
    }


    property real introContent: 0.0
    Component.onCompleted: {
        root.tab0Loaded = true;
        root.applyActiveMode();
        startupSequence.start();
        if (Config.dataReady && dynamicKeybindsModel.count === 0) {
            for (let i = 0; i < Config.keybindsData.length; i++) {
                let k = Config.keybindsData[i];
                dynamicKeybindsModel.append({
                    type: k.type || "bind",
                    mods: k.mods || "",
                    key: k.key || "",
                    dispatcher: k.dispatcher || "exec",
                    command: k.command || "",
                    isEditing: false
                });
            }
        }
        if (Config.dataReady && dynamicStartupModel.count === 0) {
            for (let s of Config.startupData) {
                dynamicStartupModel.append({ command: s.command || "", isEditing: false });
            }
        }
    }

    SequentialAnimation {
        id: startupSequence
        PauseAnimation { duration: 50 }
        NumberAnimation { 
            target: root
            property: "introContent"
            from: 0.0
            to: 1.0
            duration: 600
            easing.type: Easing.OutQuart
        } 
    }

    SequentialAnimation {
        id: closeSequence
        NumberAnimation { 
            target: root
            property: "introContent"
            to: 0.0
            duration: 200
            easing.type: Easing.InQuart
        }
        ScriptAction { 
            script: {
                Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.submap(\"reset\"))"]);
                Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
            } 
        }    
    }

    // ── Main Panel ─────────────────────────────────────────────────────────────
    Rectangle {
        id: sidebarPanel
        anchors.fill: parent
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.97)
        radius: root.s(21)
        border.width: 1
        border.color: Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.9)
        clip: true

        Rectangle {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: root.s(16)
            color: sidebarPanel.color
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: sidebarPanel.border.color }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: sidebarPanel.border.color }
            Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: sidebarPanel.border.color }
        }

        // ── Sidebar navigation ────────────────────────────────────────────────
        // Modern settings-app left rail: a vertical list of sections. Clicking a
        // section switches `root.currentTab` (the same index the old top tab bar
        // used, so all section logic/loaders keep working unchanged).
        Column {
            id: settingsSidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.s(16)
            anchors.topMargin: root.s(90)
            width: root.s(160)
            spacing: root.s(4)

            // One nav item per section: [icon, label, tabIndex]
            function navItem(icon, label, idx) {
                // (helper not used; items are declared explicitly below for clarity)
            }

            Repeater {
                model: [
                    { icon: "󰒓", label: "General",    tab: 0 },
                    { icon: "󰖐", label: "Weather",      tab: 1 },
                    { icon: "󰌌", label: "Keyboard",    tab: 2 },
                    { icon: "󰍹", label: "Monitors",  tab: 3 },
                    { icon: "󰐥", label: "Startup",   tab: 4 },
                    { icon: "󰫧", label: "Dock",      tab: 5 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    property bool isActive: root.currentTab === modelData.tab
                    width: parent.width
                    height: root.s(40)
                    radius: root.s(10)
                    color: isActive ? root.mauve : (navMa.containsMouse ? root.surface1 : "transparent")
                    opacity: isActive ? 1 : 0.85
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: root.s(12)
                        spacing: root.s(10)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.icon
                            font.family: "Hack Nerd Font"
                            font.pixelSize: root.s(15)
                            color: isActive ? root.base : root.subtext0
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            font.family: "Hack Nerd Font"
                            font.weight: isActive ? Font.Black : Font.Medium
                            font.pixelSize: root.s(12)
                            color: isActive ? root.base : root.text
                        }
                    }
                    MouseArea {
                        id: navMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentTab = modelData.tab
                    }
                }
            }

            Item { width: 1; height: root.s(24) }

            // Quick hint under the nav.
            Rectangle {
                width: parent.width
                height: root.s(2)
                color: root.surface1
                opacity: 0.6
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Usa las flechas ↑↓ para navegar · ESC cierra"
                font.family: "Hack Nerd Font"
                font.pixelSize: root.s(9)
                color: root.overlay1
            }
        }

        Item {
            anchors.left: settingsSidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            opacity: introContent
            scale: 0.96 + (0.04 * introContent)
            transform: Translate { y: root.s(40) * (1.0 - introContent) }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.s(20)
                spacing: root.s(12)

                // ── Header ────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.s(10)

                    Text { 
                        text: "Settings"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(24)
                        color: root.text; Layout.alignment: Qt.AlignVCenter 
                    }

                    Rectangle {
                        visible: root.isSearchMode
                        width: root.s(26); height: root.s(26); radius: root.s(22)
                        color: closeSearchMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
                        border.color: closeSearchMa.containsMouse ? root.red : "transparent"; border.width: 1
                        opacity: root.isSearchMode ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { anchors.centerIn: parent; text: "✕"; font.family: "Inter"; font.pixelSize: root.s(12); color: closeSearchMa.containsMouse ? root.red : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                        MouseArea {
                            id: closeSearchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.isSearchMode = false; root.globalSearchQuery = ""; globalSearchInput.text = ""; root.searchHighlightIndex = -1; }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Save button
                    Rectangle {
                        id: headerSaveBtn
                        visible: root.currentTab !== 2 && root.currentTab !== 4 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: root.s(34)
                        Layout.preferredWidth: saveBtnRow.implicitWidth + root.s(28)

                        radius: root.s(18)
                        scale: headerSaveMa.pressed ? 0.94 : (headerSaveMa.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        color: headerSaveMa.pressed
                            ? Qt.darker(root.mauve, 1.15)
                            : (headerSaveMa.containsMouse ? root.mauve : root.surface1)
                        border.color: headerSaveMa.containsMouse ? root.mauve : Qt.alpha(root.mauve, 0.4)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        RowLayout {
                            id: saveBtnRow
                            anchors.centerIn: parent
                            spacing: root.s(7)
                            Text { 
                                text: "󰆓"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: root.s(15)
                                color: headerSaveMa.containsMouse ? root.base : root.mauve
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            Text { 
                                text: "Save"
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(12)
                                color: headerSaveMa.containsMouse ? root.base : root.text
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        MouseArea {
                            id: headerSaveMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentTab === 0) Config.saveAppSettings();
                                else if (root.currentTab === 1) Config.saveWeatherConfig();
                                else if (root.currentTab === 3) Config.applyMonitors();
                            }
                        }
                    }

                    // Add button
                    Rectangle {
                        id: headerAddBtn
                        visible: (root.currentTab === 2 || root.currentTab === 4) && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: root.s(34)
                        Layout.preferredWidth: addBtnRow.implicitWidth + root.s(28)

                        radius: root.s(18)
                        scale: headerAddMa.pressed ? 0.94 : (headerAddMa.containsMouse ? 1.03 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        color: headerAddMa.pressed
                            ? Qt.darker(root.peach, 1.15)
                            : (headerAddMa.containsMouse ? root.peach : root.surface1)
                        border.color: headerAddMa.containsMouse ? root.peach : Qt.alpha(root.peach, 0.4)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        RowLayout {
                            id: addBtnRow
                            anchors.centerIn: parent
                            spacing: root.s(7)
                            Text { 
                                text: "+"
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(15)
                                color: headerAddMa.containsMouse ? root.base : root.peach
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            Text { 
                                text: "Add"
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: root.s(12)
                                color: headerAddMa.containsMouse ? root.base : root.text
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        MouseArea {
                            id: headerAddMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentTab === 2) {
                                    dynamicKeybindsModel.append({ type: "bind", mods: "", key: "", dispatcher: "exec", command: "", isEditing: true });
                                    scrollTimer.start();
                                } else if (root.currentTab === 4) {
                                    dynamicStartupModel.append({ command: "", isEditing: true });
                                    startupScrollTimer.start();
                                }
                            }
                        }
                    }
                }

                // ── Search bar ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: root.s(40); radius: root.s(13)
                    color: root.isSearchMode
                        ? Qt.alpha(root.sapphire, 0.06)
                        : (globalSearchBarMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.5))
                    border.color: root.isSearchMode ? root.sapphire : (globalSearchBarMa.containsMouse ? root.surface2 : root.surface1)
                    border.width: root.isSearchMode ? 2 : 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: root.s(11); anchors.rightMargin: root.s(11); spacing: root.s(9)
                        Text {
                            text: "󰍉"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(15)
                            color: root.isSearchMode ? root.sapphire : root.subtext0
                            Behavior on color { ColorAnimation { duration: 200 } }
                            MouseArea { anchors.fill: parent; anchors.margins: -root.s(6); hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
                        }
                        TextInput {
                            id: globalSearchInput
                            Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: TextInput.AlignVCenter
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: root.text; clip: true; selectByMouse: true
                            Text {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                text: root.isSearchMode ? "Search settings & keybinds..." : "Search"
                                color: Qt.alpha(root.subtext0, 0.45)
                                visible: !globalSearchInput.text && !globalSearchInput.activeFocus
                                font.family: "Hack Nerd Font"; font.pixelSize: root.s(12)
                            }
                            onActiveFocusChanged: { if (activeFocus && !root.isSearchMode) root.isSearchMode = true; }
                            onTextChanged: { root.globalSearchQuery = text; if (!root.isSearchMode && text.length > 0) root.isSearchMode = true; }
                            Keys.onEscapePressed: { root.isSearchMode = false; root.globalSearchQuery = ""; text = ""; root.searchHighlightIndex = -1; root.forceActiveFocus(); }
                            Keys.onDownPressed: (event) => {
                                root.forceActiveFocus();
                                let total = root.searchResultItems.length;
                                if (total === 0) { event.accepted = true; return; }
                                root.searchHighlightIndex = root.searchHighlightIndex < total - 1 ? root.searchHighlightIndex + 1 : 0;
                                root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                                event.accepted = true;
                            }
                            Keys.onUpPressed: (event) => {
                                root.forceActiveFocus();
                                let total = root.searchResultItems.length;
                                if (total === 0) { event.accepted = true; return; }
                                root.searchHighlightIndex = root.searchHighlightIndex > 0 ? root.searchHighlightIndex - 1 : (root.searchHighlightIndex === 0 ? total - 1 : total - 1);
                                root.scrollSearchHighlightIntoView(root.searchHighlightIndex);
                                event.accepted = true;
                            }
                            Keys.onReturnPressed: (event) => {
                                if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
                            }
                            Keys.onEnterPressed: (event) => {
                                if (root.searchHighlightIndex >= 0) { root.activateSearchHighlight(); event.accepted = true; }
                            }
                        }
                        Rectangle {
                            visible: root.isSearchMode && globalSearchInput.text.length > 0; width: root.s(20); height: root.s(20); radius: root.s(18)
                            color: clearSearchBtnMa.containsMouse ? Qt.alpha(root.red, 0.15) : "transparent"
                            border.color: clearSearchBtnMa.containsMouse ? root.red : "transparent"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: root.s(10); color: clearSearchBtnMa.containsMouse ? root.red : Qt.alpha(root.subtext0, 0.6); Behavior on color { ColorAnimation { duration: 150 } } }
                            MouseArea { id: clearSearchBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { globalSearchInput.text = ""; globalSearchInput.forceActiveFocus(); } }
                        }
                    }
                    MouseArea { id: globalSearchBarMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !root.isSearchMode; onClicked: { root.isSearchMode = true; globalSearchInput.forceActiveFocus(); } }
                }

                // ── Tab bar ───────────────────────────────────────────────────
                // HIDDEN: replaced by the left sidebar (settingsSidebar).
                // Kept in the tree (visible: false) so all the tab-switching and
                // keyboard logic that references it keeps working.
                Item {
                    id: tabBarContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.s(38)
                    visible: false
                    enabled: false
                    clip: true

                    Rectangle {
                        anchors.fill: parent; radius: root.s(13)
                        color: root.surface0; border.color: root.surface1; border.width: 1
                    }

                    Flickable {
                        id: tabBarFlickable
                        anchors.fill: parent
                        clip: false
                        // UX Update: Elastic boundaries feel much more native and premium than stopping dead
                        boundsBehavior: Flickable.DragAndOvershootBounds

                        // Reduced the divisor to 2.5 so tabs don't squash and it's clear the list scrolls
                        property real tabItemW: (tabBarContainer.width - root.s(6)) / (root.tabNames.length <= 3 ? 3 : 2.5)
                        contentWidth: root.tabNames.length * tabItemW + root.s(6)
                        contentHeight: height

                        // Graceful smooth scrolling animation for tab selection
                        NumberAnimation {
                            id: smoothScrollAnim
                            target: tabBarFlickable
                            property: "contentX"
                            duration: 350
                            easing.type: Easing.OutCubic
                        }

                        // UX Update: Dedicated animation for hardware scroll wheels to prevent jagged jumps
                        NumberAnimation {
                            id: wheelScrollAnim
                            target: tabBarFlickable
                            property: "contentX"
                            duration: 150
                            easing.type: Easing.OutSine
                        }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: (event) => {
                                smoothScrollAnim.stop(); // Cancel auto-scroll if user takes control
                                
                                // UX Update: Support both vertical mice and horizontal trackpads seamlessly
                                let delta = Math.abs(event.angleDelta.x) > 0 ? event.angleDelta.x : event.angleDelta.y;
                                
                                // Calculate the target with clamping so the animation doesn't break boundaries
                                let targetX = Math.max(0, Math.min(
                                    tabBarFlickable.contentWidth - tabBarFlickable.width,
                                    tabBarFlickable.contentX - delta * 0.75 // 0.75 smooths out hyper-fast scroll wheels
                                ));
                                
                                wheelScrollAnim.to = targetX;
                                wheelScrollAnim.start();
                                
                                event.accepted = true;
                            }
                        }

                        Rectangle {
                            id: tabHighlightPill
                            y: root.s(3)
                            height: root.s(32)
                            radius: root.s(18)

                            property color c0: root.teal
                            property color c1: root.blue
                            property color c2: root.peach
                            property color c3: root.green
                            property color c4: root.mauve
                            property color targetColor: {
                                if (root.currentTab === 0) return c0;
                                if (root.currentTab === 1) return c1;
                                if (root.currentTab === 2) return c2;
                                if (root.currentTab === 3) return c3;
                                return c4;
                            }
                            color: targetColor
                            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutExpo } }

                            property int prevTab: 0
                            property int curTab: root.currentTab

                            onCurTabChanged: {
                                if (curTab > prevTab) {
                                    tabRightAnim.duration = 200; tabLeftAnim.duration = 350;
                                } else if (curTab < prevTab) {
                                    tabLeftAnim.duration = 200; tabRightAnim.duration = 350;
                                }
                                prevTab = curTab;
                                
                                // Graceful scrolling: center the newly selected tab
                                let tLeft = root.s(3) + curTab * tabBarFlickable.tabItemW;
                                let targetX = tLeft - (tabBarFlickable.width / 2) + (tabBarFlickable.tabItemW / 2);
                                
                                // Clamp bounds
                                targetX = Math.max(0, Math.min(tabBarFlickable.contentWidth - tabBarFlickable.width, targetX));
                                
                                smoothScrollAnim.to = targetX;
                                smoothScrollAnim.start();
                            }

                            property real targetLeft: root.s(3) + curTab * tabBarFlickable.tabItemW
                            property real targetRight: targetLeft + tabBarFlickable.tabItemW

                            property real actualLeft: targetLeft
                            property real actualRight: targetRight

                            Behavior on actualLeft { NumberAnimation { id: tabLeftAnim; duration: 250; easing.type: Easing.OutExpo } }
                            Behavior on actualRight { NumberAnimation { id: tabRightAnim; duration: 250; easing.type: Easing.OutExpo } }

                            x: actualLeft
                            width: actualRight - actualLeft
                        }

                        Row {
                            x: root.s(3)
                            spacing: 0
                            height: tabBarFlickable.height

                            Repeater {
                                model: root.tabNames.length
                                Item {
                                    width: tabBarFlickable.tabItemW
                                    height: parent.height

                                    property bool isActive: root.currentTab === index

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: root.s(7)
                                        Text {
                                            text: root.tabIcons[index]
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: root.s(14)
                                            color: isActive ? root.base : root.subtext0
                                            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                        }
                                        Text {
                                            text: root.tabNames[index]
                                            font.family: "Hack Nerd Font"
                                            font.weight: isActive ? Font.Bold : Font.Medium
                                            font.pixelSize: root.s(12)
                                            color: isActive ? root.base : root.subtext0
                                            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.currentTab = index; root.clearHighlight(); }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Content area ──────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    // Search results
                    Flickable {
                        id: searchResultsFlickable
                        anchors.fill: parent; contentWidth: width
                        contentHeight: searchResultsCol.implicitHeight + root.s(40)
                        boundsBehavior: Flickable.StopAtBounds; clip: true
                        visible: root.isSearchMode
                        opacity: root.isSearchMode ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250 } }

                        MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

                        ColumnLayout {
                            id: searchResultsCol; width: parent.width; spacing: root.s(8)

                            Item {
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(80)
                                visible: root.globalSearchQuery.trim() === ""
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: root.s(8)
                                    Text { Layout.alignment: Qt.AlignHCenter; text: ""; font.family: "Hack Nerd Font"; font.pixelSize: root.s(30); color: Qt.alpha(root.subtext0, 0.25) }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: "Type to search settings & keybinds..."; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: Qt.alpha(root.subtext0, 0.35) }
                                }
                            }

                            Repeater {
                                id: settingsCardRepeater
                                model: root.allSettingsCards.length
                                delegate: Item {
                                    property var card: root.allSettingsCards[index]
                                    property bool matches: root.globalSearchMatches(card, root.globalSearchQuery)
                                    property int searchListIndex: {
                                        let pos = 0;
                                        for (let i = 0; i < root.searchResultItems.length; i++) {
                                            if (root.searchResultItems[i].kind === "card" && root.searchResultItems[i].cardIndex === index) { pos = i; break; }
                                        }
                                        return pos;
                                    }
                                    property bool isSearchHighlighted: matches && root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: matches ? root.s(58) : 0
                                    visible: matches; opacity: matches ? 1.0 : 0.0; clip: true
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                                    Rectangle {
                                        anchors.fill: parent; radius: root.s(13)
                                        color: isSearchHighlighted
                                            ? root.surface1
                                            : (searchCardMa.containsMouse ? root.surface1 : root.surface0)
                                        border.color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.surface1)
                                        border.width: isSearchHighlighted ? 2 : 1
                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                                        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: root.s(12); spacing: root.s(12)
                                            Rectangle {
                                                width: root.s(32); height: root.s(32); radius: root.s(18)
                                                color: Qt.alpha(root[card.color], 0.15)
                                                border.color: Qt.alpha(root[card.color], 0.3); border.width: 1
                                                Text {
                                                    anchors.centerIn: parent; text: card.icon; font.family: "Hack Nerd Font"; font.pixelSize: root.s(15)
                                                    color: root[card.color]
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: root.s(2)
                                                Text {
                                                    text: card.label; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
                                                    color: isSearchHighlighted ? root[card.color] : root.text; Layout.fillWidth: true
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                                Text {
                                                    text: card.desc; font.family: "Inter"; font.pixelSize: root.s(10)
                                                    color: Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                                }
                                            }
                                            Rectangle {
                                                height: root.s(20); width: tabBadgeText.implicitWidth + root.s(12); radius: root.s(13)
                                                color: Qt.alpha(root[root.tabColors[card.tab]], 0.15)
                                                border.color: Qt.alpha(root[root.tabColors[card.tab]], 0.4); border.width: 1
                                                Text {
                                                    id: tabBadgeText; anchors.centerIn: parent; text: root.tabNames[card.tab]
                                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                                                    color: root[root.tabColors[card.tab]]
                                                }
                                            }
                                            Text {
                                                text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
                                                color: isSearchHighlighted ? root[card.color] : (searchCardMa.containsMouse ? root[card.color] : root.subtext0)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                        MouseArea {
                                            id: searchCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                jumpToSettingTimer.targetTab = card.tab;
                                                jumpToSettingTimer.targetBox = card.boxIndex;
                                                jumpToSettingTimer.start();
                                                root.currentTab = card.tab;
                                                if (card.tab === 0) root.tab0Loaded = true;
                                                else if (card.tab === 1) root.tab1Loaded = true;
                                                else if (card.tab === 2) root.tab2Loaded = true;
                                                root.isSearchMode = false;
                                                root.forceActiveFocus();
                                                globalSearchInput.text = "";
                                                root.globalSearchQuery = "";
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: (root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0) ? root.s(30) : 0
                                visible: root.globalSearchQuery.trim() !== "" && root.matchingKeybindIndices.length > 0
                                opacity: visible ? 1.0 : 0.0; clip: true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: root.s(4); spacing: root.s(8)
                                    Rectangle { width: root.s(3); height: root.s(12); radius: root.s(8); color: root.peach }
                                    Text { text: "Keybinds (" + root.matchingKeybindIndices.length + " match" + (root.matchingKeybindIndices.length !== 1 ? "es" : "") + ")"; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(10); color: root.peach }
                                }
                            }

                            Repeater {
                                id: keybindResultRepeater
                                model: root.matchingKeybindIndices.length
                                delegate: Item {
                                    property int kbIndex: root.matchingKeybindIndices[index]
                                    property var kbItem: dynamicKeybindsModel.get(kbIndex)
                                    property int searchListIndex: {
                                        let nCards = 0;
                                        for (let i = 0; i < root.allSettingsCards.length; i++) {
                                            if (root.globalSearchMatches(root.allSettingsCards[i], root.globalSearchQuery)) nCards++;
                                        }
                                        return nCards + index;
                                    }
                                    property bool isSearchHighlighted: root.searchHighlightIndex === searchListIndex && root.searchHighlightIndex >= 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: root.globalSearchQuery.trim() !== "" ? root.s(54) : 0
                                    visible: root.globalSearchQuery.trim() !== ""; opacity: visible ? 1.0 : 0.0; clip: true
                                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                                    Behavior on opacity { NumberAnimation { duration: 200 } }

                                    Rectangle {
                                        anchors.fill: parent; radius: root.s(13)
                                        color: isSearchHighlighted ? root.surface1 : (kbResultMa.containsMouse ? root.surface1 : root.surface0)
                                        border.color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.surface1)
                                        border.width: isSearchHighlighted ? 2 : 1
                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                                        Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }

                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: root.s(11); spacing: root.s(11)
                                            Rectangle {
                                                width: root.s(32); height: root.s(32); radius: root.s(18)
                                                color: Qt.alpha(root.peach, 0.12)
                                                border.color: Qt.alpha(root.peach, 0.25); border.width: 1
                                                Text {
                                                    anchors.centerIn: parent; text: "󰌌"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(15)
                                                    color: root.peach
                                                }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: root.s(3)
                                                Row {
                                                    spacing: root.s(4)
                                                    Rectangle {
                                                        width: modsT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(18)
                                                        color: root.surface1
                                                        border.color: root.surface2; border.width: 1
                                                        visible: kbItem && kbItem.mods !== ""
                                                        Text {
                                                            id: modsT; anchors.centerIn: parent; text: kbItem ? kbItem.mods : ""
                                                            font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(8)
                                                            color: root.peach
                                                        }
                                                    }
                                                    Text {
                                                        text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                                                        color: root.overlay0
                                                        visible: kbItem && kbItem.mods !== "" && kbItem.key !== ""; anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                    Rectangle {
                                                        width: keyT.implicitWidth + root.s(8); height: root.s(18); radius: root.s(18)
                                                        color: root.surface1
                                                        border.color: root.surface2; border.width: 1
                                                        visible: kbItem && kbItem.key !== ""
                                                        Text {
                                                            id: keyT; anchors.centerIn: parent; text: kbItem ? kbItem.key : ""
                                                            font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(8)
                                                            color: root.peach
                                                        }
                                                    }
                                                }
                                                Text {
                                                    text: kbItem ? (kbItem.dispatcher + " " + kbItem.command).trim() : ""
                                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                                                    color: isSearchHighlighted ? root.peach : Qt.alpha(root.subtext0, 0.7)
                                                    elide: Text.ElideRight; Layout.fillWidth: true
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                            }
                                            Rectangle {
                                                height: root.s(20); width: kbBadgeText.implicitWidth + root.s(12); radius: root.s(13)
                                                color: Qt.alpha(root.peach, 0.12)
                                                border.color: Qt.alpha(root.peach, 0.35); border.width: 1
                                                Text {
                                                    id: kbBadgeText; anchors.centerIn: parent; text: "Keybinds"
                                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(9)
                                                    color: root.peach
                                                }
                                            }
                                            Text {
                                                text: "›"; font.family: "Inter"; font.pixelSize: root.s(18)
                                                color: isSearchHighlighted ? root.peach : (kbResultMa.containsMouse ? root.peach : root.subtext0)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                        MouseArea {
                                            id: kbResultMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                jumpToSettingTimer.targetTab = 2;
                                                jumpToSettingTimer.targetBox = kbIndex;
                                                jumpToSettingTimer.start();
                                                root.currentTab = 2;
                                                root.tab2Loaded = true;
                                                root.isSearchMode = false;
                                                root.forceActiveFocus();
                                                globalSearchInput.text = "";
                                                root.globalSearchQuery = "";
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Loader {
                        id: generalLoader
                        anchors.fill: parent
                        active: root.tab0Loaded && Config.dataReady
                        source: "tabs/GeneralTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 0 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        function focusLangInput() { if (item) item.focusLangInput(); }
                        function focusWpDirInput() { if (item) item.focusWpDirInput(); }
                        function layoutListIncrementIndex() { if (item) item.layoutListIncrementIndex(); }
                        function layoutListDecrementIndex() { if (item) item.layoutListDecrementIndex(); }
                        function acceptLayoutSelection() { if (item) item.acceptLayoutSelection(); }
                        function scrollTo(y) { if (item) item.scrollTo(y); }
                        function scrollToBox(y) { if (item) item.scrollToBox(y); }
                    }

                    Loader {
                        id: weatherLoader
                        anchors.fill: parent
                        active: root.tab1Loaded && Config.dataReady
                        source: "tabs/WeatherTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 1 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        function focusApiKey() { if (item) item.focusApiKey(); }
                        function focusCityId() { if (item) item.focusCityId(); }
                        function scrollTo(y) { if (item) item.scrollTo(y); }
                        function scrollToBox(y) { if (item) item.scrollToBox(y); }
                    }

                    Loader {
                        id: keybindLoader
                        anchors.fill: parent
                        active: root.tab2Loaded && Config.dataReady
                        source: "tabs/KeybindTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 2 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        function scrollToBottom() { if (item) item.scrollToBottom(); }
                        function scrollTo(y) { if (item) item.scrollTo(y); }
                        function scrollToBox(y) { if (item) item.scrollToBox(y); }
                    }

                    Loader {
                        id: startupLoader
                        anchors.fill: parent
                        active: root.tab4Loaded && Config.dataReady
                        source: "tabs/StartupTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 4 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        function scrollToBottom() { if (item) item.scrollToBottom(); }
                        function scrollTo(y) { if (item) item.scrollTo(y); }
                        function scrollToBox(y) { if (item) item.scrollToBox(y); }
                    }

                    Loader {
                        id: topbarLoader
                        anchors.fill: parent
                        active: root.tab5Loaded && Config.dataReady
                        source: "tabs/TopbarTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 5 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        function scrollTo(y) { if (item) item.scrollTo(y); }
                        function scrollToBox(y) { if (item) item.scrollToBox(y); }
                    }

                    Loader {
                        id: monitorsLoader
                        anchors.fill: parent
                        active: root.tab3Loaded
                        source: "tabs/MonitorsTab.qml"
                        onLoaded: item.host = root
                        visible: root.currentTab === 3 && !root.isSearchMode
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                    }
                }
            }
        }
    }
}

