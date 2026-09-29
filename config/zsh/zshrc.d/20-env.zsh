export LANG="${LANG:-en_US.UTF-8}"

if (( $+commands[nvim] )); then
  export EDITOR=nvim VISUAL=nvim
fi

# Debian/Ubuntu ship fd as `fdfind`
if (( $+commands[fdfind] && ! $+commands[fd] )); then
  alias fd=fdfind
fi
