#!/bin/bash
set -e

MARKER="$HOME/.napi_wallpaper_done"
WALL="/usr/share/backgrounds/napi-wallpaper.jpg"

[ -f "$MARKER" ] && exit 0

gsettings set org.mate.background picture-filename "$WALL"

touch "$MARKER"
exit 0
