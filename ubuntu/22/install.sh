#!/bin/bash
CD=$(pwd)
source "${CD}/../../utils.sh"
echo "Moved in $CD"

# Disable mouse acceleration
output=$(gsettings get org.gnome.desktop.peripherals.mouse accel-profile) 
echo "output ${output}"
if [ "${output}" != "'flat'" ]; then
  gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
fi

#List of all possible packets to install
LIST=(\
  neovim\
  vim\
  tmux\
  zsh\
  git\
  docker\
  latex\
  regolith\
  code
) 

# The script will probably be executed with sudo. 
# This allows for storing the name of the user.
if [ $SUDO_USER ]; then 
  real_user=$SUDO_USER
else
  real_user=$(whoami)
fi
real_home="$(getent passwd ${real_user} 2>/dev/null | cut -d: -f6)"
real_shell="$(getent passwd "${real_user}" | awk -F: '{print $7}')"

echo "Real user: ${real_user} with home ${real_home} using shell ${real_shell}"

# Define commands
MK=make
CLONE="git clone"
MOVE=cp
MKDIR="mkdir -p "
if [ "$( whoami )" == "root" ]; then
  UPDATE="apt-get update"
  IN="apt-get install -y "
else
  UPDATE="sudo apt-get update"
  IN="sudo apt-get install -y "
fi


# If no package was given in input, ask which to install
if [ "$1" == "" ]; then
  INFO $GREEN "Choose packages to install"
  INFO $WHITE "Possible packages for Ubuntu are: ${LIST[*]}"
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

check_input "${packages[*]}" "${LIST[*]}"
INFO $BGREEN "About to install packages: ${packages[*]}"

# Update system before starting
INFO $BBLUE "Updating system"
# $UPDATE &> /dev/null

# Install packages

# CODE
# wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/5437499feb04f7a586f677b155b039bc2b3669eb/code_1.90.2-1718751586_amd64.deb -O code.deb
# sudo dpkg -i code.deb
# rm code.deb

# LATEX
if in_list "${packages[*]}" "latex"; then
  INFO ${BBLUE} "LATEX"
  INFO ${GREEN} "Installing apt dependencies"
  dep "$IN" "apt-req/latex.txt" &> /dev/null
  INFO ${GREEN} "Installing python3 dependencies"
  sudo -u ${real_user} python3 -m pip install -U -r pip-req/latex.txt &> /dev/null
  INFO ${GREEN} "Installing main packages"
  $IN texlive-base texlive-plain-generic texlive-latex-recommended texlive-latex-extra texlive-science texlive-luatex &> /dev/null 
  INFO ${GREEN} "Configuring"
  $MOVE latexmkrc ${real_home}/.latexmkrc

  command -v pygmentize &> /dev/null
  if [ $? -ne 0 ]; then
    if [[ "${real_shell}" == *"zsh" ]]; then 
      echo -e "# Python3 PIP packages\nexport PATH=\"\${PATH}:${real_home}/.local/bin\"" >> "${real_home}/.zshrc"
    elif [[ "${real_shell}" == *"bash" ]]; then 
      echo -e "# Python3 PIP packages\nexport PATH=\"\${PATH}:${real_home}/.local/bin\"" >> "${real_home}/.bashrc"
    fi
  fi
fi

# DOCKER
if in_list "${packages[*]}" "docker"; then
  INFO ${BBLUE} "DOCKER"
  INFO ${GREEN} "Installing dependencies"
  dep "${IN}" "apt-req/docker.txt" &> /dev/null
  INFO ${GREEN} "Adding keys and repos"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  $UPDATE &> /dev/null
  INFO ${GREEN} "Installing docker packages"
  $IN docker-ce docker-ce-cli containerd.io docker-compose-plugin &> /dev/null
  INFO ${GREEN} "Running Docker post-installation steps"
  if [ ! $(getent group docker) ]; then
    echo "docker group does not exist, creating"
    sudo groupadd docker
  fi
  echo "Adding user ${real_user} to docker group"
  sudo usermod -aG docker ${real_user}
  sudo -u ${real_user} newgrp docker
fi

# GIT
if in_list "${packages[*]}" "git"; then  
  $INFO ${BBLUE} "GIT"
  $IN git
  read -t 5 -p "If you want to take control and generate passkeys, write y in 5 seconds [y/N] " choice
  if [ $? -eq 0 ] && { [ "${choice}" = "y" ] || [ "${choice}" = "Y" ]; }; then
    INFO ${GREEN} "ssh dir in ${SSH_DIR}"
    SSH_DIR=${real_home}/.ssh
    if [ ! -d $SSH_DIR ]; then
      mkdir -p $SSH_DIR
      chown ${real_user}:${real_user} $SSH_DIR 
      chmod 700 $SSH_DIR
    fi
    INFO ${GREEN} "Installing additional dependencies"
    # dep "${IN} "apt-req/git.txt"
    INFO ${GREEN} "Asking for passkeys"

    GIT_HOSTS=(github gitlab bitbucket)
    for GIT_HOST in "${GIT_HOSTS[@]}"; do
      choice="no"
      read -p "Do you want to create a passkey for $GIT_HOST? [y/N] " choice
      if [ "${choice}" = "y" ] || [ "${choice}" = "Y" ]; then
	# Create key
        ssh-keygen -t rsa  -f $SSH_DIR/$GIT_HOST
	# Change comment from root@$HOSTNAME
	ssh-keygen -c -C "${real_user}@$HOSTNAME" -f $SSH_DIR/$GIT_HOST
        chown $real_user:$real_user $SSH_DIR/$GIT_HOST*
        chmod 644 $SSH_DIR/$GIT_HOST.pub
        chmod 600 $SSH_DIR/$GIT_HOST
	echo -e "\nHost ${GIT_HOST}_dotfile\n  HostName ${GIT_HOST}.com\n  IdentityFile ${SSH_DIR}/${GIT_HOST}\n  IdentitiesOnly yes\n" >> $SSH_DIR/config
	sed -i "s/ root@/ ${real_user}@/g" $SSH_DIR/config
	if [ "$GIT_HOST" == "bitbucket" ]; then
	  sed -i "s/bitbucket.com/bitbucket.org/g" $SSH_DIR/config
	fi
      fi
    done
    INFO ${GREEN} "The script will now continue without interruptions"
  else
    echo -e "\n"
  fi
  INFO ${BLUE} "Git installed"
