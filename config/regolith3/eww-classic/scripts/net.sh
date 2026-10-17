#!/usr/bin/env bash
# Wired/wireless status for the eww bar, one JSON line per second:
#   {"wired": {"ip": "10.0.0.2", "down": "2 KB/s", "up": "0 KB/s"}, "wifi": {...}}
# "ip" is empty when the interface is down. Interfaces are detected, not hardcoded.

set -uo pipefail

wired="" wifi=""
for d in /sys/class/net/*; do
  n=${d##*/}
  if [ -d "$d/wireless" ]; then
    [ -n "$wifi" ] || wifi=$n
  elif [ -e "$d/device" ] && [[ $n == en* || $n == eth* ]]; then
    [ -n "$wired" ] || wired=$n
  fi
done

rate() {  # bytes/s -> "N KB/s" / "N.N MB/s"
  if [ "$1" -ge 1048576 ]; then
    awk -v b="$1" 'BEGIN { printf "%.1f MB/s", b / 1048576 }'
  else
    echo "$(( $1 / 1024 )) KB/s"
  fi
}

# Sets $json (no command substitution: the counters must survive between calls)
declare -A last_rx last_tx
iface_json() {
  local n=$1 ip rx tx down=0 up=0
  [ -n "$n" ] || { json='{"ip": "", "down": "", "up": ""}'; return; }
  ip=$(ip -4 -o addr show dev "$n" 2>/dev/null | awk '{ sub("/.*", "", $4); print $4; exit }')
  rx=$(cat "/sys/class/net/$n/statistics/rx_bytes" 2>/dev/null || echo 0)
  tx=$(cat "/sys/class/net/$n/statistics/tx_bytes" 2>/dev/null || echo 0)
  if [ -n "${last_rx[$n]:-}" ]; then
    down=$(( rx - last_rx[$n] )) up=$(( tx - last_tx[$n] ))
  fi
  last_rx[$n]=$rx last_tx[$n]=$tx
  printf -v json '{"ip": "%s", "down": "%s", "up": "%s"}' "$ip" "$(rate "$down")" "$(rate "$up")"
}

while :; do
  iface_json "$wired"; w=$json
  iface_json "$wifi"
  printf '{"wired": %s, "wifi": %s}\n' "$w" "$json"
  sleep 1
done
