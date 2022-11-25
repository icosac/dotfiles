#!/bin/bash
#This file serves the only purpose of choosing the right OS and in case pass the list of app to install to the right installer.

if [[ "$OSTYPE" == "darwin"* ]]; then

  DIR="./mac"

else

  OS=$(cat /proc/version)
  case $OS in
    *Ubuntu*)
      echo "Ubuntu"
      OS=$(lsb_release -r)
      case $OS in
        *18.*) DIR="./ubuntu/18" ;;
        *19.*) DIR="./ubuntu/19" ;;
        *20.*) DIR="./ubuntu/20" ;;
        *22.*) DIR="./ubuntu/22" ;;
        *)      DIR="nope"        ;;  
      esac ;;
    *Debian*)
	    echo "Debian"
      case $OS in 
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

