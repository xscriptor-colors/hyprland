// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/grid — DavincixGrid
//
// The thumbnail ListView (horizontal o vertical según ctx.gridOrientation;
// scroll, highlight range, add animations, wheel handling) plus the card
// delegate. Wrapped in an Item so the ListView can be exposed as `view` (ids
// do not cross file boundaries); state and actions live on `ctx`.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Item {
    id: gridRoot

    required property var ctx       // picker root (state + functions)
    required property var theme     // Colors instance

    // Exposed so the picker root can drive focus/positioning.
    property alias view: listView

    ListView {
        id: listView
        anchors.fill: parent

        opacity: gridRoot.ctx.isReady ? 1.0 : 0.0
        anchors.margins: gridRoot.ctx.isReady ? 0 : gridRoot.ctx.s(40)

        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }
        Behavior on anchors.margins { NumberAnimation { duration: 700; easing.type: Easing.OutExpo } }

        spacing: 0
        orientation: gridRoot.ctx.gridOrientation === "vertical" ? ListView.Vertical : ListView.Horizontal
        clip: false
        interactive: !gridRoot.ctx.isScrollingBlocked && !gridRoot.ctx.isApplying
        cacheBuffer: 2000

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: gridRoot.ctx.gridOrientation === "vertical"
            ? (listView.height / 2) - ((gridRoot.ctx.itemHeight * 1.5 + gridRoot.ctx.spacing) / 2)
            : (listView.width / 2) - ((gridRoot.ctx.itemWidth * 1.5 + gridRoot.ctx.spacing) / 2)
        preferredHighlightEnd: gridRoot.ctx.gridOrientation === "vertical"
            ? (listView.height / 2) + ((gridRoot.ctx.itemHeight * 1.5 + gridRoot.ctx.spacing) / 2)
            : (listView.width / 2) + ((gridRoot.ctx.itemWidth * 1.5 + gridRoot.ctx.spacing) / 2)
        highlightMoveDuration: gridRoot.ctx.initialFocusSet ? 500 : 0
        focus: true

        onCurrentIndexChanged: gridRoot.ctx.gridIndexChanged()

        // New items slide + fade in once focus has been snapped.
        add: Transition {
            enabled: gridRoot.ctx.allowAddAnimation
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.5; to: 1; duration: 400; easing.type: Easing.OutBack }
            }
        }
        addDisplaced: Transition {
            enabled: gridRoot.ctx.allowAddAnimation
            NumberAnimation { property: "x"; duration: 400; easing.type: Easing.OutCubic }
        }

        // header/footer: espaciador inicial/final para que el primer/último
        // elemento pueda centrarse en el highlight. En horizontal la fórmula
        // usa itemWidth*1.5 (la original, conservada exacta); en vertical
        // cambia al eje alto con itemHeight*1.5.
        header: Item {
            width: gridRoot.ctx.gridOrientation === "vertical" ? 0 : Math.max(0, (listView.width / 2) - ((gridRoot.ctx.itemWidth * 1.5) / 2))
            height: gridRoot.ctx.gridOrientation === "vertical" ? Math.max(0, (listView.height / 2) - ((gridRoot.ctx.itemHeight * 1.5) / 2)) : 0
        }
        footer: Item {
            width: gridRoot.ctx.gridOrientation === "vertical" ? 0 : Math.max(0, (listView.width / 2) - ((gridRoot.ctx.itemWidth * 1.5) / 2))
            height: gridRoot.ctx.gridOrientation === "vertical" ? Math.max(0, (listView.height / 2) - ((gridRoot.ctx.itemHeight * 1.5) / 2)) : 0
        }

        model: gridRoot.ctx.activeModel

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => gridRoot.ctx.gridWheel(wheel)
        }

        delegate: DavincixCard {
            ctx: gridRoot.ctx
            theme: gridRoot.theme
            onClicked: {
                listView.currentIndex = index
                gridRoot.ctx.applyWallpaper(String(fileName), String(fileName).startsWith("000_"))
            }
            onFavoriteToggled: gridRoot.ctx.toggleFavorite(String(fileName))
        }
    }
}
