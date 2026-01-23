#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$(dirname "$(dirname "$(realpath "$0")")")/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory not found at $WALLPAPER_DIR"
    exit 1
fi

echo "Converting wallpapers in $WALLPAPER_DIR to PNG..."
cd "$WALLPAPER_DIR" || exit 1

count=0

# Loop through common image formats
for img in *.{jpg,jpeg,webp,JPG,JPEG,WEBP}; do
    [ -f "$img" ] || continue
    
    filename=$(basename "$img")
    name="${filename%.*}"
    
    # Skip if PNG already exists
    if [ -f "${name}.png" ]; then
        echo "Skipping $filename (PNG already exists)"
        continue
    fi
    
    echo "Converting $filename -> ${name}.png"
    
    # Convert to PNG preserving quality
    if command -v magick >/dev/null 2>&1; then
        magick "$img" -quality 100 "${name}.png"
    elif command -v convert >/dev/null 2>&1; then
        convert "$img" -quality 100 "${name}.png"
    else
        echo "Error: ImageMagick (magick or convert) not found!"
        exit 1
    fi
    
    if [ $? -eq 0 ]; then
        count=$((count + 1))
        # Optional: Remove original
        # rm "$img"
    else
        echo "Failed to convert $filename"
    fi
done

echo "Conversion complete! Converted $count images."
