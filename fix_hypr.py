import os

path = "/home/xscriptor/.config/hypr/windowrules.conf"
print(f"Reading {path}")
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Preserve comments/empty lines exactly
    if not line.strip() or line.strip().startswith('#'):
        new_lines.append(line)
        continue
    
    # Replace windowrulev2 keyword
    l = line.replace('windowrulev2', 'windowrule')
    
    # Strip class: prefix for V1 compatibility
    l = l.replace('class:', '')
    
    # Comment out xwayland specific rule which might be incompatible
    if 'xwayland:' in l:
        l = '# ' + l
        
    new_lines.append(l)

print(f"Writing {len(new_lines)} lines to {path}")
with open(path, 'w') as f:
    f.writelines(new_lines)

print("File written successfully. Preview:")
with open(path, 'r') as f:
    print(f.read()[:300])
