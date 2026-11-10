#!/usr/bin/env bash
# desc: tmux-resurrect + tmux-continuum (sessions survive reboots), tmux-mem-cpu-load for the status bar
# check: command -v tmux-mem-cpu-load && [ -d ~/.tmux/plugins/tmux-resurrect ] && [ -d ~/.tmux/plugins/tmux-continuum ]
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

# tmux-resurrect saves and restores sessions (windows, panes, folders, programs);
# tmux-continuum saves every 15 minutes and restores when tmux starts. Loaded at the end
# of config/tmux/.tmux.conf. Cloned (or updated) into ~/.tmux/plugins, no plugin manager.
plugins="$HOME/.tmux/plugins"
for name in tmux-resurrect tmux-continuum; do
  if [ -d "$plugins/$name/.git" ]; then
    run git -C "$plugins/$name" pull -q --ff-only || warn "could not update $name"
  else
    run mkdir -p "$plugins"
    run git clone -q --depth 1 "https://github.com/tmux-plugins/$name" "$plugins/$name"
  fi
  ok "$name"
done

if have tmux-mem-cpu-load && [ "${FORCE:-0}" != 1 ]; then
  ok "tmux-mem-cpu-load already installed"
  exit 0
fi
if is_macos; then
  log "installing tmux-mem-cpu-load"
  run brew install tmux-mem-cpu-load
  exit 0
fi
for p in git cmake; do have "$p" || pkg_install "$p"; done
have c++ || pkg_install build-essential
log "building tmux-mem-cpu-load"
make_tmp
run git clone --depth 1 https://github.com/thewtex/tmux-mem-cpu-load "$TMP_DIR/src"
# classic cmake invocation: Ubuntu 18.04 ships cmake 3.10 (no -S/-B/--install)
run mkdir -p "$TMP_DIR/build"
(cd "$TMP_DIR/build" &&
  run cmake ../src -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local" &&
  run make -j"$(getconf _NPROCESSORS_ONLN)" &&
  run make install)
ok "installed ~/.local/bin/tmux-mem-cpu-load"
