#!/usr/bin/env bash
# desc: Docker Engine from docker.com (Linux) / Docker Desktop (macOS)
set -euo pipefail
# shellcheck source=lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=lib/os.sh
. "$DOTFILES/lib/os.sh"
refuse_root

if is_macos; then
  run brew install --cask docker
  exit 0
fi
is_apt || die "unsupported OS '$OS_ID'"

pkg_install ca-certificates curl gnupg
apt_repo docker "https://download.docker.com/linux/$OS_ID/gpg" \
  "deb [arch=$DEB_ARCH signed-by=@KEYRING@] https://download.docker.com/linux/$OS_ID $OS_CODENAME stable"
# Old scripts used this keyring; two different Signed-By values for one repo break apt.
[ -f /usr/share/keyrings/docker-archive-keyring.gpg ] && as_root rm -f /usr/share/keyrings/docker-archive-keyring.gpg
pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

getent group docker >/dev/null || as_root groupadd docker
if id -nG "$USER" | tr ' ' '\n' | grep -qx docker || getent group docker | cut -d: -f4 | tr ',' '\n' | grep -qx "$USER"; then
  ok "$USER is in the docker group"
else
  as_root usermod -aG docker "$USER"
  warn "added $USER to the docker group: log out and back in for it to apply"
fi
