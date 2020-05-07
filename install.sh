#!/bin/bash
SHELL=$(cat /proc/version)

echo "$SHELL"
#This file serves the only purpose of choosing the right OS.
case $SHELL in
    *Ubuntu*)
      echo "Ubuntu"
      case $SHELL in
        *18.0*) DIR="./ubuntu/18" ;;
        *19.0*) DIR="./ubuntu/19" ;;
        *20.0*) DIR="./ubuntu/20" ;;
        *)      DIR="nope"        ;;  
      esac ;;
    *Arch\ Linux*)  DIR="arch"    ;;
    *Mac*)          DIR="mac"     ;;
    *)              DIR="nope"    ;;
esac

echo "Installing for $DIR"
cd $DIR

packages=()
for p in "$@"; do
  packages+=($p)
done
bash install.sh "${packages[*]}"

echo "Finished"

exit 0

