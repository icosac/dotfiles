[[ $OSTYPE == darwin* ]] || return 0

if [[ -d /usr/local/opt/bison ]]; then
  path=(/usr/local/opt/bison/bin $path)
  export LDFLAGS="-L/usr/local/opt/bison/lib"
fi

alias subl='open -a "Sublime Text"'
alias preview='open -a Preview'
alias upgrade_oh_my_zsh='omz update'
