#!/bin/sh
# Regolith's launcher shortcuts, all in rofi with the Spotlight-like theme next to this
# script (wired in ../Xresources):
#   apps    Win+Space        calculator row (patched rofi-calc, setup/rofi-calc.sh; Enter
#                            copies the result), then apps, then files in $HOME (files.py)
#   run     Win+Shift+Space  run a command
#   window  Win+Ctrl+Space   switch to a window by name
#   files   Win+Shift+F      files and folders in $HOME only (i3/config.d/25_file_search)
#   keys    Win+Shift+?      searchable list of Regolith's keybindings (keybindings.py)
# Regolith's bindings append ilia's arguments (`-t <stylesheet>`): anything that is not a
# mode name is ignored, so with no mode this is the app launcher.
# While rofi is open it grabs the keyboard, so i3 never sees the shortcut again: each
# mode treats its own shortcut as "cancel", which makes the shortcuts toggle.
dir="$HOME/.config/regolith3/rofi"
export ROFI_PLUGIN_PATH="$HOME/.local/lib/rofi"
cancel="Escape,Control+g,Control+bracketleft"

placeholder() { printf 'entry { placeholder: "%s"; }' "$1"; }

case ${1:-} in
  run)
    exec rofi -show run -modi run \
      -kb-cancel "$cancel,Super+space,Super+Shift+space" \
      -theme "$dir/spotlight.rasi" -theme-str "$(placeholder "Run a command")" ;;
  window)
    exec rofi -show window -modi window -show-icons -window-format "{t}" \
      -kb-cancel "$cancel,Super+Control+space" \
      -theme "$dir/spotlight.rasi" -theme-str "$(placeholder "Switch to window")" ;;
  files)
    exec rofi -show files -modi "files:$dir/files.py" -show-icons \
      -kb-cancel "$cancel,Super+Alt+space,Super+F,Super+Shift+F" \
      -theme "$dir/spotlight.rasi" -theme-str "$(placeholder "Search files")" ;;
  keys)
    "$dir/keybindings.py" |
      rofi -dmenu -i -no-custom -p "" \
        -kb-cancel "$cancel,Super+question,Super+Shift+question" \
        -theme "$dir/spotlight.rasi" \
        -theme-str "$(placeholder "Search keybindings") listview { lines: 12; } element-icon { enabled: false; }" \
        >/dev/null
    exit 0 ;;
esac

exec rofi -show combi -modi combi \
  -combi-modi "qcalc,drun,files:$dir/files.py" -combi-hide-mode-prefix \
  -no-history -no-persist-history \
  -calc-command "printf %s '{result}' | xclip -selection clipboard" \
  -show-icons -drun-display-format "{name}" \
  -kb-cancel "$cancel,Super+space" \
  -theme "$dir/spotlight.rasi"
