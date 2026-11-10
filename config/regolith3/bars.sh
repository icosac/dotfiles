#!/usr/bin/env bash
# Start Regolith's top and bottom bars. All three setups stay in the repo:
#   eww          both bars in eww, "islands" style (eww/)
#   eww-classic  Polybar top bar + the first, Polybar-like eww bottom bar (eww-classic/)
#   polybar      both bars in Polybar (polybar/)
# Usage: bars.sh [eww|eww-classic|polybar]. Without an argument it restarts the setup
# chosen last (eww if installed, else polybar). Called by i3/config.d/70_polybar.

set -uo pipefail

dir="$HOME/.config/regolith3"
state="${XDG_STATE_HOME:-$HOME/.local/state}/regolith-bars"
PATH="$HOME/.local/bin:$PATH"

case ${1:-} in
  eww|eww-classic|polybar) mkdir -p "${state%/*}"; echo "$1" > "$state" ;;
  "") ;;
  *) echo "usage: ${0##*/} [eww|eww-classic|polybar]" >&2; exit 1 ;;
esac

choice=$(cat "$state" 2>/dev/null || true)
have_eww=0; command -v eww >/dev/null 2>&1 && have_eww=1
[ "$have_eww" = 1 ] || choice=polybar
: "${choice:=eww}"

# One run at a time: monitor changes (display-watch.sh) and i3 can call this in quick
# succession, and two overlapping runs each started their own eww, doubling the bars
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/regolith-bars.lock"
flock 9

# Stop every bar, whichever setup was running. pkill rather than `eww kill`, which
# only reaches the daemon owning the socket and would miss a stray second one
pkill -x polybar 2>/dev/null
pkill -x eww 2>/dev/null
for _ in $(seq 50); do
  pgrep -x eww >/dev/null || pgrep -x polybar >/dev/null || break
  sleep 0.1
done

start_eww() {  # config dir, windows...
  local cfg=$1; shift
  eww -c "$dir/$cfg" daemon >/dev/null 2>&1
  eww -c "$dir/$cfg" open-many "$@"
}

case $choice in
  eww)
    start_eww eww top bottom ;;
  eww-classic)
    polybar -q top -c "$dir/polybar/config.ini" >/dev/null 2>&1 &
    start_eww eww-classic bottom ;;
  polybar)
    polybar -q top -c "$dir/polybar/config.ini" >/dev/null 2>&1 &
    polybar -q bottom -c "$dir/polybar/config.ini" >/dev/null 2>&1 & ;;
esac
