import QtQuick
import QtQuick.Layouts
import "../DockLayout.js" as DockLayout

// Per-section list card for the SERP engine editor (DockEditor, Phase D4-E2).
// Renders one section ("left" | "center" | "right") or the synthetic
// "available" pool as a wrap-flow of chips — one chip per ITEM: loose module
// ids (or layout tokens) as single pills, arrays as GROUP boxes whose header
// drags the whole cluster and whose member chips drag individually.
//
// ── Editor drag & drop contract (extension of the ZoneEditorCard one) ────────
// The DockEditor (this card's `bar`) coordinates ONE editor-wide session:
//   * every chip (loose, group member, group header, available) is draggable
//     past a ~bar.s(10) threshold; short presses stay inert,
//   * while a chip drags, the editor paints the ghost at the pointer, marks
//     the card under the cursor dndActive with a per-ITEM insertion index
//     (dndInsertIndex) plus, for module drags, an optional join target
//     (dndJoinIndex, an item index of a GROUP the module may merge into),
//   * drop indices count ITEMS (a group box is ONE item) of the flow,
//     excluding the dragged item itself (exactly the semantics of
//     DockLayout.serpMoveTo/serpMoveGroupTo, so engine and visuals agree),
//   * an empty card is still a valid target (index 0).
// Cards expose the same query API as ZoneEditorCard (containsRootPoint /
// dropIndexAt / insertionGeometry) plus dndTargetKind: "serp" and dndTargetId
// ("left"|"center"|"right"|"available") so the editor's drop handler can
// branch on the target kind.
// ============================================================================
Rectangle {
    id: serpCard
    required property var bar
    required property string listId

    // ---- DnD target markers (mirror of ZoneEditorCard) ----
    property bool isSerpEditorCard: true
    readonly property string dndTargetKind: "serp"
    readonly property string dndTargetId: serpCard.listId
    property bool dndActive: false
    property int dndInsertIndex: -1
    // Item index of a GROUP the pointer rests on (module drags only; -1 when
    // the pointer is in a gap or over a group that already hosts the module).
    property int dndJoinIndex: -1

    readonly property string listTitle: serpCard.listId === "available" ? "Available"
        : (serpCard.listId === "center" ? "Center"
        : (serpCard.listId === "right" ? "Right" : "Left"))

    // Fresh model on every serp config change: section items as stored
    // (strings + group arrays) or the catalog ids of the available pool.
    readonly property var chipsModel: serpCard.listId === "available"
        ? DockLayout.serpAvailableModules(serpCard.bar.serp)
        : DockLayout.serpSectionItems(serpCard.bar.serp, serpCard.listId)

    height: contentCol.implicitHeight + bar.s(16)
    radius: bar.s(14)
    color: bar.colors.surface0
    border.width: bar.s(1); border.color: bar.colors.surface1

    // Is a point in editor-root coordinates inside this card?
    function containsRootPoint(mx, my) {
        let p = serpCard.mapFromItem(serpCard.bar, mx, my);
        return p.x >= 0 && p.y >= 0 && p.x <= serpCard.width && p.y <= serpCard.height;
    }

    // Flow chips (one per item), excluding the item currently being dragged —
    // the universe drop indices are counted over. Group boxes count as one.
    function dropChips() {
        let kids = chipsFlow.children;
        let out = [];
        let groupDrag = serpCard.bar.dndBusy && serpCard.bar.dndModuleId === "";
        for (let i = 0; i < kids.length; i++) {
            let c = kids[i];
            if (!c || !c.isSerpItemChip) continue;
            if (groupDrag) {
                if (serpCard.bar.dndSourceSerpList === serpCard.listId && c.chipItemIndex === serpCard.bar.dndSourceItemIndex) continue;
            } else {
                if (serpCard.bar.dndModuleId !== "" && c.chipItemId === serpCard.bar.dndModuleId) continue;
            }
            out.push(c);
        }
        return out;
    }

    // Drop index for a pointer in editor-root coordinates: -1 outside the
    // card, otherwise 0..itemCount. Flow rows are scanlined: the pointer's row
    // is found by vertical band (computed from each row's real top/bottom so
    // mixed chip heights — s(30) loose chips next to taller group boxes —
    // still scan correctly), then chips of that row whose center lies left of
    // the pointer count. Empty cards always answer 0 (valid target).
    function dropIndexAt(mx, my) {
        if (!serpCard.containsRootPoint(mx, my)) return -1;
        let chips = serpCard.dropChips();
        if (chips.length === 0) return 0;
        let f = chipsFlow.mapFromItem(serpCard.bar, mx, my);
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
            let top = row.y, bot = row.y;
            for (let i = 0; i < row.chips.length; i++) {
                bot = Math.max(bot, row.chips[i].y + row.chips[i].height);
            }
            if (f.y < top - spacing / 2) return before;
            if (f.y <= bot + spacing / 2) {
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

    // For MODULE drags only: item index of a GROUP whose box contains the
    // pointer (the module would be appended INTO that group). Groups that
    // already contain the dragged module never qualify — dropping a member
    // back onto its own cluster falls through to plain insertion.
    function groupJoinIndexAt(mx, my) {
        if (serpCard.listId === "available") return -1;
        let b = serpCard.bar;
        if (!b.dndBusy || b.dndModuleId === "") return -1;
        let chips = serpCard.dropChips();
        let f = chipsFlow.mapFromItem(serpCard.bar, mx, my);
        for (let i = 0; i < chips.length; i++) {
            let c = chips[i];
            if (!c.chipIsGroup) continue;
            if (f.x < c.x || f.x > c.x + c.width || f.y < c.y || f.y > c.y + c.height) continue;
            if (c.groupContainsId(b.dndModuleId)) return -1;
            return c.chipItemIndex;
        }
        return -1;
    }

    // Card-local geometry of the insertion indicator for dndInsertIndex
    // (thin bar spanning the height of the chip at the slot).
    function insertionGeometry() {
        let chips = serpCard.dropChips();
        let spacing = chipsFlow.spacing;
        if (chips.length === 0) {
            let p0 = chipsFlow.mapToItem(serpCard, 0, 0);
            return { x: p0.x + bar.s(1), y: p0.y + bar.s(2), height: bar.s(26) };
        }
        let idx = Math.max(0, Math.min(serpCard.dndInsertIndex, chips.length));
        if (idx < chips.length) {
            let c = chips[idx];
            let p = c.mapToItem(serpCard, 0, 0);
            return { x: p.x - spacing / 2, y: p.y, height: c.height };
        }
        let last = chips[chips.length - 1];
        let pend = last.mapToItem(serpCard, last.width, 0);
        return { x: pend.x + spacing / 2, y: pend.y, height: last.height };
    }

    function updateInsertBar() {
        if (!serpCard.dndActive || serpCard.dndInsertIndex < 0 || serpCard.dndJoinIndex >= 0) {
            insertBar.visible = false;
            return;
        }
        let g = serpCard.insertionGeometry();
        insertBar.visible = true;
        insertBar.x = g.x;
        insertBar.y = g.y;
        insertBar.height = g.height;
    }
    onDndActiveChanged: serpCard.updateInsertBar()
    onDndInsertIndexChanged: serpCard.updateInsertBar()
    onDndJoinIndexChanged: serpCard.updateInsertBar()

    Column {
        id: contentCol
        anchors.fill: parent
        anchors.margins: bar.s(8)
        spacing: bar.s(6)

        // header: list name + hint
        Row {
            width: parent.width
            spacing: bar.s(6)
            SectionTitle { bar: serpCard.bar; text: serpCard.listTitle }
            EditLabel {
                bar: serpCard.bar
                anchors.verticalCenter: parent.verticalCenter
                text: serpCard.listId === "available" ? "Not on the bar — drag a chip into a section (or onto a group) to add it."
                                                       : "Drop chips here · onto a group to join it · drag headers to move whole clusters."
                font.pixelSize: bar.s(10)
                color: bar.colors.overlay1
            }
        }

        // empty-state hint (flow has nothing to wrap)
        EditLabel {
            bar: serpCard.bar
            width: parent.width
            visible: serpCard.chipsModel.length === 0
            text: serpCard.listId === "available" ? "Every catalog module is on the bar."
                                                  : "Empty section — drop modules here from any other list."
            font.pixelSize: bar.s(10)
            color: bar.colors.overlay1
        }

        // item chips: one per entry (loose id or group array)
        Flow {
            id: chipsFlow
            width: parent.width
            spacing: bar.s(5)
            Repeater {
                model: serpCard.chipsModel
                delegate: Rectangle {
                    id: chipRoot
                    required property var modelData
                    required property int index

                    // ---- markers the card DnD logic enumerates over ----
                    property bool isSerpItemChip: true
                    readonly property bool chipIsGroup: (typeof modelData === "object") && DockLayout.isList(modelData)
                    readonly property string chipItemId: chipRoot.chipIsGroup ? "" : String(modelData)
                    readonly property int chipItemIndex: chipRoot.index
                    // "available" chips have nothing to remove from.
                    readonly property bool chipHasMinus: !chipRoot.chipIsGroup && serpCard.listId !== "available"

                    // Module metadata of a loose entry (null for tokens).
                    readonly property var looseMod: chipRoot.chipIsGroup ? null : DockLayout.getModule(String(modelData))

                    // Does this group box host `id`? (join guard)
                    function groupContainsId(id) {
                        if (!chipRoot.chipIsGroup) return false;
                        let arr = chipRoot.modelData;
                        for (let i = 0; i < arr.length; i++) {
                            if (String(arr[i]) === id) return true;
                        }
                        return false;
                    }

                    // Group box width capped so oversized clusters stay inside
                    // the editor panel (the box clips its own overflow).
                    readonly property int grpContentW: Math.max(grpHead.implicitWidth, grpMembers.implicitWidth)
                    readonly property int grpWidth: Math.min(grpContentW + bar.s(34), bar.s(700))

                    width: chipRoot.chipIsGroup ? grpWidth
                                                : looseRow.implicitWidth + bar.s(16) + (chipRoot.chipHasMinus ? bar.s(24) : 0)
                    height: chipRoot.chipIsGroup ? grpContent.implicitHeight + bar.s(10) : bar.s(30)
                    radius: bar.s(chipRoot.chipIsGroup ? 10 : 8)
                    color: bar.colors.surface1
                    border.width: chipRoot.chipIsGroup ? 1 : 0
                    border.color: bar.colors.surface2
                    clip: chipRoot.chipIsGroup

                    // Dim the dragged chip so the ghost reads clearly.
                    opacity: (bar.dndBusy && (
                        (bar.dndModuleId !== "" && chipRoot.chipItemId === bar.dndModuleId)
                        || (bar.dndModuleId === "" && bar.dndSourceSerpList === serpCard.listId && chipRoot.chipItemIndex === bar.dndSourceItemIndex))
                    ) ? 0.35 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 100 } }

                    // ── LOOSE chip content ──────────────────────────────
                    Row {
                        id: looseRow
                        visible: !chipRoot.chipIsGroup
                        anchors.left: parent.left
                        anchors.leftMargin: bar.s(6)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: bar.s(5)
                        Text {
                            text: chipRoot.looseMod ? chipRoot.looseMod.icon : "◇"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(12)
                            color: bar.colors.text
                        }
                        Text {
                            text: chipRoot.looseMod ? chipRoot.looseMod.label : chipRoot.chipItemId
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(11)
                            color: bar.colors.text
                        }
                    }

                    // ── GROUP box content ───────────────────────────────
                    Column {
                        id: grpContent
                        visible: chipRoot.chipIsGroup
                        anchors.left: parent.left
                        anchors.leftMargin: bar.s(6)
                        anchors.top: parent.top
                        anchors.topMargin: bar.s(5)
                        spacing: bar.s(3)
                        Row {
                            id: grpHead
                            height: bar.s(18)
                            spacing: bar.s(4)
                            Text {
                                text: "◧"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: bar.s(11)
                                font.weight: Font.Bold
                                color: bar.colors.accent
                            }
                            Text {
                                text: "Group"
                                font.family: "Hack Nerd Font"
                                font.pixelSize: bar.s(10)
                                font.weight: Font.Bold
                                color: bar.colors.text
                            }
                            Text {
                                text: "· " + chipRoot.modelData.length
                                font.family: "Hack Nerd Font"
                                font.pixelSize: bar.s(10)
                                color: bar.colors.overlay1
                            }
                        }
                        // Members: smaller chips, individually draggable.
                        Row {
                            id: grpMembers
                            spacing: bar.s(3)
                            Repeater {
                                model: chipRoot.chipIsGroup ? chipRoot.modelData : []
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property string memberId: String(modelData)
                                    readonly property var memberMod: DockLayout.getModule(memberId)

                                    width: memberRow.implicitWidth + bar.s(22)
                                    height: bar.s(24)
                                    radius: bar.s(6)
                                    color: bar.colors.surface0
                                    opacity: (bar.dndBusy && bar.dndModuleId === memberId) ? 0.35 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }

                                    Row {
                                        id: memberRow
                                        anchors.left: parent.left
                                        anchors.leftMargin: bar.s(4)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: bar.s(4)
                                        Text {
                                            text: memberMod ? memberMod.icon : "◇"
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(10)
                                            color: bar.colors.text
                                        }
                                        Text {
                                            text: memberMod ? memberMod.label : memberId
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(10)
                                            color: bar.colors.text
                                        }
                                    }
                                    // member drag → the module itself
                                    MouseArea {
                                        id: memberDrag
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        property point pressPos: Qt.point(0, 0)
                                        property bool dragOccurred: false
                                        onPressed: mouse => {
                                            pressPos = Qt.point(mouse.x, mouse.y);
                                            dragOccurred = false;
                                        }
                                        onPositionChanged: mouse => {
                                            if (!memberDrag.pressed) return;
                                            if (memberDrag.dragOccurred) {
                                                if (bar.dndBusy) {
                                                    let p = memberDrag.mapToItem(bar, mouse.x, mouse.y);
                                                    bar.updateDnd(p.x, p.y);
                                                }
                                                return;
                                            }
                                            let dx = mouse.x - memberDrag.pressPos.x;
                                            let dy = mouse.y - memberDrag.pressPos.y;
                                            if (Math.sqrt(dx * dx + dy * dy) < bar.s(10)) return;
                                            memberDrag.dragOccurred = true;
                                            bar.startSerpDnd(serpCard.listId, memberId, -1);
                                            if (!bar.dndBusy) {
                                                memberDrag.dragOccurred = false;
                                                return;
                                            }
                                            let p = memberDrag.mapToItem(bar, mouse.x, mouse.y);
                                            bar.updateDnd(p.x, p.y);
                                        }
                                        onReleased: mouse => {
                                            if (memberDrag.dragOccurred && bar.dndBusy) {
                                                let p = memberDrag.mapToItem(bar, mouse.x, mouse.y);
                                                bar.endDnd(p.x, p.y);
                                            }
                                        }
                                        onCanceled: {
                                            if (memberDrag.dragOccurred && bar.dndBusy) bar.cancelDnd();
                                        }
                                    }
                                    // member remove button (sends the module to Available)
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: bar.s(1)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: bar.s(15)
                                        height: bar.s(15)
                                        radius: bar.s(4)
                                        color: bar.colors.surface2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "−"
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(10)
                                            font.weight: Font.Black
                                            color: bar.colors.base
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: serpCard.bar.serpRemoveModule(memberId)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── loose chip drag (module) ────────────────────────
                    MouseArea {
                        id: looseDrag
                        visible: !chipRoot.chipIsGroup
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        property point pressPos: Qt.point(0, 0)
                        property bool dragOccurred: false
                        onPressed: mouse => {
                            pressPos = Qt.point(mouse.x, mouse.y);
                            dragOccurred = false;
                        }
                        onPositionChanged: mouse => {
                            if (!looseDrag.pressed) return;
                            if (looseDrag.dragOccurred) {
                                if (bar.dndBusy) {
                                    let p = looseDrag.mapToItem(bar, mouse.x, mouse.y);
                                    bar.updateDnd(p.x, p.y);
                                }
                                return;
                            }
                            let dx = mouse.x - looseDrag.pressPos.x;
                            let dy = mouse.y - looseDrag.pressPos.y;
                            if (Math.sqrt(dx * dx + dy * dy) < bar.s(10)) return;
                            looseDrag.dragOccurred = true;
                            bar.startSerpDnd(serpCard.listId, chipRoot.chipItemId, -1);
                            if (!bar.dndBusy) {
                                looseDrag.dragOccurred = false;
                                return;
                            }
                            let p = looseDrag.mapToItem(bar, mouse.x, mouse.y);
                            bar.updateDnd(p.x, p.y);
                        }
                        onReleased: mouse => {
                            if (looseDrag.dragOccurred && bar.dndBusy) {
                                let p = looseDrag.mapToItem(bar, mouse.x, mouse.y);
                                bar.endDnd(p.x, p.y);
                            }
                        }
                        onCanceled: {
                            if (looseDrag.dragOccurred && bar.dndBusy) bar.cancelDnd();
                        }
                    }
                    // loose chip remove button (sends the module to Available)
                    Rectangle {
                        visible: chipRoot.chipHasMinus
                        anchors.right: parent.right
                        anchors.rightMargin: bar.s(2)
                        anchors.verticalCenter: parent.verticalCenter
                        width: bar.s(18)
                        height: bar.s(18)
                        radius: bar.s(5)
                        color: bar.colors.surface2
                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(12)
                            font.weight: Font.Black
                            color: bar.colors.base
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: serpCard.bar.serpRemoveModule(chipRoot.chipItemId)
                        }
                    }

                    // ── group drag (whole cluster, via its header band) ──
                    // The header Row lives inside grpContent (not a sibling),
                    // so anchor the band to grpContent itself and cap it at the
                    // header height (bar.s(18)). The ungroup button (declared
                    // later, above this overlay) still receives its clicks.
                    MouseArea {
                        id: grpDrag
                        visible: chipRoot.chipIsGroup
                        anchors.top: grpContent.top
                        anchors.left: grpContent.left
                        anchors.right: grpContent.right
                        height: bar.s(18)
                        cursorShape: Qt.PointingHandCursor
                        property point pressPos: Qt.point(0, 0)
                        property bool dragOccurred: false
                        onPressed: mouse => {
                            pressPos = Qt.point(mouse.x, mouse.y);
                            dragOccurred = false;
                        }
                        onPositionChanged: mouse => {
                            if (!grpDrag.pressed) return;
                            if (grpDrag.dragOccurred) {
                                if (bar.dndBusy) {
                                    let p = grpDrag.mapToItem(bar, mouse.x, mouse.y);
                                    bar.updateDnd(p.x, p.y);
                                }
                                return;
                            }
                            let dx = mouse.x - grpDrag.pressPos.x;
                            let dy = mouse.y - grpDrag.pressPos.y;
                            if (Math.sqrt(dx * dx + dy * dy) < bar.s(10)) return;
                            grpDrag.dragOccurred = true;
                            bar.startSerpDnd(serpCard.listId, "", chipRoot.chipItemIndex);
                            if (!bar.dndBusy) {
                                grpDrag.dragOccurred = false;
                                return;
                            }
                            let p = grpDrag.mapToItem(bar, mouse.x, mouse.y);
                            bar.updateDnd(p.x, p.y);
                        }
                        onReleased: mouse => {
                            if (grpDrag.dragOccurred && bar.dndBusy) {
                                let p = grpDrag.mapToItem(bar, mouse.x, mouse.y);
                                bar.endDnd(p.x, p.y);
                            }
                        }
                        onCanceled: {
                            if (grpDrag.dragOccurred && bar.dndBusy) bar.cancelDnd();
                        }
                    }
                    // ungroup button (breaks the cluster into loose chips)
                    Rectangle {
                        visible: chipRoot.chipIsGroup
                        anchors.top: parent.top
                        anchors.topMargin: bar.s(4)
                        anchors.right: parent.right
                        anchors.rightMargin: bar.s(4)
                        width: bar.s(18)
                        height: bar.s(18)
                        radius: bar.s(5)
                        color: bar.colors.surface2
                        Text {
                            anchors.centerIn: parent
                            text: "⤢"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: bar.s(11)
                            font.weight: Font.Black
                            color: bar.colors.base
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: serpCard.bar.serpUngroupAt(serpCard.listId, chipRoot.chipItemIndex)
                        }
                    }

                    // Join glow: this box is the current merge target of the
                    // module being dragged (purely visual, never grabs input).
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: bar.s(1)
                        radius: bar.s(9)
                        visible: chipRoot.chipIsGroup && serpCard.dndActive && serpCard.dndJoinIndex === chipRoot.chipItemIndex
                        color: "transparent"
                        border.width: bar.s(2)
                        border.color: bar.colors.accent
                        opacity: 0.9
                        enabled: false
                        Behavior on opacity { NumberAnimation { duration: 90 } }
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
        radius: bar.s(13)
        visible: serpCard.dndActive
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
