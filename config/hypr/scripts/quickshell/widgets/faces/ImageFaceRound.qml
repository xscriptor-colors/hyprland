import QtQuick
import QtQuick.Effects
import "../../"

// ============================================================================
// ImageFaceRound — circular image frame (PreserveAspectCrop inside a circle).
// Same masking approach as ImageFaceRounded but with a circular mask; shows a
// surface0 disc + glyph while no image is available.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 40
    property real minHeight: 40
    property real maxWidth: 3000
    property real maxHeight: 3000
    property real minAspect: 1.0
    property real maxAspect: 1.0
    property bool isRound: true

    property string imagePath: ""
    property string wImagePath: imagePath
    property string path: imagePath

    function fileUrl(p) {
        if (!p || p === "") return "";
        if (p.indexOf("file://") === 0 || p.indexOf("http://") === 0 || p.indexOf("https://") === 0) return p;
        return "file://" + p;
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: (root.path === "" || artImg.status !== Image.Ready) ? Theme.surface0 : "transparent"
        radius: width / 2
        antialiasing: true

        AnimatedImage {
            id: artImg
            anchors.fill: parent
            source: root.fileUrl(root.path)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            mipmap: true
            antialiasing: true
            playing: true
            sourceSize: Qt.size(4096, 4096)
            visible: false // rendered through the masked MultiEffect below
        }

        // White circular mask captured as a texture for MultiEffect.
        Rectangle {
            id: maskRect
            anchors.fill: parent
            radius: width / 2
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
