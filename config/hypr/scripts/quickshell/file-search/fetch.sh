#!/usr/bin/env bash
# File search using fd/find
# Usage: fetch.sh <query>
QUERY="$1"
if [ -z "$QUERY" ]; then
    echo "[]"
    exit 0
fi

SEARCH_DIR="${2:-$HOME}"

if command -v fd &>/dev/null; then
    fd --type f --max-results 30 --color never "$QUERY" "$SEARCH_DIR" 2>/dev/null | head -30
elif command -v fzf &>/dev/null; then
    find "$SEARCH_DIR" -maxdepth 5 -type f -iname "*$QUERY*" 2>/dev/null | head -30
else
    find "$SEARCH_DIR" -maxdepth 4 -type f -iname "*$QUERY*" 2>/dev/null | head -20
fi
