import re

input_path = "/home/xscriptor/.config/hypr/windowrules.conf"
output_path = "/home/xscriptor/.config/hypr/windowrules.conf"

boolean_actions = ['float', 'pin', 'center', 'fullscreen', 'immediate']

def process_line(line):
    line = line.strip()
    if not line.startswith("windowrulev2") and not line.startswith("windowrule"):
        return line + "\n"
    
    # Check for block syntax end or start if we implemented that? No, assuming line based.
    if line.endswith("{") or line.endswith("}"):
        return line + "\n"

    parts = line.split('=', 1)
    if len(parts) != 2:
        return line + "\n"
    
    content = parts[1].strip()
    
    # Handle the complex xwayland rule specifically - comment out due to parser issues
    if "rounding 0" in content and "xwayland:1" in content:
         return (
            "# windowrule = rounding 0, xwayland:1, floating:1\n"
            "# Commented out during v0.53 migration due to complex matcher issues\n"
        )

    # General parsing
    if ',' not in content:
        # Maybe already in new format? e.g. "match:..., action" ?
        # If it has "match:", assume it's good or valid enough?
        if "match:" in content: 
             return line + "\n"
        return line + "\n"
        
    # Split by first comma.
    
    first_part, second_part = content.split(',', 1)
    first_part = first_part.strip()
    second_part = second_part.strip()
    
    if "match:" in first_part:
        return line + "\n" # Already migrated?

    # Assume OLD syntax: action = first_part, criteria = second_part
    action_part = first_part
    criteria_part = second_part
    
    # Remove floating:1 from criteria as it causes "invalid field type floating" error
    # We assume floating status is enforced by other rules or context
    criteria_part = criteria_part.replace('floating:1, ', '')
    criteria_part = criteria_part.replace(', floating:1', '')
    criteria_part = criteria_part.replace('floating:1', '') # If it's the only one
    criteria_part = criteria_part.strip()

    # 1. Transform Action
    # Check if boolean
    action_cmd = action_part.split(' ')[0]
    if action_cmd in boolean_actions:
        args = action_part.split(' ')[1:]
        if not args:
            action_part += " 1"
    
    # 2. Transform Criteria
    # class:^(...) -> match:class ^(...)
    # Strip "class:" or "title:" prefix and keep the regex.
    # User said: "class:^(kitty)$" -> "match:class ^(kitty)$"
    # So we replace the first colon with space?
    
    if ':' in criteria_part:
        field, regex = criteria_part.split(':', 1)
        new_criteria = f"match:{field} {regex}"
    else:
        # Fallback
        new_criteria = f"match:{criteria_part}"
        
    return f"windowrule = {new_criteria}, {action_part}\n"

print(f"Reading {input_path}")
with open(input_path, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(process_line(line))

print(f"Writing {len(new_lines)} lines to {output_path}")
with open(output_path, 'w') as f:
    f.writelines(new_lines)
    
print("Migration completed.")
