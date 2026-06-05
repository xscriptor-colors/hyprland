#!/usr/bin/env python3
import os
import glob
import json
import base64

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
                                
                    if app['name'] and app['exec'] and not no_display:
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