fi

# OH MY ZSH
if in_list "${packages[*]}" "zsh"; then
  INFO ${BBLUE} "OH MY ZSH"
  INFO ${GREEN} "Installing dependencies"
  dep "${IN}" "apt-req/zsh.txt" &> /dev/null
  if [ $? -eq 0 ]; then
    INFO ${GREEN} "Installing zsh package"
    $IN zsh &> /dev/null
    INFO ${GREEN} "Installing oh-my-zsh"
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O zsh_install.sh  &> /dev/null
    sudo -u ${real_user} sed -i "s/RUNZSH=no; CHSH=no/RUNZSH=no/g" zsh_install.sh                     1> /dev/null
    sudo -u ${real_user} sh -c "$(cat zsh_install.sh)" "" --unattended                                &> /dev/null
    sudo -u ${real_user} sed -i "s/robbyrussell/bira/g" ${real_home}/.zshrc                           1> /dev/null
    rm zsh_install.sh
  else
    ERROR "Could not install dependencies"
  fi
fi

# REGOLITH
if in_list "${packages[*]}" "zsh"; then
  wget -qO - https://regolith-desktop.org/regolith.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg > /dev/null
  echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] https://regolith-desktop.org/release-3_1-ubuntu-jammy-amd64 jammy main" | \
  sudo tee /etc/apt/sources.list.d/regolith.list
  $UPDATE &> /dev/null
  $IN regolith-desktop regolith-session-flashback regolith-look-lascaille &> /dev/null
fi
  
# NEOVIM
if in_list "${packages[*]}" "neovim"; then
  INFO ${BBLUE} "NEOVIM"
  INFO ${GREEN} "Cleaning previous installations from /opt/nvim"
  if [ -d /opt/nvim ]; then
    sudo rm -rf /opt/nvim
  fi
  INFO ${GREEN} "Intalling neovim from Github repository"
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz &> /dev/null
  sudo tar -C /opt -xzf nvim-linux64.tar.gz &> /dev/null
  rm nvim-linux64.tar.gz
  if [[ "${real_shell}" == *"zsh" ]]; then 
    echo "export PATH=\"$PATH:/opt/nvim-linux64/bin\"" >> "${real_home}/.zshrc"
  elif [[ "${real_shell}" == *"bash" ]]; then 
    echo "export PATH=\"$PATH:/opt/nvim-linux64/bin\"" >> "${real_home}/.bashrc"
  fi
  INFO ${BGREEN} "neovim installed, resource your shell"

  INFO ${GREEN} "Installing Astronvim"
  rm -rf ${real_home}/.config/nvim
  rm -rf ${real_home}/.local/share/nvim
  rm -rf ${real_home}/.local/state/nvim
  rm -rf ${real_home}/.cache/nvim
  sudo -u ${real_user} mkdir -p ${real_home}/.config/nvim-profiles/
  sudo -u ${real_user} git clone --depth 1 https://github.com/AstroNvim/template ${real_home}/.config/nvim-profiles/astronvim &> /dev/null
  sudo -u ${real_user} rm -rf ${real_home}/.config/nvim-profiles/astronvim/.git
  sudo chown -R ${real_user}:${real_user} ${real_home}/.config/nvim-profiles
  sudo -u "${real_user}" bash -c 'NVIM_APPNAME=nvim-profiles/astronvim /opt/nvim-linux64/bin/nvim +qall'
fi

# VIM
if in_list "${packages[*]}" "vim"; then
  echo -e "${BRED}VIM (DEPRECATED)${NC}"
  echo -e "${GREEN}Installing vim${NC}"
  $IN vim-gtk python3-pip #silversearcher-ag
  python3 -m pip install --user pynvim
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

#TMUX
if in_list "${packages[*]}" "tmux"; then
  echo -e "${BLUE}TMUX${NC}"
  $IN tmux
  echo -e "\tInstalling tmux-mem-cpu-load."
  $CLONE https://github.com/thewtex/tmux-mem-cpu-load
  cd tmux-mem-cpu-load
  $MKDIR build && cd build
  cmake .. && make && sudo make install && echo -e "\tFinished tmux-mem-cpu-load installation, you should probably log out and log back in."
  cd $CD
  rm -rf tmux-mem-cpu-load
  echo -e "${GREEN}Configuring tmux.${NC}"
  MV $MOVE "${PWD}/tmux/tmux.conf" "$HOME/.tmux.conf"
fi
