#!/usr/bin/env bash
# desc: Regolith desktop (Ubuntu 22.04/24.04); REGOLITH_VERSION=v3.4 by default
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=lib/os.sh
. "$DOTFILES/lib/os.sh"
refuse_root

if ! is_ubuntu 22.04 24.04; then
  warn "Regolith setup supports Ubuntu 22.04/24.04 only (this is $OS_ID $OS_VERSION), skipping"
  exit 0
fi
version="${REGOLITH_VERSION:-v3.4}"
apt_repo regolith https://archive.regolith-desktop.com/regolith.key \
  "deb [arch=$DEB_ARCH signed-by=@KEYRING@] https://archive.regolith-desktop.com/ubuntu/stable $OS_CODENAME $version"
pkg_install regolith-desktop regolith-session-flashback regolith-look-lascaille
