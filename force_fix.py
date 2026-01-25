path = "/home/xscriptor/.config/hypr/windowrules.conf"
print(f"Reading {path}")
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    # Fix lines 37/38 specifically which are broken matches
    if "pavucontrol" in line and "center" in line:
        new_lines.append("windowrule = match:class ^(pavucontrol)$, center 1\n")
        continue
    if "blueman-manager" in line and "center" in line and "floating" in line:
        new_lines.append("windowrule = match:class ^(blueman-manager)$, center 1\n")
        continue

    # Ensure xwayland block is commented
    if line.strip().startswith("windowrule {"):
        new_lines.append("# " + line)
        continue
    if "match:xwayland" in line:
        new_lines.append("# " + line)
        continue
    if "match:floating =" in line: # block syntax style
        new_lines.append("# " + line)
        continue
    if "rounding =" in line and "0" in line: # block syntax style
         new_lines.append("# " + line)
         continue
    if line.strip() == "}":
        new_lines.append("# " + line)
        continue
        
    new_lines.append(line)

print(f"Writing {len(new_lines)} lines to {path}")
with open(path, 'w') as f:
    f.writelines(new_lines)
