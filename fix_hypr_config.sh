#!/bin/bash
# First replace windowrulev2 with windowrule (already done, but safe to repeat)
sed -i 's/windowrulev2 =/windowrule =/g' /home/xscriptor/.config/hypr/windowrules.conf

# Replace "class:" with empty string to use V1 syntax
sed -i 's/class://g' /home/xscriptor/.config/hypr/windowrules.conf

# Comment out complex xwayland rule for now
sed -i 's/^windowrule = rounding 0, xwayland:1/# windowrule = rounding 0, xwayland:1/' /home/xscriptor/.config/hypr/windowrules.conf

echo "Applied V1 syntax fix to /home/xscriptor/.config/hypr/windowrules.conf"
