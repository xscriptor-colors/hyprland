import QtQuick
import Quickshell
import "../../dock"

// ============================================================================
// Weather — accent island with the current conditions.
//
// Data comes from the dock's shared weather watcher (dock/Dock.qml poller on
// calendar/weather.sh): bar.weatherIcon (Nerd glyph), bar.weatherTemp
// ("12°"), bar.weatherHex ("#rrggbb"). While the first fetch is still
// pending (weatherTemp === "--°") the island shows only the glyph so it never
// looks broken on boot. Click opens the full calendar/weather popup.
//
// Compact (vertical dock): glyph and temperature stack in a column.
// ============================================================================

ModulePill {
    id: mod

    accentRole: "yellow"
    accentActive: true
    // The weather color override arrives as a hex string; convert it so the
    // island fill follows the weather code (sun/rain/...), falling back to
    // yellow (the accentRole) before the first poll completes.
    property color weatherColor: {
        let h = String(bar.weatherHex || "");
        if (/^#[0-9a-fA-F]{6}$/.test(h)) return h;
        return "transparent";
    }
    accentColor: weatherColor
    readonly property bool hasData: bar.weatherTemp !== "--°" && bar.weatherTemp !== ""

    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])

    // --- horizontal: glyph + temperature -------------------------------------
    Row {
        visible: mod.horizontal
        spacing: bar.s(8)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.weatherIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.s(18)
            color: mod.contentColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.weatherTemp
            visible: mod.hasData
            font.family: bar.fontFamily
            font.pixelSize: bar.s(13)
            font.weight: Font.Black
            color: mod.contentColor
        }
    }

    // --- compact: glyph over temperature -------------------------------------
    Column {
        visible: mod.compact
        spacing: -2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: bar.weatherIcon
            font.family: bar.fontFamily
            font.pixelSize: bar.s(20)
            color: mod.contentColor
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: mod.hasData ? bar.weatherTemp : "--"
            font.family: bar.fontFamily
            font.pixelSize: bar.s(9)
            font.weight: Font.Black
            color: mod.contentColor
        }
    }
}
