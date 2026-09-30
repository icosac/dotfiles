#!/usr/bin/env bash
# OS detection + package manager helpers. Source after lib/common.sh.
# Sets: OS_ID (ubuntu|debian|macos|unknown), OS_VERSION (22.04, 10, 14.5...),
#       OS_CODENAME (jammy, buster...), ARCH (x86_64|arm64), DEB_ARCH (amd64|arm64)
# shellcheck disable=SC2034

case "$(uname -s)" in
  Darwin)
    OS_ID=macos
    OS_VERSION="$(sw_vers -productVersion)"
    OS_CODENAME=""
    ;;
  Linux)
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      OS_ID="${ID:-unknown}"
      OS_VERSION="${VERSION_ID:-}"
      OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
    else
      OS_ID=unknown OS_VERSION="" OS_CODENAME=""
    fi
    ;;
  *) OS_ID=unknown OS_VERSION="" OS_CODENAME="" ;;
esac

case "$(uname -m)" in
  x86_64|amd64)  ARCH=x86_64 DEB_ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64  DEB_ARCH=arm64 ;;
  *)             ARCH="$(uname -m)" DEB_ARCH="$ARCH" ;;
esac

is_macos() { [ "$OS_ID" = macos ]; }
is_apt()   { [ "$OS_ID" = ubuntu ] || [ "$OS_ID" = debian ]; }
is_ubuntu() { [ "$OS_ID" = ubuntu ] && { [ $# -eq 0 ] || [[ " $* " == *" $OS_VERSION "* ]]; }; }

# Major version as integer (22.04 -> 22, 10 -> 10) for comparisons.
os_major() { printf '%s\n' "${OS_VERSION%%.*}"; }

_PKG_UPDATED=0
pkg_update() {
  [ "$_PKG_UPDATED" = 1 ] && return 0
  if is_apt; then
    log "updating package lists"
    as_root apt-get update
  elif is_macos && have brew; then
    run brew update
  fi
  _PKG_UPDATED=1
}

# pkg_install PKG... : install with the native package manager.
pkg_install() {
  [ $# -gt 0 ] || return 0
  if is_apt; then
    pkg_update
    log "installing packages: $*"
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
  elif is_macos; then
    have brew || die "Homebrew is missing: run ./install.sh first"
    log "installing packages: $*"
    run brew install "$@"
  else
    die "unsupported OS '$OS_ID' for package install"
  fi
}

# pkg_install_list FILE [OVERRIDE_FILE] : install every package listed in FILE.
# OVERRIDE_FILE (optional, may not exist) adds names, or removes them with `!name`.
pkg_install_list() {
  [ -f "$1" ] || return 0
  local pkgs=() p q drop=()
  if [ -n "${2:-}" ] && [ -f "$2" ]; then
    while IFS= read -r p; do
      case "$p" in '!'*) drop+=("${p#!}") ;; *) pkgs+=("$p") ;; esac
    done < <(read_list "$2")
  fi
  while IFS= read -r p; do
    for q in ${drop[@]+"${drop[@]}"}; do [ "$p" = "$q" ] && continue 2; done
    pkgs+=("$p")
  done < <(read_list "$1")
  pkg_install ${pkgs[@]+"${pkgs[@]}"}
}

# Is an apt package already installed?
apt_has() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

# apt_repo NAME KEY_URL "DEB_LINE" : add a signed apt repo idempotently.
# DEB_LINE may use @KEYRING@, which is replaced with the keyring path.
apt_repo() {
  local name="$1" key_url="$2" line="$3"
  local keyring="/etc/apt/keyrings/$name.gpg" list="/etc/apt/sources.list.d/$name.list"
  line="${line//@KEYRING@/$keyring}"
  if [ ! -s "$keyring" ] || [ ! -f "$list" ] || [ "$(cat "$list")" != "$line" ]; then
    log "adding apt repository $name"
  fi
  as_root install -d -m 0755 /etc/apt/keyrings
  if [ ! -s "$keyring" ]; then
    if [ "$DRY_RUN" = 1 ]; then
      printf '   [dry-run] fetch key %s -> %s\n' "$key_url" "$keyring"
    else
      curl -fsSL "$key_url" | ${SUDO[@]+"${SUDO[@]}"} gpg --dearmor --yes -o "$keyring"
      ${SUDO[@]+"${SUDO[@]}"} chmod a+r "$keyring"
    fi
  fi
  if [ ! -f "$list" ] || [ "$(cat "$list")" != "$line" ]; then
    if [ "$DRY_RUN" = 1 ]; then
      printf '   [dry-run] write %s: %s\n' "$list" "$line"
    else
      printf '%s\n' "$line" | ${SUDO[@]+"${SUDO[@]}"} tee "$list" >/dev/null
    fi
    _PKG_UPDATED=0
  fi
}
