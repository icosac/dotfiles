#!/usr/bin/env bash
# desc: rofi-calc plugin, patched: calculator results inside the Win+Space launcher
# applies: command -v apt-get
# check: [ -f ~/.local/lib/rofi/calc.so ]
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! is_apt; then
  warn "rofi-calc setup supports Debian/Ubuntu only (this is $OS_ID), skipping"
  exit 0
fi

# Built with setup/patches/rofi-calc-combi.patch (calculator row inside the Win+Space
# app/file list, see config/regolith3/rofi/launcher.sh) and installed per user as the
# "qcalc" mode; the launcher points ROFI_PLUGIN_PATH at it.
plugin_dir="$HOME/.local/lib/rofi"
if [ -f "$plugin_dir/calc.so" ] && [ "${FORCE:-0}" != 1 ]; then
  ok "rofi-calc already installed (FORCE=1 to rebuild)"
  exit 0
fi

# Newer rofi-calc releases need rofi >= 1.7.6; v2.2.1 is the last for older rofi (Ubuntu 22.04: 1.7.1)
version="${ROFI_CALC_VERSION:-v2.2.1}"
pkg_install rofi rofi-dev qalc xclip libqalculate-dev libglib2.0-dev libcairo2-dev \
  autoconf automake libtool libtool-bin pkg-config build-essential git
make_tmp
log "building rofi-calc $version"
run git clone --depth 1 --branch "$version" https://github.com/svenstaro/rofi-calc "$TMP_DIR/rofi-calc"
(cd "$TMP_DIR/rofi-calc" &&
  run git apply "$DOTFILES/setup/patches/rofi-calc-combi.patch" &&
  run mkdir -p m4 &&
  run autoreconf -i &&
  run mkdir -p build &&
  cd build &&
  run ../configure &&
  run make)
run mkdir -p "$plugin_dir"
run install -m 755 "$TMP_DIR/rofi-calc/build/.libs/calc.so" "$plugin_dir/calc.so"
ok "installed rofi-calc (qcalc) in $plugin_dir"
