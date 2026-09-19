# ═══════════════════════════════════════════════════════════════════════════
# gtk — GTK3/GTK4 gtk.css + system scheme (gsettings).
#
# Writes @define-color overrides for the active palette into
# ~/.config/gtk-3.0/gtk.css and gtk-4.0/gtk.css (adw-gtk3/Adwaita/libadwaita
# names) and adjusts the system scheme (color-scheme and gtk-theme
# adw-gtk3[-dark]) so GTK3, libadwaita, portal dialogs and browsers in system
# mode follow the palette. GTK3 is fully recolored; GTK4/libadwaita respects
# light/dark and the @define-color names it uses. Open apps need a restart.
# ═══════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from pathlib import Path

from ..core import best_fg, mix, palette_bg_fg, palette_hex, read_text

NAME = "gtk"
DESCRIPTION = "gtk.css (GTK3/4) + system scheme (gsettings)"

BEGIN = "/* === xscriptor-colors theme-sync (managed) === */"
END = "/* === end xscriptor-colors === */"


def available(env) -> bool:
    return True


def _defs(env) -> list:
    """(name, hex) list of @define-color values for the active palette."""
    pal = env.palette
    bg, fg = palette_bg_fg(pal)
    c5 = palette_hex(pal, "color5", fg)
    accent_fg = best_fg(c5, fg, bg)
    base = mix(bg, fg, 0.04)
    header = mix(bg, fg, 0.06)
    border = mix(bg, fg, 0.15)
    border2 = mix(bg, fg, 0.10)
    muted = mix(fg, bg, 0.45)
    insens = mix(bg, fg, 0.06)
    shade = mix(bg, "#000000", 0.18)
    red = palette_hex(pal, "color1", fg)
    green = palette_hex(pal, "color2", fg)
    yellow = palette_hex(pal, "color3", fg)

    return [
        ("window_bg_color", bg), ("window_fg_color", fg),
        ("view_bg_color", base), ("view_fg_color", fg),
        ("headerbar_bg_color", header), ("headerbar_fg_color", fg),
        ("headerbar_border_color", border), ("headerbar_backdrop_color", bg),
        ("headerbar_shade_color", shade), ("headerbar_darker_shade_color", shade),
        ("sidebar_bg_color", base), ("sidebar_fg_color", fg),
        ("sidebar_backdrop_color", bg), ("sidebar_border_color", border),
        ("sidebar_shade_color", shade),
        ("card_bg_color", header), ("card_fg_color", fg), ("card_shade_color", shade),
        ("popover_bg_color", mix(bg, fg, 0.08)), ("popover_fg_color", fg),
        ("popover_shade_color", shade),
        ("dialog_bg_color", bg), ("dialog_fg_color", fg),
        ("panel_bg_color", header), ("panel_fg_color", fg),
        ("accent_color", c5), ("accent_bg_color", c5), ("accent_fg_color", accent_fg),
        ("destructive_color", red), ("destructive_bg_color", red), ("destructive_fg_color", accent_fg),
        ("error_color", red), ("error_bg_color", red), ("error_fg_color", accent_fg),
        ("warning_color", yellow), ("warning_bg_color", yellow), ("warning_fg_color", accent_fg),
        ("success_color", green), ("success_bg_color", green), ("success_fg_color", accent_fg),
        ("borders", border), ("unfocused_borders", border2),
        ("theme_bg_color", bg), ("theme_base_color", base),
        ("theme_fg_color", fg), ("theme_text_color", fg),
        ("theme_selected_bg_color", c5), ("theme_selected_fg_color", accent_fg),
        ("theme_unfocused_bg_color", bg), ("theme_unfocused_base_color", base),
        ("theme_unfocused_fg_color", muted), ("theme_unfocused_text_color", muted),
        ("theme_unfocused_selected_bg_color", c5), ("theme_unfocused_selected_fg_color", accent_fg),
        ("insensitive_bg_color", insens), ("insensitive_fg_color", muted),
        ("insensitive_base_color", insens), ("unfocused_insensitive_color", muted),
        ("content_view_bg", base), ("text_view_bg", base),
        ("shade_color", shade), ("scrollbar_outline_color", border),
        ("thumbnail_bg_color", header), ("thumbnail_fg_color", fg),
    ]


def apply(env) -> list:
    out = []
    block = [BEGIN,
             "/* palette: %s — auto-generated, do not edit this block */" % env.slug]
    block += ["@define-color %s %s;" % (name, val) for name, val in _defs(env)]
    block.append(END)

    # ── 1) gtk.css for GTK3 and GTK4 (managed block) ──
    for gtk_dir in ("gtk-3.0", "gtk-4.0"):
        d = env.home / ".config" / gtk_dir
        env.mkdir(d)
        css = d / "gtk.css"
        kept, inside = [], False
        if css.is_file():
            for ln in read_text(css).splitlines():
                t = ln.strip()
                if t == BEGIN:
                    inside = True
                    continue
                if t == END:
                    inside = False
                    continue
                if inside:
                    continue
                kept.append(ln)
        text = "\n".join(kept).rstrip("\n")
        text = (text + "\n\n" if text else "") + "\n".join(block) + "\n"
        env.write(css, text)
    out.append("gtk colors → '%s' (gtk-3.0 + gtk-4.0 gtk.css)" % env.slug)

    # ── 2) System scheme (libadwaita, portal, browsers in system mode) ──
    gsettings = env.binary("gsettings")
    if gsettings:
        dark = not env.light
        theme = "adw-gtk3-dark" if dark else "adw-gtk3"
        scheme = "prefer-dark" if dark else "prefer-light"
        if Path("/usr/share/themes/" + theme).is_dir():
            env.run([gsettings, "set", "org.gnome.desktop.interface", "gtk-theme", theme])
        # Explicit prefer-light (portal=2); fall back to 'default' on old schemas.
        if not env.run([gsettings, "set", "org.gnome.desktop.interface", "color-scheme", scheme]):
            scheme = "default"
            env.run([gsettings, "set", "org.gnome.desktop.interface", "color-scheme", scheme])
        out.append("gtk system scheme → %s (%s)" % (scheme, theme))
    return out
