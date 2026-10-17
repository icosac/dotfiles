# fzf key bindings and completion: Ctrl-R history, Ctrl-T files, Alt-C directories,
# `**<Tab>` fuzzy completion (./install.sh ohmyzsh installs a recent fzf)
(( $+commands[fzf] )) && fzf --zsh >/dev/null 2>&1 || return 0
source <(fzf --zsh)
