#!/usr/bin/env bash
# desc: macOS: brew update && upgrade at reboot and daily at 20:00 (cron)
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

is_macos || { warn "macOS only, skipping"; exit 0; }
have brew || die "Homebrew missing: run ./install.sh first"
brew_bin="$(command -v brew)"
job="/bin/bash -c '($brew_bin update && $brew_bin upgrade)' >> $HOME/Library/Logs/brew-autoupdate.log 2>&1"
current="$(crontab -l 2>/dev/null || true)"
new="$current"
for when in "@reboot" "0 20 * * *"; do
  line="$when $job"
  grep -qxF "$line" <<<"$current" || new="${new:+$new
}$line"
done
if [ "$new" = "$current" ]; then
  ok "cron jobs already present"
else
  if [ "$DRY_RUN" = 1 ]; then printf '   [dry-run] update crontab\n'; else printf '%s\n' "$new" | crontab -; fi
  ok "added brew auto-update cron jobs (log: ~/Library/Logs/brew-autoupdate.log)"
fi
