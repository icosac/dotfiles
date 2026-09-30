#!/usr/bin/env bash
# Entry point. Links configs into $HOME, installs base packages, then runs any
# opt-in setup/<name>.sh given on the command line. Safe to re-run.
set -euo pipefail

# ---------------------------------------------------------------------------
# Bootstrap: when this script is not inside a clone (e.g. downloaded alone or
# run as `curl -fsSL .../install.sh | bash`), install git, clone the repo and
# re-run the install.sh from the clone. Self-contained: lib/ may not exist yet.
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/icosac/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-dev}"

self_dir=""
[ -f "${BASH_SOURCE[0]:-}" ] && self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$self_dir" ] || [ ! -e "$self_dir/.git" ] || [ ! -f "$self_dir/lib/common.sh" ]; then
  bs_die() { printf 'error %s\n' "$*" >&2; exit 1; }
  dest="$HOME/dotfiles" prev=""
  for a in "$@"; do
    [ "$prev" = --dir ] && dest="$a"
    case "$a" in --dir=*) dest="${a#--dir=}" ;; esac
    prev="$a"
  done
  [ "$prev" = --dir ] && bs_die "--dir needs a directory"
  [ "$(id -u)" -ne 0 ] || bs_die "Run as your normal user, not root/sudo. sudo is used only where needed."

  if ! command -v git >/dev/null 2>&1; then
    printf '==> installing git\n'
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -qq && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git ca-certificates >/dev/null \
        || bs_die "could not install git"
    elif [ "$(uname -s)" = Darwin ]; then
      xcode-select --install 2>/dev/null || true
      bs_die "git comes with the Xcode Command Line Tools: finish their install, then run this again"
    else
      bs_die "install git, then run this again"
    fi
  fi

  if [ -e "$dest/.git" ]; then
    printf '==> using the existing clone in %s\n' "$dest"
  elif [ -e "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
    bs_die "$dest exists and is not a git clone: pick another place with --dir DIR"
  else
    printf '==> cloning %s (branch %s) into %s\n' "$DOTFILES_REPO" "$DOTFILES_BRANCH" "$dest"
    git clone -q --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$dest" || bs_die "git clone failed"
  fi
  cd "$dest"
  # When piped into bash, stdin is the script itself: give prompts the terminal back
  if [ ! -t 0 ] && { : </dev/tty; } 2>/dev/null; then
    exec bash ./install.sh "$@" </dev/tty
  fi
  exec bash ./install.sh "$@"
fi

DOTFILES="$self_dir"
export DOTFILES

. "$DOTFILES/lib/common.sh"
. "$DOTFILES/lib/os.sh"

usage() {
  cat <<EOF
Usage: ./install.sh [options] [setup...]

Links every config in config/ into \$HOME (backing up what was there), installs
base packages, then runs the named opt-in setups from setup/.

Options:
  -n, --dry-run      print what would happen, change nothing
      --dir DIR      where to clone the repo when run outside a clone (default ~/dotfiles)
  -v, --verbose      show every command's output (default: only on failure)
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
    -v|--verbose)   VERBOSE=1 ;;
    --dir)          shift; [ $# -gt 0 ] || die "--dir needs a directory" ;;  # only used by the bootstrap
    --dir=*)        ;;
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
export DRY_RUN VERBOSE BACKUP_DIR

refuse_root
if [ "$LINK_ONLY" = 1 ] && [ ${#SETUPS[@]} -gt 0 ]; then
  die "--link-only cannot be combined with setups"
fi

LOG_DIR="$HOME/.cache/dotfiles"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/install.log"
export LOG
exec > >(tee -a "$LOG") 2>&1
printf '\n===== %s  %s %s (%s)  %s\n' "$(date)" "$OS_ID" "$OS_VERSION" "$ARCH" "$ARGS"
[ "$DRY_RUN" = 1 ] && log "dry run: nothing will be changed"

# Ask for sudo once now (command output is hidden later, so a prompt could go
# unnoticed) and keep it fresh until we exit.
if [ "$DRY_RUN" != 1 ] && [ ${#SUDO[@]} -gt 0 ] && { [ "$PACKAGES" = 1 ] || [ ${#SETUPS[@]} -gt 0 ]; }; then
  log "sudo is needed for packages and setups"
  sudo -v || die "could not get sudo"
  while kill -0 $$ 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 60; done &
  SUDO_KEEPALIVE=$!
  trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
fi

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
