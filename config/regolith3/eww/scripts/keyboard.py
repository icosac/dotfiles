#!/usr/bin/env python3
"""
Active keyboard layout for the eww bar (e.g. "us"), printed whenever it changes.

`setxkbmap -query` lists every configured layout ("us,it"); which one is active is
the X keyboard "group", read here through libX11's XkbGetState.
"""
import ctypes
import ctypes.util
import subprocess
import sys
import time

XKB_USE_CORE_KBD = 0x100


class XkbStateRec(ctypes.Structure):
    _fields_ = [("group", ctypes.c_ubyte), ("locked_group", ctypes.c_ubyte),
                ("base_group", ctypes.c_ushort), ("latched_group", ctypes.c_ushort),
                ("mods", ctypes.c_ubyte), ("base_mods", ctypes.c_ubyte),
                ("latched_mods", ctypes.c_ubyte), ("locked_mods", ctypes.c_ubyte),
                ("compat_state", ctypes.c_ubyte), ("grab_mods", ctypes.c_ubyte),
                ("compat_grab_mods", ctypes.c_ubyte), ("lookup_mods", ctypes.c_ubyte),
                ("compat_lookup_mods", ctypes.c_ubyte), ("ptr_buttons", ctypes.c_ushort)]


def layouts():
    out = subprocess.run(["setxkbmap", "-query"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        if line.startswith("layout:"):
            return line.split()[1].split(",")
    return ["?"]


def main():
    x11 = ctypes.cdll.LoadLibrary(ctypes.util.find_library("X11"))
    x11.XOpenDisplay.restype = ctypes.c_void_p
    display = x11.XOpenDisplay(None)
    if not display:
        print("?", flush=True)
        return 1
    state = XkbStateRec()
    names, names_at, last = layouts(), time.monotonic(), None
    while True:
        if time.monotonic() - names_at > 10:  # layouts can be changed at runtime
            names, names_at = layouts(), time.monotonic()
        x11.XkbGetState(ctypes.c_void_p(display), XKB_USE_CORE_KBD, ctypes.byref(state))
        current = names[state.group] if state.group < len(names) else names[0]
        if current != last:
            print(current, flush=True)
            last = current
        time.sleep(0.3)


if __name__ == "__main__":
    sys.exit(main())
