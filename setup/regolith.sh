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

# Keybindings, launcher, compositor etc. are only Recommends of the packages
# above (and of regolith-i3-root-config/regolith-wm-config, which they pull in),
# which pkg_install skips: list them explicitly. The i3xrocks bar is left out,
# polybar replaces it.
pkg_install \
  regolith-i3-ilia \
  regolith-i3-session \
  regolith-i3-default-style \
  regolith-i3-compositor \
  regolith-i3-gaps \
  regolith-i3-unclutter \
  i3-next-workspace \
  regolith-wm-base-launchers \
  regolith-wm-navigation \
  regolith-wm-resize \
  regolith-wm-workspace-config \
  regolith-wm-swap-focus \
  regolith-wm-networkmanager \
  regolith-wm-rofication-ilia \
  regolith-wm-ftue \
  regolith-session-flashback-ext \
  regolith-compositor-picom-glx \
  regolith-i3-control-center-regolith \
  xdg-desktop-portal-regolith-x11-config

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
# Xresources points the wallpaper/lockscreen at ~/.background.png
link "$DOTFILES/config/regolith3/assets/IMG_2882.png" "$HOME/.background.png"
ok "Regolith ready (log out and pick the Regolith session)"
