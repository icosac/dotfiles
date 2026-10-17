#!/usr/bin/env bash
# The configs dotfiles links into $HOME, as "PROGRAM<TAB>SOURCE<TAB>TARGET" lines
# (SOURCE in the repo; PROGRAM groups them in check.sh's report). One list for
# install.sh / setup/regolith.sh (which create the links) and check.sh (which
# verifies them).

# Linked by every ./install.sh run
base_links() {
  local C="$DOTFILES/config" vscode
  if [ "$(uname -s)" = Darwin ]; then
    vscode="$HOME/Library/Application Support/Code/User"
  else
    vscode="$HOME/.config/Code/User"
  fi
  printf '%s\t%s\t%s\n' \
    zsh      "$C/zsh/.zshrc"              "$HOME/.zshrc" \
    git      "$C/git/.gitconfig"          "$HOME/.gitconfig" \
    tmux     "$C/tmux/.tmux.conf"         "$HOME/.tmux.conf" \
    tmux     "$C/tmux/tmux-status"        "$HOME/.local/bin/tmux-status" \
    latex    "$C/latex/.latexmkrc"        "$HOME/.latexmkrc" \
    kitty    "$C/kitty/.config/kitty"     "$HOME/.config/kitty" \
    ghostty  "$C/ghostty/.config/ghostty" "$HOME/.config/ghostty" \
    neovim   "$C/nvim/.config/nvim"       "$HOME/.config/nvim" \
    vscode   "$C/vscode/settings.json"    "$vscode/settings.json" \
    vscode   "$C/vscode/keybindings.json" "$vscode/keybindings.json"
}

# Linked by ./install.sh regolith
regolith_links() {
  printf '%s\t%s\t%s\n' \
    regolith "$DOTFILES/config/regolith3"                      "$HOME/.config/regolith3" \
    regolith "$DOTFILES/config/regolith3/assets/IMG_2882.png" "$HOME/.background.png"
}

# link_all FUNCTION: create every link the list function prints
link_all() {
  local _program src dst
  while IFS=$'\t' read -r _program src dst; do
    link "$src" "$dst"
  done < <("$1")
}
