#!/bin/bash

MARKER="$HOME/.napi_wallpaper_done"
WALL="/usr/share/backgrounds/napi-wallpaper.jpg"

# выполнить только один раз
[ -f "$MARKER" ] && exit 0

# ждём пока xfconf поднимется
sleep 3

# получить все backdrop пути
paths=$(xfconf-query -c xfce4-desktop -lv | \
        grep last-image | awk '{print $1}')

for p in $paths; do
    xfconf-query -c xfce4-desktop -p "$p" -s "$WALL"
done

touch "$MARKER"
exit 0
