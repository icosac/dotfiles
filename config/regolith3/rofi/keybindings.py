#!/usr/bin/env python3
"""
List Regolith's keybindings for rofi (Win+Shift+?, see launcher.sh keys).

Regolith documents each binding in its i3 config partials with a comment like
  ## Launch // Application // <> Space ##
This turns those into aligned, searchable rows: "Win+Space   Launch › Application".
User partials in ~/.config/regolith3 are read after the system ones, as i3 does, and
replace the system entry for the same action (e.g. File Search moved to Win+Shift+D).
"""
import glob
import os
import re

DIRS = [
    "/usr/share/regolith/common/config.d",
    "/usr/share/regolith/i3/config.d",
    os.path.expanduser("~/.config/regolith3/common-wm/config.d"),
    os.path.expanduser("~/.config/regolith3/i3/config.d"),
]
LINE = re.compile(r"^##\s*(.+?)\s*//\s*(.+?)\s*//\s*(.+?)\s*##\s*$")
MODS = {"<Shift>": "Shift+", "<Ctrl>": "Ctrl+", "<Alt>": "Alt+"}  # anything else is
# the super key, written as a Windows-logo glyph in brackets


def keys(spec):
    mods, _, key = spec.partition(" ")
    out = ""
    for token in re.findall(r"<[^>]*>", mods):
        out += MODS.get(token, "Win+")
    return out + key.strip()


USER = os.path.expanduser("~/.config/regolith3")
system, user = [], {}  # system: every entry (some actions have two key sets); user: overrides
for d in DIRS:
    for path in sorted(glob.glob(os.path.join(d, "*"))):
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            continue
        for line in text.splitlines():
            m = LINE.match(line)
            if not m:
                continue
            category, action, spec = m.groups()
            if d.startswith(USER):
                user.setdefault((category, action), []).append(keys(spec))
            elif (category, action, keys(spec)) not in system:
                system.append((category, action, keys(spec)))
rows = [(k, f"{c} › {a}") for c, a, k in system if (c, a) not in user]
rows += [(k, f"{c} › {a}") for (c, a), ks in user.items() for k in ks]

width = max((len(k) for k, _ in rows), default=0)
for k, what in sorted(rows, key=lambda r: r[1]):
    print(f"{k.ljust(width)}   {what}")
