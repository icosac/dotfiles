#!/usr/bin/env bash
# Start the bottom bar: eww (real app icons) or Polybar. Both configs stay in the repo.
#   bottom-bar.sh          (re)start the bar chosen last (eww if installed, else Polybar)
#   bottom-bar.sh eww      switch to eww and remember it
#   bottom-bar.sh polybar  switch back to Polybar and remember it
# Called by i3/config.d/70_polybar at login and on i3 reload.

set -uo pipefail

dir="$HOME/.config/regolith3"
state="${XDG_STATE_HOME:-$HOME/.local/state}/regolith-bottom-bar"
PATH="$HOME/.local/bin:$PATH"

case ${1:-} in
  eww|polybar) mkdir -p "${state%/*}"; echo "$1" > "$state" ;;
  "") ;;
  *) echo "usage: ${0##*/} [eww|polybar]" >&2; exit 1 ;;
esac

choice=$(cat "$state" 2>/dev/null || true)
if [ "$choice" != polybar ] && ! command -v eww >/dev/null 2>&1; then
  choice=polybar
fi
: "${choice:=eww}"

# Stop whichever bottom bar is running
pkill -f "^polybar .*bottom " 2>/dev/null
command -v eww >/dev/null 2>&1 && eww -c "$dir/eww" close-all >/dev/null 2>&1

if [ "$choice" = eww ]; then
  eww -c "$dir/eww" daemon >/dev/null 2>&1
  eww -c "$dir/eww" open bottom
else
  polybar -q bottom -c "$dir/polybar/config.ini" >/dev/null 2>&1 &
fi
