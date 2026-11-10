# System summary when a shell opens: new terminal windows and tabs, tmux panes, ssh
# logins (installed by ./install.sh, setup/fastfetch.sh). Only in an interactive shell on
# a terminal, and not in Neovim's :terminal or VS Code's terminal.
# Turn it off on one machine with `export NO_FASTFETCH=1` in ~/.zshenv.
if [[ -o interactive && -t 1 && -z $NO_FASTFETCH && -z $NVIM && $TERM_PROGRAM != vscode ]] &&
   (( $+commands[fastfetch] )); then
  fastfetch
fi
