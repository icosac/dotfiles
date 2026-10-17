#!/usr/bin/env bash
# desc: Ghostty terminal (+ Nerd Fonts)
# check: command -v ghostty || [ -d /Applications/Ghostty.app ]
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! have ghostty; then
  if is_macos; then
    run brew install --cask ghostty
  elif is_apt && apt-cache show ghostty >/dev/null 2>&1; then
    # In the Ubuntu archive from 26.04
    pkg_install ghostty
  elif have snap; then
    as_root snap install ghostty --classic
  else
    die "no Ghostty package here: see https://ghostty.org/docs/install/binary"
  fi
fi
ok "ghostty installed"

# Per-session settings (no titlebar/rounded corners under Regolith), refreshed at every login
if ! is_macos; then
  autostart="$HOME/.config/autostart/ghostty-session.desktop"
  if [ "$DRY_RUN" = 1 ]; then
    log "[dry-run] would write $autostart"
  else
    mkdir -p "$(dirname "$autostart")"
    printf '[Desktop Entry]\nType=Application\nName=Ghostty session settings\nExec=%s\nNoDisplay=true\n' \
      "$DOTFILES/config/ghostty/session.sh" > "$autostart"
    "$DOTFILES/config/ghostty/session.sh"
  fi
  ok "ghostty session settings at login"
fi
bash "$DOTFILES/setup/fonts.sh"
