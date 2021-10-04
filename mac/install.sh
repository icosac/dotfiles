CD=$(pwd)
source "${CD}/../utils.sh"
echo "Moved in $CD"

LIST=(brew neovim vim macvim tmux cron iterm2) #List of all possible packets to install

#If no package was given in input, ask which to install
if [ "$1" == "" ]; then
  echo "Possible packages for Mac are: ${LIST[*]}"
  echo "Note:\n-vim will only set the configuration file, if you want to install from Homebrew add vim_in to the list;\n-cron will only set the crontab rules.\nPlease do not run vim-in."
  read -e -r -p "Insert packages names or \`all\` for to install all packages: " string
  if [ "$string" == "all" ]; then
    packages=("${LIST[*]}")
  else
    packages=("$string")
  fi
else
  for p in "$@"; do
    packages+=("$p")
  done
fi

LIST+=("vim_in")

check_input "${packages[*]}" "${LIST[*]}"
echo "About to install packages: ${packages[*]}"

#Define commands
MK=make
CLONE="git clone"
MOVE=cp
MKDIR="mkdir -p "
IN="brew install --quiet "
echo "Updating system"
#Check if Homebrew installed. If it is, update the system, otherwise update the list if not present
if command -v brew &> /dev/null; then
  brew update
else
  if ! in_list "${packages[*]}" "brew"; then
    packages+=("brew")
  fi
fi

#Install packages
#Homebrew
if ! in_list "${packages[*]}" "brew"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

#Neovim
if in_list "${packages[*]}" "neovim"; then
  echo -e "${BLUE}NEOVIM${NC}"
  echo -e "${GREEN}Intalling neovim from Homebrew$NC"
  $IN neovim
  echo -e "${GREEN}Configuring neovim${NC}"
  echo -e "\tFirst configuring vim"
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  if [ ! -d $HOME/.config/nvim ]; then
    $MKDIR $HOME/.config/nvim
  fi
  #Move first plugins
  echo -e "if filereadable(expand(\"~/.vim/vimrc.plug\"))\nsource ~/.vim/vimrc.plug\nendif" > $HOME/.vim/vimrc
  MV $MOVE "./vim/vimrc.plug" "$HOME/.vim/vimrc.plug"
  MV $MOVE "./nvim/init.vim" "$HOME/.config/nvim/init.vim"
  curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #Install plugin and move the correct Vim configuration file
  nvim +PlugInstall +qa
  MV $MOVE "./vim/vimrc" "$HOME/.vim/vimrc"
fi

#Install VIM from Homebrew
if in_list "${packages[*]}" "vim_in"; then #TODO this has not been tested and I don't really want to
  echo -e "${BLUE}VIM${NC}"
  echo -e "${GREEN}Installing vim${NC} from brew"
  $IN vim
fi

#VIM
if in_list "${packages[*]}" "vim"; then
  echo -e "${BLUE}VIM${NC}"
  echo -e "${GREEN}Configuring vim${NC}"
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #Move first plugins to install
  echo -e "if filereadable(expand(\"~/.vim/vimrc.plug\"))\nsource ~/.vim/vimrc.plug\nendif" > $HOME/.vim/vimrc
  MV $MOVE "./vim/vimrc.plug" "$HOME/.vim/vimrc.plug"
  vim +PlugInstall +qa
  #Then move config file
  MV $MOVE "./vim/vimrc" "$HOME/.vim/vimrc"
fi

#MACVIM
if in_list "${packages[*]}" "macvim"; then
  echo -e "${BLUE}MACVIM${NC}"
  echo -e "${GREEN}Installing macvim from Homebrew${NC}"
  $IN --cask macvim
  if [ ! -d $HOME/.vim ]; then
    $MKDIR $HOME/.vim
  fi
  curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  #Move first plugins to install
  echo -e "if filereadable(expand(\"~/.vim/vimrc.plug\"))\nsource ~/.vim/vimrc.plug\nendif" > $HOME/.vim/vimrc
  MV $MOVE "./vim/vimrc.plug" "$HOME/.vim/vimrc.plug"
  vim +PlugInstall +qa
  #Then move config file
  MV $MOVE "./vim/vimrc" "$HOME/.vim/vimrc"
fi

#TMUX
if in_list "${packages[*]}" "tmux"; then
  echo -e "${BLUE}TMUX${NC}"
  echo -e "${GREEN}Installing tmux from Homebrew.${NC}"
  $IN tmux
  echo -e "${GREEN}Installing tmux-mem-cpu-load from Homebrew.${NC}"
  $IN tmux-mem-cpu-load
  echo -e "${GREEN}Configuring tmux.${NC}"
  MV $MOVE "${PWD}/tmux/tmux.conf" "$HOME/.tmux.conf"
fi

#CRONTAB
if in_list "${pakages[*]}" "cron"; then
  echo -e "${BLUE}CRONTAB${NC}"
  echo -e "${GREEN}Configuring crontab${NC}"
  cat cron/cron | crontab
fi 

#ITERM2
if in_list "${packages[*]}" "iterm2"; then
  echo -e "${BLUE}iTerm2${NC}"
  echo -e "${GREEN}Installing iTerm2${NC}"
  brew install --cask iterm2
fi
  
