# Commands without a zsh completion only complete file names. For those, complete
# options (`cmd --<Tab>`) from the command's own --help output instead.
_default_or_help() {
  if [[ $PREFIX == -* ]] && (( CURRENT > 1 )); then
    _gnu_generic && return
  fi
  _default
}
compdef _default_or_help -default-
