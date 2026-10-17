# Managed by the dotfiles repo (config/zsh/.zshrc) -- edits here are edits in the repo.
# Machine-specific or private settings go in ~/.zshrc.local (never committed).

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"
plugins=(git extract docker colored-man-pages zsh-autosuggestions)
# Extra completion definitions: must be on fpath before oh-my-zsh runs compinit
fpath+=("${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src")

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  # Minimal fallback until `./install.sh ohmyzsh` has run
  autoload -Uz compinit && compinit
  PROMPT='%n@%m %~ %# '
fi

# Load every snippet next to this file (resolved through the symlink).
for _f in "${${(%):-%x}:A:h}"/zshrc.d/*.zsh(N); do
  source "$_f"
done
unset _f

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
