#!/usr/bin/env bash
# Entry point. Links configs into $HOME, installs base packages, then runs any
# opt-in setup/<name>.sh given on the command line. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES
# shellcheck source=lib/common.sh
. "$DOTFILES/lib/common.sh"
# shellcheck source=lib/os.sh
. "$DOTFILES/lib/os.sh"

usage() {
  cat <<EOF
Usage: ./install.sh [options] [setup...]

Links every config in config/ into \$HOME (backing up what was there), installs
base packages, then runs the named opt-in setups from setup/.

Options:
  -n, --dry-run      print what would happen, change nothing
  -l, --link-only    only link configs (no packages, no sudo)
      --no-packages  skip base package install
      --list         list available setups
  -h, --help         show this help

Examples:
  ./install.sh                       # link + base packages
  ./install.sh ohmyzsh neovim fonts  # ...plus those setups
  ./install.sh --link-only
EOF
}

list_setups() {
  local f
  for f in "$DOTFILES"/setup/*.sh; do
    printf '  %-14s %s\n' "$(basename "$f" .sh)" "$(sed -n 's/^# desc: //p' "$f")"
  done
}

ARGS="$*" LINK_ONLY=0 PACKAGES=1 SETUPS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run)   DRY_RUN=1 ;;
    -l|--link-only) LINK_ONLY=1; PACKAGES=0 ;;
    --no-packages)  PACKAGES=0 ;;
    --list)         list_setups; exit 0 ;;
    -h|--help)      usage; exit 0 ;;
    -*)             usage; die "unknown option $1" ;;
    *)              [ -f "$DOTFILES/setup/$1.sh" ] || die "no such setup '$1' (see --list)"
                    SETUPS+=("$1") ;;
  esac
  shift
done
export DRY_RUN BACKUP_DIR

refuse_root
if [ "$LINK_ONLY" = 1 ] && [ ${#SETUPS[@]} -gt 0 ]; then
  die "--link-only cannot be combined with setups"
fi

LOG_DIR="$HOME/.cache/dotfiles"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/install.log"
exec > >(tee -a "$LOG") 2>&1
printf '\n===== %s  %s %s (%s)  %s\n' "$(date)" "$OS_ID" "$OS_VERSION" "$ARCH" "$ARGS"
[ "$DRY_RUN" = 1 ] && log "dry run: nothing will be changed"

# ---------------------------------------------------------------------------
section "Linking configs"

# Keep an existing git identity: move [user] from a real ~/.gitconfig into ~/.gitconfig.local
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ] && [ ! -f "$HOME/.gitconfig.local" ]; then
  for key in user.name user.email user.signingkey; do
    if val="$(git config -f "$HOME/.gitconfig" "$key")"; then
      run git config -f "$HOME/.gitconfig.local" "$key" "$val"
    fi
  done
  [ -f "$HOME/.gitconfig.local" ] && ok "kept git identity in ~/.gitconfig.local"
fi

if is_macos; then
  VSCODE_USER="$HOME/Library/Application Support/Code/User"
else
  VSCODE_USER="$HOME/.config/Code/User"
fi

C="$DOTFILES/config"
link "$C/zsh/.zshrc"                "$HOME/.zshrc"
link "$C/git/.gitconfig"            "$HOME/.gitconfig"
link "$C/tmux/.tmux.conf"           "$HOME/.tmux.conf"
link "$C/latex/.latexmkrc"          "$HOME/.latexmkrc"
link "$C/kitty/.config/kitty"       "$HOME/.config/kitty"
link "$C/nvim/.config/nvim"         "$HOME/.config/nvim"
link "$C/vscode/settings.json"      "$VSCODE_USER/settings.json"
link "$C/vscode/keybindings.json"   "$VSCODE_USER/keybindings.json"

# Repo-local privacy guard (blocks committing emails / home paths)
if [ "$(git -C "$DOTFILES" config core.hooksPath || true)" != .githooks ]; then
  run git -C "$DOTFILES" config core.hooksPath .githooks
  ok "enabled pre-commit privacy check"
fi

# ---------------------------------------------------------------------------
if [ "$PACKAGES" = 1 ]; then
  section "Base packages ($OS_ID $OS_VERSION)"
  if is_apt; then
    pkg_install_list "$DOTFILES/packages/apt.txt" "$DOTFILES/packages/apt-$OS_VERSION.txt"
  elif is_macos; then
    if ! have brew; then
      log "installing Homebrew"
      run env NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$b" ] && eval "$("$b" shellenv)" && break
      done
    fi
    pkg_install_list "$DOTFILES/packages/brew.txt"
  else
    warn "no package list for '$OS_ID', skipping"
  fi
fi

# ---------------------------------------------------------------------------
FAILED=()
for s in ${SETUPS[@]+"${SETUPS[@]}"}; do
  section "Setup: $s"
  if [ "$DRY_RUN" = 1 ]; then
    log "[dry-run] would run setup/$s.sh"
    continue
  fi
  if bash "$DOTFILES/setup/$s.sh"; then
    ok "$s done"
  else
    warn "$s FAILED (continuing)"
    FAILED+=("$s")
  fi
done

section "Summary"
[ -d "$BACKUP_DIR" ] && log "replaced files were backed up to $BACKUP_DIR"
log "log: $LOG"
if [ ${#FAILED[@]} -gt 0 ]; then
  warn "failed setups: ${FAILED[*]}"
  exit 1
fi
ok "all done"
