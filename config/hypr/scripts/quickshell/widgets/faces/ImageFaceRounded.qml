import QtQuick
import QtQuick.Effects
import "../../"

// ============================================================================
// ImageFaceRounded — rectangular image frame with rounded corners.
// The loaded image is masked by a white rounded layer (MultiEffect), so the
// picture never bleeds past the card corners; while no image is available a
// surface0 card with a glyph placeholder is drawn.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 30
    property real minHeight: 30
    property real maxWidth: 4000
    property real maxHeight: 4000
    property real minAspect: 0.02
    property real maxAspect: 50.0
    property bool isRound: false

    property string imagePath: ""
    property string wImagePath: imagePath
    property string path: imagePath
    property real cornerRadius: Theme.clampedBorderRadius

    function fileUrl(p) {
        if (!p || p === "") return "";
        if (p.indexOf("file://") === 0 || p.indexOf("http://") === 0 || p.indexOf("https://") === 0) return p;
        return "file://" + p;
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: (root.path === "" || artImg.status !== Image.Ready) ? Theme.surface0 : "transparent"
        radius: root.cornerRadius
        antialiasing: true

        AnimatedImage {
            id: artImg
            anchors.fill: parent
            source: root.fileUrl(root.path)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
            smooth: true
            mipmap: true
            antialiasing: true
            playing: true
            sourceSize: Qt.size(4096, 4096)
            visible: false // rendered through the masked MultiEffect below
        }

        // White rounded mask captured as a texture for MultiEffect.
        Rectangle {
            id: maskRect
            anchors.fill: parent
            radius: root.cornerRadius
            color: "white"
            antialiasing: true
            visible: false
            layer.enabled: true
            layer.smooth: true
        }

        MultiEffect {
            id: effect
            anchors.fill: parent
            source: artImg
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: maskRect
            visible: root.path !== "" && artImg.status === Image.Ready
        }

        Item {
            anchors.fill: parent
            visible: root.path === "" || artImg.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: "󰋩"
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(16, Math.min(root.width, root.height) * 0.35)
                color: Theme.subtext0
            }
        }
    }
}
