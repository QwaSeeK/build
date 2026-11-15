#!/bin/bash
set -e

MARKER="$HOME/.napi_wallpaper_done"
WALL="/usr/share/backgrounds/napi-wallpaper.jpg"

case ":${XDG_CURRENT_DESKTOP:-}:" in
	*:MATE:*) desktop=mate ;;
	*:GNOME:*) desktop=gnome; MARKER="${MARKER}_gnome" ;;
	*) exit 0 ;;
esac

[ -f "$MARKER" ] && exit 0

case "$desktop" in
	mate) gsettings set org.mate.background picture-filename "$WALL" ;;
	gnome)
		gsettings set org.gnome.desktop.background picture-uri "file://$WALL"
		gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL"
		;;
esac

touch "$MARKER"
exit 0
