// ═══════════════════════════════════════════════════════════════════════════
// davincix · ui/lib — color
//
// Pure color helpers. hexBucket() maps a hex color into the named filter
// bucket (Red/Green/Blue/.../Monochrome) used by the color filters.
// ═══════════════════════════════════════════════════════════════════════════
.pragma library

function hexBucket(hexStr) {
    if (!hexStr) return "Monochrome";

    hexStr = String(hexStr).trim().replace(/#/g, '');
    if (hexStr.length > 6) hexStr = hexStr.substring(0, 6);
    if (hexStr.length !== 6) return "Monochrome";

    let r = parseInt(hexStr.substring(0, 2), 16) / 255;
    let g = parseInt(hexStr.substring(2, 4), 16) / 255;
    let b = parseInt(hexStr.substring(4, 6), 16) / 255;

    if (isNaN(r) || isNaN(g) || isNaN(b)) return "Monochrome";

    let max = Math.max(r, g, b), min = Math.min(r, g, b);
    let d = max - min;
    let s = max === 0 ? 0 : d / max;
    let v = max;
    let h = 0;

    if (max !== min) {
        if (max === r) {
            h = (g - b) / d + (g < b ? 6 : 0);
        } else if (max === g) {
            h = (b - r) / d + 2;
        } else {
            h = (r - g) / d + 4;
        }
        h /= 6;
    }
    h = h * 360;

    if (s < 0.05 || v < 0.08) return "Monochrome";

    if (h >= 345 || h < 15) return "Red";
    if (h >= 15 && h < 45) return "Orange";
    if (h >= 45 && h < 75) return "Yellow";
    if (h >= 75 && h < 165) return "Green";
    if (h >= 165 && h < 260) return "Blue";
    if (h >= 260 && h < 315) return "Purple";
    if (h >= 315 && h < 345) return "Pink";

    return "Monochrome";
}
