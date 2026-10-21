#!/usr/bin/env bash
# Start (or restart) picom with picom/config. Regolith runs this at login and on i3
# reloads (wm.program.compositor in Xresources), display-watch.sh on monitor changes.
#
# vsync makes picom wait for the screen's vertical blank before each frame. Monitors on
# the DisplayLink dock (evdi driver, outputs named DVI-I-*) have none, so when they are
# the only active outputs (lid closed) picom would wait forever and the picture freezes.
# In that case run without vsync; with a laptop/GPU output active, keep it.

set -uo pipefail

config="$HOME/.config/regolith3/picom/config"
[ -f "$config" ] || config="$(xrescat regolith.compositor.picom.config /etc/regolith/picom/config 2>/dev/null)"

while pidof picom >/dev/null; do
  pkill -x picom
  sleep 0.1
done

flags=()
active=$(xrandr --listactivemonitors 2>/dev/null | awk 'NR > 1 { print $NF }')
if [ -n "$active" ] && ! grep -qv '^DVI-I-' <<<"$active"; then
  flags+=(--no-vsync)
fi

printf '%s compositor: picom %s(outputs: %s)\n' "$(date '+%F %T')" "${flags[*]:+${flags[*]} }" \
  "$(paste -sd' ' <<<"$active")" >> "${XDG_CACHE_HOME:-$HOME/.cache}/display-watch.log"
exec picom --config "$config" ${flags[@]+"${flags[@]}"} --daemon
