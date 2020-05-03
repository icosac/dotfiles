#!/bin/bash
SHELL=$(cat /proc/version)
VIM=$1

#Install packages
if [[ $SHELL = *"Ubuntu"* ]]; then
  sudo apt-get update
  sudo apt-get install -y vim neovim silversearcher-ag
#elif [[ $SHELL= *"Arch Linux"* ]]; then
#  pacman -Sy
#  pacman -S neovim --noconfirm the_silver_searcher
else #Mac
  brew install the_silver_searcher
fi

#Move things 
if [ ! -d ~/.vim ]; then 
  mkdir ~/.vim
fi
if [ ! -d ~/.config/nvim ]; then
  mkdir -p ~/.config/nvim
fi
cp vimrc* ~/.vim/
echo "set runtimepath^=~/.vim runtimepath+=~/.vim/after" > ~/.config/nvim/init.vim
echo "let &packpath=&runtimepath" >> ~/.config/nvim/init.vim
echo "source ~/.vim/vimrc" >> ~/.config/nvim/init.vim

python3 -m pip install --user pynvim

#Intall vim-plug and plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
$VIM +PlugInstall +qall

if [[ $VIM = "nvim" ]]; then
  #Create alias for vim
  echo "alias vim=nvim" >> ~/.bashrc
fi
