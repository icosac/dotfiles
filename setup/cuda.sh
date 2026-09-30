#!/usr/bin/env bash
# desc: CUDA toolkit from NVIDIA's apt repo (Ubuntu 20.04/22.04/24.04, NVIDIA GPU only)
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if ! is_ubuntu 20.04 22.04 24.04; then
  warn "CUDA setup supports Ubuntu 20.04/22.04/24.04 only (this is $OS_ID $OS_VERSION), skipping"
  exit 0
fi
if ! { have lspci && lspci | grep -qi nvidia; } && ! [ -e /proc/driver/nvidia/version ]; then
  warn "no NVIDIA GPU detected, skipping"
  exit 0
fi

case "$ARCH" in x86_64) repo_arch=x86_64 ;; arm64) repo_arch=sbsa ;; *) die "unsupported arch $ARCH" ;; esac
if ! apt_has cuda-keyring; then
  make_tmp
  download "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${OS_VERSION//./}/$repo_arch/cuda-keyring_1.1-1_all.deb" "$TMP_DIR/cuda-keyring.deb"
  as_root dpkg -i "$TMP_DIR/cuda-keyring.deb"
  _PKG_UPDATED=0
fi
pkg_install cuda-toolkit
ok "CUDA installed; /usr/local/cuda/bin is added to PATH by config/zsh/zshrc.d/10-path.zsh"
command -v nvidia-smi >/dev/null || warn "no NVIDIA driver found: 'sudo ubuntu-drivers install' then reboot"
