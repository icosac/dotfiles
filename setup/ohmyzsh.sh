#!/usr/bin/env bash
# desc: oh-my-zsh (keeps the repo .zshrc) and zsh as login shell
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

have zsh || pkg_install zsh
have git || pkg_install git

if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "oh-my-zsh already installed"
else
  log "installing oh-my-zsh"
  make_tmp; tmp="$TMP_DIR"
  download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh "$tmp/omz.sh"
  run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$tmp/omz.sh" --unattended --keep-zshrc
fi

zsh_path="$(command -v zsh)"
if is_macos; then
  login_shell="$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')"
else
  login_shell="$(getent passwd "$USER" | cut -d: -f7)"
fi
if [ "$(basename "$login_shell")" = zsh ]; then
  ok "login shell is already zsh"
else
  grep -qxF "$zsh_path" /etc/shells || printf '%s\n' "$zsh_path" | as_root tee -a /etc/shells >/dev/null
  # via sudo, so it reuses install.sh's cached credentials instead of asking again
  log "changing login shell to $zsh_path"
  as_root chsh -s "$zsh_path" "$USER" || warn "could not change the login shell: run 'chsh -s $zsh_path' yourself"
fi
