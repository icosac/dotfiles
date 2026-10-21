#!/usr/bin/env bash
# Restart the compositor (picom) and the bars whenever the monitor layout changes:
# lid closed/opened, a monitor selected in the display settings, a dock (un)plugged.
#
# Why: with the DisplayLink dock (evdi driver), picom's OpenGL backend keeps drawing into
# its old screen buffer when the laptop panel turns off: the external monitor shows tiled
# copies of the old screen, then goes black and stops responding (dock keyboard included).
# A fresh picom (compositor.sh, which also turns vsync off when only DisplayLink
# monitors are active) picks up the new layout. Started by i3/config.d/71_display_watch.
#
# Listens to i3's "output" events (sent on every RandR change), waits until they stop
# for a moment (one lid close sends several), then restarts once.

set -uo pipefail

dir="$HOME/.config/regolith3"
log="${XDG_CACHE_HOME:-$HOME/.cache}/display-watch.log"
settle=2  # seconds without new events before acting

# Single instance: i3 starts this on every config reload. Run in our own process group
# so the previous copy (script, event pipe and all) can be stopped as a whole.
[ "$(ps -o pgid= $$ | tr -d ' ')" = "$$" ] || exec setsid "$0" "$@"
pidfile="${XDG_RUNTIME_DIR:-/tmp}/display-watch.pid"
old=$(cat "$pidfile" 2>/dev/null)
[ -n "$old" ] && [ "$old" != "$$" ] && kill -- "-$old" 2>/dev/null
echo $$ > "$pidfile"

note() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$log"; }

restart() {
  note "layout: $(xrandr --listactivemonitors | tail -n +2 | awk '{print $4, $3}' | paste -sd ' ')"
  # Restarts picom, without vsync if only DisplayLink monitors are active
  "$dir/compositor.sh" >/dev/null 2>&1 &
  sleep 1
  "$dir/bars.sh" >/dev/null 2>&1 &
  note "restarted picom and bars"
}

note "watching i3 output events"
i3-msg -t subscribe -m '["output"]' 2>/dev/null | while read -r _; do
  # Swallow the rest of the burst, then act once
  while read -r -t "$settle" _; do :; done
  restart
done
note "i3 event stream ended"
