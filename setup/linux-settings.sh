#!/usr/bin/env bash
# desc: Linux desktop settings: flat mouse, no screen blanking/screensaver, Caps<->Esc on the built-in keyboard
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

is_macos && { warn "Linux only, skipping"; exit 0; }

# gset SCHEMA KEY VALUE DESC: set a GNOME setting unless it's already VALUE.
gset() {
  local schema="$1" key="$2" value="$3" desc="$4" cur
  if ! gsettings list-keys "$schema" 2>/dev/null | grep -qx "$key"; then
    warn "$schema $key not available, skipping"
    return 0
  fi
  cur="$(gsettings get "$schema" "$key")"
  if [ "$cur" = "$value" ] || [ "$cur" = "uint32 $value" ]; then
    ok "$desc (already set)"
  else
    run gsettings set "$schema" "$key" "$value"
    ok "$desc"
  fi
}

if have gsettings; then
  gset org.gnome.desktop.peripherals.mouse accel-profile "'flat'" "mouse acceleration flat"

  # Never blank, dim, start the screensaver or suspend when idle
  # (GNOME and Regolith both go through these)
  gset org.gnome.desktop.session idle-delay 0 "no screen blanking when idle"
  gset org.gnome.desktop.screensaver idle-activation-enabled false "no screensaver when idle"
  gset org.gnome.settings-daemon.plugins.power idle-dim false "no screen dimming when idle"
  gset org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "'nothing'" "no suspend when idle (on AC)"
  gset org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "'nothing'" "no suspend when idle (on battery)"
else
  warn "gsettings not found, skipping desktop settings"
fi

# Caps Lock <-> Escape on the built-in keyboard only, via udev hwdb (kernel
# level: works in X11, Wayland and the console, leaves external keyboards alone)
hwdb_src="$DOTFILES/config/udev/90-builtin-caps-esc.hwdb"
hwdb_dst=/etc/udev/hwdb.d/90-builtin-caps-esc.hwdb
if ! have systemd-hwdb; then
  warn "systemd-hwdb not found, skipping Caps/Esc swap"
elif cmp -s "$hwdb_src" "$hwdb_dst"; then
  ok "Caps Lock/Escape swapped on the built-in keyboard (already set)"
else
  log "swapping Caps Lock and Escape on the built-in keyboard"
  as_root install -D -m 0644 "$hwdb_src" "$hwdb_dst"
  as_root systemd-hwdb update
  as_root udevadm trigger --subsystem-match=input --action=change
  ok "Caps Lock/Escape swapped on the built-in keyboard"
fi
