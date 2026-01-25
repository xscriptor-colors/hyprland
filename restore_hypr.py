import shutil
import os

src = "/home/xscriptor/Documentos/repos/xscriptordev/hyprland/fix_restore.conf"
dst = "/home/xscriptor/.config/hypr/windowrules.conf"

print(f"Restoring {dst} from {src}")
with open(src, 'r') as f:
    content = f.read()

with open(dst, 'w') as f:
    f.write(content)

print("Restored.")
