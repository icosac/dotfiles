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

# Third-party plugins (loaded from config/zsh/.zshrc); FORCE=1 updates them
custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-completions; do
  dest="$custom/${repo#*/}"
  if [ ! -d "$dest" ]; then
    run git clone --depth 1 "https://github.com/$repo" "$dest"
    ok "installed ${repo#*/}"
  elif [ "${FORCE:-0}" = 1 ]; then
    run git -C "$dest" pull --ff-only
    ok "updated ${repo#*/}"
  else
    ok "${repo#*/} already installed"
  fi
done

# fzf: Ctrl-R history search, Ctrl-T files, Alt-C directories (see zshrc.d/40-fzf.zsh).
# Ubuntu's package is too old for `fzf --zsh` (needs >= 0.48): use the release binary.
if have fzf && fzf --zsh >/dev/null 2>&1 && [ "${FORCE:-0}" != 1 ]; then
  ok "fzf already installed: $(fzf --version | cut -d' ' -f1)"
elif is_macos; then
  run brew install fzf
else
  tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/junegunn/fzf/releases/latest)"
  tag="${tag##*/}"
  case "$ARCH" in x86_64) farch=amd64 ;; *) farch="$ARCH" ;; esac
  [ -n "${TMP_DIR:-}" ] || make_tmp
  download "https://github.com/junegunn/fzf/releases/download/$tag/fzf-${tag#v}-linux_$farch.tar.gz" "$TMP_DIR/fzf.tgz"
  run mkdir -p "$HOME/.local/bin"
  run tar -xzf "$TMP_DIR/fzf.tgz" -C "$HOME/.local/bin" fzf
  ok "installed fzf ${tag#v} in ~/.local/bin"
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
