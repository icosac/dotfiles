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
  cuda\
  neovim\
  vim\
  tmux\
  zsh\
  git\
  docker\
  latex\
  regolith\
  code\
  kitty
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
$UPDATE &> /dev/null

# Install packages

# KITTY
if in_list "${packages[*]}" "kitty"; then
  INFO ${BBLUE} "KITTY"
  INFO ${GREEN} "Installing Kitty"
  $IN kitty &> /dev/null
  INFO ${GREEN} "Installing JetBrains fonts"
  wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip -O font.zip &> /dev/null
  unzip -f font.zip -d ${real_home}/.local/share/fonts &> /dev/null
  rm font.zip
  sudo -u ${real_user} fc-cache -f -v &> /dev/null
  INFO ${GREEN} "Configuring" 
  mkdir -p ${real_home}/.config/kitty
  cp -r ./kitty/* ${real_home}/.config/kitty/
  sudo chown -R ${real_user}:${real_user} ${real_home}/.config/kitty
fi

# OH MY ZSH
if in_list "${packages[*]}" "zsh"; then
  INFO ${BBLUE} "OH MY ZSH"
  INFO ${GREEN} "Installing dependencies"
  dep "${IN}" "apt-req/zsh.txt"                                                                       &> /dev/null
  if [ $? -eq 0 ]; then
    INFO ${GREEN} "Installing zsh package"
    $IN zsh &> /dev/null                                                                                         &> /dev/null
    INFO ${GREEN} "Installing oh-my-zsh"
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O zsh_install.sh  &> /dev/null
    sudo -u ${real_user} sed -i "s/RUNZSH=no; CHSH=no/RUNZSH=no/g" zsh_install.sh                     1> /dev/null
    sudo -u ${real_user} yes | sudo -u ${real_user} sh -c "$(cat zsh_install.sh)" "" --unattended     &> /dev/null
    sudo -u ${real_user} sed -i "s/robbyrussell/bira/g" ${real_home}/.zshrc                           1> /dev/null
    sudo -u ${real_user} chsh -s /usr/bin/zsh
    rm zsh_install.sh
  else
    ERROR "Could not install dependencies"
  fi
fi


# CODE
if in_list "${packages[*]}" "code"; then
  wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/5437499feb04f7a586f677b155b039bc2b3669eb/code_1.90.2-1718751586_amd64.deb -O code.deb &> /dev/null
  sudo dpkg -i code.deb &> /dev/null
  rm code.deb
fi


# CUDA
if in_list "${packages[*]}" "cuda"; then
	INFO ${BBLUE} "Installing CUDA"
	INFO ${GREEN} "Checking GPU support"
	if [[ $(lshw -C display | grep vendor) =~ NVIDIA ]]; then
		INFO ${GREEN} "Installing dependencies"
		dep ${IN} "apt-req/cuda.txt"                                                                        &> /dev/null
		wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin &> /dev/null
		sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
		INFO ${GREEN} "Downloading CUDA from Nvidia"
		wget https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda-repo-ubuntu2204-12-5-local_12.5.0-555.42.02-1_amd64.deb -O cuda.deb &> /dev/null
		sudo dpkg -i cuda.deb                                                                               &> /dev/null
		sudo apt -f install                                                                                 &> /dev/null
		sudo cp /var/cuda-repo-ubuntu2204-12-5-local/cuda-*-keyring.gpg /usr/share/keyrings/
		$UPDATE                                                                                             &> /dev/null
		INFO ${GREEN} "Installing CUDA and nvcc"
		${IN} cuda-toolkit-12-5 cuda-nvcc-12-5                                                              &> /dev/null
		sudo rm cuda.deb 
		if [[ "${real_shell}" == *"zsh" ]]; then 
			echo -e "PATH=$PATH:/usr/local/cuda-12.5/bin/" >> "${real_home}/.zshrc"
    elif [[ "${real_shell}" == *"bash" ]]; then 
			echo -e "PATH=$PATH:/usr/local/cuda-12.5/bin/" >> "${real_home}/.bashrc"
    fi
	else
		ERROR "No Nvidia GPU available"
	fi
fi


# LATEX
if in_list "${packages[*]}" "latex"; then
  INFO ${BBLUE} "LATEX"
  INFO ${GREEN} "Installing apt dependencies"
  dep "$IN" "apt-req/latex.txt"                                                                                       &> /dev/null
  INFO ${GREEN} "Installing python3 dependencies"
  sudo -u ${real_user} python3 -m pip install -U -r pip-req/latex.txt                                                 &> /dev/null
  INFO ${GREEN} "Installing main packages"
  $IN texlive-base texlive-plain-generic texlive-latex-recommended texlive-latex-extra texlive-science texlive-luatex &> /dev/null 
  INFO ${GREEN} "Configuring"
  $MOVE latexmkrc ${real_home}/.latexmkrc

  command -v pygmentize                                                                                               &> /dev/null
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
  dep "${IN}" "apt-req/docker.txt"                                &> /dev/null
  INFO ${GREEN} "Adding keys and repos"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  $UPDATE                                                         &> /dev/null
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
  INFO ${BBLUE} "GIT"
  INFO ${GREEN} "Installing git"
  $IN git &> /dev/null
  INFO ${GREEN} "Reading and setting the configuration from $CD/git/config"
  . git/config
  sudo -u ${real_user} git config --global user.email $git_email
  sudo -u ${real_user} git config --global user.name $git_username

  read -t 5 -p "If you want to take control and generate passkeys, write y in 5 seconds [y/N] " choice
  if [ $? -eq 0 ] && { [ "${choice}" = "y" ] || [ "${choice}" = "Y" ]; }; then
    INFO ${GREEN} "Installing additional dependencies"
    dep ${IN} "apt-req/git.txt"
    SSH_DIR=${real_home}/.ssh
    if [ ! -d $SSH_DIR ]; then
      mkdir -p $SSH_DIR
      chown ${real_user}:${real_user} $SSH_DIR 
      chmod 700 $SSH_DIR
    fi
    INFO ${GREEN} "ssh dir at ${SSH_DIR}"
    
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

# REGOLITH
if in_list "${packages[*]}" "regolith"; then
  wget -qO - https://regolith-desktop.org/regolith.key | \
  gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg &> /dev/null
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
  INFO ${BGREEN} "neovim installed, re-source your shell"

  INFO ${GREEN} "Installing Astronvim"
  rm -rf ${real_home}/.config/nvim
  rm -rf ${real_home}/.local/share/nvim
  rm -rf ${real_home}/.local/state/nvim
  rm -rf ${real_home}/.cache/nvim
  #############################################################################
  # TODO REMOVE THIS LINE
  #############################################################################
  if [ -d "${real_home}/.config/nvim-profiles" ]; then rm -Rf $WORKING_DIR; fi
  sudo -u ${real_user} mkdir -p ${real_home}/.config/nvim-profiles/
  sudo -u ${real_user} git clone --depth 1 https://github.com/AstroNvim/template ${real_home}/.config/nvim-profiles/astronvim &> /dev/null
  sudo -u ${real_user} rm -rf ${real_home}/.config/nvim-profiles/astronvim/.git
  sudo chown -R ${real_user}:${real_user} ${real_home}/.config/nvim-profiles

  INFO ${GREEN} "Installing Dependencies"
  # VictorMono Font 
  if [ ! -d ${real_home}/.local/share/fonts ]; then
    mkdir ${real_home}/.local/share/fonts
  fi
  wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/VictorMono.zip -O font.zip &> /dev/null
  # wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip -O font.zip &> /dev/null
  unzip -f font.zip -d ${real_home}/.local/share/fonts &> /dev/null
  rm font.zip
  sudo -u ${real_user} fc-cache -f -v &> /dev/null

  INFO ${GREEN} "Configuring Astronvim"
  sudo -u "${real_user}" bash -c 'NVIM_APPNAME=nvim-profiles/astronvim /opt/nvim-linux64/bin/nvim +qall'
  if [[ "${real_shell}" == *"zsh" ]]; then 
    echo "export NVIM_APPNAME=nvim-profiles/astronvim" >> "${real_home}/.zshrc"
  elif [[ "${real_shell}" == *"bash" ]]; then 
    echo "export NVIM_APPNAME=nvim-profiles/astronvim" >> "${real_home}/.bashrc"
  fi
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
