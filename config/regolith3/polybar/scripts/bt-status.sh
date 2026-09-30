#!/usr/bin/env bash

set -Eeuo pipefail

ICON_ON=${ICON_ON:-}
ICON_OFF=${ICON_OFF:-}

# If bluetoothctl is missing, just say off.
if ! command -v bluetoothctl >/dev/null 2>&1; then
  echo "${ICON_OFF} off"
  exit 0
fi

# Powered state
powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}')

# Find first connected device
connected_name=""
while read -r _ mac name; do
  if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
    connected_name=${name:-"connected"}
    break
  fi
done < <(bluetoothctl devices 2>/dev/null)

if [[ "$powered" != "yes" ]]; then
  echo "${ICON_OFF} Off"
elif [[ -n "$connected_name" ]]; then
  echo "${ICON_ON} ${connected_name}"
else
  echo "${ICON_ON} On"
fi
