#!/usr/bin/env python3
"""
Display per-workspace app icons for Polybar.
"""
import json
import re
import subprocess
import sys
from typing import Dict, List
import re

# Map window classes to icons (Font Awesome / Nerd Font friendly).
ICON_MAP = {
    "firefox": "",
    "firefox_firefox": "",
    "google-chrome": "",
    "chromium": "",
    "code": "",
    "codium": "",
    "code - insiders": "",
    "gnome-terminal": "",
    "alacritty": "",
    "kitty": "",
    "org.gnome.nautilus": "",
    "nautilus": "",
    "thunar": "",
    "jetbrains-idea": "",
    "jetbrains-pycharm": "",
    "libreoffice": "",
    "libreoffice-writer": "",
    "libreoffice-calc": "",
    "spotify": "",
    "vlc": "",
    "evince": "",
    "okular": "",
    "discord": "",
    "slack": "",
    "org.gnome.gedit": "",
    "gedit": "",
    "org.gnome.calendar": "",
    "org.gnome.eog": "",
    "feh": "",
    "telegram": "",
    "telegramdesktop": "",
    "telegram-desktop": "",
    "zotero": "Zotero",
}


def class_to_label(cls: str) -> str:
    return cls[:2].upper() if cls else "??"


def class_to_icon_or_label(cls: str) -> str:
    icon = ICON_MAP.get(cls.lower())
    if icon:
        return icon
    return class_to_label(cls)


def collect_workspaces(node: Dict, current_ws: str, out: Dict[str, List[str]]) -> None:
    ntype = node.get("type")
    if ntype == "workspace":
        current_ws = node.get("name")
        if current_ws and not current_ws.startswith("__"):
            out.setdefault(current_ws, [])
    win_class = None
    if node.get("window") and node.get("window_properties"):
        win_class = node["window_properties"].get("class")
    if win_class and current_ws and not current_ws.startswith("__"):
        out.setdefault(current_ws, []).append(class_to_icon_or_label(win_class))
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        collect_workspaces(child, current_ws, out)


def sort_key(ws_name: str):
    try:
        num = int(ws_name.split(":")[0])
        return (0, num)
    except ValueError:
        return (1, ws_name)


def main() -> int:
    try:
        tree_json = subprocess.check_output(["i3-msg", "-t", "get_tree"], text=True)
        tree = json.loads(tree_json)
    except Exception:
        return 0

    workspaces: Dict[str, List[str]] = {}
    collect_workspaces(tree, None, workspaces)

    parts = []
    tag_re = re.compile(r"<[^>]+>")

    for ws in sorted(workspaces.keys(), key=sort_key):
        # Strip any pango/markup tags and collapse whitespace.
        clean_ws = tag_re.sub("", ws)
        clean_ws = " ".join(clean_ws.split())
        # Remove a leading duplicate number (e.g., "1: 1 :" -> "1").
        clean_ws = f"{clean_ws.split(':')[0]}"
        
        icons = workspaces[ws]
        display_icons = " ".join(icons) if icons else "—"
        parts.append(f"{clean_ws}: {display_icons}")

    if parts:
        print(" | ".join(parts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
