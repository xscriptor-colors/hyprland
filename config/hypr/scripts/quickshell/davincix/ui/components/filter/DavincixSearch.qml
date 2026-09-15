// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/filter — DavincixSearch
//
// Search control: the pause/play button plus the expanding search box
// (input + submit). Owns the input text and the search-state persistence
// (Settings object), and calls ctx.submitSearch(query) on submit.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick

Row {
    id: searchRow

    required property var ctx        // picker root
    required property var theme      // Colors instance
    required property var settings   // Settings (QS_Davincix)

    height: ctx.s(44)
    spacing: ctx.s(12)

    function submit() {
        let q = searchInput.text.trim();
        if (q === "") return;
        ctx.submitSearch(q);
        searchInput.focus = false;
        ctx.gridFocus();
    }

    // Restore the search state when the picker reopens.
    Component.onCompleted: {
        if (settings.searched) {
            searchInput.text = settings.query;
            ctx.searchQuery = settings.query;
            ctx.hasSearched = true;
            ctx.lastSearchName = settings.lastName;
            ctx.isSearchPaused = true;
        }
    }

    // Persist the search state before destruction.
    Component.onDestruction: {
        if (ctx.hasSearched) {
            settings.query = searchInput.text;
            settings.searched = ctx.hasSearched;
            settings.lastName = ctx.lastSearchName;
        }
    }

    Rectangle {
        id: searchControlBtn
        visible: ctx.currentFilter === "Search" && ctx.hasSearched
        width: visible ? ctx.s(44) : 0
        height: ctx.s(44)
        radius: ctx.s(13)
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        color: ctx.isSearchPaused ? theme.surface2 : "transparent"
        border.color: ctx.isSearchPaused ? theme.text : theme.surface1
        border.width: ctx.isSearchPaused ? ctx.s(2) : 1

        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }

        MouseArea {
            id: scMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !ctx.isApplying
            cursorShape: Qt.PointingHandCursor
            onClicked: ctx.isSearchPaused = !ctx.isSearchPaused
        }

        Canvas {
            width: ctx.s(44)
            height: ctx.s(44)
            anchors.centerIn: parent
            property bool paused: ctx.isSearchPaused
            property string activeColor: paused ? theme.text
                : (scMouse.containsMouse ? theme.text
                   : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7))
            onActiveColorChanged: requestPaint()
            onPausedChanged: requestPaint()
            property real scaleTrigger: ctx.s(1)
            onScaleTriggerChanged: requestPaint()

            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.fillStyle = activeColor;
                if (!paused) {
                    c.fillRect(ctx.s(15), ctx.s(14), ctx.s(4), ctx.s(16));
                    c.fillRect(ctx.s(25), ctx.s(14), ctx.s(4), ctx.s(16));
                } else {
                    c.beginPath();
                    c.moveTo(ctx.s(16), ctx.s(12));
                    c.lineTo(ctx.s(32), ctx.s(22));
                    c.lineTo(ctx.s(16), ctx.s(32));
                    c.closePath();
                    c.fill();
                }
            }
        }
    }

    // Load more: siguiente página de resultados (solo con búsqueda pausada).
    Rectangle {
        id: loadMoreBtn
        visible: ctx.currentFilter === "Search" && ctx.hasSearched && ctx.isSearchPaused && ctx.searchResultCount > 0
        width: visible ? ctx.s(44) : 0
        height: ctx.s(44)
        radius: ctx.s(13)
        anchors.verticalCenter: parent.verticalCenter

        color: lmMouse.containsMouse ? theme.surface1 : "transparent"
        border.color: theme.surface1
        border.width: 1

        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        Behavior on color { ColorAnimation { duration: 300 } }

        Text {
            anchors.centerIn: parent
            text: "\uF055"  // fa-plus-circle
            font.family: "Hack Nerd Font"
            font.pixelSize: ctx.s(16)
            color: lmMouse.containsMouse ? theme.text : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
        }

        MouseArea {
            id: lmMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !ctx.isApplying
            cursorShape: Qt.PointingHandCursor
            onClicked: ctx.loadMoreSearch()
        }
    }

    Rectangle {
        id: searchBox
        height: ctx.s(44)
        width: ctx.currentFilter === "Search" ? ctx.s(360) : ctx.s(44)
        radius: ctx.s(13)
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        color: ctx.currentFilter === "Search" ? Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8) : "transparent"
        border.color: ctx.currentFilter === "Search" ? theme.text : theme.surface1
        border.width: ctx.currentFilter === "Search" ? ctx.s(2) : 1

        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
        Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutQuart } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        MouseArea {
            id: searchMouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: !ctx.isApplying
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (ctx.currentFilter !== "Search") {
                    ctx.currentFilter = "Search";
                } else {
                    ctx.currentFilter = "All";
                }
            }
        }

        Canvas {
            id: searchIcon
            width: ctx.s(44)
            height: ctx.s(44)
            anchors.left: parent.left
            anchors.leftMargin: ctx.currentFilter === "Search" ? ctx.s(5) : 0
            anchors.verticalCenter: parent.verticalCenter
            Behavior on anchors.leftMargin { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }

            property string activeColor: ctx.currentFilter === "Search" ? theme.text
                : (searchMouseArea.containsMouse ? theme.text
                   : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7))
            onActiveColorChanged: requestPaint()
            property real scaleTrigger: ctx.s(1)
            onScaleTriggerChanged: requestPaint()

            onPaint: {
                var c = getContext("2d");
                c.reset();
                c.lineWidth = ctx.s(3);
                c.strokeStyle = activeColor;
                c.beginPath();
                c.arc(ctx.s(18), ctx.s(18), ctx.s(7), 0, Math.PI * 2);
                c.stroke();
                c.beginPath();
                c.moveTo(ctx.s(23), ctx.s(23));
                c.lineTo(ctx.s(31), ctx.s(31));
                c.stroke();
            }
        }

        TextInput {
            id: searchInput
            anchors.left: searchIcon.right
            anchors.right: submitBtn.left
            anchors.rightMargin: ctx.s(8)
            anchors.verticalCenter: parent.verticalCenter

            opacity: ctx.currentFilter === "Search" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

            color: theme.text
            font.family: "Hack Nerd Font"
            font.pixelSize: ctx.s(16)
            clip: true

            onActiveFocusChanged: ctx.searchInputFocused = searchInput.activeFocus

            onTextEdited: {
                ctx.hasSearched = false;
                settings.searched = false;
            }

            onAccepted: searchRow.submit()
        }

        Rectangle {
            id: submitBtn
            width: ctx.s(32)
            height: ctx.s(32)
            radius: ctx.s(10)
            anchors.right: parent.right
            anchors.rightMargin: ctx.s(8)
            anchors.verticalCenter: parent.verticalCenter

            opacity: ctx.currentFilter === "Search" ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

            color: submitMouseArea.containsMouse ? theme.surface1 : "transparent"
            border.color: submitMouseArea.containsMouse ? theme.text : theme.surface2
            border.width: 1
            Behavior on color { ColorAnimation { duration: 300 } }

            MouseArea {
                id: submitMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                enabled: !ctx.isApplying
                onClicked: searchRow.submit()
            }

            Canvas {
                width: ctx.s(16)
                height: ctx.s(16)
                anchors.centerIn: parent
                property string activeColor: submitMouseArea.containsMouse ? theme.text
                    : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                onActiveColorChanged: requestPaint()
                property real scaleTrigger: ctx.s(1)
                onScaleTriggerChanged: requestPaint()

                onPaint: {
                    var c = getContext("2d");
                    c.reset();
                    c.lineWidth = ctx.s(2);
                    c.lineCap = "round";
                    c.lineJoin = "round";
                    c.strokeStyle = activeColor;

                    c.beginPath();
                    c.moveTo(ctx.s(2), ctx.s(8));
                    c.lineTo(ctx.s(14), ctx.s(8));
                    c.moveTo(ctx.s(9), ctx.s(3));
                    c.lineTo(ctx.s(14), ctx.s(8));
                    c.lineTo(ctx.s(9), ctx.s(13));
                    c.stroke();
                }
            }
        }
    }
}
