#!/usr/bin/env python3
import os
import glob
import json
import base64

SYSTEM_BLOCKLIST = [
    "avahi", "advanced network", "ark", "file roller", "gdebi", "backup",
    "firewall", "logs", "system monitor", "disk usage", "partition",
    "printer", "settings", "control center", "gnome control center",
    "about", "software", "firmware", "language", "region", "accessibility",
    "color management", "universal access", "users", "account details",
    "startup disk", "disks", "drives", "hardware", "blueman",
    "bluetooth", "connect to server", "network connections",
    "network proxy", "online accounts", "power statistics", "power manager",
    "details", "display", "wallpapers", "background", "look and feel",
    "mate", "cinnamon", "xfce", "lxde", "kde", "gnome", "plasma",
    "session", "welcome", "tour", "first", "setup", "configuration",
    "document viewer", "image viewer", "text editor", "gedit", "kate",
    "calculator", "calendar", "clock", "notes", "contacts", "maps",
    "weather", "help", "terminal", "lxterminal", "xfce4-terminal",
    "mate-terminal", "konsole", "gnome-terminal", "tilix", "terminator",
    "whatsapp", "telegram-desktop",
]

def is_system_app(name, exec_path):
    name_lower = name.lower()
    exec_lower = exec_path.lower() if exec_path else ""
    for blocked in SYSTEM_BLOCKLIST:
        if blocked in name_lower or blocked in exec_lower:
            return True
    return False

def load_usage_db():
    db_path = os.path.expanduser('~/.cache/quickshell/applauncher_usage.json')
    if os.path.exists(db_path):
        try:
            with open(db_path, 'r') as f:
                return json.load(f)
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
        '/run/current-system/sw/share/applications'
    ]
    
    usage_db = load_usage_db()
    
    for d in dirs:
        if not os.path.exists(d):
            continue
            
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8') as file:
                    app = {'name': '', 'exec': '', 'icon': ''}
                    is_desktop = False
                    no_display = False
                    
                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False
                            
                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                                
                    if app['name'] and app['exec'] and not no_display and not is_system_app(app['name'], app['exec']):
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
        return (-count, -last_used, x['name'].lower())
    
    res.sort(key=sort_key)
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()


