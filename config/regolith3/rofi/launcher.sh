#!/bin/sh
# Win+Space launcher: rofi with the Spotlight-like theme next to this script.
# One list: a calculator row when the input is math (rofi-calc, patched by
# setup/rofi-calc.sh into ~/.local/lib/rofi; Enter copies the result), then apps,
# then files and folders in $HOME (files.py).
# Regolith's binding appends ilia's `-t <stylesheet>` arguments: they are ignored.
# While rofi is open it grabs the keyboard, so i3 never sees Win+Space: rofi itself
# treats it as "cancel", which makes the shortcut toggle the launcher.
dir="$HOME/.config/regolith3/rofi"
export ROFI_PLUGIN_PATH="$HOME/.local/lib/rofi"
exec rofi -show combi -modi combi \
  -combi-modi "qcalc,drun,files:$dir/files.py" -combi-hide-mode-prefix \
  -no-history -no-persist-history \
  -calc-command "printf %s '{result}' | xclip -selection clipboard" \
  -show-icons -drun-display-format "{name}" \
  -kb-cancel "Escape,Control+g,Control+bracketleft,Super+space" \
  -theme "$dir/spotlight.rasi"
