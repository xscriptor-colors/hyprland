// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui — DavincixPicker
//
// The wallpaper picker root. It owns the STATE and LOGIC (models, filters,
// focus, search/apply orchestration) and composes the view components:
//   - components/grid/DavincixGrid  → the thumbnail ListView + card delegate
//   - components/filter/DavincixFilterBar → top bar (status, monitors, controls,
//     color chips, search)
// Pure helpers live in lib/ (constants.js, color.js) and the headless engine
// in ../kernel/. Components receive the picker root as `ctx` plus the Colors
// instance as `theme`.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import Qt.labs.folderlistmodel
import QtMultimedia
import Quickshell
import Quickshell.Io
import "../../"
import "../../dock"
import "lib/constants.js" as C
import "components/grid"
import "components/filter"
import "lib/color.js" as Color

Item {
    id: window
    width: Screen.width

    Caching { id: paths }

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }

    function s(val) {
        return scaler.s(val);
    }

    Colors { id: _theme }

    property string widgetArg: ""
    property string targetWallName: ""
    property bool initialFocusSet: false
    property int visibleItemCount: -1
    property int scrollAccum: 0
    property real scrollThreshold: window.s(300)

    property string currentFilter: "All"
    property string _lastFilter: "All"
    property string searchQuery: ""
    property bool isOnlineSearch: false
    property bool isSearchPaused: false
    property bool hasSearched: false
    property var colorMap: ({})
    property int cacheVersion: 0

    property bool isDownloadingWallpaper: false
    property string currentDownloadName: ""

    property bool isApplying: false
    property bool isMonitorSelectorOpen: false
    // Set by the search component while its TextInput has focus (Return shortcut).
    property bool searchInputFocused: false

    // Separate flag so add-animations fire on new arrivals
    // even before the first focus snap has happened
    property bool allowAddAnimation: false

    Timer {
        id: applyUnlockTimer
        interval: 250
        onTriggered: window.isApplying = false
    }

    property bool isStartup: localFolderModel.status === FolderListModel.Loading || srcModel.status === FolderListModel.Loading
    property bool isReady: visible && localFolderModel.status === FolderListModel.Ready
    property bool isSearchActive: window.currentFilter === "Search" && window.hasSearched && searchFolderModel.status === FolderListModel.Loading

    property string lastSearchName: ""
    property bool isModelChanging: false
    property bool searchIndexRestored: false

    property bool isScrollingBlocked: window.currentFilter === "Search" && window.hasSearched && window.isSearchActive && !window.isSearchPaused
    property bool jumpToLastOnFilterChange: false

    readonly property var filterData: C.FILTERS
    readonly property var transitions: C.TRANSITIONS

    ListModel { id: monitorModel }

    Process {
        id: monitorProc
        command: ["sh", "-c", "export PATH=$PATH:/usr/bin:/usr/local/bin:/run/current-system/sw/bin && hyprctl monitors -j"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let response = this.text;

                if (response && response.trim().length > 0) {
                    try {
                        var monitors = JSON.parse(response);
                        monitorModel.clear();
                        for (var i = 0; i < monitors.length; i++) {
                            monitorModel.append({ "name": monitors[i].name, "selected": true });
                        }
                    } catch (e) {}
                }
            }
        }
    }

    function loadMonitors() {
        monitorProc.running = true;
    }

    function getMonitorOutputs() {
        if (monitorModel.count <= 1) return "all";

        let selected = [];
        for (let i = 0; i < monitorModel.count; i++) {
            if (monitorModel.get(i).selected) {
                selected.push(monitorModel.get(i).name);
            }
        }

        if (selected.length === 0) return "none";
        if (selected.length === monitorModel.count) return "all";

        return selected.join(",");
    }

    // Apply a wallpaper through the davincix CLI (kernel layer): the UI
    // decides WHAT to apply; download/convert/cache/apply live in kernel/.
    function applyWallpaper(safeFileName, isVideo) {
        if (!safeFileName || window.isApplying) return;

        let outputs = window.getMonitorOutputs();
        if (outputs === "none") return;

        window.isApplying = true;
        applyUnlockTimer.restart();
        window.targetWallName = safeFileName;

        let cli = decodeURIComponent(Qt.resolvedUrl("../kernel/davincix.sh").toString().replace(/^file:\/\//, ""));
        let transition = window.transition;

        if (window.currentFilter === "Search" && window.hasSearched) {
            let destFile = window.srcDir + "/" + safeFileName;
            let finalThumb = decodeURIComponent(window.thumbDir.replace("file://", "")) + "/" + safeFileName;

            if (window.isDownloaded(safeFileName)) {
                Quickshell.execDetached([cli, "set", destFile,
                                         "--monitors", outputs,
                                         "--transition", transition,
                                         "--notify"]);
            } else {
                window.isDownloadingWallpaper = true;
                window.currentDownloadName = safeFileName;
                let tempThumb = decodeURIComponent(window.searchDir.replace("file://", "")) + "/" + safeFileName;
                let mapFile = paths.getCacheDir("wallpaper_picker") + "/search_map.txt";
                Quickshell.execDetached([cli, "fetch",
                                         "--name", safeFileName,
                                         "--map", mapFile,
                                         "--dest", destFile,
                                         "--thumb-in", tempThumb,
                                         "--thumb-out", finalThumb,
                                         "--monitors", outputs,
                                         "--transition", transition]);
            }
            return;
        }

        let originalFile = window.srcDir + "/" + window.getCleanName(safeFileName);
        let thumbFile = paths.getCacheDir("wallpaper_picker") + "/thumbs/" + safeFileName;
        let args = [cli, "set", originalFile,
                    "--monitors", outputs,
                    "--transition", transition];
        if (isVideo) args.push("--video", "--thumb", thumbFile);
        Quickshell.execDetached(args);
    }

    Settings {
        id: searchState
        category: "QS_Davincix"
        property string query: ""
        property bool searched: false
        property string lastName: ""
    }

    onIsSearchPausedChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + (isSearchPaused ? "pause" : "run") + "' > " + paths.getRunDir("wallpaper_picker") + "/ddg_search_control"]);
    }

    onVisibleChanged: {
        if (!visible) {
            window.initialFocusSet = false;
            window.allowAddAnimation = false;
            window.searchIndexRestored = false;
            window.isApplying = false;
            window.isMonitorSelectorOpen = false;

            if (window.hasSearched) {
                window.isSearchPaused = true;
            }
        } else {
            window.isFilterAnimating = true;
            filterAnimationTimer.restart();

            if (window.currentFilter !== "Search") {
                window.applyFilters(true);
            } else if (window.hasSearched) {
                window.searchIndexRestored = false;
                window.isSearchPaused = true;
                window.trySearchFocus();
                window.syncSearchModel();
            }
        }
    }

    property bool isLoading: localFolderModel.status === FolderListModel.Loading ||
                             srcModel.status === FolderListModel.Loading ||
                             (window.currentFilter === "Search" && searchFolderModel.status === FolderListModel.Loading)

    property bool showSpinner: window.isDownloadingWallpaper ||
                               (window.currentFilter === "Search" && window.hasSearched && !window.isSearchPaused) ||
                               (window.currentFilter !== "Search" && window.isLoading)

    property string currentNotification: {
        if (window.isDownloadingWallpaper) return "Downloading wallpaper...";

        if (window.currentFilter === "Search") {
            if (!window.hasSearched) return "Type something to search...";
            if (window.isSearchPaused) return "Search Paused";
            if (window.visibleItemCount === 0) return "Searching DDG (FHD+)...";
            return "Generating thumbnails...";
        }

        if (isLoading) return "Generating thumbnails...";
        if (window.visibleItemCount === 0) return "No wallpapers found";

        if (window.currentFilter === "All") return "";
        if (window.currentFilter === "Video") return "Videos";

        return window.currentFilter;
    }

    property bool showNotification: !window.isStartup && currentNotification !== ""

    function getCleanName(name) {
        if (!name) return "";
        let clean = String(name);
        return clean.startsWith("000_") ? clean.substring(4) : clean;
    }

    function isDownloaded(name) {
        if (!name) return false;
        for (let i = 0; i < srcModel.count; i++) {
            if (srcModel.get(i, "fileName") === name) return true;
        }
        return false;
    }

    onWidgetArgChanged: {
        if (widgetArg !== "") {
            targetWallName = widgetArg;
            initialFocusSet = false;
            tryFocus();
        }
    }

    function executeFocusRestore(targetIndex, isSearchRestore, requirePositioning) {
        let targetModel = window.getModelForFilter(window.currentFilter);

        if (targetIndex !== -1 && targetIndex < targetModel.count) {
            window.isModelChanging = true;

            if (requirePositioning) {
                grid.view.forceLayout();
                grid.view.positionViewAtIndex(targetIndex, ListView.Center);
            }

            grid.view.currentIndex = targetIndex;

            if (isSearchRestore) {
                window.searchIndexRestored = true;
            }

            window.isModelChanging = false;
            window.initialFocusSet = true;

            // Allow add-animations for future incremental arrivals
            // Use a short delay so the initial snap itself isn't animated
            allowAddAnimationTimer.restart();
        } else if (isSearchRestore) {
            window.searchIndexRestored = true;
        }
    }

    Timer {
        id: allowAddAnimationTimer
        interval: 600
        onTriggered: window.allowAddAnimation = true
    }

    function tryFocus() {
        if (initialFocusSet) return;

        if (localProxyModel.count > 0) {
            let foundIndex = -1;
            let cleanTarget = window.getCleanName(targetWallName);

            if (cleanTarget !== "") {
                for (let i = 0; i < localProxyModel.count; i++) {
                    let fname = localProxyModel.get(i).fileName || "";
                    if (window.getCleanName(fname) === cleanTarget) {
                        foundIndex = i;
                        break;
                    }
                }
            }

            let finalIndex = foundIndex !== -1 ? foundIndex : 0;
            window.executeFocusRestore(finalIndex, false, true);
        }
    }

    function trySearchFocus() {
        if (window.searchIndexRestored || searchProxyModel.count === 0) return;

        if (window.lastSearchName === "") {
            window.searchIndexRestored = true;
            return;
        }

        for (let i = 0; i < searchProxyModel.count; i++) {
            let fname = searchProxyModel.get(i).fileName || "";
            if (fname === window.lastSearchName) {
                window.executeFocusRestore(i, true, true);
                return;
            }
        }

        if (searchFolderModel.status === FolderListModel.Ready && searchProxyModel.count === searchFolderModel.count) {
            window.searchIndexRestored = true;
        }
    }

    function getModelForFilter(filter) {
        return filter === "Search" ? searchProxyModel : localProxyModel;
    }

    function updateVisibleCount() {
        let targetModel = window.getModelForFilter(window.currentFilter);

        if (!targetModel || targetModel.count === 0) {
            window.visibleItemCount = 0;
            return;
        }
        let count = 0;
        for (let i = 0; i < targetModel.count; i++) {
            let fname = targetModel.get(i).fileName || "";
            let isVid = fname.startsWith("000_");
            if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                count++;
            }
        }
        window.visibleItemCount = count;
    }

    // Start a DuckDuckGo search (called by the search component on submit).
    function submitSearch(query) {
        window.isModelChanging = true;
        searchProxyModel.clear();
        window.lastSearchName = "";
        searchState.lastName = "";

        if (window.currentFilter === "Search") {
            grid.view.currentIndex = 0;
            grid.view.positionViewAtIndex(0, ListView.Center);
        }
        window.isModelChanging = false;

        window.searchIndexRestored = true;
        window.isOnlineSearch = true;
        window.hasSearched = true;

        window.visibleItemCount = 0;

        searchState.searched = true;
        searchState.query = query;

        window.isSearchPaused = false;
        window.searchQuery = query;

        // The CLI stops the previous search, clears its cache and starts the new one.
        let cli = decodeURIComponent(Qt.resolvedUrl("../kernel/davincix.sh").toString().replace(/^file:\/\//, ""));
        Quickshell.execDetached([cli, "search", window.searchQuery]);
    }

    readonly property string homeDir: "file://" + Quickshell.env("HOME")
    readonly property string thumbDir: "file://" + paths.getCacheDir("wallpaper_picker") + "/thumbs"
    readonly property string searchDir: "file://" + paths.getCacheDir("wallpaper_picker") + "/search_thumbs"
    readonly property string srcDir: Config.wallpaperDir

    // User-selected transition (cycles via the header button; "random" picks one).
    property string transition: "random"
    // Thumbnail corners: rounded vs square.
    property bool roundedThumbs: true
    property int thumbRadius: roundedThumbs ? window.s(12) : 0

    readonly property real itemWidth: window.s(400)
    readonly property real itemHeight: window.s(420)
    readonly property real borderWidth: window.s(3)
    readonly property real spacing: window.s(10)
    readonly property real skewFactor: -0.35

    Timer {
        id: scrollThrottle
        interval: 150
    }

    property bool isFilterAnimating: false
    Timer {
        id: filterAnimationTimer
        interval: 800
        onTriggered: window.isFilterAnimating = false
    }

    property bool isItemAnimating: false
    Timer {
        id: itemAnimationTimer
        interval: 500
        onTriggered: window.isItemAnimating = false
    }

    function checkItemMatchesFilter(fileName, isVid, cv, filter) {
        if (filter === "Search") return true;
        if (filter === "All") return true;
        if (filter === "Video") return isVid;

        let hexColor = window.colorMap[String(fileName)];
        if (!hexColor) return filter === "Monochrome";

        return Color.hexBucket(hexColor) === filter;
    }

    FolderListModel {
        id: markerModel
        folder: "file://" + paths.getCacheDir("wallpaper_picker") + "/colors_markers"
        showDirs: false
        nameFilters: ["*_HEX_*"]

        onCountChanged: window.processMarkers()
        onStatusChanged: {
            if (status === FolderListModel.Ready) window.processMarkers()
        }
    }

    FolderListModel {
        id: srcModel
        folder: "file://" + window.srcDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
        showDirs: false

        onCountChanged: {
            if (window.isDownloadingWallpaper && window.isDownloaded(window.currentDownloadName)) {
                window.isDownloadingWallpaper = false;
            }
        }
    }

    function processMarkers() {
        let newMap = {};
        for (let i = 0; i < markerModel.count; i++) {
            let markerName = markerModel.get(i, "fileName") || "";
            if (!markerName) continue;

            let splitIdx = markerName.lastIndexOf("_HEX_");
            if (splitIdx !== -1) {
                let fName = markerName.substring(0, splitIdx);
                let hexCode = markerName.substring(splitIdx + 5);
                newMap[fName] = "#" + hexCode;
            }
        }
        window.colorMap = newMap;
        window.cacheVersion++;
        window.updateVisibleCount();
    }

    function triggerColorExtraction() {
        const extractScript = `
            COLOR_DIR="${paths.getCacheDir('wallpaper_picker')}/colors_markers"
            THUMBS="${paths.getCacheDir('wallpaper_picker')}/thumbs"
            CSV="${paths.getCacheDir('wallpaper_picker')}/colors.csv"

            mkdir -p "$COLOR_DIR"

            if [ -f "$CSV" ]; then
                while IFS=, read -r fname hexcode; do
                    cleanhex=$(echo "$hexcode" | tr -d '\r#' | cut -c 1-6)
                    if [ -n "$cleanhex" ] && [ -n "$fname" ]; then
                        touch "$COLOR_DIR/$fname""_HEX_$cleanhex" 2>/dev/null
                    fi
                done < "$CSV"
                mv "$CSV" "$CSV.bak" 2>/dev/null
            fi

            if command -v magick &> /dev/null; then CMD="magick"; else CMD="convert"; fi

            for file in "$THUMBS"/*; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file")
                    found=0
                    for marker in "$COLOR_DIR/$filename"_HEX_*; do
                        if [ -e "$marker" ]; then found=1; break; fi
                    done

                    if [ $found -eq 0 ]; then
                        hex=$($CMD "$file" -modulate 100,200 -resize "1x1^" -gravity center -extent 1x1 -depth 8 -format "%[hex:p{0,0}]" info:- 2>/dev/null | grep -oE '[0-9A-Fa-f]{6}' | head -n 1)
                        if [ -n "$hex" ]; then
                            touch "$COLOR_DIR/$filename""_HEX_$hex"
                        fi
                    fi
                fi
            done
        `;
        Quickshell.execDetached(["bash", "-c", extractScript]);
    }

    function stepToNextValidIndex(direction) {
        let targetModel = window.getModelForFilter(window.currentFilter);
        if (!targetModel || targetModel.count === 0) return;

        let start = grid.view.currentIndex;
        let found = -1;

        if (direction === 1) {
            for (let i = start + 1; i < targetModel.count; i++) {
                let fname = targetModel.get(i).fileName || "";
                let isVid = fname.startsWith("000_");
                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                    found = i; break;
                }
            }
        } else {
            for (let i = start - 1; i >= 0; i--) {
                let fname = targetModel.get(i).fileName || "";
                let isVid = fname.startsWith("000_");
                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                    found = i; break;
                }
            }
        }

        if (found !== -1) {
            grid.view.currentIndex = found;
            return;
        }

        let currentFilterIdx = C.FILTER_ORDER.indexOf(window.currentFilter);

        if (currentFilterIdx === -1) {
            let current = start;
            for (let i = 0; i < targetModel.count; i++) {
                current = (current + direction + targetModel.count) % targetModel.count;
                let fname = targetModel.get(current).fileName || "";
                let isVid = fname.startsWith("000_");

                if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                    grid.view.currentIndex = current;
                    return;
                }
            }
            return;
        }

        let nextFilterIdx = currentFilterIdx + direction;

        if (nextFilterIdx >= 0 && nextFilterIdx < C.FILTER_ORDER.length) {
            window.jumpToLastOnFilterChange = (direction === -1);
            window.currentFilter = C.FILTER_ORDER[nextFilterIdx];
        }
    }

    function cycleFilter(direction) {
        let currentIdx = -1;
        for (let i = 0; i < window.filterData.length; i++) {
            if (window.filterData[i].name === window.currentFilter) {
                currentIdx = i;
                break;
            }
        }

        if (currentIdx !== -1) {
            let nextIdx = (currentIdx + direction + window.filterData.length) % window.filterData.length;
            window.currentFilter = window.filterData[nextIdx].name;
        }
    }

    function applyFilters(forceSnap) {
        let targetModel = window.getModelForFilter(window.currentFilter);

        if (!targetModel || targetModel.count === 0) {
            window.updateVisibleCount();
            return;
        }

        if (window.currentFilter === "Search") {
            window.updateVisibleCount();
            return;
        }

        let firstValidIndex = -1;
        let lastValidIndex = -1;
        let cleanTarget = window.getCleanName(window.targetWallName);
        let targetIndex = -1;

        for (let i = 0; i < targetModel.count; i++) {
            let fname = targetModel.get(i).fileName || "";
            let isVid = fname.startsWith("000_");

            if (checkItemMatchesFilter(fname, isVid, window.cacheVersion, window.currentFilter)) {
                if (firstValidIndex === -1) {
                    firstValidIndex = i;
                }
                lastValidIndex = i;

                if (cleanTarget !== "" && window.getCleanName(fname) === cleanTarget) {
                    targetIndex = i;
                }
            }
        }

        let indexToFocus = -1;

        if (targetIndex !== -1) {
            indexToFocus = targetIndex;
        } else if (window.jumpToLastOnFilterChange && lastValidIndex !== -1) {
            indexToFocus = lastValidIndex;
        } else if (firstValidIndex !== -1) {
            indexToFocus = firstValidIndex;
        }

        window.jumpToLastOnFilterChange = false;

        if (indexToFocus !== -1) {
            window.executeFocusRestore(indexToFocus, false, forceSnap === true);
        }

        window.updateVisibleCount();
    }

    onCurrentFilterChanged: {
        window.isFilterAnimating = true;
        filterAnimationTimer.restart();
        window.isModelChanging = true;
        let returningFromSearch = (window._lastFilter === "Search" && window.currentFilter !== "Search");
        window._lastFilter = window.currentFilter;

        if (returningFromSearch) {
            window.searchIndexRestored = false;
        }

        Qt.callLater(() => {
            grid.view.forceActiveFocus();

            if (window.currentFilter === "Search") {
                if (window.hasSearched) {
                    window.searchIndexRestored = false;
                    window.trySearchFocus();
                }
            } else {
                window.applyFilters(returningFromSearch);
            }
            window.isModelChanging = false;
        });
    }

    Shortcut {
        sequence: "Left"
        enabled: !window.isScrollingBlocked && !window.isApplying
        onActivated: window.stepToNextValidIndex(-1)
    }
    Shortcut {
        sequence: "Right"
        enabled: !window.isScrollingBlocked && !window.isApplying
        onActivated: window.stepToNextValidIndex(1)
    }

    Shortcut {
        sequence: "Return"
        enabled: !window.searchInputFocused && !window.isScrollingBlocked && !window.isApplying
        onActivated: {
            let targetModel = window.getModelForFilter(window.currentFilter);
            if (grid.view.currentIndex >= 0 && grid.view.currentIndex < targetModel.count) {
                let fname = targetModel.get(grid.view.currentIndex).fileName;
                if (fname) {
                    let isVid = String(fname).startsWith("000_");
                    window.applyWallpaper(String(fname), isVid);
                }
            }
        }
    }

    Shortcut { sequence: "Escape"; enabled: !window.isApplying; onActivated: { if (window.currentFilter === "Search") { window.currentFilter = "All"; } } }
    Shortcut { sequence: "Tab"; enabled: !window.isApplying; onActivated: window.cycleFilter(1) }
    Shortcut { sequence: "Backtab"; enabled: !window.isApplying; onActivated: window.cycleFilter(-1) }

    ListModel { id: localProxyModel }
    ListModel { id: searchProxyModel }

    readonly property var activeModel: window.currentFilter === "Search" ? searchProxyModel : localProxyModel

    FolderListModel {
        id: localFolderModel
        folder: window.thumbDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
        showDirs: false
        sortField: FolderListModel.Name

        onCountChanged: window.syncLocalModel()
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncLocalModel() }
    }

    // Tracks the highest index we have already synced into localProxyModel
    // so we never re-scan items we already ingested.
    property int _localSyncedCount: 0

    function syncLocalModel() {
        let folderCount = localFolderModel.count;

        // If the folder shrank (files deleted), we need a full rebuild.
        if (folderCount < window._localSyncedCount) {
            let wasAllowing = window.allowAddAnimation;
            window.allowAddAnimation = false;
            window.isModelChanging = true;

            localProxyModel.clear();
            window._localSyncedCount = 0;

            window.isModelChanging = false;
            window.syncLocalModel();
            if (wasAllowing) allowAddAnimationTimer.restart();
            return;
        }

        // Incremental append — only new items
        if (folderCount > window._localSyncedCount) {
            let batch = [];
            for (let i = window._localSyncedCount; i < folderCount; i++) {
                let fn = localFolderModel.get(i, "fileName");
                let fu = localFolderModel.get(i, "fileUrl");
                if (fn !== undefined) {
                    batch.push({ "fileName": fn, "fileUrl": String(fu) });
                }
            }

            if (batch.length > 0) {
                localProxyModel.append(batch);
            }

            window._localSyncedCount = folderCount;
        }

        if (window.currentFilter !== "Search") window.updateVisibleCount();

        // First-time focus snap
        if (!window.initialFocusSet && window.currentFilter !== "Search" && localProxyModel.count > 0) {
            window.tryFocus();
        }
    }

    function syncSearchModel() {
        let startIdx = searchProxyModel.count;
        let endIdx = searchFolderModel.count;

        if (endIdx < startIdx) {
            window.isModelChanging = true;
            searchProxyModel.clear();
            startIdx = 0;
            window.isModelChanging = false;
        }

        let batch = [];
        for (let i = startIdx; i < endIdx; i++) {
            let fn = searchFolderModel.get(i, "fileName");
            let fu = searchFolderModel.get(i, "fileUrl");
            if (fn !== undefined) {
                batch.push({ "fileName": fn, "fileUrl": String(fu) });
            }
        }

        if (batch.length > 0) {
            searchProxyModel.append(batch);
        }

        if (window.currentFilter === "Search") window.updateVisibleCount();

        if (window.currentFilter === "Search" && window.hasSearched) {
            if (!window.searchIndexRestored) {
                window.trySearchFocus();
            }

            if (window.isScrollingBlocked && startIdx === 0 && searchProxyModel.count > 0 && window.lastSearchName === "") {
                grid.view.forceLayout();
                grid.view.currentIndex = 0;
                grid.view.positionViewAtIndex(0, ListView.Center);
            }
        }
    }

    FolderListModel {
        id: searchFolderModel
        folder: window.searchDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
        showDirs: false
        sortField: FolderListModel.Name

        onFolderChanged: {
            window.isModelChanging = true;
            searchProxyModel.clear()
            window.isModelChanging = false;
        }

        onCountChanged: window.syncSearchModel()
        onStatusChanged: { if (status === FolderListModel.Ready) window.syncSearchModel() }
    }

    // ── Grid delegates back into the root state (the ListView lives in the
    // grid component and exposes `view`). ────────────────────────────────────
    function gridIndexChanged() {
        window.isItemAnimating = true;
        itemAnimationTimer.restart();

        if (grid.view.model !== searchProxyModel || window.currentFilter !== "Search") return;

        if (!window.isModelChanging && window.hasSearched && window.searchIndexRestored) {
            let ci = grid.view.currentIndex;
            if (ci >= 0 && ci < searchProxyModel.count) {
                let fname = searchProxyModel.get(ci).fileName;
                if (fname !== undefined && fname !== "") {
                    window.lastSearchName = String(fname);
                    searchState.lastName = String(fname);
                }
            }
        }
    }

    function gridWheel(wheel) {
        if (window.isScrollingBlocked || window.isApplying) {
            wheel.accepted = true;
            return;
        }

        if (scrollThrottle.running) {
            wheel.accepted = true;
            return;
        }

        let dx = wheel.angleDelta.x;
        let dy = wheel.angleDelta.y;
        let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;

        scrollAccum += delta;

        if (Math.abs(scrollAccum) >= scrollThreshold) {
            window.stepToNextValidIndex(scrollAccum > 0 ? -1 : 1);
            scrollAccum = 0;
            scrollThrottle.start();
        }

        wheel.accepted = true;
    }

    function gridFocus() {
        grid.view.forceActiveFocus();
    }

    // ── View: grid + top filter bar ────────────────────────────────────────
    DavincixGrid {
        id: grid
        ctx: window
        theme: _theme
        anchors.fill: parent
    }

    DavincixFilterBar {
        id: filterBar
        ctx: window
        theme: _theme
        monitors: monitorModel
        settings: searchState
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "mkdir -p '" + decodeURIComponent(window.searchDir.replace("file://", "")) + "'"]);

        window.loadMonitors();

        grid.view.forceActiveFocus();
        window.processMarkers();
        window.triggerColorExtraction();
    }

    Component.onDestruction: {
        if (window.hasSearched) {
            Quickshell.execDetached(["bash", "-c", "echo 'pause' > " + paths.getRunDir("wallpaper_picker") + "/ddg_search_control"]);
        } else {
            let cli = decodeURIComponent(Qt.resolvedUrl("../kernel/davincix.sh").toString().replace(/^file:\/\//, ""));
            Quickshell.execDetached([cli, "stop"]);
        }
    }
}
