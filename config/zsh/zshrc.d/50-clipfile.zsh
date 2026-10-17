# clipfile FILE...: put files on the system clipboard as files (not their text), the way
# a file manager's Copy does, so Ctrl+V in an email or chat attaches them.
# Linux: text/uri-list via xclip (mail clients, browsers, most apps; GNOME Files wants its
# own format and may not paste them). macOS: Finder file references via osascript.
clipfile() {
  if (( $# == 0 )); then
    print -u2 "usage: clipfile FILE..."
    return 1
  fi
  local f
  local -a paths
  for f in "$@"; do
    [[ -e $f ]] || { print -u2 "clipfile: no such file: $f"; return 1 }
    paths+=("${f:A}")  # absolute path, symlinks resolved
  done

  if [[ $OSTYPE == darwin* ]]; then
    local list=""
    for f in "${paths[@]}"; do
      list+="${list:+, }POSIX file \"${f//\"/\\\"}\""
    done
    osascript -e "tell application \"Finder\" to set the clipboard to {$list}" >/dev/null
  else
    (( $+commands[xclip] )) || { print -u2 "clipfile: xclip is not installed"; return 1 }
    python3 -c 'import sys, urllib.parse
print("\r\n".join("file://" + urllib.parse.quote(p) for p in sys.argv[1:]), end="")' "${paths[@]}" |
      xclip -selection clipboard -t text/uri-list
  fi
  print "copied ${#paths} file(s) to the clipboard"
}
