#!/usr/bin/env bash
# desc: fastfetch system summary shown when a shell opens (also run by the base install)
# check: command -v fastfetch
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if have fastfetch; then
  ok "$(fastfetch --version)"
  exit 0
fi

if is_macos; then
  pkg_install fastfetch
elif is_apt && apt-cache show fastfetch >/dev/null 2>&1; then
  # Packaged in Debian 13 / Ubuntu 25.04 and later
  pkg_install fastfetch
elif is_apt; then
  # Older releases: the upstream .deb. The plain build wants a recent glibc (it is built
  # on Ubuntu 22.04); the "polyfilled" one runs on older systems (18.04, Debian 10).
  case "$DEB_ARCH" in
    amd64) arch=amd64 ;;
    arm64) arch=aarch64 ;;
    *) die "no fastfetch .deb for $DEB_ARCH" ;;
  esac
  glibc="$(ldd --version 2>/dev/null | awk 'NR == 1 { print $NF }')"
  variant=""
  if [ -z "$glibc" ] || [ "$(printf '%s\n' "$glibc" 2.35 | sort -V | head -1)" != 2.35 ]; then
    variant="-polyfilled"
  fi
  make_tmp
  log "installing fastfetch from GitHub (fastfetch-linux-$arch$variant.deb, glibc ${glibc:-unknown})"
  download "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-$arch$variant.deb" \
    "$TMP_DIR/fastfetch.deb"
  pkg_update
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$TMP_DIR/fastfetch.deb"
else
  die "unsupported OS '$OS_ID'"
fi
[ "${DRY_RUN:-0}" = 1 ] || ok "$(fastfetch --version)"
