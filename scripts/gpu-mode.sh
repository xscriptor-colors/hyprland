#!/bin/bash
# ┌───────────────────────────────────────────────────────────────────────────────────┐
# │ GPU OPTIMUS MODE SWITCHER (ENVYCONTROL WRAPPER)                                   │
# │ Replaces the custom power-limit script with the community standard                │
# └───────────────────────────────────────────────────────────────────────────────────┘

export LC_NUMERIC="C"

# ────────────────────────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────────────────────────

if ! command -v envycontrol >/dev/null 2>&1; then
    # Return silent error for waybar status, notify for actions
    if [ "$1" != "status" ]; then
        notify-send -u critical "GPU Mode" "envycontrol is not installed.\nPlease install it via yay/pacman."
    fi
    exit 1
fi

MODE_FILE="$HOME/.cache/gpu-mode-current"

# ────────────────────────────────────────────────────────────────────────────
# Functions
# ────────────────────────────────────────────────────────────────────────────

get_current_mode() {
    # envycontrol --query outputs 'integrated', 'hybrid', or 'nvidia'
    # It requires an Optimus system. If not found, it might error, so we catch it.
    local current
    current=$(envycontrol --query 2>/dev/null)
    
    # Fallback to hybrid if unknown or failing
    if [[ "$current" != "integrated" && "$current" != "hybrid" && "$current" != "nvidia" ]]; then
        current="unknown"
    fi
    
    echo "$current" > "$MODE_FILE"
    echo "$current"
} # End get_current_mode

status_output() {
    local mode
    mode=$(get_current_mode)
    local icon=""
    local tooltip="EnvyControl Optimus Mode"

    if [ "$mode" = "unknown" ]; then
        # Hide module if not an Optimus system or envycontrol is failing
        echo ""
        exit 0
    fi

    case "$mode" in
        integrated)
            icon="󰁹" # Battery icon
            tooltip="Integrated (NVIDIA OFF)\nMaximum battery life"
            ;;
        hybrid)
            icon="󰚰" # Swap icon
            tooltip="Hybrid (Default)\nIntel/AMD drives display, NVIDIA offloads"
            ;;
        nvidia)
            icon="󰓅" # Speed icon
            tooltip="NVIDIA (Performance)\nNVIDIA drives everything. High power usage."
            ;;
    esac

    # Output JSON for Waybar
    cat <<EOF
{"text": "$icon ${mode^^}", "tooltip": "$tooltip", "class": "$mode", "alt": "$mode"}
EOF
}

set_mode() {
    local target="$1"
    local current
    current=$(get_current_mode)

    if [ "$target" = "$current" ]; then
        notify-send -u low "GPU Mode" "Already in $target mode."
        return
    fi
    
    if [[ "$target" != "integrated" && "$target" != "hybrid" && "$target" != "nvidia" ]]; then
        return
    fi

    # execute command with sudo (relies on the passwordless sudoers rule from install.sh)
    if sudo envycontrol -s "$target"; then
        notify-send -u critical "GPU Mode" "Switched to ${target^^} mode.\n\n⚠️ REBOOT REQUIRED to apply changes."
        echo "$target" > "$MODE_FILE"
        # Signal Waybar to update
        pkill -RTMIN+8 waybar || true
    else
        notify-send -u critical "GPU Mode" "Failed or cancelled mode switch."
    fi
}

show_menu() {
    local current
    current=$(get_current_mode)
    
    # Define options with an indicator for the current one
    local opt_int="Integrated Mode (Max Battery)"
    local opt_hyb="Hybrid Mode (Default)"
    local opt_nvd="NVIDIA Mode (Max Performance)"
    
    if [ "$current" = "integrated" ]; then opt_int="[Active] $opt_int"; fi
    if [ "$current" = "hybrid" ]; then opt_hyb="[Active] $opt_hyb"; fi
    if [ "$current" = "nvidia" ]; then opt_nvd="[Active] $opt_nvd"; fi

    local chosen
    chosen=$(printf "%s\n%s\n%s" "$opt_int" "$opt_hyb" "$opt_nvd" | rofi -dmenu -i -p "Select GPU Optimus Mode")
    
    if [ -n "$chosen" ]; then
        case "$chosen" in
            *"Integrated"*) set_mode "integrated" ;;
            *"Hybrid"*)     set_mode "hybrid" ;;
            *"NVIDIA"*)     set_mode "nvidia" ;;
        esac
    fi
}

cycle_mode() {
    local current
    current=$(get_current_mode)
    local next="hybrid"
    
    case "$current" in
        integrated) next="hybrid" ;;
        hybrid)     next="nvidia" ;;
        nvidia)     next="integrated" ;;
    esac
    
    set_mode "$next"
}

# ────────────────────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────────────────────

case "$1" in
    status) status_output ;;
    menu)   show_menu ;;
    cycle)  cycle_mode ;;
    integrated|hybrid|nvidia) set_mode "$1" ;;
    *) echo "Usage: $0 {status|menu|cycle|integrated|hybrid|nvidia}" ;;
esac
