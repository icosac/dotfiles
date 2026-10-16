#!/bin/sh
# Run at login (XDG autostart, see setup/ghostty.sh): writes the Ghostty settings
# that depend on the desktop session into ~/.config/ghostty/session.local.
# Regolith (i3) gets a plain, square-cornered window like kitty; GNOME keeps the GTK titlebar.
out="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/session.local"
[ -d "${out%/*}" ] || exit 0
case ":${XDG_CURRENT_DESKTOP:-}:" in
  *:Regolith:*) echo 'window-decoration = none' > "$out" ;;
  *)            : > "$out" ;;
esac
