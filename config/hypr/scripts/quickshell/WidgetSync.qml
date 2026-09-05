pragma Singleton
import QtQuick

// ============================================================================
// WidgetSync — editing bus between the desktop-widget subsystem and the
// redactor (Phase W5).
//
// The whole shell runs in one process, so this singleton replaces the
// per-window IPC of serpantinum: the redactor (and any other caller) invokes
// these functions with a screen name, and WidgetSync fans the call out to the
// WidgetLoader registered for that screen. WidgetLoader instances
// self-register on Component.onCompleted (see widgets/WidgetLoader.qml).
//
// Public API (documented for the future redactor author):
//   redactorScreen : string  — safeMonitorName of the screen whose widgets
//                              are currently being redacted ("" = closed).
//   redactorOpen   : bool    — true while any redactor session is active.
//   redactorInfo   : var     — { screenName, widgets: [ { id, type, variant,
//                              x, y, w, h, opacity, rotation, imagePath } ] }
//                              refreshed after every change on the redacted
//                              screen ("" widgets array when closed).
//   widgetsChanged()         — signal emitted after any model mutation that
//                              changed the persisted layout of any screen.
//
// Functions (all take the raw screen name; matching tolerates sanitization):
//   registerLoader(loader) / unregisterLoader(loader)
//   addWidget(type, screenName)
//   removeWidget(id, screenName)
//   clearWidgets(screenName)
//   bringToFront(id, screenName)          — reorders so the window is on top
//   setVariant(id, variant, screenName)
//   setGeometry(id, x, y, w, h, screenName)
//   setOpacity(id, opacity, screenName)
//   setRotation(id, rotation, screenName)
//   setImagePath(id, imagePath, screenName)
//   setRedactMode(screenName, on)         — hides real windows while redacting
//   layoutForRedactor(screenName)         — JSON string of the layout list
//
// Screens WITHOUT a registered loader are ignored silently, which keeps the
// bus usable before loaders exist (e.g. during shell startup).
// ============================================================================

QtObject {
    id: sync

    property string redactorScreen: ""
    property bool redactorOpen: false
    property var loaders: []
    property var redactorInfo: ({ screenName: "", widgets: [] })

    signal widgetsChanged()

    // --- registration ---------------------------------------------------------
    function registerLoader(loader) {
        if (!loader) return;
        if (sync.loaders.indexOf(loader) !== -1) return;
        let arr = sync.loaders.slice();
        arr.push(loader);
        sync.loaders = arr;
    }

    function unregisterLoader(loader) {
        let idx = sync.loaders.indexOf(loader);
        if (idx === -1) return;
        let arr = sync.loaders.slice();
        arr.splice(idx, 1);
        sync.loaders = arr;
    }

    function matchesScreen(loader, screenName) {
        if (!loader || !screenName) return false;
        let safe = String(screenName).replace(/[^a-zA-Z0-9_-]/g, "_");
        return loader.safeMonitorName === safe
            || loader.safeMonitorName === screenName
            || (loader.monitorName === screenName);
    }

    // --- internal helpers -------------------------------------------------------
    function loaderFor(screenName) {
        for (let i = 0; i < sync.loaders.length; i++) {
            if (sync.matchesScreen(sync.loaders[i], screenName)) return sync.loaders[i];
        }
        return null;
    }

    // Rebuild redactorInfo from the loader of the redacted screen.
    function refreshRedactorInfo() {
        let loader = sync.redactorScreen ? sync.loaderFor(sync.redactorScreen) : null;
        sync.redactorInfo = loader ? loader.redactorInfo : { screenName: sync.redactorScreen, widgets: [] };
    }

    // Called by WidgetLoaders after any model mutation.
    function notifyWidgetsChanged() {
        sync.widgetsChanged();
        sync.refreshRedactorInfo();
    }

    // --- redactor mode -----------------------------------------------------------
    function setRedactMode(screenName, on) {
        let loader = sync.loaderFor(screenName);
        if (on) {
            sync.redactorScreen = loader ? loader.safeMonitorName : String(screenName).replace(/[^a-zA-Z0-9_-]/g, "_");
            sync.redactorOpen = true;
        } else {
            sync.redactorScreen = "";
            sync.redactorOpen = false;
        }
        if (loader) loader.opSetRedactMode(on);
        sync.refreshRedactorInfo();
    }

    // --- widget operations (delegated to the matching loader) ---------------------
    function addWidget(type, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opAddWidget(type);
    }

    function removeWidget(id, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opRemoveWidget(id);
    }

    function clearWidgets(screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opClearWidgets();
    }

    function bringToFront(id, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opBringToFront(id);
    }

    function setVariant(id, variant, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opSetVariant(id, variant);
    }

    function setGeometry(id, x, y, w, h, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opSetGeometry(id, x, y, w, h);
    }

    function setOpacity(id, opacity, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opSetOpacity(id, opacity);
    }

    function setRotation(id, rotation, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opSetRotation(id, rotation);
    }

    function setImagePath(id, imagePath, screenName) {
        let loader = sync.loaderFor(screenName);
        if (loader) loader.opSetImagePath(id, imagePath);
    }

    // JSON string of the current layout for the given screen ("" widgets if
    // no loader / no redaction — use redactorInfo for structured access).
    function layoutForRedactor(screenName) {
        let loader = sync.loaderFor(screenName || sync.redactorScreen);
        if (!loader) return "[]";
        return loader.layoutForRedactor();
    }
}
