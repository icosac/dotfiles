#!/usr/bin/env bash
# Battery for the eww top bar, one JSON line every 5s:
#   {"present": true, "pct": 87, "state": "Charging"}   (state as in sysfs)
# "present" is false on machines without a battery: the bar then hides it.

set -uo pipefail

while :; do
  bat=""
  for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] && { bat=$b; break; }
  done
  if [ -n "$bat" ]; then
    printf '{"present": true, "pct": %s, "state": "%s"}\n' "$(cat "$bat/capacity")" "$(cat "$bat/status")"
  else
    echo '{"present": false, "pct": 0, "state": ""}'
  fi
  sleep 5
done
