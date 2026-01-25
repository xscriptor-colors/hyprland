import re

path = "/home/xscriptor/.config/hypr/windowrules.conf"
output_path = "/home/xscriptor/.config/hypr/windowrules.conf"

print(f"Reading {path}")
with open(path, 'r') as f:
    lines = f.readlines()

new_lines = []
in_block = False

for line in lines:
    stripped = line.strip()
    
    # Handle block syntax - comment out everything inside windowrule { }
    if stripped.startswith("windowrule {"):
        in_block = True
        new_lines.append("# " + line)
        continue
        
    if in_block:
        new_lines.append("# " + line)
        if stripped == "}":
            in_block = False
        continue
    
    # Handle floating match cleanup
    # Remove "match:floating 1" and associated commas
    # Patterns:
    # "match:floating 1, " -> "match:" (keep match prefix for next item)
    # ", match:floating 1" -> "" (item is later in list)
    
    l = line
    l = l.replace("match:floating 1, ", "match:")
    l = l.replace(", match:floating 1", "")
    
    # Ensure space separator for match syntax
    # "match:class:" -> "match:class "
    l = l.replace("match:class:", "match:class ")
    l = l.replace("match:title:", "match:title ")
    
    new_lines.append(l)

print(f"Writing {len(new_lines)} lines to {output_path}")
with open(output_path, 'w') as f:
    f.writelines(new_lines)

print("Cleanup completed.")
