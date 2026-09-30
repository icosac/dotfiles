#!/bin/bash

set -Eeuo pipefail

DLY=${DLY:-1}
ICON=${ICON:-}

read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total_before=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_before=$((idle + iowait))

sleep "${DLY}"

read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total_after=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_after=$((idle + iowait))

total_delta=$((total_after - total_before))
idle_delta=$((idle_after - idle_before))

if [ "${total_delta}" -le 0 ]; then
  echo "${ICON} n/a"
  exit 0
fi

usage=$(( (1000 * (total_delta - idle_delta) / total_delta + 5) / 10 ))

echo "${ICON} ${usage}%"
