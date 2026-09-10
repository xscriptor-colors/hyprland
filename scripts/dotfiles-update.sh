#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# dotfiles-update.sh — Comprobación/actualización de los dotfiles (git/main).
#
# ALCANCE (importante):
#   - SOLO toca el CLON del repo: `git fetch` (máx. 1 vez al mes) y, si es
#     seguro, `git pull --ff-only origin main`. NUNCA toca ~/.config/hypr,
#     settings.json, paletas del usuario ni estado del shell.
#   - La referencia de comprobación es SIEMPRE `origin/main` (la rama estable),
#     estés en la rama que estés.
#   - Auto-pull SOLO si: estás en main/master, árbol limpio y sin commits
#     locales por delante de origin/main. En cualquier otro caso: notifica y
#     no toca nada.
#   - Si NO hay clon del repo: compara la versión remota del instalador con la
#     local (`~/.local/state/xshell-version`) y notifica si hay una nueva.
#
# Modos:
#   (sin args)         → comprobación mensual (fetch limitado) + auto-pull seguro
#   --check [--force]  → informe por stdout; --force ignora el límite mensual
#   --install-timer    → instala y activa el timer mensual de systemd --user
#   --uninstall-timer  → desactiva y elimina el timer
#   --status           → estado del timer, último fetch y log
# ═══════════════════════════════════════════════════════════════════════════

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
LOG_FILE="$STATE_DIR/dotfiles-update.log"
PENDING_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updater"
PENDING_FILE="$PENDING_DIR/update_pending"
FETCH_STAMP="$STATE_DIR/dotfiles-last-fetch"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
VERSION_FILE="$HOME/.local/state/xshell-version"
REMOTE_MANIFEST_URL="https://raw.githubusercontent.com/xscriptor-colors/hyprland/main/updates.json"
REMOTE_INSTALL_URL="https://raw.githubusercontent.com/xscriptor-colors/hyprland/main/install.sh"
REF_BRANCH="main"
# Cache del manifest del updater (MISMO path que usa el popup SUPER+U:
# Caching.getCacheDir("updater")). El popup solo hace red si el sello no es
# del mes actual; este script lo deja fresco una vez al mes.
UPDATER_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updater"
MANIFEST_CACHE="$UPDATER_CACHE_DIR/manifest.json"
MANIFEST_STAMP="$UPDATER_CACHE_DIR/manifest_check"
CUR_MONTH="$(date +%Y-%m)"

# El estado puede no existir aún (primer run en una máquina nueva): sin este
# mkdir, la redirección del `git fetch` a $LOG_FILE fallaba y el fetch ni se
# ejecutaba ("fetch fallido" falso).
mkdir -p "$STATE_DIR"

