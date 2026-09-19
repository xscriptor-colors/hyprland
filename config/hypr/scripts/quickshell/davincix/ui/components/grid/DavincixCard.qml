// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/grid — DavincixCard
//
// ListView delegate: one wallpaper thumbnail with the skewed cover look, video
// preview (MediaPlayer) and the play badge. Pure view: it reads the model
// roles (fileName/fileUrl/index/ListView) from the delegate context and the
// picker state from `ctx`; it emits `clicked()` and `favoriteToggled()`.
// ═══════════════════════════════════════════════════════════════════════════
import QtQuick
import QtQuick.Effects
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
    readonly property bool isLocalVideo: safeFileName.startsWith("000_")
    // Vídeo local o resultado de una búsqueda de vídeo (badge; el preview
    // MediaPlayer solo corre para vídeos locales).
    readonly property bool isVideo: isLocalVideo || (ctx.currentFilter === "Search" && ctx.searchKind === "video")
    readonly property bool matchesFilter: ctx.checkItemMatchesFilter(safeFileName, isVideo, ctx.cacheVersion, ctx.currentFilter)

    // ═══════════════════════════════════════════════════════════════════════
    // Modos de vista del picker (ctx.gridOrientation / ctx.cardShape).
    //   rect   → diseño original (shear diagonal, fondo estirado)
    //   square → tarjeta cuadrada limpia, sin shear, sin fondo
    //   circle → thumbnail circular con entorno TRANSPARENTE (máscara)
    // effSkew anula el shear en square/circle para que la geometría sea recta.
    // ═══════════════════════════════════════════════════════════════════════
    readonly property bool isVertical: ctx.gridOrientation === "vertical"
    readonly property bool isCircle: ctx.cardShape === "circle"
    readonly property bool isSquare: ctx.cardShape === "square"
    readonly property bool isFlat: isCircle || isSquare
    readonly property real effSkew: isFlat ? 0 : ctx.skewFactor
    readonly property bool isFavorite: ctx.isFavorite(safeFileName)

    // Tamaño objetivo según el modo de vista. Las ramas rect+horizontal son
    // las fórmulas originales, sin tocar.
    readonly property real targetWidth: {
        if (isFlat) {
            return isVisuallyEnlarged ? ctx.itemHeight * 1.25 : ctx.itemHeight * 0.6;
        }
        if (isVertical) {
            return ctx.itemWidth * 0.8;
        }
        return isVisuallyEnlarged ? (ctx.itemWidth * 1.5) : (ctx.itemWidth * 0.5);
    }

    readonly property real targetHeight: {
        if (isFlat) {
            return targetWidth;   // cuadrado → círculo perfecto en circle
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
        running: cardRoot.isVisuallyEnlarged && cardRoot.isLocalVideo && !ctx.isScrollingBlocked && !ctx.isFilterAnimating && !ctx.isItemAnimating
        onTriggered: {
            if (cardRoot.isVisuallyEnlarged && cardRoot.isLocalVideo) {
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
            // Fondo estirado solo en modo rect; en square/circle el entorno
            // de la tarjeta queda TRANSPARENTE (sin cuadrado de fondo).
            visible: !cardRoot.isFlat
            asynchronous: true
        }

        Rectangle {
            id: cover
            anchors.fill: parent
            anchors.margins: ctx.borderWidth
            color: cardRoot.isFlat ? "transparent" : theme.base
            radius: cardRoot.isCircle ? (width / 2) : ctx.thumbRadius
            border.color: cardRoot.isFlat ? theme.surface1 : "transparent"
            border.width: cardRoot.isFlat ? 1 : 0
            clip: true

            // `clip` recorta solo al rectángulo límite; el recorte circular
            // se hace con MultiEffect + máscara (mismo patrón que
            // ImageFaceRound/MusicPopup del shell).
            Image {
                id: coverImage
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: cardRoot.effSkew !== 0 ? ctx.s(-50) : 0
                width: cardRoot.effSkew !== 0
                    ? (ctx.itemWidth * 1.5) + ((ctx.itemHeight + ctx.s(30)) * Math.abs(cardRoot.effSkew)) + ctx.s(50)
                    : parent.width
                height: cardRoot.effSkew !== 0 ? ctx.itemHeight + ctx.s(30) : parent.height
                fillMode: Image.PreserveAspectCrop
                source: fileUrl
                asynchronous: true
                visible: !cardRoot.isCircle   // en circle lo pinta el MultiEffect

                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }

            // Máscara circular (textura blanca, oculta).
            Rectangle {
                id: circleMask
                anchors.fill: coverImage
                radius: width / 2
                color: "white"
                visible: false
                layer.enabled: cardRoot.isCircle
                layer.smooth: true
            }

            MultiEffect {
                id: imageCircleEffect
                anchors.fill: coverImage
                source: coverImage
                maskEnabled: cardRoot.isCircle
                maskSource: circleMask
                autoPaddingEnabled: false
                visible: cardRoot.isCircle
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
                visible: !cardRoot.isCircle && cardRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState

                transform: Matrix4x4 {
                    property real s: -cardRoot.effSkew
                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
            }

            MultiEffect {
                id: videoCircleEffect
                anchors.fill: previewOutput
                source: previewOutput
                maskEnabled: cardRoot.isCircle
                maskSource: circleMask
                autoPaddingEnabled: false
                visible: cardRoot.isCircle && cardRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState
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
