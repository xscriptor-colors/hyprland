// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/components/grid — DavincixCard
//
// ListView delegate: one wallpaper thumbnail with the skewed cover look, video
// preview (MediaPlayer) and the play badge. Pure view: it reads the model
// roles (fileName/fileUrl/index/ListView) from the delegate context and the
// picker state from `ctx`; it only emits `clicked()`.
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

    readonly property string safeFileName: String(fileName)
    readonly property bool isCurrent: ListView.isCurrentItem && !ctx.isScrollingBlocked
    readonly property bool isFakeSelected: ctx.isScrollingBlocked && index === 0
    readonly property bool isVisuallyEnlarged: isCurrent || isFakeSelected
    readonly property bool isVideo: safeFileName.startsWith("000_")
    readonly property bool matchesFilter: ctx.checkItemMatchesFilter(safeFileName, isVideo, ctx.cacheVersion, ctx.currentFilter)

    readonly property real targetWidth: isVisuallyEnlarged ? (ctx.itemWidth * 1.5) : (ctx.itemWidth * 0.5)
    readonly property real targetHeight: isVisuallyEnlarged ? (ctx.itemHeight + ctx.s(30)) : ctx.itemHeight

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

    width: matchesFilter ? (targetWidth + ctx.spacing) : 0
    visible: width > 0.1 || opacity > 0.01
    opacity: matchesFilter ? (isVisuallyEnlarged ? 1.0 : 0.6) : 0.0
    scale: matchesFilter ? 1.0 : 0.5
    height: matchesFilter ? targetHeight : 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    anchors.verticalCenterOffset: ctx.s(15)
    z: isVisuallyEnlarged ? 10 : 1

    Behavior on scale { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on width { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on height { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
    Behavior on opacity { enabled: ctx.initialFocusSet; NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }

    Item {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: ((ctx.itemHeight - height) / 2) * ctx.skewFactor
        width: parent.width > 0 ? parent.width * (targetWidth / (targetWidth + ctx.spacing)) : 0
        height: parent.height

        transform: Matrix4x4 {
            property real s: ctx.skewFactor
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
            radius: ctx.thumbRadius
            clip: true

            Image {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ctx.s(-50)
                width: (ctx.itemWidth * 1.5) + ((ctx.itemHeight + ctx.s(30)) * Math.abs(ctx.skewFactor)) + ctx.s(50)
                height: ctx.itemHeight + ctx.s(30)
                fillMode: Image.PreserveAspectCrop
                source: fileUrl
                asynchronous: true

                transform: Matrix4x4 {
                    property real s: -ctx.skewFactor
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
                anchors.horizontalCenterOffset: ctx.s(-50)
                width: (ctx.itemWidth * 1.5) + ((ctx.itemHeight + ctx.s(30)) * Math.abs(ctx.skewFactor)) + ctx.s(50)
                height: ctx.itemHeight + ctx.s(30)
                fillMode: VideoOutput.PreserveAspectCrop
                visible: cardRoot.isPlayingVideo && previewPlayer.playbackState === MediaPlayer.PlayingState

                transform: Matrix4x4 {
                    property real s: -ctx.skewFactor
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
                    property real s: -ctx.skewFactor
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
        }
    }
}
