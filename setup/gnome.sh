#!/usr/bin/env bash
# desc: GNOME tweaks (flat mouse acceleration)
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=lib/os.sh
. "$DOTFILES/lib/os.sh"
refuse_root

have gsettings || { warn "gsettings not found, skipping"; exit 0; }
schema=org.gnome.desktop.peripherals.mouse
gsettings list-keys "$schema" 2>/dev/null | grep -qx accel-profile || { warn "$schema not available, skipping"; exit 0; }
if [ "$(gsettings get "$schema" accel-profile)" = "'flat'" ]; then
  ok "mouse acceleration already flat"
else
  run gsettings set "$schema" accel-profile flat
  ok "mouse acceleration set to flat"
fi
