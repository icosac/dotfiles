#!/usr/bin/env bash
# desc: eww widgets (Regolith top/bottom bars, real app icons), built from source; FORCE=1 to rebuild
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! is_apt; then
  warn "eww setup supports Debian/Ubuntu only (this is $OS_ID), skipping"
  exit 0
fi

version="${EWW_VERSION:-v0.6.0}"
if [ -x "$HOME/.local/bin/eww" ] && [ "${FORCE:-0}" != 1 ]; then
  ok "eww already installed: $("$HOME/.local/bin/eww" --version) (FORCE=1 to rebuild)"
else
  # No prebuilt releases: build the X11-only variant (Regolith runs on X11)
  pkg_install git pkg-config build-essential libgtk-3-dev libdbusmenu-gtk3-dev
  if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
    log "installing Rust (rustup) to build eww"
    run sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path"
  fi
  make_tmp
  log "building eww $version (a few minutes)"
  run git clone --depth 1 --branch "$version" https://github.com/elkowar/eww "$TMP_DIR/eww"
  # The repo pins its Rust version in rust-toolchain.toml; rustup fetches it on demand
  (cd "$TMP_DIR/eww" && run "$HOME/.cargo/bin/cargo" build --release --no-default-features --features x11)
  run mkdir -p "$HOME/.local/bin"
  run install -m 755 "$TMP_DIR/eww/target/release/eww" "$HOME/.local/bin/eww"
  ok "installed ~/.local/bin/eww"
fi

# Bar config lives in config/regolith3/eww; python3-gi resolves the app icons
have python3 && python3 -c 'import gi' 2>/dev/null || pkg_install python3-gi
log "switch bars with ~/.config/regolith3/bars.sh {eww|eww-classic|polybar}"
