#!/usr/bin/env bash

ACTION=$1
TYPE=$2
ID=$3
VAL=$4

case $ACTION in
    set-volume)
        # Intercept master slider to use wpctl
        if [[ "$ID" == "@DEFAULT@" ]]; then
            if [[ "$TYPE" == "sink" ]]; then
                wpctl set-volume @DEFAULT_AUDIO_SINK@ "$VAL%"
            elif [[ "$TYPE" == "source" ]]; then
                wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$VAL%"
            fi
        else
            # Background specific sliders still use pactl
            pactl set-$TYPE-volume "$ID" "$VAL%"
        fi
        ;;
    toggle-mute)
        if [[ "$ID" == "@DEFAULT@" ]]; then
            if [[ "$TYPE" == "sink" ]]; then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            elif [[ "$TYPE" == "source" ]]; then
                wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            fi
        else
            pactl set-$TYPE-mute "$ID" toggle
        fi
        ;;
    set-default)
        # pactl is still preferred for setting defaults by name
        pactl set-default-$TYPE "$ID"
        ;;
esac
