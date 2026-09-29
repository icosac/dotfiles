# PATH entries are added only if the directory exists; `typeset -U` drops duplicates.
typeset -U path

[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

for _d in "$HOME/.local/bin" "$HOME/bin"; do
  [[ -d $_d ]] && path=("$_d" $path)
done
for _d in /opt/nvim/bin /usr/local/cuda/bin "$HOME"/Library/Python/*/bin(N); do
  [[ -d $_d ]] && path+=("$_d")
done
unset _d
