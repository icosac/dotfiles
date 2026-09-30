#!/usr/bin/env bash
# desc: kitty terminal (+ Nerd Fonts)
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! have kitty; then
  if is_macos; then
    run brew install --cask kitty
  elif is_apt && apt-cache show kitty >/dev/null 2>&1; then
    pkg_install kitty
  else
    # Not packaged (e.g. Ubuntu 18.04): official installer into ~/.local/kitty.app
    log "installing kitty with the upstream installer"
    run sh -c 'curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n'
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty"
  fi
fi
ok "kitty installed"
bash "$DOTFILES/setup/fonts.sh"
