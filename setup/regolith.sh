#!/usr/bin/env bash
# desc: Regolith desktop (Ubuntu 22.04/24.04) + polybar/rofi config; REGOLITH_VERSION=v3.4 by default
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! is_ubuntu 22.04 24.04; then
  warn "Regolith setup supports Ubuntu 22.04/24.04 only (this is $OS_ID $OS_VERSION), skipping"
  exit 0
fi

version="${REGOLITH_VERSION:-v3.4}"
apt_repo regolith https://archive.regolith-desktop.com/regolith.key \
  "deb [arch=$DEB_ARCH signed-by=@KEYRING@] https://archive.regolith-desktop.com/ubuntu/stable $OS_CODENAME $version"
pkg_install \
  regolith-desktop \
  regolith-session-flashback \
  regolith-look-nord \
  xdg-desktop-portal-regolith

# Tools used by the polybar/i3xrocks modules and scripts in config/regolith3
pkg_install \
  polybar \
  rofi \
  python3 \
  bluez \
  libnotify-bin \
  x11-utils \
  x11-xkb-utils

# Polybar/rofi use Iosevka, i3xrocks uses JetBrainsMono
bash "$DOTFILES/setup/fonts.sh"

link "$DOTFILES/config/regolith3" "$HOME/.config/regolith3"
ok "Regolith ready (log out and pick the Regolith session)"
