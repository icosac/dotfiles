#!/bin/sh
# Power menu: rofi tiles in the Spotlight style (powermenu.rasi), replacing GNOME's
# dialogs. The argument pre-selects a tile (wired in ../Xresources):
#   powermenu.sh [poweroff]   Win+Shift+P, and the power button on the eww top bar
#   powermenu.sh reboot       Win+Shift+B
#   powermenu.sh logout       Win+Shift+E
# Any of the three shortcuts, or Esc, closes it again.
dir="$HOME/.config/regolith3/rofi"
case ${1:-} in
  reboot) selected=1 ;;
  logout) selected=4 ;;
  *)      selected=0 ;;
esac

tile() {  # label, icon file in icons/
  printf '%s\0icon\037%s\n' "$1" "$dir/icons/$2.svg"
}

choice=$({
  tile "Power off" power
  tile "Restart" restart
  tile "Sleep" sleep
  tile "Lock" lock
  tile "Log out" logout
} | rofi -dmenu -show-icons -format i -no-custom -selected-row "$selected" \
    -kb-cancel "Escape,Control+g,Control+bracketleft,Super+P,Super+Shift+P,Super+B,Super+Shift+B,Super+E,Super+Shift+E" \
    -theme "$dir/powermenu.rasi")

case $choice in
  0) systemctl poweroff ;;
  1) systemctl reboot ;;
  2) systemctl suspend ;;
  3) dbus-send --type=method_call --dest=org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock ;;
  4) gnome-session-quit --logout --no-prompt ;;
esac
