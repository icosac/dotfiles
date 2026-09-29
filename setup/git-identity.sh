#!/usr/bin/env bash
# desc: set git name/email in ~/.gitconfig.local (kept out of the repo)

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

local_cfg="$HOME/.gitconfig.local"
for key in user.name user.email; do
  if cur="$(git config -f "$local_cfg" "$key" 2>/dev/null)"; then
    ok "$key = $cur"
    continue
  fi
  [ -t 0 ] || die "$key not set and no terminal to ask: git config -f ~/.gitconfig.local $key VALUE"
  read -r -p "git $key: " val
  [ -n "$val" ] || die "empty $key"
  run git config -f "$local_cfg" "$key" "$val"
done
