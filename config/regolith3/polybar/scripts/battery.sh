#!/usr/bin/env bash
# Battery percentage + charging state for polybar's top bar.
# Prints nothing (polybar then hides the module) when the machine has no battery.

set -Eeuo pipefail

bat=""
for b in /sys/class/power_supply/BAT*; do
  [ -r "$b/capacity" ] && { bat=$b; break; }
done
[ -n "$bat" ] || exit 0

pct=$(cat "$bat/capacity")
state=$(cat "$bat/status")

case $state in
  Charging)    echo "%{F#43a047}󰂄%{F-} ${pct}%" ;;
  Discharging) levels=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
               icon=${levels[$(( pct >= 100 ? 9 : pct / 10 ))]}
               if [ "$pct" -le 20 ]; then
                 echo "%{F#FF5250}${icon} ${pct}%%{F-}"
               else
                 echo "${icon} ${pct}%"
               fi ;;
  *)           echo "󰚥 ${pct}%" ;;  # Full / Not charging: on AC
esac
