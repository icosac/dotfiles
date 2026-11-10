# Word deletion like in other editors (loaded after oh-my-zsh's key bindings).
# Ghostty and kitty send ^H for Ctrl+Backspace (plain Backspace is ^?) and ESC[3;5~ for
# Ctrl+Delete, and tmux passes both through unchanged.
bindkey '^H' backward-kill-word        # Ctrl+Backspace: delete the previous word
bindkey '^[[3;5~' kill-word            # Ctrl+Delete: delete the next word
# A "word" stops at / . - _ and the like (oh-my-zsh sets WORDCHARS empty), so
# Ctrl+Backspace on ~/dotfiles/config deletes only "config", as in VS Code
