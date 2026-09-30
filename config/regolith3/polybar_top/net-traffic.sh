#!/bin/bash

set -Eeuo pipefail

DLY=${DLY:-2}

find_if() {
  if [ -n "${IFACE:-}" ]; then
    echo "${IFACE}"
    return
  fi
  # Find the first default route that's not ppp/tun/tap.
  ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' | grep -Ev '^(ppp|tun|tap)' | head -n1
}

IFACE="$(find_if)"
SYS="/sys/class/net/${IFACE}"
if [ -z "${IFACE}" ] || [ ! -r "${SYS}/statistics/rx_bytes" ] || [ ! -r "${SYS}/statistics/tx_bytes" ]; then
  echo " no-if"
  exit 0
fi

if [ -d "${SYS}/wireless" ]; then
  ICON=""
else
  ICON=""
fi

rx1=$(<"${SYS}/statistics/rx_bytes")
tx1=$(<"${SYS}/statistics/tx_bytes")
sleep "${DLY}"
rx2=$(<"${SYS}/statistics/rx_bytes")
tx2=$(<"${SYS}/statistics/tx_bytes")

rxps=$(( (rx2 - rx1) / DLY ))
txps=$(( (tx2 - tx1) / DLY ))

fmt() { numfmt --to=iec --format='%.1f' "${1:-0}"; }

echo "${ICON} ↓$(fmt "${rxps}")/s ↑$(fmt "${txps}")/s"
