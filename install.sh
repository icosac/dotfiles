#!/bin/bash
SHELL=$(cat /proc/version)
VIM=$1

MV=cp

#Check input parameter
if [ "$1" != "vim" -a "$1" != "nvim" ]; then
  echo "Need to specify vim or nvim"
  exit -1
fi

#Install packages
if [[ $SHELL == *"Ubuntu"* ]]; then
  sudo apt-get update
  sudo apt-get install -y vim-gtk neovim silversearcher-ag tmux
#elif [[ $SHELL= *"Arch Linux"* ]]; then
#  pacman -Sy
#  pacman -S --noconfirm vim neovim the_silver_searcher tmux
else #Mac eh... 
  brew install the_silver_searcher
fi

#MOVE THINGS
#Vim - Neovim
if [ ! -d ~/.vim ]; then 
  mkdir ~/.vim
fi
if [ ! -d ~/.config/nvim ]; then
  mkdir -p ~/.config/nvim
fi
$MV vimrc* ~/.vim/
echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after" > ~/.config/nvim/init.vim
echo "let &packpath=&runtimepath" >> ~/.config/nvim/init.vim
echo "source ~/.vim/vimrc" >> ~/.config/nvim/init.vim

python3 -m pip install --user pynvim

#Intall vim-plug and plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
$VIM +PlugInstall +qall

if [ $VIM == "nvim" ]; then
  #Create alias for vim
  echo "alias vim=nvim" >> ~/.bashrc
fi

#Tmux
$MV tmux.conf ~/.tmux.conf
