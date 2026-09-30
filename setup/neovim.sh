#!/usr/bin/env bash
# desc: latest stable Neovim (/opt/nvim + /usr/local/bin/nvim) and AstroNvim plugins (FORCE=1 to reinstall)
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

if is_macos; then
  have nvim || run brew install neovim
else
  # AstroNvim needs these at runtime
  for p in git curl; do have "$p" || pkg_install "$p"; done
  have rg || pkg_install ripgrep || warn "ripgrep not available, AstroNvim search will be limited"
  have cc || pkg_install build-essential

  if [ -x /opt/nvim/bin/nvim ] && /opt/nvim/bin/nvim --version >/dev/null 2>&1 && [ "${FORCE:-0}" != 1 ]; then
    ok "neovim already installed: $(/opt/nvim/bin/nvim --version | head -1) (FORCE=1 to upgrade)"
  else
    make_tmp; tmp="$TMP_DIR"
    asset="nvim-linux-$ARCH.tar.gz"
    # Official builds need a recent glibc; neovim-releases has builds for older ones (e.g. Ubuntu 18.04).
    for url in "https://github.com/neovim/neovim/releases/download/stable/$asset" \
               "https://github.com/neovim/neovim-releases/releases/latest/download/$asset"; do
      log "trying $url"
      rm -rf "$tmp/nvim" && mkdir -p "$tmp/nvim"
      download "$url" "$tmp/$asset" || continue
      tar -C "$tmp/nvim" --strip-components=1 -xzf "$tmp/$asset"
      if "$tmp/nvim/bin/nvim" --version >/dev/null 2>&1; then
        as_root rm -rf /opt/nvim
        as_root mv "$tmp/nvim" /opt/nvim
        break
      fi
      warn "this build does not run here, trying the next one"
    done
    [ -x /opt/nvim/bin/nvim ] || die "could not install a working neovim"
    ok "installed $(/opt/nvim/bin/nvim --version | head -1)"
  fi
  if [ "$(readlink /usr/local/bin/nvim 2>/dev/null || true)" != /opt/nvim/bin/nvim ]; then
    as_root ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  fi
fi

if [ -L "$HOME/.config/nvim" ]; then
  log "installing AstroNvim plugins (headless)"
  run nvim --headless "+Lazy! restore" +qa || warn "plugin install reported errors; open nvim to see them"
else
  warn "$HOME/.config/nvim is not linked: run ./install.sh first"
fi
