[[ -n $KITTY_WINDOW_ID ]] && (( $+commands[kitty] )) || return 0

# Copies kitty's terminfo to the remote host, so TERM=xterm-kitty works there.
alias ssh='kitty +kitten ssh'
