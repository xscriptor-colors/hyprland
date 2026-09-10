// ═══════════════════════════════════════════════════════════════════════════
// WeatherTab — pestaña "Weather" de SettingsPopup, extraída del Component
// inline para poder compartirla (popup de settings + BarEditor).
//
// `host` = root de SettingsPopup: el cuerpo del tab quedó intacto y usa
// root.s(), root.<rol>, root.highlightedBox, etc. mediante el bloque de
// forwarding de abajo (mismos nombres que el root del popup).
// ═══════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: root

    // ════ Forwarding al host (SettingsPopup) ════
    // El cuerpo de este tab quedó intacto y sigue usando root.s(),
    // root.<rol>, root.highlightedBox… vía estos proxies.
    property var host: null
    readonly property color base: host ? host.base : "#363537"
    readonly property color blue: host ? host.blue : "#5ad4e6"
    readonly property color overlay0: host ? host.overlay0 : "#f7f1ff"
    readonly property color peach: host ? host.peach : "#fd9353"
    readonly property color subtext0: host ? host.subtext0 : "#f7f1ff"
    readonly property color subtext1: host ? host.subtext1 : "#f7f1ff"
    readonly property color surface0: host ? host.surface0 : "#363537"
    readonly property color surface1: host ? host.surface1 : "#363537"
    readonly property color surface2: host ? host.surface2 : "#363537"
    readonly property color text: host ? host.text : "#f7f1ff"
    readonly property color yellow: host ? host.yellow : "#fce566"
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


    // ════ Cuerpo original del tab ════

    function focusApiKey() { apiKeyInput.forceActiveFocus(); }
    function focusCityId() { cityIdInput.forceActiveFocus(); }
    function scrollTo(y) {
        let maxY = Math.max(0, weatherFlickable.contentHeight - weatherFlickable.height);
        weatherFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
    }
    function scrollToBox(approxItemY) {
        let viewH = weatherFlickable.height;
        let itemTop = approxItemY;
        let itemBottom = approxItemY + root.s(80);
        let curY = weatherFlickable.contentY;
        let maxY = Math.max(0, weatherFlickable.contentHeight - viewH);
        if (itemTop < curY + root.s(10)) {
            weatherFlickable.contentY = Math.max(0, itemTop - root.s(20));
        } else if (itemBottom > curY + viewH - root.s(10)) {
            weatherFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
        }
    }

    Component.onCompleted: {
        apiKeyInput.text = Config.weatherApiKey;
        cityIdInput.text = Config.weatherCityId;
    }

    Connections {
        target: Config
        function onWeatherApiKeyChanged() { if (apiKeyInput.text !== Config.weatherApiKey) apiKeyInput.text = Config.weatherApiKey; }
        function onWeatherCityIdChanged() { if (cityIdInput.text !== Config.weatherCityId) cityIdInput.text = Config.weatherCityId; }
    }

    property bool apiKeyVisible: false

    Flickable {
        id: weatherFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: wCol.implicitHeight + root.s(100)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        MouseArea { anchors.fill: parent; onClicked: root.clearHighlight(); z: -1 }

        ColumnLayout {
            id: wCol
            width: parent.width
            spacing: root.s(10)

            // ── Box 0: Instructions ──────────────────────────────────
            Rectangle {
                id: wBox0
                Layout.fillWidth: true
                Layout.preferredHeight: instructionLayout.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 0
                color: isActive ? root.blue : root.surface0
                border.color: isActive ? root.blue : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                clip: true

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 }

                ColumnLayout {
                    id: instructionLayout
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(14)
                    spacing: root.s(10)
                    Text {
                        text: "Weather Widget Setup"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                        color: wBox0.isActive ? root.base : root.text; Layout.bottomMargin: root.s(2)
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                    }
                    RowLayout {
                        spacing: root.s(10)
                        Rectangle {
                            width: root.s(22); height: root.s(22); radius: root.s(22)
                            color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.blue, 0.2)
                            border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.blue; border.width: 1
                            Behavior on color { ColorAnimation { duration: 220 } }
                            Text { anchors.centerIn: parent; text: "1"; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.blue; Behavior on color { ColorAnimation { duration: 220 } } }
                        }
                        Text {
                            text: "Get an API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
                            color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    RowLayout {
                        spacing: root.s(10); Layout.fillWidth: true
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.fillHeight: true
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height + root.s(10)
                                color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2)
                            Repeater {
                                model: ["Go to openweathermap.org & create an account.", "Navigate to profile -> 'My API keys'.", "Generate a new key and paste it below."]
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
                                    radius: root.s(22)
                                    color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0
                                    border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 220 } }
                                    Behavior on border.color { ColorAnimation { duration: 220 } }
                                    RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7)
                                        Text { text: "󰄾"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } }
                                        Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } }
                                    }
                                }
                            }
                        }
                    }
                    RowLayout {
                        spacing: root.s(10)
                        Rectangle {
                            width: root.s(22); height: root.s(22); radius: root.s(22)
                            color: wBox0.isActive ? Qt.alpha(root.base, 0.25) : Qt.alpha(root.peach, 0.2)
                            border.color: wBox0.isActive ? Qt.alpha(root.base, 0.5) : root.peach; border.width: 1
                            Behavior on color { ColorAnimation { duration: 220 } }
                            Text { anchors.centerIn: parent; text: "2"; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: wBox0.isActive ? root.base : root.peach; Behavior on color { ColorAnimation { duration: 220 } } }
                        }
                        Text {
                            text: "Find your City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(13)
                            color: wBox0.isActive ? root.base : root.text; Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    RowLayout {
                        spacing: root.s(10); Layout.fillWidth: true
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.fillHeight: true
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: parent.height - root.s(10); anchors.top: parent.top
                                color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2
                                Behavior on color { ColorAnimation { duration: 220 } }
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: wBox0.isActive ? Qt.alpha(root.base, 0.3) : root.surface2 }
                                    GradientStop { position: 1.0; color: "transparent" }
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(2); Layout.bottomMargin: root.s(2)
                            Repeater {
                                model: ["Search for your city on openweathermap.org.", "Look at the URL (e.g. .../city/2643743).", "Copy the number at the end and paste below."]
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: root.s(30)
                                    radius: root.s(22)
                                    color: wBox0.isActive ? Qt.alpha(root.base, 0.12) : root.surface0
                                    border.color: wBox0.isActive ? Qt.alpha(root.base, 0.2) : root.surface1; border.width: 1
                                    Behavior on color { ColorAnimation { duration: 220 } }
                                    Behavior on border.color { ColorAnimation { duration: 220 } }
                                    RowLayout { anchors.fill: parent; anchors.margins: root.s(7); spacing: root.s(7)
                                        Text { text: "󰄾"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(12); color: wBox0.isActive ? Qt.alpha(root.base, 0.6) : root.overlay0; Behavior on color { ColorAnimation { duration: 220 } } }
                                        Text { text: modelData; font.family: "Inter"; font.pixelSize: root.s(11); color: wBox0.isActive ? Qt.alpha(root.base, 0.85) : root.subtext1; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 220 } } }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        text: "* Note: New API keys may take a few hours to activate."; font.family: "Inter"; font.pixelSize: root.s(10)
                        color: wBox0.isActive ? Qt.alpha(root.base, 0.7) : root.yellow; font.italic: true; Layout.topMargin: root.s(2)
                        Behavior on color { ColorAnimation { duration: 220 } }
                    }
                }
            }

            // ── Box 1: API Key ───────────────────────────────────────
            Rectangle {
                id: wBox1
                Layout.fillWidth: true
                Layout.preferredHeight: apiKeyRow.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 1
                color: isActive ? root.blue : root.surface0
                border.color: isActive ? root.blue : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 }

                ColumnLayout {
                    id: apiKeyRow
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    spacing: root.s(10)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "󰌆"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: wBox1.isActive ? root.base : root.blue
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: root.s(3)
                            Text {
                                text: "API Key"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: wBox1.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "OpenWeather API key"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: wBox1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: root.s(42)
                        radius: root.s(15)
                        color: wBox1.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                        border.color: apiKeyInput.activeFocus
                            ? (wBox1.isActive ? root.base : root.blue)
                            : (wBox1.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        RowLayout {
                            anchors.fill: parent; anchors.margins: root.s(10); spacing: root.s(10)
                            Text {
                                text: "󰌆"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(16)
                                color: wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                            TextInput { 
                                id: apiKeyInput
                                Layout.fillWidth: true; Layout.fillHeight: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: "Hack Nerd Font"; font.pixelSize: root.s(12)
                                color: wBox1.isActive ? root.base : root.text; clip: true; selectByMouse: true
                                echoMode: root.apiKeyVisible ? TextInput.Normal : TextInput.Password
                                passwordCharacter: "•"
                                onTextChanged: Config.weatherApiKey = text
                                Behavior on color { ColorAnimation { duration: 220 } }
                                Text {
                                    text: "Enter API Key..."; color: wBox1.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
                                    visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 220 } }
                                }
                            }
                            Rectangle {
                                width: root.s(24); height: root.s(24); radius: root.s(18); color: "transparent"
                                Text {
                                    anchors.centerIn: parent; text: root.apiKeyVisible ? "󰈈" : "󰈉"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(16)
                                    color: eyeMa.containsMouse
                                        ? (wBox1.isActive ? root.base : root.blue)
                                        : (wBox1.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea { id: eyeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.apiKeyVisible = !root.apiKeyVisible }
                            }
                        }
                    }
                }
            }

            // ── Box 2: City ID ───────────────────────────────────────
            Rectangle {
                id: wBox2
                Layout.fillWidth: true
                Layout.preferredHeight: cityIdRow.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 2
                color: isActive ? root.blue : root.surface0
                border.color: isActive ? root.blue : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 }

                ColumnLayout {
                    id: cityIdRow
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    spacing: root.s(10)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "󰖐"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: wBox2.isActive ? root.base : root.blue
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: root.s(3)
                            Text {
                                text: "City ID"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: wBox2.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "OpenWeather city ID"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: wBox2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: root.s(42)
                        radius: root.s(15)
                        color: wBox2.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                        border.color: cityIdInput.activeFocus
                            ? (wBox2.isActive ? root.base : root.blue)
                            : (wBox2.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        TextInput {
                            id: cityIdInput
                            anchors.fill: parent; anchors.margins: root.s(10)
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(12)
                            color: wBox2.isActive ? root.base : root.text; clip: true; selectByMouse: true
                            onTextChanged: Config.weatherCityId = text
                            Behavior on color { ColorAnimation { duration: 220 } }
                            Text {
                                text: "City ID (e.g. 2624652)"; color: wBox2.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
                                visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                        }
                    }
                }
            }

            // ── Box 3: Temperature Unit ──────────────────────────────
            Rectangle {
                id: wBox3
                Layout.fillWidth: true
                Layout.preferredHeight: unitRow.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 3
                color: isActive ? root.blue : root.surface0
                border.color: isActive ? root.blue : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 }

                ColumnLayout {
                    id: unitRow
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    spacing: root.s(10)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "°C"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: wBox3.isActive ? root.base : root.blue
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: root.s(3)
                            Text {
                                text: "Temperature Unit"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: wBox3.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Celsius / Fahrenheit / Kelvin"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: wBox3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(8)
                        Repeater {
                            model: [{ val: "metric", label: "Celsius" }, { val: "imperial", label: "Fahrenheit" }, { val: "standard", label: "Kelvin" }]
                            Rectangle {
                                Layout.preferredWidth: root.s(88); Layout.preferredHeight: root.s(30); radius: root.s(22)
                                property bool isSelected: Config.weatherUnit === modelData.val
                                property bool parentActive: wBox3.isActive
                                color: isSelected
                                    ? (parentActive ? Qt.alpha(root.base, 0.25) : root.blue)
                                    : (parentActive ? Qt.alpha(root.base, 0.1) : "transparent")
                                border.color: isSelected
                                    ? (parentActive ? Qt.alpha(root.base, 0.6) : root.blue)
                                    : (parentActive ? Qt.alpha(root.base, 0.2) : root.surface1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Text {
                                    anchors.centerIn: parent; text: modelData.label
                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(10); font.capitalization: Font.Capitalize
                                    color: isSelected
                                        ? (parentActive ? root.base : root.base)
                                        : (parentActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.weatherUnit = modelData.val }
                            }
                        }
                    }
                }
            }
        }
    }
}
