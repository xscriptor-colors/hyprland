import QtQuick
import QtQuick.Layouts
import "../DockLayout.js" as DockLayout

// Per-zone editor card for the DockEditor. Height grows with content so the
// module chips never overlap the rows below. Width is managed by the parent
// layout (Layout.fillWidth) so it never fights the container.
//
// ── Editor module drag & drop (Phase D3) ────────────────────────────────────
// The DockEditor (this card's `bar`) coordinates ONE editor-wide drag session:
//   * ENABLED chips are draggable with the left button past a ~bar.s(10)
//     visual threshold; short presses stay clicks, so the chip toggle and the
//     ◀ ▶ buttons (which sit above this area) keep working untouched.
//   * While a chip drags, the editor paints a ghost at the pointer, this card
//     lights up as the drop target under the cursor (dndActive) and shows a
//     thin accent insertion bar (dndInsertIndex).
//   * Drop indices count ENABLED chips only and skip the dragged chip —
//     exactly the semantics DockLayout.moduleMoveTo() expects, so the engine
//     and the visuals always agree. Disabled chips (dimmed) are NOT draggable
//     and are never counted; they keep their fixed spots until enabled with a
//     click, then they can be dragged like any other chip.
//   * A card with zero chips is still a valid drop target (index 0).
//   * Dropping outside every card cancels the gesture.
// Contract with the DockEditor:
//   * bar.startDnd(zoneId, moduleId) / bar.updateDnd(px,py) /
//     bar.endDnd(px,py) / bar.cancelDnd() plus bar.dndBusy + bar.dndModuleId.
//   * The editor enumerates the cards through the Zones card's column children
//     (isZoneEditorCard marker) and feeds them root/editor coordinates via
//     containsRootPoint() / dropIndexAt().
// ============================================================================
Rectangle {
    id: zoneCard
    required property var bar
    required property var zoneData
    required property int zoneIndex

    // Marker used by the editor to enumerate zone cards (like Zone.isDockZone).
    property bool isZoneEditorCard: true
    // Zone id the editor passes to DockLayout.moduleMoveTo on drop.
    readonly property string cardZoneId: zoneData.id

    height: contentCol.implicitHeight + bar.s(20)
    radius: bar.s(16)
    color: bar.colors.surface0
    border.width: bar.s(1); border.color: bar.colors.surface1

    // ---- DnD target state (owned by the editor while a chip drags) ----
    property bool dndActive: false
    property int dndInsertIndex: -1

    function patch(fn) { bar.applyDock(fn(bar.dock)); }

    // Is a point in editor-root coordinates inside this card?
    function containsRootPoint(mx, my) {
        let p = zoneCard.mapFromItem(zoneCard.bar, mx, my);
        return p.x >= 0 && p.y >= 0 && p.x <= zoneCard.width && p.y <= zoneCard.height;
    }

    // Enabled chips of this zone in linear (visual) order, excluding the chip
    // currently being dragged — the universe drop indices are counted over.
    function dropChips() {
        let kids = chipsFlow.children;
        let out = [];
        let dragged = zoneCard.bar ? zoneCard.bar.dndModuleId : "";
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (!c || !c.isModuleChip) continue;
            if (c.chipModuleId === dragged) continue;
            if (!c.chipEnabled) continue;
            out.push(c);
        }
        return out;
    }

    // Drop index for a pointer in editor-root coordinates: -1 outside the card,
    // otherwise 0..enabledCount. Flow rows are scanlined: the pointer's row is
    // found by vertical band, then chips of that row whose center lies left of
    // the pointer count. Empty zones always answer 0 (valid target).
    function dropIndexAt(mx, my) {
        if (!zoneCard.containsRootPoint(mx, my)) return -1;
        let chips = zoneCard.dropChips();
        if (chips.length === 0) return 0;
        let f = chipsFlow.mapFromItem(zoneCard.bar, mx, my);
        let rows = [];
        for (let i = 0; i < chips.length; i++) {
            let c = chips[i];
            if (rows.length > 0 && rows[rows.length - 1].y === c.y) rows[rows.length - 1].chips.push(c);
            else rows.push({ y: c.y, chips: [c] });
        }
        let spacing = chipsFlow.spacing;
        let before = 0;
        for (let r = 0; r < rows.length; r++) {
            let row = rows[r];
            let bandTop = row.y - spacing / 2;
            let bandBot = row.y + row.chips[0].height + spacing / 2;
            if (f.y < bandTop) return before;
            if (f.y <= bandBot) {
                let count = 0;
                for (let i = 0; i < row.chips.length; i++) {
                    let c = row.chips[i];
                    if (f.x > c.x + c.width / 2) count++;
                    else break;
                }
                return before + count;
            }
            before += row.chips.length;
        }
        return before;
    }

    // Card-local geometry of the insertion indicator for dndInsertIndex.
    function insertionGeometry() {
        let chips = zoneCard.dropChips();
        let spacing = chipsFlow.spacing;
        if (chips.length === 0) {
            let p0 = chipsFlow.mapToItem(zoneCard, 0, 0);
            return { x: p0.x + bar.s(1), y: p0.y + bar.s(2), height: bar.s(26) };
        }
        let idx = Math.max(0, Math.min(zoneCard.dndInsertIndex, chips.length));
        if (idx < chips.length) {
            let c = chips[idx];
            let p = c.mapToItem(zoneCard, 0, 0);
            return { x: p.x - spacing / 2, y: p.y, height: c.height };
        }
        let last = chips[chips.length - 1];
        let pend = last.mapToItem(zoneCard, last.width, 0);
        return { x: pend.x + spacing / 2, y: pend.y, height: last.height };
    }

    function updateInsertBar() {
        if (!zoneCard.dndActive || zoneCard.dndInsertIndex < 0) {
            insertBar.visible = false;
            return;
        }
        let g = zoneCard.insertionGeometry();
        insertBar.visible = true;
        insertBar.x = g.x;
        insertBar.y = g.y;
        insertBar.height = g.height;
    }
    onDndActiveChanged: zoneCard.updateInsertBar()
    onDndInsertIndexChanged: zoneCard.updateInsertBar()

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        anchors.margins: bar.s(10)
        spacing: bar.s(6)

        // header: id + align + unify + delete
        RowLayout {
            Layout.fillWidth: true
            spacing: bar.s(8)

            Text {
                text: "◈ " + zoneData.id
                font.family: "Hack Nerd Font"
                font.pixelSize: bar.s(13)
                font.weight: Font.Black
                color: bar.colors.text
            }
            EditPill { bar: zoneCard.bar; modelData: "start"; text: "Start"; active: zoneData.align === "start"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "start")) }
            EditPill { bar: zoneCard.bar; modelData: "center"; text: "Center"; active: zoneData.align === "center"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "center")) }
            EditPill { bar: zoneCard.bar; modelData: "end"; text: "End"; active: zoneData.align === "end"; onActivated: patch(d => DockLayout.setZoneAlign(d, zoneData.id, "end")) }
            Item { Layout.fillWidth: true; height: 1 }
            EditLabel { bar: zoneCard.bar; text: "Unify" }
            ToggleSwitch { bar: zoneCard.bar; checked: zoneData.unify === true; onToggled: patch(d => DockLayout.setZoneUnify(d, zoneData.id, !zoneData.unify)) }
            Rectangle {
                width: bar.s(28); height: bar.s(28); radius: bar.s(8)
                color: bar.colors.red
                Text { anchors.centerIn: parent; text: ""; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(14); color: bar.colors.base }
                MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.removeZone(d, zoneData.id)) }
            }
        }

        // zone border
        RowLayout {
            Layout.fillWidth: true
            spacing: bar.s(8)

            EditLabel { bar: zoneCard.bar; text: "Zone border" }
            Item { Layout.fillWidth: true; height: 1 }
            Stepper {
                bar: zoneCard.bar
                label: Math.round(zoneData.borderWidth || 0) + "px"
                onDec: patch(d => DockLayout.setZoneBorder(d, zoneData.id, Math.max(0, (zoneData.borderWidth || 0) - 1)))
                onInc: patch(d => DockLayout.setZoneBorder(d, zoneData.id, Math.min(8, (zoneData.borderWidth || 0) + 1)))
            }
            ColorCycle {
                bar: zoneCard.bar
                role: zoneData.borderColor || "surface1"
                onCycled: (role) => patch(d => DockLayout.setZoneBorder(d, zoneData.id, zoneData.borderWidth || 0, role))
            }
        }

        Rectangle { Layout.fillWidth: true; height: bar.s(1); color: bar.colors.surface1; opacity: 0.4 }

        // module chips (wrap; card grows). One chip per zoneData.modules entry
        // (disabled entries are dimmed). See the DnD contract in the header.
        Flow {
            id: chipsFlow
            Layout.fillWidth: true
            spacing: bar.s(5)
            Repeater {
                model: zoneData.modules
                delegate: Rectangle {
                    id: chipRoot
                    required property var modelData
                    required property int index
                    readonly property var mod: DockLayout.getModule(modelData.id)

                    // Chip markers the card DnD logic enumerates over.
                    property bool isModuleChip: true
                    readonly property string chipModuleId: modelData.id
                    readonly property bool chipEnabled: modelData.enabled !== false

                    width: chipRow.implicitWidth + bar.s(42)
                    height: bar.s(30)
                    radius: bar.s(8)
                    color: bar.colors.surface1
                    // Dim the chip being dragged so the ghost reads clearly.
                    opacity: (modelData.enabled === false ? 0.4 : 1.0)
                             * ((bar.dndBusy && bar.dndModuleId === modelData.id) ? 0.35 : 1.0)
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    Row {
                        id: chipRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: bar.s(6)
                        spacing: bar.s(5)
                        Text { text: mod ? mod.icon : "?"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(12); color: bar.colors.text }
                        Text { text: mod ? mod.label : modelData.id; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(11); color: bar.colors.text }
                    }
                    // Chip click (toggle) + editor drag & drop (Phase D3).
                    // Short presses toggle; movements past ~s(10) px start a
                    // drag session owned by the DockEditor (bar.startDnd…).
                    MouseArea {
                        id: chipDrag
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        property point pressPos: Qt.point(0, 0)
                        property bool dragOccurred: false
                        onPressed: mouse => {
                            pressPos = Qt.point(mouse.x, mouse.y);
                            dragOccurred = false;
                        }
                        onPositionChanged: mouse => {
                            if (!chipDrag.pressed) return;
                            if (chipDrag.dragOccurred) {
                                // Session running: feed the editor pointer moves.
                                if (zoneCard.bar.dndBusy) {
                                    let p = chipRoot.mapToItem(zoneCard.bar, mouse.x, mouse.y);
                                    zoneCard.bar.updateDnd(p.x, p.y);
                                }
                                return;
                            }
                            // Only ENABLED chips drag; disabled chips keep the
                            // click-to-enable behavior only.
                            if (!chipRoot.chipEnabled) return;
                            let dx = mouse.x - chipDrag.pressPos.x;
                            let dy = mouse.y - chipDrag.pressPos.y;
                            if (Math.sqrt(dx * dx + dy * dy) < bar.s(10)) return;
                            chipDrag.dragOccurred = true;
                            zoneCard.bar.startDnd(zoneCard.cardZoneId, chipRoot.chipModuleId);
                            if (!zoneCard.bar.dndBusy) {
                                chipDrag.dragOccurred = false;
                                return;
                            }
                            let p = chipRoot.mapToItem(zoneCard.bar, mouse.x, mouse.y);
                            zoneCard.bar.updateDnd(p.x, p.y);
                        }
                        onReleased: mouse => {
                            if (chipDrag.dragOccurred && zoneCard.bar.dndBusy) {
                                let p = chipRoot.mapToItem(zoneCard.bar, mouse.x, mouse.y);
                                zoneCard.bar.endDnd(p.x, p.y);
                            }
                            // dragOccurred stays set for this gesture so the
                            // trailing clicked() (release over the source chip)
                            // never toggles the module after a drag.
                        }
                        onCanceled: {
                            if (chipDrag.dragOccurred && zoneCard.bar.dndBusy) zoneCard.bar.cancelDnd();
                        }
                        onClicked: {
                            if (!chipDrag.dragOccurred) patch(d => DockLayout.toggleEnabled(d, chipRoot.chipModuleId));
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: bar.s(2)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.s(2)
                        Rectangle {
                            width: bar.s(18); height: bar.s(18); radius: bar.s(4)
                            color: bar.colors.surface1
                            Text { anchors.centerIn: parent; text: "◀"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, -1)) }
                        }
                        Rectangle {
                            width: bar.s(18); height: bar.s(18); radius: bar.s(4)
                            color: bar.colors.surface1
                            Text { anchors.centerIn: parent; text: "▶"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(10); color: bar.colors.text }
                            MouseArea { anchors.fill: parent; onClicked: patch(d => DockLayout.moduleMove(d, modelData.id, 1)) }
                        }
                    }
                }
            }
        }
    }

    // Drop-target highlight (accent border) while the pointer hovers this card
    // during a chip drag. Pure visuals: never grabs the mouse.
    Rectangle {
        id: dropHighlight
        anchors.fill: parent
        anchors.margins: bar.s(1)
        radius: bar.s(15)
        visible: zoneCard.dndActive
        color: "transparent"
        border.width: bar.s(2)
        border.color: bar.colors.accent
        opacity: 0.9
        enabled: false
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    // Thin accent insertion indicator (positioned by updateInsertBar).
    Rectangle {
        id: insertBar
        visible: false
        width: bar.s(3)
        radius: bar.s(1.5)
        color: bar.colors.accent
        enabled: false
        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
    }
}
