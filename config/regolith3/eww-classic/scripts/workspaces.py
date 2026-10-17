#!/usr/bin/env python3
"""
Per-workspace app list for the eww bottom bar, with the apps' real icons.

Prints one JSON line per change (eww `deflisten`):
  [{"num": "1", "focused": true, "apps": [{"id": 94371, "icon": "/path.png", "name": "firefox", "focused": false}]}]

Icons are resolved like a dock does it: window class -> .desktop file
(StartupWMClass, or the file name) -> its Icon= -> a file in the GTK icon theme.
"""
import configparser
import glob
import json
import os
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk  # noqa: E402

ICON_SIZE = 32  # looked up larger than drawn, so it stays sharp when scaled down
FALLBACK_ICON = "application-x-executable"


def desktop_dirs():
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
    extra = ["/var/lib/snapd/desktop", "/var/lib/flatpak/exports/share",
             os.path.expanduser("~/.local/share/flatpak/exports/share")]
    seen = []
    for d in [data_home] + data_dirs + extra:
        d = os.path.join(d, "applications")
        if os.path.isdir(d) and d not in seen:
            seen.append(d)
    return seen


def load_desktop_icons():
    """Map lowercase window class / desktop id -> Icon= value."""
    by_wmclass, by_id = {}, {}
    for d in desktop_dirs():
        for path in glob.glob(os.path.join(d, "*.desktop")):
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(path, encoding="utf-8")
                entry = cp["Desktop Entry"]
            except Exception:
                continue
            icon = entry.get("Icon")
            if not icon:
                continue
            wmclass = entry.get("StartupWMClass")
            if wmclass:
                by_wmclass.setdefault(wmclass.lower(), icon)
            by_id.setdefault(os.path.basename(path)[:-len(".desktop")].lower(), icon)
    return by_wmclass, by_id


BY_WMCLASS, BY_ID = load_desktop_icons()
THEME = Gtk.IconTheme.get_default()
_cache = {}


def icon_file(name):
    if not name:
        return None
    if os.path.isabs(name):
        return name if os.path.exists(name) else None
    info = THEME.lookup_icon(name, ICON_SIZE, 0)
    return info.get_filename() if info else None


def icon_for(wm_class, instance):
    key = (wm_class or "", instance or "")
    if key not in _cache:
        candidates = []
        for c in (wm_class, instance):
            if c:
                c = c.lower()
                candidates += [BY_WMCLASS.get(c), BY_ID.get(c), c, c.split(".")[-1]]
        path = next((p for p in map(icon_file, filter(None, candidates)) if p), None)
        _cache[key] = path or icon_file(FALLBACK_ICON) or ""
    return _cache[key]


def i3(*args):
    return json.loads(subprocess.check_output(["i3-msg", "-t", *args], text=True))


def collect(node, ws, out):
    if node.get("type") == "workspace":
        name = node.get("name") or ""
        if name.startswith("__"):  # i3 scratchpad
            return
        ws = {"name": name, "num": name.split(":")[0].strip(), "apps": []}
        out.append(ws)
    props = node.get("window_properties")
    if ws is not None and node.get("window") and props and props.get("class") != "Polybar":
        ws["apps"].append({
            "id": node["id"],
            "name": props.get("class") or "",
            "icon": icon_for(props.get("class"), props.get("instance")),
            "focused": node.get("focused", False),
        })
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        collect(child, ws, out)


def snapshot():
    workspaces = []
    collect(i3("get_tree"), None, workspaces)
    focused = {w["name"] for w in i3("get_workspaces") if w.get("focused")}
    for w in workspaces:
        w["focused"] = w.pop("name") in focused
    workspaces.sort(key=lambda w: (not w["num"].isdigit(), int(w["num"]) if w["num"].isdigit() else 0, w["num"]))
    return workspaces


def main():
    last = None
    events = subprocess.Popen(["i3-msg", "-t", "subscribe", "-m", '["window", "workspace"]'],
                              stdout=subprocess.PIPE, text=True)
    lines = iter(events.stdout.readline, "")
    while True:
        try:
            out = json.dumps(snapshot())
        except Exception:
            out = "[]"
        if out != last:
            print(out, flush=True)
            last = out
        if next(lines, None) is None:  # i3 restarted or exited
            return 1


if __name__ == "__main__":
    sys.exit(main())
