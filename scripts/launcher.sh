#!/bin/bash

mode="${1:-drun}"

if command -v rofi >/dev/null 2>&1; then
    if [ "$mode" = "run" ]; then
        rofi -show run -show-icons -display-run "" -theme "$HOME/.config/rofi/launcher.rasi"
    else
        rofi -show drun -show-icons -display-drun "" -theme "$HOME/.config/rofi/launcher.rasi"
    fi
    exit 0
fi

