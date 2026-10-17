#!/usr/bin/env bash
# What is not installed yet on this machine: the base packages from packages/ (what
# ./install.sh installs on this OS), the optional setups in setup/ (./install.sh NAME),
# each judged by its `# check:` line (`# applies:` marks setups irrelevant here, e.g. CUDA
# without an NVIDIA GPU), and the configs linked into $HOME (lib/links.sh).
#   ./check.sh                      # report
#   ./check.sh -q | xargs sudo apt-get install -y   # missing base packages only (macOS: brew install)
# Exit status: 0 if everything that applies is installed, 1 otherwise.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES
. "$DOTFILES/lib/common.sh"
. "$DOTFILES/lib/os.sh"
. "$DOTFILES/lib/links.sh"

# Orange is not one of the basic terminal colors: use the 256-color palette
ORANGE=''; [ -t 1 ] && ORANGE=$'\033[1;38;5;208m'

quiet=0
case ${1:-} in
  -q|--quiet) quiet=1 ;;
  -h|--help)  sed -n '2,8s/^# \{0,1\}//p' "$0"; exit 0 ;;
  "") ;;
  *) die "unknown option $1 (see --help)" ;;
esac

mapfile -t pkgs < <(os_pkg_list)
[ ${#pkgs[@]} -gt 0 ] || die "no package list for $OS_ID $OS_VERSION"

missing=()
for p in "${pkgs[@]}"; do
  pkg_has "$p" || missing+=("$p")
done

if [ "$quiet" = 1 ]; then
  [ ${#missing[@]} -eq 0 ] || printf '%s\n' "${missing[@]}"
  [ ${#missing[@]} -eq 0 ]
  exit
fi

section "Base packages"
if [ ${#missing[@]} -eq 0 ]; then
  ok "all ${#pkgs[@]} base packages are installed ($OS_ID $OS_VERSION)" >&2
else
  warn "${#missing[@]} of ${#pkgs[@]} base packages are not installed ($OS_ID $OS_VERSION):"
  for p in "${missing[@]}"; do
    note=""
    # apt: flag names this release cannot install at all (typo, or needs a repo)
    if is_apt && [ -z "$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" { print $2 }')" ]; then
      note="  (not available from the configured apt sources)"
    fi
    printf '%s%s\n' "$p" "$note"
  done
  if is_apt; then
    log "install them with ./install.sh, or: ./check.sh -q | xargs sudo apt-get install -y" >&2
  else
    log "install them with ./install.sh, or: ./check.sh -q | xargs brew install" >&2
  fi
fi

section "Setups (./install.sh NAME)"
setups_missing=0
for f in "$DOTFILES"/setup/*.sh; do
  name=$(basename "$f" .sh)
  desc=$(sed -n 's/^# desc: //p' "$f")
  applies=$(sed -n 's/^# applies: //p' "$f")
  check=$(sed -n 's/^# check: //p' "$f")
  if [ -n "$applies" ] && ! bash -c "$applies" >/dev/null 2>&1; then
    printf '  %s%-15s n/a here%s\n' "$RED" "$name" "$NC"
  elif [ -z "$check" ]; then
    printf '  %-15s %s\n' "$name" "? (no check)"
  elif bash -c "$check" >/dev/null 2>&1; then
    printf '  %s%-15s%s installed\n' "$GREEN" "$name" "$NC"
  else
    printf '  %s%-15s not installed:%s %s\n' "$ORANGE" "$name" "$NC" "$desc"
    setups_missing=$((setups_missing + 1))
  fi
done

section "Configs (linked from the repo)"
configs_bad=0
# check_link SOURCE TARGET FIX: print one status line; FIX is the command that links it
check_link() {
  local src=$1 dst=$2 fix=$3 shown="${2/#$HOME/\~}" changes
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    # Edits through the link land in the repo: report them as uncommitted changes
    changes=$(git -C "$DOTFILES" status --porcelain --untracked-files=all -- "$src" 2>/dev/null | wc -l)
    if [ "$changes" -eq 0 ]; then
      printf '    %s%-38s%s linked\n' "$GREEN" "$shown" "$NC"
    else
      printf '    %s%-38s linked, %s uncommitted change(s)%s (git status %s)\n' \
        "$ORANGE" "$shown" "$changes" "$NC" "${src#"$DOTFILES"/}"
    fi
  elif [ -L "$dst" ]; then
    printf '    %s%-38s points elsewhere:%s %s\n' "$RED" "$shown" "$NC" "$(readlink "$dst")"
    configs_bad=$((configs_bad + 1))
  elif [ -e "$dst" ]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      printf '    %s%-38s local copy, same as the repo%s (%s turns it into a link)\n' "$ORANGE" "$shown" "$NC" "$fix"
    else
      printf '    %s%-38s local copy, differs from the repo%s (see: diff -r %s %s)\n' \
        "$RED" "$shown" "$NC" "${src/#$HOME/\~}" "$shown"
    fi
    configs_bad=$((configs_bad + 1))
  else
    printf '    %s%-38s not linked%s (%s)\n' "$ORANGE" "$shown" "$NC" "$fix"
    configs_bad=$((configs_bad + 1))
  fi
}
# How to tell whether each program the configs belong to is installed
program_installed() {
  case $1 in
    latex)    have latexmk ;;
    neovim)   have nvim ;;
    vscode)   have code || [ -d "/Applications/Visual Studio Code.app" ] ;;
    ghostty)  have ghostty || [ -d /Applications/Ghostty.app ] ;;
    kitty)    have kitty || [ -d /Applications/kitty.app ] ;;
    regolith) dpkg -s regolith-desktop >/dev/null 2>&1 ;;
    *)        have "$1" ;;
  esac
}
# check_links LIST_FUNCTION FIX: the links grouped by program, one header per program
check_links() {
  local program src dst last=""
  while IFS=$'\t' read -r program src dst; do
    if [ "$program" != "$last" ]; then
      if program_installed "$program"; then
        printf '  %s%s%s\n' "$BOLD" "$program" "$NC"
      else
        printf '  %s%s%s %s(program not installed)%s\n' "$BOLD" "$program" "$NC" "$ORANGE" "$NC"
      fi
      last=$program
    fi
    check_link "$src" "$dst" "$2"
  done < <("$1")
}
check_links base_links ./install.sh
if bash -c "$(sed -n 's/^# applies: //p' "$DOTFILES/setup/regolith.sh")" >/dev/null 2>&1; then
  check_links regolith_links "./install.sh regolith"
fi

[ ${#missing[@]} -eq 0 ] && [ "$setups_missing" -eq 0 ] && [ "$configs_bad" -eq 0 ]
