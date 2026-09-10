// ═══════════════════════════════════════════════════════════════════════════
// GeneralTab — pestaña "General" de SettingsPopup, extraída del Component
// inline para poder compartirla (popup de settings + BarEditor).
//
// `host` = root de SettingsPopup: el cuerpo del tab quedó intacto y usa
// root.s(), root.<rol>, root.highlightedBox, etc. mediante el bloque de
// forwarding de abajo (mismos nombres que el root del popup).
// ═══════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.."

Item {
    id: root

    // ════ Forwarding al host (SettingsPopup) ════
    // El cuerpo de este tab quedó intacto y sigue usando root.s(),
    // root.<rol>, root.highlightedBox… vía estos proxies.
    property var host: null
    readonly property color base: host ? host.base : "#363537"
    readonly property color blue: host ? host.blue : "#5ad4e6"
    readonly property color green: host ? host.green : "#7bd88f"
    readonly property color mauve: host ? host.mauve : "#948ae3"
    readonly property color peach: host ? host.peach : "#fd9353"
    readonly property color red: host ? host.red : "#fc618d"
    readonly property color sapphire: host ? host.sapphire : "#5ad4e6"
    readonly property color subtext0: host ? host.subtext0 : "#f7f1ff"
    readonly property color surface0: host ? host.surface0 : "#363537"
    readonly property color surface1: host ? host.surface1 : "#363537"
    readonly property color surface2: host ? host.surface2 : "#363537"
    readonly property color teal: host ? host.teal : "#5ad4e6"
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

    // isLayoutDropdownOpen se escribe desde este tab y desde el host: proxy bidireccional
    // (re-arma el binding tras cada escritura local para no desincronizar).
    property bool isLayoutDropdownOpen: host ? host.isLayoutDropdownOpen : false
    onIsLayoutDropdownOpenChanged: {
        if (host && host.isLayoutDropdownOpen !== isLayoutDropdownOpen) {
            host.isLayoutDropdownOpen = isLayoutDropdownOpen;
            isLayoutDropdownOpen = Qt.binding(function() { return host ? host.isLayoutDropdownOpen : false; });
        }
    }

    function appScaleStep(dir) { if (host) host.appScaleStep(dir); }


    // ════ Movidos desde SettingsPopup.qml (exclusivos de este tab) ════

    property var kbToggleModelArr: [
        { label: "Alt + Shift", val: "grp:alt_shift_toggle" },
        { label: "Win + Space", val: "grp:win_space_toggle" },
        { label: "Caps Lock", val: "grp:caps_toggle" },
        { label: "Ctrl + Shift", val: "grp:ctrl_shift_toggle" },
        { label: "Ctrl + Alt", val: "grp:ctrl_alt_toggle" },
        { label: "Right Alt", val: "grp:toggle" },
        { label: "No Toggle", val: "" }
    ]

    function getKbToggleLabel(val) {
        for (let i = 0; i < root.kbToggleModelArr.length; i++) {
            if (root.kbToggleModelArr[i].val === val) return root.kbToggleModelArr[i].label;
        }
        return "Alt + Shift";
    }

    ListModel {
        id: langModel

        // --- Americas ---
        ListElement { code: "us"; name: "English (US)" }
        ListElement { code: "ca"; name: "English/French (Canada)" }
        ListElement { code: "ca-multix"; name: "Canadian Multilingual" }
        ListElement { code: "latam"; name: "Spanish (Latin America)" }
        ListElement { code: "br"; name: "Portuguese (Brazil)" }
        ListElement { code: "ar"; name: "Arabic (Latin America)" }
        ListElement { code: "bo"; name: "Bolivia" }
        ListElement { code: "cl"; name: "Chile" }
        ListElement { code: "co"; name: "Colombia" }
        ListElement { code: "cr"; name: "Costa Rica" }
        ListElement { code: "cu"; name: "Cuba" }
        ListElement { code: "do"; name: "Dominican Republic" }
        ListElement { code: "ec"; name: "Ecuador" }
        ListElement { code: "sv"; name: "El Salvador" }
        ListElement { code: "gt"; name: "Guatemala" }
        ListElement { code: "hn"; name: "Honduras" }
        ListElement { code: "mx"; name: "Mexico" }
        ListElement { code: "ni"; name: "Nicaragua" }
        ListElement { code: "pa"; name: "Panama" }
        ListElement { code: "py"; name: "Paraguay" }
        ListElement { code: "pe"; name: "Peru" }
        ListElement { code: "pr"; name: "Puerto Rico" }
        ListElement { code: "uy"; name: "Uruguay" }
        ListElement { code: "ve"; name: "Venezuela" }

        // --- Europe (West, Central, & North) ---
        ListElement { code: "gb"; name: "English (UK)" }
        ListElement { code: "ie"; name: "English (Ireland)" }
        ListElement { code: "gd"; name: "Scottish Gaelic" }
        ListElement { code: "cy-gb"; name: "Welsh" }
        ListElement { code: "fr"; name: "French" }
        ListElement { code: "be"; name: "Belgian" }
        ListElement { code: "ch"; name: "Swiss" }
        ListElement { code: "de"; name: "German" }
        ListElement { code: "at"; name: "Austrian" }
        ListElement { code: "nl"; name: "Dutch" }
        ListElement { code: "lu"; name: "Luxembourgish" }
        ListElement { code: "es"; name: "Spanish" }
        ListElement { code: "pt"; name: "Portuguese" }
        ListElement { code: "it"; name: "Italian" }
        ListElement { code: "mt"; name: "Maltese" }
        ListElement { code: "se"; name: "Swedish" }
        ListElement { code: "no"; name: "Norwegian" }
        ListElement { code: "dk"; name: "Danish" }
        ListElement { code: "fi"; name: "Finnish" }
        ListElement { code: "is"; name: "Icelandic" }
        ListElement { code: "fo"; name: "Faroese" }
        ListElement { code: "gl"; name: "Greenlandic" }
        ListElement { code: "pl"; name: "Polish" }
        ListElement { code: "cz"; name: "Czech" }
        ListElement { code: "sk"; name: "Slovak" }
        ListElement { code: "hu"; name: "Hungarian" }
        ListElement { code: "ad"; name: "Andorra" }
        ListElement { code: "mc"; name: "Monaco" }
        ListElement { code: "sm"; name: "San Marino" }
        ListElement { code: "va"; name: "Vatican" }
        ListElement { code: "epo"; name: "Esperanto" }
        ListElement { code: "eu"; name: "Basque" }
        ListElement { code: "ca-fr"; name: "Catalan" }

        // --- Europe (East) & Caucasus ---
        ListElement { code: "ru"; name: "Russian" }
        ListElement { code: "ua"; name: "Ukrainian" }
        ListElement { code: "by"; name: "Belarusian" }
        ListElement { code: "ro"; name: "Romanian" }
        ListElement { code: "bg"; name: "Bulgarian" }
        ListElement { code: "rs"; name: "Serbian" }
        ListElement { code: "hr"; name: "Croatian" }
        ListElement { code: "si"; name: "Slovenian" }
        ListElement { code: "mk"; name: "Macedonian" }
        ListElement { code: "ba"; name: "Bosnian" }
        ListElement { code: "me"; name: "Montenegrin" }
        ListElement { code: "gr"; name: "Greek" }
        ListElement { code: "cy"; name: "Cyprus" }
        ListElement { code: "ee"; name: "Estonian" }
        ListElement { code: "lv"; name: "Latvian" }
        ListElement { code: "lt"; name: "Lithuanian" }
        ListElement { code: "md"; name: "Moldovan" }
        ListElement { code: "am"; name: "Armenian" }
        ListElement { code: "ge"; name: "Georgian" }
        ListElement { code: "az"; name: "Azerbaijani" }
        ListElement { code: "kz"; name: "Kazakh" }
        ListElement { code: "kg"; name: "Kyrgyz" }
        ListElement { code: "tj"; name: "Tajik" }
        ListElement { code: "tm"; name: "Turkmen" }
        ListElement { code: "uz"; name: "Uzbek" }
        ListElement { code: "mn"; name: "Mongolian" }
        ListElement { code: "tat"; name: "Tatar" }
        ListElement { code: "chu"; name: "Chuvash" }
        ListElement { code: "os"; name: "Ossetian" }
        ListElement { code: "udm"; name: "Udmurt" }
        ListElement { code: "kbd"; name: "Kabardian" }
	ListElement { code: "che"; name: "Chechen" }
	ListElement { code: "tr"; name: "Turkish" }

        // --- Asia & Pacific ---
        ListElement { code: "au"; name: "English (Australia)" }
        ListElement { code: "nz"; name: "English (New Zealand)" }
        ListElement { code: "cn"; name: "Chinese" }
        ListElement { code: "jp"; name: "Japanese" }
        ListElement { code: "kr"; name: "Korean" }
        ListElement { code: "tw"; name: "Taiwanese" }
        ListElement { code: "hk"; name: "Hong Kong" }
        ListElement { code: "in"; name: "Indian" }
        ListElement { code: "pk"; name: "Pakistani" }
        ListElement { code: "bd"; name: "Bangla" }
        ListElement { code: "lk"; name: "Sri Lankan" }
        ListElement { code: "np"; name: "Nepali" }
        ListElement { code: "mv"; name: "Maldivian (Dhivehi)" }
        ListElement { code: "bt"; name: "Bhutanese (Dzongkha)" }
        ListElement { code: "af"; name: "Afghan (Pashto/Dari)" }
        ListElement { code: "th"; name: "Thai" }
        ListElement { code: "vn"; name: "Vietnamese" }
        ListElement { code: "la"; name: "Lao" }
        ListElement { code: "mm"; name: "Burmese" }
        ListElement { code: "kh"; name: "Khmer" }
        ListElement { code: "id"; name: "Indonesian" }
        ListElement { code: "my"; name: "Malay" }
        ListElement { code: "ph"; name: "Filipino" }
        ListElement { code: "sg"; name: "Singaporean" }
        ListElement { code: "bn"; name: "Bengali" }
        ListElement { code: "ta"; name: "Tamil" }
        ListElement { code: "te"; name: "Telugu" }
        ListElement { code: "gu"; name: "Gujarati" }
        ListElement { code: "pa"; name: "Punjabi" }
        ListElement { code: "ml"; name: "Malayalam" }
        ListElement { code: "kn"; name: "Kannada" }
        ListElement { code: "or"; name: "Odia" }
        ListElement { code: "as"; name: "Assamese" }
        ListElement { code: "ur"; name: "Urdu" }

        // --- Middle East & North Africa ---
        ListElement { code: "il"; name: "Hebrew" }
        ListElement { code: "ara"; name: "Arabic" }
        ListElement { code: "iq"; name: "Iraqi" }
        ListElement { code: "sy"; name: "Syrian" }
        ListElement { code: "ir"; name: "Persian (Farsi)" }
        ListElement { code: "ma"; name: "Moroccan" }
        ListElement { code: "dz"; name: "Algerian" }
        ListElement { code: "eg"; name: "Egyptian" }
        ListElement { code: "ly"; name: "Libyan" }
        ListElement { code: "tn"; name: "Tunisian" }
        ListElement { code: "sd"; name: "Sudanese" }
        ListElement { code: "lb"; name: "Lebanese" }
        ListElement { code: "jo"; name: "Jordanian" }
        ListElement { code: "ps"; name: "Palestinian" }
        ListElement { code: "sa"; name: "Saudi Arabian" }
        ListElement { code: "kw"; name: "Kuwaiti" }
        ListElement { code: "bh"; name: "Bahraini" }
        ListElement { code: "qa"; name: "Qatari" }
        ListElement { code: "ae"; name: "UAE" }
        ListElement { code: "om"; name: "Omani" }
        ListElement { code: "ye"; name: "Yemeni" }

        // --- Sub-Saharan Africa ---
        ListElement { code: "za"; name: "English (South Africa)" }
        ListElement { code: "ng"; name: "Nigerian" }
        ListElement { code: "et"; name: "Ethiopian" }
        ListElement { code: "sn"; name: "Senegalese" }
        ListElement { code: "ke"; name: "Kenyan" }
        ListElement { code: "tz"; name: "Tanzanian" }
        ListElement { code: "gh"; name: "Ghanaian" }
        ListElement { code: "cm"; name: "Cameroonian" }
        ListElement { code: "ci"; name: "Ivorian" }
        ListElement { code: "ml"; name: "Malian" }
        ListElement { code: "gn"; name: "Guinean" }
        ListElement { code: "cd"; name: "Congolese (DRC)" }
        ListElement { code: "cg"; name: "Congolese (RC)" }
        ListElement { code: "rw"; name: "Rwandan" }
        ListElement { code: "bi"; name: "Burundian" }
        ListElement { code: "ug"; name: "Ugandan" }
        ListElement { code: "zm"; name: "Zambian" }
        ListElement { code: "zw"; name: "Zimbabwean" }
        ListElement { code: "mw"; name: "Malawian" }
        ListElement { code: "mz"; name: "Mozambican" }
        ListElement { code: "ao"; name: "Angolan" }
        ListElement { code: "na"; name: "Namibian" }
        ListElement { code: "bw"; name: "Motswana" }
        ListElement { code: "mg"; name: "Malagasy" }
        ListElement { code: "so"; name: "Somali" }
        ListElement { code: "dj"; name: "Djiboutian" }
        ListElement { code: "er"; name: "Eritrean" }
        ListElement { code: "tg"; name: "Togolese" }
        ListElement { code: "bj"; name: "Beninese" }
        ListElement { code: "bf"; name: "Burkinabe" }
        ListElement { code: "ne"; name: "Nigerien" }
        ListElement { code: "td"; name: "Chadian" }
        ListElement { code: "cf"; name: "Central African" }
        ListElement { code: "gq"; name: "Equatorial Guinean" }
        ListElement { code: "ga"; name: "Gabonese" }

        // --- Alternative Layouts ---
        ListElement { code: "us-intl"; name: "US International" }
        ListElement { code: "dvorak"; name: "US Dvorak" }
        ListElement { code: "colemak"; name: "US Colemak" }
        ListElement { code: "norman"; name: "US Norman" }
        ListElement { code: "workman"; name: "US Workman" }
        ListElement { code: "math"; name: "Mathematics" }
        ListElement { code: "brai"; name: "Braille" }
    }

    ListModel { id: pathSuggestModel }
    ListModel { id: langSearchModel }

    function updateLangSearch(query) {
        langSearchModel.clear();
        let q = query.trim().toLowerCase();
        for (let i = 0; i < langModel.count; i++) {
            let item = langModel.get(i);
            if (q === "" || item.code.toLowerCase().includes(q) || item.name.toLowerCase().includes(q)) {
                langSearchModel.append({ code: item.code, name: item.name });
            }
        }
    }

    Process {
        id: pathSuggestProc
        property string query: ""
        command: ["bash", "-c", "eval ls -dp " + query + "* 2>/dev/null | grep '/$' | head -n 5 || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                pathSuggestModel.clear();
                if (this.text) {
                    let lines = this.text.trim().split('\n');
                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i];
                        if (line.length > 0) {
                            if (line.endsWith('/')) { line = line.slice(0, -1); }
                            pathSuggestModel.append({ path: line });
                        }
                    }
                }
            }
        }
    }

    // ════ Cuerpo original del tab ════

    function focusLangInput() { langInput.forceActiveFocus(); }
    function focusWpDirInput() { wpDirInput.forceActiveFocus(); }
    function layoutListIncrementIndex() { layoutListView.incrementCurrentIndex(); }
    function layoutListDecrementIndex() { layoutListView.decrementCurrentIndex(); }
    function acceptLayoutSelection() {
        if (layoutListView.currentIndex >= 0 && layoutListView.currentIndex < root.kbToggleModelArr.length) {
            Config.kbOptions = root.kbToggleModelArr[layoutListView.currentIndex].val;
        }
    }
    function scrollTo(y) {
        let maxY = Math.max(0, generalFlickable.contentHeight - generalFlickable.height);
        generalFlickable.contentY = Math.max(0, Math.min(y - root.s(40), maxY > 0 ? maxY : y));
    }
    function scrollToBox(approxItemY) {
        let viewH = generalFlickable.height;
        let itemTop = approxItemY;
        let itemBottom = approxItemY + root.s(80);
        let curY = generalFlickable.contentY;
        let maxY = Math.max(0, generalFlickable.contentHeight - viewH);
        if (itemTop < curY + root.s(10)) {
            generalFlickable.contentY = Math.max(0, itemTop - root.s(20));
        } else if (itemBottom > curY + viewH - root.s(10)) {
            generalFlickable.contentY = Math.min(maxY, itemBottom - viewH + root.s(20));
        }
    }

    Flickable {
        id: generalFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsMainCol.implicitHeight + root.s(100)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: root.clearHighlight()
            z: -1
        }

        ColumnLayout {
            id: settingsMainCol
            width: parent.width
            spacing: root.s(10)

            // ── Box 0: Guide on startup ──────────────────────────────
            Rectangle {
                id: box0
                Layout.fillWidth: true
                Layout.preferredHeight: guideRow.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 0
                color: isActive ? root.peach : root.surface0
                border.color: isActive ? root.peach : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 0; z: -1 }

                RowLayout {
                    id: guideRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: root.s(16)
                    spacing: root.s(14)
                    Item {
                        Layout.preferredWidth: root.s(22)
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: "󰑊"
                            font.family: "Hack Nerd Font"
                            font.pixelSize: root.s(18)
                            color: box0.isActive ? root.base : root.peach
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: root.s(3)
                        Text {
                            text: "Guide on startup"
                            font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                            color: box0.isActive ? root.base : root.text
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        Text {
                            text: "Launch on login"
                            font.family: "Inter"; font.pixelSize: root.s(11)
                            color: box0.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7)
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.preferredWidth: root.s(40)
                        Layout.preferredHeight: root.s(22)
                        radius: root.s(22)
                        scale: toggle1Ma.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        color: Config.openGuideAtStartup
                            ? (box0.isActive ? root.base : root.peach)
                            : Qt.alpha(root.surface2, box0.isActive ? 0.4 : 1.0)
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        Rectangle {
                            width: root.s(16); height: root.s(16); radius: root.s(18)
                            color: Config.openGuideAtStartup
                                ? (box0.isActive ? root.peach : root.base)
                                : (box0.isActive ? root.peach : root.surface0)
                            y: root.s(3); x: Config.openGuideAtStartup ? root.s(21) : root.s(3)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        MouseArea { id: toggle1Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.openGuideAtStartup = !Config.openGuideAtStartup; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // ── Box 1: Help icon ─────────────────────────────────────
            Rectangle {
                id: box1
                Layout.fillWidth: true
                Layout.preferredHeight: helpIconRow.implicitHeight + root.s(28)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 1
                color: isActive ? root.blue : root.surface0
                border.color: isActive ? root.blue : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 1; z: -1 }

                RowLayout {
                    id: helpIconRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: root.s(16)
                    spacing: root.s(14)
                    Item {
                        Layout.preferredWidth: root.s(22)
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent; text: "󰋖"
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                            color: box1.isActive ? root.base : root.blue
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                        Text {
                            text: "Help icon"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                            color: box1.isActive ? root.base : root.text; Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        Text {
                            text: "Show button in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
                            color: box1.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.preferredWidth: root.s(40); Layout.preferredHeight: root.s(22); radius: root.s(22)
                        scale: toggle2Ma.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        color: Config.topbarHelpIcon
                            ? (box1.isActive ? root.base : root.blue)
                            : Qt.alpha(root.surface2, box1.isActive ? 0.4 : 1.0)
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        Rectangle {
                            width: root.s(16); height: root.s(16); radius: root.s(18)
                            color: Config.topbarHelpIcon
                                ? (box1.isActive ? root.blue : root.base)
                                : (box1.isActive ? root.blue : root.surface0)
                            y: root.s(3); x: Config.topbarHelpIcon ? root.s(21) : root.s(3)
                            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        MouseArea { id: toggle2Ma; anchors.fill: parent; hoverEnabled: true; onClicked: Config.topbarHelpIcon = !Config.topbarHelpIcon; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // ── Box 2: UI Scale ──────────────────────────────────────
            Rectangle {
                id: box2
                Layout.fillWidth: true
                Layout.preferredHeight: col2.implicitHeight + root.s(32)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 2
                color: isActive ? root.sapphire : root.surface0
                border.color: isActive ? root.sapphire : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 2; z: -1 }

                ColumnLayout {
                    id: col2
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "󰁦"
                                font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: box2.isActive ? root.base : root.sapphire
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                            Text {
                                text: "UI Scale"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box2.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Base size scalar"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box2.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
                            Rectangle {
                                width: root.s(28); height: root.s(28); radius: root.s(22)
                                color: sMinusMa.pressed
                                    ? Qt.alpha(root.base, 0.3)
                                    : (sMinusMa.containsMouse
                                        ? Qt.alpha(root.base, 0.2)
                                        : Qt.alpha(root.base, 0.15))
                                scale: sMinusMa.pressed ? 0.90 : (sMinusMa.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent; text: "-"
                                    font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: root.s(15)
                                    color: box2.isActive ? root.base : root.sapphire
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                MouseArea { id: sMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.max(0.5, (Config.uiScale - 0.1).toFixed(1)) }
                            }
                            Text { 
                                text: Config.uiScale.toFixed(1) + "x"
                                font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(13)
                                color: box2.isActive ? root.base : root.sapphire
                                Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Rectangle {
                                width: root.s(28); height: root.s(28); radius: root.s(22)
                                color: sPlusMa.pressed
                                    ? Qt.alpha(root.base, 0.3)
                                    : (sPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                scale: sPlusMa.pressed ? 0.90 : (sPlusMa.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent; text: "+"
                                    font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: root.s(15)
                                    color: box2.isActive ? root.base : root.sapphire
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                MouseArea { id: sPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.uiScale = Math.min(2.0, (Config.uiScale + 0.1).toFixed(1)) }
                            }
                        }
                    }
                }
            }

            // ── Box 3: Keyboard layouts ──────────────────────────────
            Rectangle {
                id: box3
                Layout.fillWidth: true
                Layout.preferredHeight: col3lang.implicitHeight + root.s(32)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 3
                color: isActive ? root.green : root.surface0
                border.color: isActive ? root.green : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 3; z: -1 }

                ColumnLayout {
                    id: col3lang
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    spacing: root.s(16)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                            Text {
                                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰌌"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: box3.isActive ? root.base : root.green
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                            Text {
                                text: "Keyboard layouts"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box3.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Matches hyprland.conf. Click ✖ to remove."; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box3.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Flow {
                                Layout.fillWidth: true; spacing: root.s(6); Layout.topMargin: root.s(8)
                                Repeater {
                                    model: Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : []
                                    Rectangle {
                                        width: langChipLayout.implicitWidth + root.s(20); height: root.s(26); radius: root.s(24)
                                        color: box3.isActive ? Qt.alpha(root.base, 0.2) : root.surface1
                                        border.color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.4) : "transparent")
                                        border.width: chipMa.containsMouse ? 1 : 0
                                        scale: chipMa.containsMouse ? 1.05 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        RowLayout {
                                            id: langChipLayout; anchors.centerIn: parent; spacing: root.s(6)
                                            Text {
                                                text: modelData; font.family: "Hack Nerd Font"; font.weight: Font.Medium; font.pixelSize: root.s(11)
                                                color: chipMa.containsMouse ? root.red : (box3.isActive ? root.base : root.text)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                            Text {
                                                text: "✖"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                                                color: chipMa.containsMouse ? root.red : (box3.isActive ? Qt.alpha(root.base, 0.6) : root.subtext0)
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                        MouseArea {
                                            id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let arr = Config.language.split(",").filter(x => x.trim() !== "");
                                                arr.splice(index, 1);
                                                Config.language = arr.join(",");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                        radius: root.s(15)
                        color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                        border.color: langInput.activeFocus
                            ? (box3.isActive ? root.base : root.green)
                            : (box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        TextInput {
                            id: langInput
                            anchors.fill: parent; anchors.margins: root.s(9)
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                            color: box3.isActive ? root.base : root.text; clip: true; selectByMouse: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                                    if (langSearchModel.count > 0) { langListView.incrementCurrentIndex(); event.accepted = true; }
                                } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
                                    if (langSearchModel.count > 0) { langListView.decrementCurrentIndex(); event.accepted = true; }
                                }
                            }
                            Keys.onReturnPressed: (event) => langInputAccept(event)
                            Keys.onEnterPressed: (event) => langInputAccept(event)
                            function langInputAccept(event) {
                                if (langSearchModel.count > 0 && langListView.currentIndex >= 0) {
                                    let item = langSearchModel.get(langListView.currentIndex);
                                    let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
                                    if (!arr.includes(item.code)) { arr.push(item.code); Config.language = arr.join(","); }
                                }
                                text = ""; focus = false; event.accepted = true;
                            }
                            onActiveFocusChanged: { if (activeFocus) root.updateLangSearch(text); }
                            onTextChanged: { root.updateLangSearch(text); }
                            Text {
                                text: "Search to add..."
                                color: box3.isActive ? Qt.alpha(root.base, 0.5) : Qt.alpha(root.subtext0, 0.7)
                                visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: langInput.activeFocus && langSearchModel.count > 0 ? Math.min(root.s(160), langSearchModel.count * root.s(30) + root.s(8)) : 0
                        radius: root.s(15)
                        color: box3.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                        border.color: box3.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                        border.width: 1
                        clip: true
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        ListView {
                            id: langListView
                            anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                            model: langSearchModel; interactive: true
                            opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }
                            delegate: Rectangle {
                                width: parent.width - root.s(8); height: root.s(30)
                                anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(18)
                                property bool isHovered: sMa.containsMouse
                                color: isHovered
                                    ? Qt.alpha(box3.isActive ? root.base : root.green, 0.2)
                                    : (ListView.isCurrentItem ? Qt.alpha(box3.isActive ? root.base : root.green, 0.1) : "transparent")
                                Behavior on color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8); spacing: root.s(8)
                                    Text { text: model.code; font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(11); color: box3.isActive ? root.base : root.text; Behavior on color { ColorAnimation { duration: 150 } } }
                                    Text { text: model.name; font.family: "Inter"; font.pixelSize: root.s(11); color: box3.isActive ? Qt.alpha(root.base, 0.7) : Qt.alpha(root.subtext0, 0.7); elide: Text.ElideRight; Layout.fillWidth: true; Behavior on color { ColorAnimation { duration: 150 } } }
                                }
                                MouseArea {
                                    id: sMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let arr = Config.language ? Config.language.split(",").filter(x => x.trim() !== "") : [];
                                        if (!arr.includes(model.code)) { arr.push(model.code); Config.language = arr.join(","); }
                                        langInput.text = ""; langInput.focus = false;
                                    }
                                }
                            }
                        }
                    }
                }                       
            }

            // ── Box 4: Layout shortcut ───────────────────────────────
            Rectangle {
                id: box4
                Layout.fillWidth: true
                Layout.preferredHeight: col4layout.implicitHeight + root.s(32)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 4
                color: isActive ? root.teal : root.surface0
                border.color: isActive ? root.teal : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 4; z: -1 }

                ColumnLayout {
                    id: col4layout
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    spacing: root.s(16)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                            Text {
                                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰯍"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: box4.isActive ? root.base : root.teal
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                            Text {
                                text: "Layout shortcut"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Toggle combination"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box4.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                                radius: root.s(15)
                                color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                border.color: root.isLayoutDropdownOpen
                                    ? (box4.isActive ? root.base : root.teal)
                                    : (box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: root.s(9)
                                    Text {
                                        text: root.getKbToggleLabel(Config.kbOptions)
                                        font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                                        color: box4.isActive ? root.base : root.text; Layout.fillWidth: true
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                    Text {
                                        text: root.isLayoutDropdownOpen ? "▴" : "▾"; font.pixelSize: root.s(12)
                                        color: box4.isActive ? Qt.alpha(root.base, 0.7) : root.subtext0
                                        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.isLayoutDropdownOpen = !root.isLayoutDropdownOpen;
                                        if (root.isLayoutDropdownOpen) {
                                            let idx = root.kbToggleModelArr.findIndex(x => x.val === Config.kbOptions);
                                            layoutListView.currentIndex = Math.max(0, idx);
                                        }
                                        root.forceActiveFocus();
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.isLayoutDropdownOpen ? root.kbToggleModelArr.length * root.s(30) + root.s(8) : 0
                                radius: root.s(15)
                                color: box4.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                border.color: box4.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                                border.width: 1
                                clip: true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                ListView {
                                    id: layoutListView
                                    anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                                    model: root.kbToggleModelArr; interactive: false
                                    opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    delegate: Rectangle {
                                        width: parent.width - root.s(8); height: root.s(30)
                                        anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(18)
                                        property bool isHovered: toggleMa.containsMouse
                                        color: isHovered
                                            ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.2)
                                            : (ListView.isCurrentItem ? Qt.alpha(box4.isActive ? root.base : root.teal, 0.1) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: root.s(8); anchors.rightMargin: root.s(8)
                                            Text {
                                                text: modelData.label; font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                                                color: Config.kbOptions === modelData.val
                                                    ? (box4.isActive ? root.base : root.teal)
                                                    : (box4.isActive ? Qt.alpha(root.base, 0.8) : root.text)
                                                Layout.fillWidth: true
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                        MouseArea { id: toggleMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Config.kbOptions = modelData.val; root.isLayoutDropdownOpen = false; } }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Box 5: Wallpaper directory ───────────────────────────
            Rectangle {
                id: box5
                Layout.fillWidth: true
                Layout.preferredHeight: col5wp.implicitHeight + root.s(32)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 5
                color: isActive ? root.mauve : root.surface0
                border.color: isActive ? root.mauve : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 5; z: -1 }

                ColumnLayout {
                    id: col5wp
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignTop; Layout.topMargin: root.s(2)
                            Text {
                                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰋩"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: box5.isActive ? root.base : root.mauve
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; spacing: root.s(3)
                            Text {
                                text: "Wallpaper directory"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                                color: box5.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Absolute source path"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box5.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: root.s(34); Layout.topMargin: root.s(8)
                                radius: root.s(15)
                                color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                border.color: wpDirInput.activeFocus
                                    ? (box5.isActive ? root.base : root.mauve)
                                    : (box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface2)
                                border.width: 1
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                TextInput {
                                    id: wpDirInput
                                    anchors.fill: parent; anchors.margins: root.s(9)
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: Config.wallpaperDir
                                    font.family: "Hack Nerd Font"; font.pixelSize: root.s(11)
                                    color: box5.isActive ? root.base : root.text; clip: true; selectByMouse: true
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down) {
                                            if (pathSuggestModel.count > 0) { wpSuggestListView.incrementCurrentIndex(); event.accepted = true; }
                                        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) {
                                            if (pathSuggestModel.count > 0) { wpSuggestListView.decrementCurrentIndex(); event.accepted = true; }
                                        }
                                    }
                                    Keys.onReturnPressed: (event) => wpDirInputAccept(event)
                                    Keys.onEnterPressed: (event) => wpDirInputAccept(event)
                                    function wpDirInputAccept(event) {
                                        if (pathSuggestModel.count > 0 && wpSuggestListView.currentIndex >= 0) {
                                            let item = pathSuggestModel.get(wpSuggestListView.currentIndex);
                                            if (item) { text = item.path; Config.wallpaperDir = text; }
                                        }
                                        pathSuggestModel.clear(); focus = false; event.accepted = true;
                                    }
                                    onActiveFocusChanged: {
                                        if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
                                    }
                                    onTextChanged: {
                                        Config.wallpaperDir = text;
                                        if (activeFocus) { pathSuggestProc.query = text; pathSuggestProc.running = false; pathSuggestProc.running = true; }
                                    }
                                    Text {
                                        text: "Enter directory..."; color: box5.isActive ? Qt.alpha(root.base, 0.5) : root.subtext0
                                        visible: !parent.text && !parent.activeFocus; font: parent.font; anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: wpDirInput.activeFocus && pathSuggestModel.count > 0 ? pathSuggestModel.count * root.s(28) + root.s(8) : 0
                                radius: root.s(15)
                                color: box5.isActive ? Qt.alpha(root.base, 0.15) : root.surface0
                                border.color: box5.isActive ? Qt.alpha(root.base, 0.3) : root.surface1
                                border.width: 1
                                clip: true
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                ListView {
                                    id: wpSuggestListView
                                    anchors.fill: parent; anchors.topMargin: root.s(4); anchors.bottomMargin: root.s(4)
                                    model: pathSuggestModel; interactive: false
                                    opacity: parent.Layout.preferredHeight > root.s(10) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                    delegate: Rectangle {
                                        width: parent.width - root.s(8); height: root.s(28)
                                        anchors.horizontalCenter: parent.horizontalCenter; radius: root.s(18)
                                        property bool isHovered: suggestMa.containsMouse
                                        color: isHovered
                                            ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.2)
                                            : (ListView.isCurrentItem ? Qt.alpha(box5.isActive ? root.base : root.mauve, 0.1) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; x: root.s(8)
                                            text: model.path; font.family: "Hack Nerd Font"; font.pixelSize: root.s(10)
                                            color: box5.isActive ? root.base : root.text
                                            elide: Text.ElideMiddle; width: parent.width - root.s(16)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        MouseArea { id: suggestMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { wpDirInput.text = model.path; pathSuggestModel.clear(); wpDirInput.focus = false; } }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Box 6: Workspaces ────────────────────────────────────
            Rectangle {
                id: box6
                Layout.fillWidth: true
                Layout.preferredHeight: col6ws.implicitHeight + root.s(32)
                radius: root.s(26)

                property bool isActive: root.highlightedBox === 6
                color: isActive ? root.red : root.surface0
                border.color: isActive ? root.red : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 6; z: -1 }

                ColumnLayout {
                    id: col6ws
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: root.s(16)
                    RowLayout {
                        Layout.fillWidth: true; spacing: root.s(14)
                        Item {
                            Layout.preferredWidth: root.s(22); Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent; text: "󰽿"; font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                                color: box6.isActive ? root.base : root.red
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: root.s(3)
                            Text {
                                text: "Workspaces"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: root.s(14)
                                color: box6.isActive ? root.base : root.text; Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Text {
                                text: "Static count in topbar"; font.family: "Inter"; font.pixelSize: root.s(11)
                                color: box6.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7); Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
                            Rectangle {
                                width: root.s(28); height: root.s(28); radius: root.s(22)
                                color: wsMinusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsMinusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                scale: wsMinusMa.pressed ? 0.90 : (wsMinusMa.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent; text: "-"
                                    font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                    color: box6.isActive ? root.base : root.red
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                MouseArea { id: wsMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.max(2, Config.workspaceCount - 1) }
                            }
                            Text { 
                                text: Config.workspaceCount.toString()
                                font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: root.s(14)
                                color: box6.isActive ? root.base : root.red
                                Layout.minimumWidth: root.s(36); horizontalAlignment: Text.AlignHCenter
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            Rectangle {
                                width: root.s(28); height: root.s(28); radius: root.s(22)
                                color: wsPlusMa.pressed ? Qt.alpha(root.base, 0.3) : (wsPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                                scale: wsPlusMa.pressed ? 0.90 : (wsPlusMa.containsMouse ? 1.08 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Text {
                                    anchors.centerIn: parent; text: "+"
                                    font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                    color: box6.isActive ? root.base : root.red
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                                }
                                MouseArea { id: wsPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: Config.workspaceCount = Math.min(10, Config.workspaceCount + 1) }
                            }
                        }
                    }
                }
            }

            // -- Box 7: App scale ------------------------------------
            Rectangle {
                id: box7
                property bool isActive: root.highlightedBox === 7
                Layout.fillWidth: true
                Layout.preferredHeight: appScaleRow.implicitHeight + root.s(28)
                radius: root.s(26)
                color: isActive ? root.sapphire : root.surface0
                border.color: isActive ? root.sapphire : root.surface1
                border.width: 1
                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }

                MouseArea { anchors.fill: parent; onClicked: root.highlightedBox = 7; z: -1 }

                RowLayout {
                    id: appScaleRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: root.s(16)
                    spacing: root.s(14)
                    Item {
                        Layout.preferredWidth: root.s(22)
                        Layout.alignment: Qt.AlignVCenter
                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Hack Nerd Font"; font.pixelSize: root.s(18)
                            color: box7.isActive ? root.base : root.sapphire
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: root.s(3)
                        Text {
                            text: "App scale"
                            font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: root.s(14)
                            color: box7.isActive ? root.base : root.text
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        Text {
                            text: "GTK / Electron apps. Restart them to apply."
                            font.family: "Inter"; font.pixelSize: root.s(11)
                            color: box7.isActive ? Qt.alpha(root.base, 0.75) : Qt.alpha(root.subtext0, 0.7)
                            Layout.fillWidth: true
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight; spacing: root.s(10)
                        Rectangle {
                            width: root.s(28); height: root.s(28); radius: root.s(22)
                            color: asMinusMa.pressed ? Qt.alpha(root.base, 0.3) : (asMinusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                            scale: asMinusMa.pressed ? 0.90 : (asMinusMa.containsMouse ? 1.08 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent; text: "-"
                                font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                color: box7.isActive ? root.base : root.sapphire
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            MouseArea { id: asMinusMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.appScaleStep(-1) }
                        }
                        Text {
                            text: Config.appScale.toFixed(2) + "x"
                            font.family: "Hack Nerd Font"; font.weight: Font.Black; font.pixelSize: root.s(14)
                            color: box7.isActive ? root.base : root.sapphire
                            Layout.minimumWidth: root.s(46); horizontalAlignment: Text.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                        }
                        Rectangle {
                            width: root.s(28); height: root.s(28); radius: root.s(22)
                            color: asPlusMa.pressed ? Qt.alpha(root.base, 0.3) : (asPlusMa.containsMouse ? Qt.alpha(root.base, 0.2) : Qt.alpha(root.base, 0.15))
                            scale: asPlusMa.pressed ? 0.90 : (asPlusMa.containsMouse ? 1.08 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Text {
                                anchors.centerIn: parent; text: "+"
                                font.family: "Hack Nerd Font"; font.weight: Font.Bold; font.pixelSize: root.s(15)
                                color: box7.isActive ? root.base : root.sapphire
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutExpo } }
                            }
                            MouseArea { id: asPlusMa; anchors.fill: parent; hoverEnabled: true; onClicked: root.appScaleStep(1) }
                        }
                    }
                }
            }


        }
    }        
}
