#!/usr/bin/env bash

# File paths
SETTINGS_FILE="$HOME/.config/hypr/settings.json"
WEATHER_SCRIPT="$HOME/.config/hypr/scripts/weather.sh"
ENV_FILE="$HOME/.config/hypr/scripts/quickshell/calendar/.env"

# Target configuration files
CONF_DIR="$HOME/.config/hypr/config"
TMPL_DIR="$HOME/.config/hypr/templates"
SETTINGS_CONF="$CONF_DIR/settings.conf"
AUTOSTART_CONF="$CONF_DIR/autostart.conf"
ENV_CONF="$CONF_DIR/env.conf"
KEYBINDS_CONF="$CONF_DIR/keybindings.conf"
MONITORS_CONF="$CONF_DIR/monitors.conf"
ZSH_RC="$HOME/.zshrc"

# Ensure the required files and directories exist
mkdir -p "$CONF_DIR" "$TMPL_DIR" "$(dirname "$SETTINGS_FILE")" "$(dirname "$ENV_FILE")"
[ ! -f "$SETTINGS_FILE" ] && echo "{}" > "$SETTINGS_FILE"

CACHE_DIR="$HOME/.cache/settings_watcher"
mkdir -p "$CACHE_DIR"

compile_settings() {
    echo "Regenerating configurations from templates..."

    # Hash existing configs before any changes, split by monitor vs non-monitor.
    # This means a pure uiScale/wallpaperDir/weatherApiKey write never triggers a reload.
    OLD_NONMON_HASH=$(md5sum "$SETTINGS_CONF" "$KEYBINDS_CONF" "$AUTOSTART_CONF" "$ENV_CONF" 2>/dev/null | md5sum)
    OLD_MON_HASH=$(md5sum "$MONITORS_CONF" 2>/dev/null | md5sum)

    # Read state from JSON (Using 'has' to safely parse booleans)
    LANG=$(jq -r '.language // "us"' "$SETTINGS_FILE")
    KB_OPT=$(jq -r '.kbOptions // "grp:alt_shift_toggle"' "$SETTINGS_FILE")
    WP_DIR=$(jq -r '.wallpaperDir // empty' "$SETTINGS_FILE")

    # Safely parse booleans so "false" doesn't trigger a fallback
    GUIDE_STARTUP=$(jq -r 'if has("openGuideAtStartup") then .openGuideAtStartup else true end' "$SETTINGS_FILE")

    PIC_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
    VID_DIR="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")"

    # Read the hardware variables injected by install.sh directly out of the JSON
    HW_ENV=$(jq -r '.hardwareEnvs[]? // empty' "$SETTINGS_FILE")

    # Application scaling. Deliberately avoids QT_SCALE_FACTOR: QuickShell is a
    # Qt app, so setting it would rescale the shell itself instead of only the
    # apps. GTK gets an integer scale plus a DPI correction for the remainder,
    # Electron/Chromium take a fractional factor directly.
    APP_SCALE=$(jq -r '.appScale // 1' "$SETTINGS_FILE")
    APP_SCALE_ENV=""
    if [[ "$APP_SCALE" != "1" && "$APP_SCALE" != "1.0" ]]; then
        GDK_INT=$(awk -v s="$APP_SCALE" 'BEGIN{ i=int(s+0.0001); if (i<1) i=1; print i }')
        GDK_DPI=$(awk -v s="$APP_SCALE" -v i="$GDK_INT" 'BEGIN{ printf "%.4f", s/i }')
        APP_SCALE_ENV=$(printf 'env = GDK_SCALE,%s\nenv = GDK_DPI_SCALE,%s\nenv = ELECTRON_FORCE_DEVICE_SCALE_FACTOR,%s\nenv = XCURSOR_SIZE,%s' \
            "$GDK_INT" "$GDK_DPI" "$APP_SCALE" \
            "$(awk -v s="$APP_SCALE" 'BEGIN{ printf "%d", 24*s }')")
    fi

    # 1. Regenerate env.conf using the template
    echo "Regenerating env.conf..."
    sed -e "s|{{XDG_PICTURES_DIR}}|$PIC_DIR|g" \
        -e "s|{{XDG_VIDEOS_DIR}}|$VID_DIR|g" \
        -e "s|{{WALLPAPER_DIR}}|$WP_DIR|g" \
        -e "s|{{SCRIPT_DIR}}|$HOME/.config/hypr/scripts|g" \
        "$TMPL_DIR/env.conf.template" > "${ENV_CONF}.tmp"

    # Use awk to safely substitute the multi-line HW_ENV array without breaking escapes
    awk -v hw="$HW_ENV" -v apps="$APP_SCALE_ENV" '{
        if (index($0, "{{HARDWARE_ENV}}")) {
            print hw
        } else if (index($0, "{{APP_SCALE_ENV}}")) {
            if (apps != "") print apps
        } else {
            print $0
        }
    }' "${ENV_CONF}.tmp" > "$ENV_CONF"
    rm -f "${ENV_CONF}.tmp"

    # Sync ZSH_RC if Wallpaper Dir changed
    if [ -n "$WP_DIR" ] && [ -f "$ZSH_RC" ]; then
        sed -i "s|^export WALLPAPER_DIR=.*|export WALLPAPER_DIR=\"$WP_DIR\"|" "$ZSH_RC"
    fi

    # 2. Regenerate settings.conf using template
    echo "Regenerating settings.conf..."
    sed -e "s|{{KB_LAYOUT}}|$LANG|g" \
        -e "s|{{KB_OPTIONS}}|$KB_OPT|g" \
        "$TMPL_DIR/settings.conf.template" > "$SETTINGS_CONF"

    # 3. Regenerate autostart.conf
    echo "Regenerating autostart.conf..."
    cp "$TMPL_DIR/autostart.conf.template" "$AUTOSTART_CONF"

    # Dump normal startup entries
    jq -r '.startup[]? | "exec-once = \(.command)"' "$SETTINGS_FILE" >> "$AUTOSTART_CONF"

    # Evaluate the guide boolean natively in jq and output the line ONLY if it resolves to true
    if [[ $(jq -r 'if (if type == "object" and has("openGuideAtStartup") then .openGuideAtStartup else true end) then "yes" else "no" end' "$SETTINGS_FILE") == "yes" ]]; then
        echo "exec-once = bash -c 'sleep 1 && ~/.config/hypr/scripts/qs_manager.sh toggle guide'" >> "$AUTOSTART_CONF"
    fi

    # 4. Regenerate keybindings.conf
    echo "Regenerating keybindings.conf..."
    cp "$TMPL_DIR/keybinds.conf.template" "$KEYBINDS_CONF"
    jq -r '.keybinds[]? | "\(.type // "bind") = \(.mods // ""), \(.key // ""), \(.dispatcher // "exec")\(if .command and .command != "" then ", \(.command)" else "" end)"' "$SETTINGS_FILE" >> "$KEYBINDS_CONF"

    # 5. Regenerate monitors.conf
    echo "Regenerating monitors.conf..."
    MONITOR_COUNT=$(jq '.monitors | length' "$SETTINGS_FILE" 2>/dev/null)
    if [[ "$MONITOR_COUNT" -gt 0 ]]; then
        cp "$TMPL_DIR/monitors.conf.template" "$MONITORS_CONF"
        jq -r '.monitors[]? | "monitor = \(.name), \(.resW)x\(.resH)@\(.rate), \(.x)x\(.y), \(.scale)\(if .transform and .transform != 0 then ", transform, \(.transform)" else "" end)"' "$SETTINGS_FILE" >> "$MONITORS_CONF"
    else
        # Fallback: auto-detect with max refresh rate per monitor
        DETECT_SCRIPT="$HOME/.config/hypr/scripts/detect-monitors.sh"
        if [ -x "$DETECT_SCRIPT" ]; then
            "$DETECT_SCRIPT" --silent
        else
            cp "$TMPL_DIR/monitors.conf.template" "$MONITORS_CONF"
            echo "monitor = , preferred, auto, 1" >> "$MONITORS_CONF"
        fi
    fi

    # Hash after changes
    NEW_NONMON_HASH=$(md5sum "$SETTINGS_CONF" "$KEYBINDS_CONF" "$AUTOSTART_CONF" "$ENV_CONF" 2>/dev/null | md5sum)
    NEW_MON_HASH=$(md5sum "$MONITORS_CONF" 2>/dev/null | md5sum)

    if [ "$OLD_MON_HASH" != "$NEW_MON_HASH" ]; then
        # Monitor layout actually changed — full reload needed
        echo "Monitor config changed, reloading Hyprland..."
        hyprctl reload
    elif [ "$OLD_NONMON_HASH" != "$NEW_NONMON_HASH" ]; then
        # Non-monitor settings changed (keybinds, autostart, input, env) — reload safe, no display flicker
        echo "Non-monitor config changed, reloading Hyprland..."
        hyprctl reload
    else
        # Nothing that affects Hyprland changed (e.g. uiScale, weatherApiKey) — skip reload entirely
        echo "No Hyprland config changes detected, skipping reload."
    fi
}

# If called with --compile, execute once and exit (used by install.sh)
if [[ "$1" == "--compile" ]]; then
    compile_settings
    exit 0
fi

echo "Started watching settings directories for changes..."

inotifywait -m -q -e close_write,moved_to --format '%w%f' "$(dirname "$SETTINGS_FILE")" "$(dirname "$ENV_FILE")" | while read -r filepath; do

    # ---------------------------------------------------------
    # SETTINGS JSON TRIGGER
    # ---------------------------------------------------------
    if [[ "$filepath" == "$SETTINGS_FILE" ]]; then
        compile_settings
    fi

    # ---------------------------------------------------------
    # .ENV WEATHER TRIGGER
    # ---------------------------------------------------------
    if [[ "$filepath" == "$ENV_FILE" ]]; then
        echo ".env updated! Forcing weather cache refresh..."
        if [ -x "$WEATHER_SCRIPT" ]; then
            "$WEATHER_SCRIPT" --getdata &
        else
            bash "$WEATHER_SCRIPT" --getdata &
        fi
    fi
done
