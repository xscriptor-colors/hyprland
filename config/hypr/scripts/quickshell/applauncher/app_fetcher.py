#!/usr/bin/env python3
import os
import glob
import json
import base64

# ────────────────────────────────────────────────────────────────
# BLOCKLIST: .desktop file IDs that are system utilities nobody
# launches directly from an app launcher.
# ────────────────────────────────────────────────────────────────
DESKTOP_ID_BLOCKLIST = [
    "avahi-discover", "bssh", "bvnc",
    "blueman-adapters", "blueman-manager",
    "cmake-gui",
    "designer", "linguist", "assistant", "qdbusviewer",
    "qt5ct", "qt6ct",
    "qv4l2", "qvidcap",
    "rofi-theme-selector",
    "lstopo",
    "nm-connection-editor",
    "nvidia-settings",
    "org.gnome.seahorse.Application",
    "org.kde.drkonqi.coredump.gui",
    "org.kde.kmenuedit",
    "org.kde.plasma.emojier",
    "org.pulseaudio.pavucontrol",
    "org.rncbc.qtractor",
    "systemsettings", "kdesystemsettings",
    "org.kde.plasma-welcome",
]

# ────────────────────────────────────────────────────────────────
# KEYWORD BLOCKLIST (checked against lowercase Name=).
# Only block very generic system utility names that nobody
# would intentionally launch from an app launcher.
# ────────────────────────────────────────────────────────────────
KEYWORD_BLOCKLIST = [
    "about", "accessibility", "color management", "connect to server",
    "control center", "font viewer", "look and feel",
    "network connections", "network proxy", "online accounts",
    "power manager", "power statistics",
    "region", "session", "startup disk",
    "universal access",
]


def is_system_app(name, desktop_id):
    name_lower = name.lower()

    if desktop_id in DESKTOP_ID_BLOCKLIST:
        return True

    for keyword in KEYWORD_BLOCKLIST:
        if keyword in name_lower:
            return True

    return False


# Icons known to look bad at launcher size (hardware diag, generic placeholders)
BAD_ICONS = {
    'hwinfo', 'krfb', 'krdc', 'preferences-system',
    'utilities-log-viewer', 'utilities-file-archiver',
    'document-print', 'accessories-calculator',
    'nm-device-wireless', 'network-wired', 'network-server',
    'emblem-system', 'computer', 'drive-harddisk',
    'input-mouse', 'input-keyboard', 'input-tablet',
    'media-optical', 'printer', 'camera-photo',
    'phone', 'modem', 'multimedia-player',
    'package-x-generic', 'text-x-generic', 'application-x-executable',
    'application-default-icon',
}


def validate_icon(icon_name):
    if not icon_name:
        return ''
    if icon_name.startswith('/'):
        return icon_name if os.path.exists(icon_name) else ''

    if icon_name in BAD_ICONS:
        return ''

    return icon_name


def load_usage_db():
    db_path = os.path.expanduser('~/.cache/quickshell/applauncher_usage.json')
    if os.path.exists(db_path):
        try:
            with open(db_path, 'r') as f:
                raw = json.load(f)
            # Migrate old keys (from broken echo-based tracking that added \n)
            migrated = {}
            for key, val in raw.items():
                try:
                    decoded = base64.b64decode(key).decode()
                    if decoded.endswith('\n'):
                        clean_key = base64.b64encode(decoded.rstrip('\n').encode()).decode()
                    else:
                        clean_key = key
                except Exception:
                    clean_key = key
                if clean_key in migrated:
                    migrated[clean_key]['count'] = migrated[clean_key].get('count', 0) + val.get('count', 0)
                    migrated[clean_key]['last_used'] = max(
                        migrated[clean_key].get('last_used', 0), val.get('last_used', 0))
                else:
                    migrated[clean_key] = val
            # Write back cleaned data
            if migrated != raw:
                with open(db_path, 'w') as f:
                    json.dump(migrated, f)
            return migrated
        except Exception:
            pass
    return {}


def fetch_apps():
    apps = {}
    home = os.path.expanduser('~')

    dirs = [
        '/usr/share/applications',
        '/usr/local/share/applications',
        f'{home}/.local/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.nix-profile/share/applications',
        '/run/current-system/sw/share/applications',
    ]

    usage_db = load_usage_db()

    for d in dirs:
        if not os.path.exists(d):
            continue

        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                desktop_id = os.path.splitext(os.path.basename(f))[0]
                with open(f, 'r', encoding='utf-8', errors='replace') as file:
                    app = {
                        'name': '', 'exec': '', 'icon': '',
                        'generic_name': '', 'comment': '',
                        'categories': '', 'keywords': '',
                    }
                    in_desktop_entry = False
                    no_display = False
                    hidden = False

                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            in_desktop_entry = True
                            continue
                        elif line.startswith('['):
                            in_desktop_entry = False
                            continue

                        if not in_desktop_entry:
                            continue

                        if line.startswith('Name=') and not app['name']:
                            app['name'] = line[5:]
                        elif line.startswith('GenericName=') and not app['generic_name']:
                            app['generic_name'] = line[12:]
                        elif line.startswith('Comment=') and not app['comment']:
                            app['comment'] = line[8:]
                        elif line.startswith('Categories=') and not app['categories']:
                            app['categories'] = line[11:]
                        elif line.startswith('Keywords=') and not app['keywords']:
                            app['keywords'] = line[9:]
                        elif line.startswith('Exec=') and not app['exec']:
                            app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                        elif line.startswith('Icon=') and not app['icon']:
                            app['icon'] = line[5:]
                        elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                            no_display = True
                        elif line.startswith('Hidden=true') or line.startswith('Hidden=1'):
                            hidden = True
                        elif line.startswith('NotShowIn='):
                            shown_in = line[10:].split(';')
                            if 'Hyprland' in shown_in:
                                hidden = True

                    if not app['name'] or not app['exec'] or no_display or hidden:
                        continue

                    if is_system_app(app['name'], desktop_id):
                        continue

                    app['icon'] = validate_icon(app['icon'])

                    key = base64.b64encode(app['exec'].encode()).decode()
                    usage = usage_db.get(key, {})

                    if usage:
                        app['usage'] = usage

                    apps[app['name']] = app

            except Exception:
                pass

    res = list(apps.values())

    def sort_key(x):
        u = x.get('usage', {})
        count = u.get('count', 0)
        last_used = u.get('last_used', 0)
        has_usage = 0 if count > 0 else 1
        return (has_usage, -count, -last_used, x['name'].lower())

    res.sort(key=sort_key)
    print(json.dumps(res))


if __name__ == "__main__":
    fetch_apps()
