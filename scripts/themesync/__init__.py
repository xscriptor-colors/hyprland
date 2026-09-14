# ═══════════════════════════════════════════════════════════════════════════
# themesync — motor de theming de xscriptor-colors.
#
# Sincroniza las aplicaciones con la paleta activa del panel
# (fuente de verdad: dock/palettes/*.json). Cada destino vive en
# targets/<app>.py y expone NAME, DESCRIPTION, available(env) y apply(env);
# la orquestación está en runner.py y la CLI en cli.py.
#
# El entry point del repo sigue siendo scripts/theme-sync.sh (wrapper fino),
# porque lo invocan Colors.qml (hook de paleta), install.sh y reload.sh.
# ═══════════════════════════════════════════════════════════════════════════

__version__ = "2.0.0"
