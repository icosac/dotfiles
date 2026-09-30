#!/usr/bin/env bash
# desc: Visual Studio Code (+ Microsoft apt repo); extensions come from Settings Sync
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! have code; then
  log "installing VS Code"
  if is_macos; then
    run brew install --cask visual-studio-code
  elif is_apt; then
    make_tmp
    # The official .deb registers the Microsoft apt repo itself, so later updates come via apt.
    download "https://update.code.visualstudio.com/latest/linux-deb-${DEB_ARCH/amd64/x64}/stable" "$TMP_DIR/code.deb"
    pkg_update
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$TMP_DIR/code.deb"
  else
    die "unsupported OS"
  fi
fi
ok "$(code --version | head -1)"

