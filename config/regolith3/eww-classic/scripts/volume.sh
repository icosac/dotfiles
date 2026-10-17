#!/usr/bin/env bash
# Default sink volume for the eww bar: {"vol": 35, "muted": false}, printed at
# start and again on every PulseAudio/PipeWire sink change.

set -uo pipefail

status() {
  local vol muted
  vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d %)
  muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{ print ($2 == "yes") ? "true" : "false" }')
  printf '{"vol": %s, "muted": %s}\n' "${vol:-0}" "${muted:-false}"
}

status
pactl subscribe 2>/dev/null | while read -r line; do
  case $line in *"on sink"*|*"on server"*) status ;; esac
done
