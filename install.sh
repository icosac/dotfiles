#!/bin/bash
#This file serves the only purpose of choosing the right OS and in case pass the list of app to install to the right installer.

if [[ "$OSTYPE" == "darwin"* ]]; then

  DIR="./mac"

else

  SHELL=$(cat /proc/version)
  case $SHELL in
      *Ubuntu*)
        echo "Ubuntu"
        case $SHELL in
          *18.0*) DIR="./ubuntu/18" ;;
          *19.0*) DIR="./ubuntu/19" ;;
          *20.0*) DIR="./ubuntu/20" ;;
          *)      DIR="nope"        ;;  
        esac ;;
      *Debian*)
	echo "Debian"
	case $SHELL in 
	  *10.0*) DIR="./debian/10" ;; 
	  *)      DIR="nope"        ;;
        esac ;;
      *Arch\ Linux*)  DIR="./arch"  ;;
      *)              DIR="nope"    ;;
  esac
fi

echo "Installing for $DIR"
cd $DIR

packages=()
for p in "$@"; do
  packages+=($p)
done
bash install.sh "${packages[*]}"

echo "Finished"

exit 0

