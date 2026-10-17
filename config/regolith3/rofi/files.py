#!/usr/bin/env python3
"""
rofi script mode: files and folders under $HOME, so the Win+Space launcher finds
them next to the apps (see launcher.sh). Selecting one opens it with xdg-open.

The list comes from a cache that is refreshed in the background (fd, about a
quarter of a second), so the launcher never waits for the file scan.
"""
import os
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME", os.path.join(HOME, ".cache")), "rofi-files.list")
MAX_AGE = 120  # seconds before a launch triggers a background rescan
# fd already skips hidden and .gitignored files; these are just noise in a launcher
EXCLUDE = ["snap", "miniconda3", "anaconda3", "node_modules", "__pycache__", "go/pkg",
           "*.o", "*.pyc", "build", "target", "venv", ".venv"]

ICONS = {
    ".pdf": "application-pdf", ".png": "image-x-generic", ".jpg": "image-x-generic",
    ".jpeg": "image-x-generic", ".svg": "image-x-generic", ".gif": "image-x-generic",
    ".mp4": "video-x-generic", ".mkv": "video-x-generic", ".mp3": "audio-x-generic",
    ".zip": "package-x-generic", ".gz": "package-x-generic", ".tar": "package-x-generic",
    ".doc": "x-office-document", ".docx": "x-office-document", ".odt": "x-office-document",
    ".xls": "x-office-spreadsheet", ".xlsx": "x-office-spreadsheet", ".csv": "x-office-spreadsheet",
    ".ppt": "x-office-presentation", ".pptx": "x-office-presentation",
    ".sh": "text-x-script", ".py": "text-x-script", ".tex": "text-x-generic",
}


def fd():
    for name in ("fd", "fdfind"):
        for d in os.environ.get("PATH", "").split(":") + ["/usr/bin"]:
            p = os.path.join(d, name)
            if os.access(p, os.X_OK):
                return p
    return None


def refresh():
    """Rebuild the cache: one rofi row per path, written atomically."""
    exe = fd()
    if not exe:
        return
    cmd = [exe, "--type", "f", "--type", "d", "--absolute-path", "--color", "never", "."]
    for e in EXCLUDE:
        cmd += ["--exclude", e]
    out = subprocess.run(cmd + [HOME], capture_output=True, text=True).stdout
    rows = []
    for path in out.splitlines():
        path = path.rstrip("/")
        if not path or path == HOME:
            continue
        is_dir = os.path.isdir(path)
        name = os.path.basename(path)
        where = "~" + os.path.dirname(path)[len(HOME):] if path.startswith(HOME) else os.path.dirname(path)
        icon = "folder" if is_dir else ICONS.get(os.path.splitext(name)[1].lower(), "text-x-generic")
        rows.append(f"{name}   {where}\0icon\x1f{icon}\x1finfo\x1f{path}")
    tmp = CACHE + ".tmp"
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(tmp, "w") as f:
        f.write("\n".join(rows) + "\n")
    os.replace(tmp, CACHE)


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--refresh":
        refresh()
        return 0

    if os.environ.get("ROFI_RETV") == "1" and os.environ.get("ROFI_INFO"):
        subprocess.Popen(["xdg-open", os.environ["ROFI_INFO"]], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return 0

    print("\0no-custom\x1ftrue")
    try:
        stale = time.time() - os.path.getmtime(CACHE) > MAX_AGE
    except OSError:
        refresh()  # first run ever: build it now
        stale = False
    if stale:
        subprocess.Popen([sys.executable, __file__, "--refresh"], start_new_session=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        with open(CACHE) as f:
            sys.stdout.write(f.read())
    except OSError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
