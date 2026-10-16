#!/usr/bin/env bash
# desc: set git name/email and pull policy in ~/.gitconfig.local (kept out of the repo)

set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

local_cfg="$HOME/.gitconfig.local"
# Without a terminal (CI, piped runs) only report what is missing.
skip() { warn "$1 not set and no terminal to ask: run ./install.sh git-identity"; }

for key in user.name user.email; do
  if cur="$(git config -f "$local_cfg" "$key" 2>/dev/null)"; then
    ok "$key = $cur"
    continue
  fi
  [ -t 0 ] || { skip "$key"; continue; }
  val=""
  while [ -z "$val" ]; do read -r -p "git $key: " val; done
  run git config -f "$local_cfg" "$key" "$val"
done

# What `git pull` does when the branches diverged (git asks about this otherwise)
if cur="$(git config -f "$local_cfg" pull.rebase 2>/dev/null)" ||
   cur="$(git config -f "$local_cfg" pull.ff 2>/dev/null)"; then
  ok "pull policy already set ($cur)"
elif [ -t 0 ]; then
  printf 'When `git pull` finds diverged branches:\n'
  printf '  1) merge (default git behaviour)\n  2) rebase\n  3) fast-forward only (fail otherwise)\n'
  read -r -p "choice [1]: " choice
  case "${choice:-1}" in
    1) run git config -f "$local_cfg" pull.rebase false ;;
    2) run git config -f "$local_cfg" pull.rebase true ;;
    3) run git config -f "$local_cfg" pull.ff only ;;
    *) die "invalid choice '$choice'" ;;
  esac
  ok "pull policy saved"
else
  skip "pull policy"
fi
