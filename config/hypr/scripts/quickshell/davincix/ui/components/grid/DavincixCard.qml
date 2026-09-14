// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/grid — DavincixCard
//
// ListView delegate: one wallpaper thumbnail with the skewed cover look, video
// preview (MediaPlayer) and the play badge. Pure view: it reads the model
// roles (fileName/fileUrl/index/ListView) from the delegate context and the
// picker state from `ctx`; it emits `clicked()` and `favoriteToggled()`.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick
import QtMultimedia

Item {
    id: cardRoot

    required property var ctx       // the picker root (state + functions)
    required property var theme     // Colors instance
    // Model roles (injected by the ListView via required properties: the
    // delegate lives in another file, so the roles are NOT ambient scope).
    required property string fileName
    required property url fileUrl
    required property int index

    signal clicked()
    signal favoriteToggled()

    readonly property string safeFileName: String(fileName)
    readonly property bool isCurrent: ListView.isCurrentItem && !ctx.isScrollingBlocked
    readonly property bool isFakeSelected: ctx.isScrollingBlocked && index === 0
    readonly property bool isVisuallyEnlarged: isCurrent || isFakeSelected
    readonly property bool isVideo: safeFileName.startsWith("000_")
    readonly property bool matchesFilter: ctx.checkItemMatchesFilter(safeFileName, isVideo, ctx.cacheVersion, ctx.currentFilter)

    // ═══════════════════════════════════════════════════════════════════════
    // Modos de vista del picker (ctx.gridOrientation / ctx.cardShape).
    // effSkew anula el shear en modo circle para que el diámetro quede como
    // un círculo perfecto (radius = width/2 sobre un cuadrado).
    // ═══════════════════════════════════════════════════════════════════════
    readonly property bool isVertical: ctx.gridOrientation === "vertical"
    readonly property bool isCircle: ctx.cardShape === "circle"
    readonly property real effSkew: isCircle ? 0 : ctx.skewFactor
    readonly property bool isFavorite: ctx.isFavorite(safeFileName)

    // Tamaño objetivo según el modo de vista. Las ramas rect+horizontal son
    // las fórmulas originales, sin tocar.
    readonly property real targetWidth: {
        if (isCircle) {
            return isVisuallyEnlarged ? ctx.itemHeight * 1.25 : ctx.itemHeight * 0.6;
        }
        if (isVertical) {
            return ctx.itemWidth * 0.8;
        }
        return isVisuallyEnlarged ? (ctx.itemWidth * 1.5) : (ctx.itemWidth * 0.5);
    }

    readonly property real targetHeight: {
        if (isCircle) {
            return targetWidth;   // cuadrado → círculo perfecto
        }
        if (isVertical) {
            return isVisuallyEnlarged ? ctx.itemHeight * 1.5 : ctx.itemHeight * 0.5;
        }
        return isVisuallyEnlarged ? (ctx.itemHeight + ctx.s(30)) : ctx.itemHeight;
    }

    property bool isPlayingVideo: false

    Timer {
        id: videoPlayTimer
        interval: 250
        running: cardRoot.isVisuallyEnlarged && cardRoot.isVideo && !ctx.isScrollingBlocked && !ctx.isFilterAnimating && !ctx.isItemAnimating
        onTriggered: {
            if (cardRoot.isVisuallyEnlarged && cardRoot.isVideo) {
                cardRoot.isPlayingVideo = true;
                previewPlayer.play();
            }
        }
    }

    onIsVisuallyEnlargedChanged: {
        if (!isVisuallyEnlarged) {
            isPlayingVideo = false;
            videoPlayTimer.stop();
            previewPlayer.stop();
        }
    }

    width: matchesFilter ? (isVertical ? targetWidth : targetWidth + ctx.spacing) : 0
    visible: width > 0.1 || opacity > 0.01
    opacity: matchesFilter ? (isVisuallyEnlarged ? 1.0 : 0.6) : 0.0
    scale: matchesFilter ? 1.0 : 0.5
    height: matchesFilter ? (isVertical ? targetHeight + ctx.spacing : targetHeight) : 0

    // En horizontal el ListView gestiona la x y la tarjeta se centra en y;
    // en vertical se invierte (el view gestiona la y).
    anchors.horizontalCenter: isVertical && parent ? parent.horizontalCenter : undefined
    anchors.verticalCenter: !isVertical && parent ? parent.verticalCenter : undefined
    anchors.verticalCenterOffset: isVertical ? 0 : ctx.s(15)
    z: isVisuallyEnlarged ? 10 : 1

    Behavior on scale { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on width { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on height { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on opacity { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

    Item {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: ((ctx.itemHeight - height) / 2) * cardRoot.effSkew
        width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + ctx.spacing)) : 0
        height: parent.height

        transform: Matrix4x4 {
            property real s: cardRoot.effSkew
            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardRoot.matchesFilter && !ctx.isScrollingBlocked && !ctx.isApplying
            onClicked: cardRoot.clicked()
        }

        Image {
            anchors.fill: parent
            source: fileUrl
            sourceSize: Qt.size(1, 1)
            fillMode: Image.Stretch
            visible: true
            asynchronous: true
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: ctx.borderWidth
            color: theme.base
            radius: cardRoot.isCircle ? (width / 2) : ctx.thumbRadius
            clip: true

            Image {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: cardRoot.effSkew !== 0 ? ctx.s(-50) : 0
                width: cardRoot.effSkew !== 0
                    ? (ctx.itemWidth * 1.5) + ((ctx.itemHeight + ctx.s(30)) * Math.abs(cardRoot.effSkew)) + ctx.s(50)
                    : parent.width
                height: cardRoot.effSkew !== 0 ? ctx.itemHeight + ctx.s(30) : parent.height
                fillMode: Image.PreserveAspectCrop
                source: fileUrl
                asynchronous: true

                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }

            MediaPlayer {
                id: previewPlayer
                source: cardRoot.isPlayingVideo ? "file://" + ctx.srcDir + "/" + ctx.getCleanName(cardRoot.safeFileName) : ""
                audioOutput: AudioOutput { muted: true }
                videoOutput: previewOutput
                loops: MediaPlayer.Infinite
            }

            VideoOutput {
                id: previewOutput
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: cardRoot.effSkew !== 0 ? ctx.s(-50) : 0
                width: cardRoot.effSkew !== 0
                    ? (ctx.itemWidth * 1.5) + ((ctx.itemHeight + ctx.s(30)) * Math.abs(cardRoot.effSkew)) + ctx.s(50)
                    : parent.width
                height: cardRoot.effSkew !== 0 ? ctx.itemHeight + ctx.s(30) : parent.height
                fillMode: VideoOutput.PreserveAspectCrop
                visible: cardRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState

                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }

            Rectangle {
                visible: cardRoot.isVideo && (!cardRoot.isPlayingVideo || previewPlayer.playbackState !== MediaPlayer.PlayingState)
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: ctx.s(10)
                width: ctx.s(32)
                height: ctx.s(32)
                radius: ctx.s(8)
                color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.6)

                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                Canvas {
                    anchors.fill: parent
                    anchors.margins: ctx.s(8)
                    property real scaleTrigger: ctx.s(1)
                    onScaleTriggerChanged: requestPaint()

                    onPaint: {
                        var c = getContext("2d");
                        c.reset();
                        c.fillStyle = Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.93);
                        c.beginPath();
                        c.moveTo(ctx.s(4), 0);
                        c.lineTo(ctx.s(14), ctx.s(8));
                        c.lineTo(ctx.s(4), ctx.s(16));
                        c.closePath();
                        c.fill();
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════════
            // Estrella de favorito (esquina superior-izquierda). Visible
            // al ampliar la tarjeta o si ya es favorita. Emite solo
            // favoriteToggled(), nunca clicked(), para no disparar el
            // apply del wallpaper.
            // ═══════════════════════════════════════════════════════════════
            Rectangle {
                id: favoriteBadge
                visible: cardRoot.isVisuallyEnlarged || cardRoot.isFavorite
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: ctx.s(10)
                width: ctx.s(28)
                height: ctx.s(28)
                radius: ctx.s(8)
                z: 20
                color: cardRoot.isFavorite
                    ? Qt.rgba(theme.mauve.r, theme.mauve.g, theme.mauve.b, 0.9)
                    : Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.55)
                border.width: 1
                border.color: theme.surface1

                // Contra-shear idéntico al badge de play para que la
                // estrella se vea derecha; identidad en circle (effSkew = 0).
                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uF005"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: ctx.s(14)
                    color: cardRoot.isFavorite ? theme.crust : theme.text
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: cardRoot.matchesFilter && !ctx.isScrollingBlocked && !ctx.isApplying
                    onClicked: cardRoot.favoriteToggled()
                }
            }
        }
    }
}
