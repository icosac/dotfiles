#!/usr/bin/env bash
# desc: TeX Live + latexmk + pygments (for minted); ~/.latexmkrc is linked by install.sh
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if is_macos; then
  log "installing MacTeX (large download)"
  run brew install --cask mactex-no-gui
  run brew install pygments
  exit 0
fi
is_apt || die "unsupported OS '$OS_ID'"

pkgs=(latexmk python3-pygments texlive-base texlive-latex-recommended texlive-latex-extra texlive-science texlive-luatex)
# texlive-plain-generic replaced texlive-generic-recommended in TeX Live 2019 (Ubuntu 20.04, Debian 11)
if apt-cache show texlive-plain-generic >/dev/null 2>&1; then
  pkgs+=(texlive-plain-generic)
else
  pkgs+=(texlive-generic-recommended)
fi
pkg_install "${pkgs[@]}"
