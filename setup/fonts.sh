#!/usr/bin/env bash
# desc: JetBrainsMono + VictorMono + Iosevka Nerd Fonts (FORCE=1 to reinstall)
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
. "$DOTFILES/lib/os.sh"

refuse_root

FONTS=(JetBrainsMono VictorMono Iosevka)

if is_macos; then
  log "installing Nerd Fonts"
  run brew install --cask font-jetbrains-mono-nerd-font font-victor-mono-nerd-font font-iosevka-nerd-font
  exit 0
fi

have unzip   || pkg_install unzip
have fc-cache || pkg_install fontconfig
dir="$HOME/.local/share/fonts"
make_tmp; tmp="$TMP_DIR"
changed=0
for font in "${FONTS[@]}"; do
  dest="$dir/$font"
  if [ "${FORCE:-0}" != 1 ] && compgen -G "$dest/*.ttf" >/dev/null; then
    ok "$font already installed"
    continue
  fi
  log "downloading $font Nerd Font"
  download "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip" "$tmp/$font.zip"
  run mkdir -p "$dest"
  run unzip -oq "$tmp/$font.zip" -d "$dest"
  changed=1
done
[ "$changed" = 1 ] && log "refreshing font cache" && run fc-cache -f "$dir"
ok "fonts ready"
