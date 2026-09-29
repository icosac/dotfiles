#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

if [ -t 1 ]; then
  NC=$'\033[0m' BOLD=$'\033[1m' RED=$'\033[1;31m' GREEN=$'\033[1;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[1;34m'
else
  NC='' BOLD='' RED='' GREEN='' YELLOW='' BLUE=''
fi

log()     { printf '%s==>%s %s\n' "$BLUE" "$NC" "$*"; }
ok()      { printf '%s ok%s %s\n' "$GREEN" "$NC" "$*"; }
warn()    { printf '%swarn%s %s\n' "$YELLOW" "$NC" "$*" >&2; }
err()     { printf '%serror%s %s\n' "$RED" "$NC" "$*" >&2; }
die()     { err "$*"; exit 1; }
section() { printf '\n%s%s%s\n' "$BOLD" "$*" "$NC"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it in dry-run mode.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Run a command as root (plain run when already root, e.g. in CI containers).
if [ "$(id -u)" -eq 0 ]; then SUDO=(); else SUDO=(sudo); fi
as_root() { run ${SUDO[@]+"${SUDO[@]}"} "$@"; }

refuse_root() {
  [ "$(id -u)" -ne 0 ] || die "Run as your normal user, not root/sudo. sudo is used only where needed."
}

# link SRC DST: make DST a symlink to SRC. Existing real files are moved to $BACKUP_DIR.
link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "missing source $src"; return 1; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local rel="${dst#"$HOME"/}"
    run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    run mv "$dst" "$BACKUP_DIR/$rel"
    warn "backed up $dst -> $BACKUP_DIR/$rel"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  ok "linked $dst"
}

# append_once LINE FILE: append LINE to FILE unless an identical line is already there.
append_once() {
  local line="$1" file="$2"
  if [ -f "$file" ] && grep -qxF -- "$line" "$file"; then
    return 0
  fi
  run mkdir -p "$(dirname "$file")"
  if [ "$DRY_RUN" = 1 ]; then
    printf '   [dry-run] append %q to %s\n' "$line" "$file"
  else
    printf '%s\n' "$line" >> "$file"
  fi
  ok "added line to $file"
}

# make_tmp: create a temp dir in $TMP_DIR, removed when the script exits.
make_tmp() {
  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")"
  trap 'rm -rf "$TMP_DIR"' EXIT
}

# download URL DEST: fails with an error message if URL is unreachable.
download() {
  local url="$1" dest="$2" code
  # Probe with a 1-byte GET (some hosts reject HEAD); runs in dry-run too, it changes nothing.
  code="$(curl -sL --retry 3 --connect-timeout 10 -r 0-0 -o /dev/null -w '%{http_code}' "$url" || true)"
  case "$code" in
    2??) ;;
    000|'') err "cannot reach $url (network/DNS error)"; return 1 ;;
    *)      err "cannot reach $url (HTTP $code)"; return 1 ;;
  esac
  if ! run curl -fsSL --retry 3 -o "$dest" "$url"; then
    err "download failed: $url"
    return 1
  fi
}

# Read a package list, dropping comments and blank lines.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}
