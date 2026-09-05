import QtQuick
import "../../"

// ============================================================================
// ClockFaceAnalog — round analog clock face.
// Constraint-driven sizing is declared for the widget window / redactor.
// ============================================================================

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 100
    property real minHeight: 100
    property real maxWidth: 800
    property real maxHeight: 800
    property real minAspect: 1.0
    property real maxAspect: 1.0
    property bool isRound: true

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surface0

        Rectangle {
            width: parent.width * 0.045
            height: parent.height * 0.32
            color: Theme.text
            anchors.bottom: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Bottom
            rotation: (root.currentTime.getHours() % 12) * 30 + root.currentTime.getMinutes() * 0.5 + root.currentTime.getSeconds() * (0.5 / 60)
            radius: width / 2

            Behavior on rotation {
                RotationAnimation {
                    duration: 1000
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.Linear
                }
            }
        }

        Rectangle {
            width: parent.width * 0.03
            height: parent.height * 0.42
            color: Theme.subtext0
            anchors.bottom: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Bottom
            rotation: root.currentTime.getMinutes() * 6 + root.currentTime.getSeconds() * 0.1
            radius: width / 2

            Behavior on rotation {
                RotationAnimation {
                    duration: 1000
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.Linear
                }
            }
        }

        Rectangle {
            width: parent.width * 0.015
            height: parent.height * 0.46
            color: Theme.mauve
            anchors.bottom: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            transformOrigin: Item.Bottom
            rotation: root.currentTime.getSeconds() * 6
            radius: width / 2

            Behavior on rotation {
                RotationAnimation {
                    duration: 1000
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.Linear
                }
            }
        }

        Rectangle {
            width: parent.width * 0.05
            height: width
            color: Theme.mauve
            anchors.centerIn: parent
            radius: width / 2
        }
    }
}
