#!/bin/bash
CD=$(pwd)
source "${CD}/../../utils.sh"

LIST=(neovim vim tmux) #List of all possible packets to install

#If no package was given in input, ask which to install
if [ -z $1 ]; then
  echo "Possible packages for Ubuntu are: ${LIST[*]}"
  read -e -r -p "Insert packages names or \`all\` for to install all packages: " string
  if [ "$string" == "all" ]; then
    packages=("${LIST[*]}")
  else
    packages=("$string")
  fi
fi

check_input "${packages[*]}" "${LIST[*]}"
echo "About to install packages: ${packages[*]}"

#Define commands
MK=make
CLONE=git clone
MOVE=cp
MKDIR="mkdir -p "
echo "Updating system"
if [ "$( whoami )" == "root" ]; then
  apt-get update
  IN="apt-get install -y "
else
  sudo apt-get update
  IN="sudo apt-get install -y "
fi

#Install packages
echo -e "${BLUE}Installing packages"
if in_list "${packages[@]}" "neovim"; then
  echo -e "${GREEN}Intalling neovim from source$NC"
  $IN build-essential make automake cmake pkg-config libtool libtool-bin gettext
  if [ -d neovim ]; then rm -rf neovim; fi
  $CLONE -b stable https://github.com/neovim/neovim
  cd neovim 
  make CMAKE_BUILD_TYPE=Release -j
  if [ $(whoami) == "root" ]; then make install; else sudo make install; fi
  #NEOVIM
  echo -e "${GREEN}Configuring neovim${NC}"
  if [ ! -d $HOME/.config/nvim ]; then
    $MKDIR $HOME/.config/nvim
  fi
  MV $MOVE "./neovim/init.vim" "$HOME/.config/nvim/init.vim"
  curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  nvim +PlugInstall +qa
fi

packages=( $( remove "${packages[*]}" "neovim" ) )

echo -e "${GREEN}Installing remaining packages: ${packages[*]} ${NC}"
$IN ${packages[*]}

#Move configuration files
echo -e "${BLUE}Moving configuration files${NC}"

#VIM
if in_list "${packages[@]}" "vim"; then
  echo -e "${GREEN}Configuring vim${NC}"
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  MV $MOVE "./vim/vimrc*" "$HOME/.vim"
  python3 -m pip install --user pynvim
  curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qa
fi

#TMUX
if in_list "${packages[@]}" "tmux"; then
  echo -e "\tInstalling tmux-mem-cpu-load."
  $CLONE https://github.com/thewtex/tmux-mem-cpu-load
  cd tmux-mem-cpu-load
  $MKDIR build && cd build
  cmake .. && make && sudo make install && echo -e "\tFinished tmux-mem-cpu-load installation, you should probably log out and log back in."
  echo -e "${GREEN}Configuring tmux.${NC}"
  MV $MOVE "${PWD}/tmux/tmux.conf" "$HOME/.tmux.conf"
fi