log() {
    mkdir -p "$STATE_DIR"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

notify() {
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Dotfiles" "$1" "${2:-}"
}

set_pending() { mkdir -p "$PENDING_DIR"; printf '%s\n' "$1" > "$PENDING_FILE"; }
clear_pending() { rm -f "$PENDING_FILE"; }

# ── Límite de un fetch al mes ──────────────────────────────────────────────
month_fetched() { [ -f "$FETCH_STAMP" ] && [ "$(cat "$FETCH_STAMP" 2>/dev/null)" = "$CUR_MONTH" ]; }
mark_fetched() { mkdir -p "$STATE_DIR"; printf '%s' "$CUR_MONTH" > "$FETCH_STAMP"; }

# ── Localización del clon ──────────────────────────────────────────────────
resolve_repo() {
    if [ -n "${DOTFILES_REPO:-}" ] && [ -d "${DOTFILES_REPO}/.git" ]; then
        printf '%s\n' "$DOTFILES_REPO"; return
    fi
    local cand
    cand="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
    if [ -n "$cand" ] && [ -d "$cand/.git" ]; then printf '%s\n' "$cand"; return; fi
    for cand in "$HOME/Documents/xscriptor-colors/hyprland" "$HOME/hyprland"; do
        if [ -d "$cand/.git" ]; then printf '%s\n' "$cand"; return; fi
    done
    printf ''
}

# ── Versión (caso sin clon) ────────────────────────────────────────────────
# Descarga el manifest UNA vez y lo deja en el cache del updater (mismo path
# que el popup) con sello YYYY-MM. Atómico (tmp + mv). Devuelve 0 si quedó
# cache fresco; 1 si falló (el cache viejo, si existe, no se toca).
cache_manifest() {
    local month tmp
    month="$(date +%Y-%m)"
    mkdir -p "$UPDATER_CACHE_DIR" 2>/dev/null || return 1
    tmp="$UPDATER_CACHE_DIR/.manifest.$$"
    if curl -fsSL -m 20 "$REMOTE_MANIFEST_URL" -o "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
        mv -f "$tmp" "$MANIFEST_CACHE"
        printf '%s' "$month" > "$MANIFEST_STAMP"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Preferencia: cache del manifest (fresco o viejo) → curl directo → scrape del
# instalador (INSTALL_VERSION) como respaldo.
manifest_version() {
    local json=""
    [ -s "$MANIFEST_CACHE" ] && json="$(cat "$MANIFEST_CACHE" 2>/dev/null)"
    [ -n "$json" ] || json="$(curl -fsSL -m 20 "$REMOTE_MANIFEST_URL" 2>/dev/null)"
    [ -n "$json" ] || return 0
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$json" | jq -r '.version // empty' 2>/dev/null
    else
        printf '%s' "$json" | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("version","") or "")
except Exception:
    pass' 2>/dev/null
    fi
}
remote_version() {
    local v
    v="$(manifest_version)"
    if [ -n "$v" ]; then printf '%s\n' "$v"; return; fi
    curl -fsSL -m 20 "$REMOTE_INSTALL_URL" 2>/dev/null | grep -m1 '^INSTALL_VERSION=' | cut -d'"' -f2
}
local_version() {
    sed -n 's/^LOCAL_VERSION="\(.*\)"/\1/p' "$VERSION_FILE" 2>/dev/null
}
version_gt() { # $1 > $2 (semver simple con sort -V)
    [ -n "$1" ] && [ -n "$2" ] && [ "$1" != "$2" ] && \
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

# ── Comprobación principal ─────────────────────────────────────────────────
run_check() {
    local dry="$1" force="$2"
    local repo; repo="$(resolve_repo)"

    # ── Sin clon: comparar versión remota vs local ──
    if [ -z "$repo" ]; then
        local rv lv
        # Deja el cache del manifest fresco para el popup (una sola descarga).
        cache_manifest && log "manifest cacheado (sin clon)"
        rv="$(remote_version)"; lv="$(local_version)"
        if [ -z "$rv" ]; then
            log "sin clon y sin versión remota (¿sin red?)"
            [ "$dry" = "1" ] && echo "Sin clon y sin versión remota (¿sin red?)."
            return 0
        fi
        if version_gt "$rv" "$lv"; then
            set_pending "$rv"
            notify "Dotfiles: versión $rv disponible" "Tienes $lv. No hay clon git: actualiza con el updater de la barra o install.sh"
            log "sin clon: remoto $rv > local $lv"
            [ "$dry" = "1" ] && echo "Actualización disponible: $lv → $rv (sin clon)."
        else
            clear_pending
            log "sin clon: al día ($lv)"
            [ "$dry" = "1" ] && echo "Al día (sin clon): $lv."
        fi
        return 0
    fi

    # ── Con clon: fetch (máx. 1/mes salvo --force) ──
    if [ "$force" != "1" ] && month_fetched; then
        log "fetch ya hecho este mes ($CUR_MONTH); se omite"
        [ "$dry" = "1" ] && echo "Fetch ya realizado este mes ($CUR_MONTH). Usa --force para forzar."
        return 0
    fi
    if ! timeout 60 git -C "$repo" fetch --prune --quiet origin >>"$LOG_FILE" 2>&1; then
        log "git fetch falló (¿sin red?); se reintentará la próxima ejecución"
        [ "$dry" = "1" ] && echo "fetch fallido (sin red?)."
        return 0
    fi
    mark_fetched

    # Deja el cache del manifest fresco para el popup (una sola descarga).
    cache_manifest && log "manifest cacheado (con clon)"

    local branch behind ahead clean
    branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
    behind="$(git -C "$repo" rev-list --count "HEAD..origin/$REF_BRANCH" 2>/dev/null || echo 0)"
    ahead="$(git -C "$repo" rev-list --count "origin/$REF_BRANCH..HEAD" 2>/dev/null || echo 0)"
    clean="no"; [ -z "$(git -C "$repo" status --porcelain 2>/dev/null)" ] && clean="si"
    log "check: rama=$branch vs origin/$REF_BRANCH behind=$behind ahead=$ahead limpio=$clean"

    if [ "$behind" -eq 0 ]; then
        clear_pending
        [ "$dry" = "1" ] && echo "Al día respecto a origin/$REF_BRANCH (rama $branch)."
        return 0
    fi

    # Hay novedades en main: encender el indicador de la barra (󰚰 verde).
    set_pending "$behind"

    local on_main="no"
    case "$branch" in main|master) on_main="si" ;; esac

    if [ "$dry" != "1" ] && [ "$on_main" = "si" ] && [ "$clean" = "si" ] && [ "$ahead" -eq 0 ]; then
        if timeout 120 git -C "$repo" pull --ff-only --quiet origin "$REF_BRANCH" >>"$LOG_FILE" 2>&1; then
            clear_pending
            log "auto-pull OK: $behind commits de $REF_BRANCH"
            notify "Dotfiles actualizadas" "$behind commits nuevos de $REF_BRANCH (solo el clon; el runtime no se toca)"
        else
            log "auto-pull falló; queda pendiente"
            notify "Dotfiles: $behind actualizaciones en $REF_BRANCH" "El pull automático falló; actualiza a mano en $repo"
        fi
        return 0
    fi

    # No es seguro auto-actualizar: solo avisar.
    local why="estás en la rama '$branch' (no main)"
    [ "$clean" != "si" ] && why="hay cambios locales sin commitear"
    [ "$ahead" -gt 0 ] && why="tienes commits locales por delante de $REF_BRANCH"
    log "pendiente ($why): $behind commits detrás de origin/$REF_BRANCH"
    notify "Dotfiles: $behind actualizaciones en $REF_BRANCH" "$why; no se ha tocado nada. Repo: $repo"
    [ "$dry" = "1" ] && echo "Pendiente: $behind commits detrás de origin/$REF_BRANCH ($why)."
    return 0
}

install_timer() {
    local repo; repo="$(resolve_repo)"
    [ -z "$repo" ] && { echo "Aviso: no se encontró clon; el timer funcionará igual (modo versión)." >&2; }
    mkdir -p "$UNIT_DIR"
    cat > "$UNIT_DIR/dotfiles-update.service" <<EOF
[Unit]
Description=Comprobación mensual de dotfiles (xscriptor-colors)

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/dotfiles-update.sh
EOF
    cat > "$UNIT_DIR/dotfiles-update.timer" <<'EOF'
[Unit]
Description=Comprobación mensual de dotfiles (xscriptor-colors)

[Timer]
OnCalendar=monthly
Persistent=true
RandomizedDelaySec=3600
AccuracySec=1h

[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now dotfiles-update.timer
    echo "Timer mensual instalado y activo:"
    systemctl --user list-timers dotfiles-update.timer --no-pager 2>/dev/null | head -3
    log "timer mensual instalado (repo=${repo:-sin clon})"
}

uninstall_timer() {
    systemctl --user disable --now dotfiles-update.timer 2>/dev/null || true
    rm -f "$UNIT_DIR/dotfiles-update.timer" "$UNIT_DIR/dotfiles-update.service"
    systemctl --user daemon-reload
    echo "Timer mensual desinstalado."
    log "timer mensual desinstalado"
}

show_status() {
    echo "── Timer:"
    systemctl --user list-timers dotfiles-update.timer --no-pager 2>/dev/null || true
    echo "── Último fetch mensual: $(cat "$FETCH_STAMP" 2>/dev/null || echo '(ninguno)')"
    echo "── Repo detectado: $(resolve_repo || true)"
    echo "── Últimas líneas del log ($LOG_FILE):"
    tail -n 8 "$LOG_FILE" 2>/dev/null || echo "(sin log todavía)"
}

# ── Parseo de argumentos ───────────────────────────────────────────────────
DRY=0; FORCE=0; MODE="run"
for arg in "$@"; do
    case "$arg" in
        --check)           DRY=1 ;;
        --force)           FORCE=1 ;;
        --install-timer)   MODE="timer" ;;
        --uninstall-timer) MODE="untimer" ;;
        --status)          MODE="status" ;;
    esac
done

case "$MODE" in
    timer)   install_timer ;;
    untimer) uninstall_timer ;;
    status)  show_status ;;
    *)       run_check "$DRY" "$FORCE" ;;
esac
