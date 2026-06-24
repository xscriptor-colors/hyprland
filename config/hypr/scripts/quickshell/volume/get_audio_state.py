#!/usr/bin/env python3
import subprocess
import json
import sys

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL).decode('utf-8')
    except:
        return "[]"

def parse_pactl(output):
    try:
        return json.loads(output)
    except:
        return []

def get_valid_string(*args):
    """Safely return the first valid string that isn't 'null' or empty."""
    for arg in args:
        if arg and str(arg).strip().lower() not in ["null", "none", ""]:
            return str(arg)
    return ""

def get_wpctl_default(node_target):
    """Gets the accurate default node name directly from WirePlumber."""
    try:
        out = run_cmd(f"wpctl inspect {node_target}")
        for line in out.splitlines():
            if "node.name" in line:
                parts = line.split("=", 1)
                if len(parts) == 2:
                    return parts[1].strip().strip('"')
    except:
        pass
    return ""

def get_data():
    sinks = parse_pactl(run_cmd("pactl -f json list sinks"))
    sources = parse_pactl(run_cmd("pactl -f json list sources"))
    sink_inputs = parse_pactl(run_cmd("pactl -f json list sink-inputs"))
    
    # Use wpctl for accurate default nodes under PipeWire
    default_sink = get_wpctl_default("@DEFAULT_AUDIO_SINK@")
    default_source = get_wpctl_default("@DEFAULT_AUDIO_SOURCE@")

    # Fallback to pactl info if wpctl fails
    if not default_sink or not default_source:
        try:
            info = parse_pactl(run_cmd("pactl -f json info"))
            if not default_sink: default_sink = info.get("default_sink_name", "")
            if not default_source: default_source = info.get("default_source_name", "")
        except:
            pass

    def format_node(n, is_default=False, is_app=False):
        vol = 0
        if "volume" in n and isinstance(n["volume"], dict):
            if "front-left" in n["volume"]:
                vol = int(n["volume"]["front-left"].get("value_percent", "0%").strip("%"))
            elif "mono" in n["volume"]:
                vol = int(n["volume"]["mono"].get("value_percent", "0%").strip("%"))

        props = n.get("properties", {})
        
        if is_app:
            display_name = get_valid_string(props.get("application.name"), props.get("application.process.binary"), "Unknown App")
            sub_desc = get_valid_string(props.get("media.name"), props.get("window.title"), props.get("media.role"), "Audio Stream")
        else:
            display_name = get_valid_string(props.get("device.description"), n.get("name"), "Unknown Device")
            sub_desc = get_valid_string(n.get("name"), "Unknown")

        icon = get_valid_string(props.get("application.icon_name"), props.get("device.icon_name"), "audio-card")
        
        return {
            "id": str(n.get("index")),
            "name": sub_desc,
            "description": display_name,
            "volume": vol,
            "mute": bool(n.get("mute", False)),
            "is_default": bool(is_default),
            "icon": icon
        }

    apps = []
    for s in sink_inputs:
        props = s.get("properties", {})
        if props.get("application.id") != "org.PulseAudio.pavucontrol":
            apps.append(format_node(s, is_app=True))

    # Filter out monitor sources so outputs don't show up in the inputs tab
    real_inputs = []
    for s in sources:
        props = s.get("properties", {})
        if props.get("device.class") == "monitor" or str(s.get("name", "")).endswith(".monitor"):
            continue
        real_inputs.append(format_node(s, s.get("name") == default_source))

    out = {
        "outputs": [format_node(s, s.get("name") == default_sink) for s in sinks],
        "inputs": real_inputs,
        "apps": apps
    }
    
    print(json.dumps(out))

if __name__ == "__main__":
    get_data()
