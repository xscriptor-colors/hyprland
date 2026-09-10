import QtQuick

// ═══════════════════════════════════════════════════════════════════════════
// GuidePage — página del panel Settings que embebe el widget `guide`
// (guide/GuidePopup.qml) TAL CUAL: info del sistema, GitHub, paletas, about
// y demás contenido del popup de la X (󰅖) de la barra.
//
// El guide es autocontenido (Caching/Scaler/Colors propios, sin masterWindow
// ni propiedades externas): aquí solo se envuelve en un Loader y se le da el
// tamaño del stage, que es lo único que necesita de su contenedor.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    // Contrato del editor (las páginas reciben el root como `bar`); el guide
    // no lo usa, pero se declara para que `ensurePage` no avise.
    property var bar: null

    Loader {
        id: guideLoader
        anchors.fill: parent
        source: "../../guide/GuidePopup.qml"
        onLoaded: {
            // El guide espera que su contenedor le dé tamaño (en Main.qml lo
            // hace el StackView); aquí se lo da el Loader.
            item.width = Qt.binding(function() { return guideLoader.width; });
            item.height = Qt.binding(function() { return guideLoader.height; });
        }
    }
}
