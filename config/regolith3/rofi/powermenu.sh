#!/bin/sh
# Win+Shift+P power menu: rofi tiles in the Spotlight style (powermenu.rasi), replacing
# GNOME's power-off dialog (Lock Screen / Cancel / Power Off). Pressing Win+Shift+P or
# Esc again closes it. Also used by the power button on the eww top bar.
dir="$HOME/.config/regolith3/rofi"

tile() {  # label, icon file in icons/
  printf '%s\0icon\037%s\n' "$1" "$dir/icons/$2.svg"
}

choice=$({
  tile "Power off" power
  tile "Restart" restart
  tile "Sleep" sleep
  tile "Lock" lock
  tile "Log out" logout
} | rofi -dmenu -show-icons -format i -no-custom \
    -kb-cancel "Escape,Control+g,Control+bracketleft,Super+P,Super+Shift+P" \
    -theme "$dir/powermenu.rasi")

case $choice in
  0) systemctl poweroff ;;
  1) systemctl reboot ;;
  2) systemctl suspend ;;
  3) dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock ;;
  4) gnome-session-quit --logout --no-prompt ;;
esac
