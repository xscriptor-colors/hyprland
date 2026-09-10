// ═══════════════════════════════════════════════════════════════════════════
// StartupTab — pestaña "Startup" de SettingsPopup, extraída del Component
// inline para poder compartirla (popup de settings + BarEditor).
//
// `host` = root de SettingsPopup: el cuerpo del tab quedó intacto y usa
// root.s(), root.<rol>, root.highlightedBox, etc. mediante el bloque de
// forwarding de abajo (mismos nombres que el root del popup).
// ═══════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // ════ Forwarding al host (SettingsPopup) ════
    // El cuerpo de este tab quedó intacto y sigue usando root.s(),
    // root.<rol>, root.highlightedBox… vía estos proxies.
    property var host: null
    readonly property color base: host ? host.base : "#363537"
    readonly property color green: host ? host.green : "#7bd88f"
    readonly property color overlay0: host ? host.overlay0 : "#f7f1ff"
    readonly property color red: host ? host.red : "#fc618d"
    readonly property color subtext0: host ? host.subtext0 : "#f7f1ff"
    readonly property color surface0: host ? host.surface0 : "#363537"
    readonly property color surface1: host ? host.surface1 : "#363537"
    readonly property color surface2: host ? host.surface2 : "#363537"
    readonly property color text: host ? host.text : "#f7f1ff"
    function s(val) { return host ? host.s(val) : val; }
    // highlightedBox se escribe desde este tab y desde el host: proxy bidireccional
    // (re-arma el binding tras cada escritura local para no desincronizar).
    property int highlightedBox: host ? host.highlightedBox : -1
    onHighlightedBoxChanged: {
        if (host && host.highlightedBox !== highlightedBox) {
            host.highlightedBox = highlightedBox;
            highlightedBox = Qt.binding(function() { return host ? host.highlightedBox : -1; });
        }
    }

    function clearHighlight() { if (host) host.clearHighlight(); }

    property var dynamicStartupModel: host ? host.startupModel : null
    function saveAllStartup() { if (host) host.saveAllStartup(); }


    // ════ Cuerpo original del tab ════

    function scrollTo(y) {
        let maxY = Math.max(0, startupFlickable.contentHeight - startupFlickable.height);
        startupFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
    }
    function scrollToBottom() {
        startupFlickable.contentY = Math.max(0, startupColLayout.implicitHeight - startupFlickable.height + root.s(100));
    }
    function scrollToBox(approxItemY) {
        let viewH = startupFlickable.height;
        let itemTop = approxItemY;
        let itemBottom = approxItemY + root.s(56);
        let curY = startupFlickable.contentY;
        let maxY = Math.max(0, startupFlickable.contentHeight - viewH);
        if (itemTop < curY + root.s(10)) {
            startupFlickable.contentY = Math.max(0, itemTop - root.s(20));
        } else if (itemBottom > curY + viewH - root.s(10)) {
            startupFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
        }
    }

    Flickable {
        id: startupFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: startupColLayout.implicitHeight + root.s(100)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

        ColumnLayout {
            id: startupColLayout
            width: parent.width
            spacing: root.s(8)

            ListView {
                id: startupListView
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                implicitHeight: dynamicStartupModel.count * root.s(56) + root.s(20)
                model: dynamicStartupModel
                interactive: false
                cacheBuffer: root.s(2000)
                spacing: root.s(8)

                delegate: Rectangle {
                    id: startupRowRect
                    property int outerIndex: index
                    property bool isJumpHighlighted: root.highlightedBox === outerIndex

                    property bool layoutReady: false
                    Component.onCompleted: Qt.callLater(() => layoutReady = true)

                    width: startupListView.width
                    height: root.s(44) + (model.isEditing ? editPanel.implicitHeight + root.s(12) : 0)
                    radius: root.s(18)

                    HoverHandler { id: startupRowHover }
                    property bool isHovered: startupRowHover.hovered || model.isEditing || isJumpHighlighted
                    color: isJumpHighlighted ? root.surface1 : (isHovered ? root.surface1 : root.surface0)
                    border.color: isJumpHighlighted ? root.green : (isHovered ? Qt.alpha(root.green, 0.5) : root.surface1)
                    border.width: isJumpHighlighted ? 2 : 1

                    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.OutExpo } }
                    Behavior on border.width { NumberAnimation { duration: 150 } }

                    MouseArea { anchors.fill: parent; z: -2; onClicked: root.highlightedBox = outerIndex; }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10)

                        Item {
                            Layout.fillWidth: true; Layout.preferredHeight: root.s(24); clip: true

                            Rectangle {
                                id: startupEditBtn
                                width: root.s(26); height: root.s(26); radius: root.s(22)
                                anchors.verticalCenter: parent.verticalCenter
                                x: startupRowRect.isHovered ? parent.width - width : parent.width
                                color: model.isEditing
                                    ? root.green
                                    : (startupEditMa.containsMouse ? root.green : root.surface2)
                                Behavior on x {
                                    enabled: startupRowRect.layoutReady
                                    NumberAnimation { duration: 250; easing.type: Easing.OutQuart }
                                }
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                Text {
                                    anchors.centerIn: parent
                                    text: model.isEditing ? "▴" : "󰏫"
                                    font.family: model.isEditing ? "Inter" : "Hack Nerd Font"
                                    font.pixelSize: root.s(13)
                                    color: model.isEditing
                                        ? root.base
                                        : (startupEditMa.containsMouse ? root.base : root.subtext0)
                                    Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutExpo } }
                                }
                                MouseArea {
                                    id: startupEditMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor;
                                    onClicked: {
                                        dynamicStartupModel.setProperty(outerIndex, "isEditing", !model.isEditing);
                                        if (!model.isEditing) root.forceActiveFocus();
                                    }
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: startupEditBtn.left; anchors.rightMargin: root.s(6)
                                anchors.verticalCenter: parent.verticalCenter; height: parent.height; clip: true

                                Text {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    text: model.command !== "" ? model.command : "(empty command)"
                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(10)
                                    color: model.command !== "" ? root.text : root.overlay0
                                    elide: Text.ElideRight; width: parent.width
                                }
                            }
                        }

                        Item {
                            id: editPanel
                            Layout.fillWidth: true
                            implicitHeight: editPanelCol.implicitHeight
                            visible: model.isEditing
                            opacity: model.isEditing ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

                            ColumnLayout {
                                id: editPanelCol
                                anchors.left: parent.left; anchors.right: parent.right
                                spacing: root.s(8)

                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(32); radius: root.s(22)
                                    color: root.surface0; border.color: cmdInputFocus.activeFocus ? root.green : root.surface2; border.width: 1
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: root.s(10); anchors.rightMargin: root.s(10); spacing: root.s(8)
                                        TextInput {
                                            id: cmdInputFocus
                                            Layout.fillWidth: true; Layout.fillHeight: true; verticalAlignment: TextInput.AlignVCenter
                                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: root.text; clip: true; selectByMouse: true
                                            text: model.command
                                            onTextChanged: dynamicStartupModel.setProperty(outerIndex, "command", text)
                                            Keys.onEscapePressed: { dynamicStartupModel.setProperty(outerIndex, "isEditing", false); root.forceActiveFocus(); }
                                            Text {
                                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                                text: "e.g. waybar, dunst, nm-applet"
                                                color: Qt.alpha(root.subtext0, 0.45); visible: !parent.text && !parent.activeFocus
                                                font.family: "Hack Nerd Font"; font.pixelSize: root.s(10)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignRight; spacing: root.s(8)

                                    Rectangle {
                                        Layout.preferredHeight: root.s(28); Layout.preferredWidth: startupDelRow.implicitWidth + root.s(16)
                                        radius: root.s(22)
                                        color: startupDelMa.containsMouse ? root.red : root.surface1
                                        border.color: startupDelMa.containsMouse ? root.red : root.surface2; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        RowLayout {
                                            id: startupDelRow; anchors.centerIn: parent; spacing: root.s(5)
                                            Text { text: "󰆴"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: startupDelMa.containsMouse ? root.base : root.red; Behavior on color { ColorAnimation { duration: 150 } } }
                                            Text { text: "Delete"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: startupDelMa.containsMouse ? root.base : root.red; Behavior on color { ColorAnimation { duration: 150 } } }
                                        }
                                        MouseArea { id: startupDelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { dynamicStartupModel.remove(outerIndex); root.saveAllStartup(); } }
                                    }

                                    Rectangle {
                                        Layout.preferredHeight: root.s(28); Layout.preferredWidth: startupDoneRow.implicitWidth + root.s(16)
                                        radius: root.s(22)
                                        color: startupDoneMa.containsMouse ? root.green : root.surface1
                                        border.color: startupDoneMa.containsMouse ? root.green : root.surface2; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        RowLayout {
                                            id: startupDoneRow; anchors.centerIn: parent; spacing: root.s(5)
                                            Text { text: "󰸞"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: startupDoneMa.containsMouse ? root.base : root.green; Behavior on color { ColorAnimation { duration: 150 } } }
                                            Text { text: "Done"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); color: startupDoneMa.containsMouse ? root.base : root.green; Behavior on color { ColorAnimation { duration: 150 } } }
                                        }
                                        MouseArea {
                                            id: startupDoneMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dynamicStartupModel.setProperty(outerIndex, "isEditing", false);
                                                root.forceActiveFocus();
                                                root.saveAllStartup();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
