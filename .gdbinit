# Portable GDB config for CTF / pwn.
# Loads pwndbg, GEF or PEDA automatically if one of them is installed.

set pagination off
set confirm off
set width 0
set height 0
set history save on
set history size 10000
set history filename ~/.gdb_history
set print pretty on
set print elements 0
set print repeats 0
set print thread-events off
set breakpoint pending on

python
import os
import gdb

# Keep GDB from trying to download debuginfo on a contest network.
try:
    gdb.execute("set debuginfod enabled off", to_string=True)
except Exception:
    pass

try:
    gdb.execute("set disassembly-flavor intel", to_string=True)
except Exception:
    pass

try:
    gdb.execute("set python print-stack full", to_string=True)
except Exception:
    pass

home = os.path.expanduser("~")
candidates = [
    os.path.join(home, ".local", "share", "pwndbg", "gdbinit.py"),
    os.path.join(home, "pwndbg", "gdbinit.py"),
    os.path.join(home, "tools", "pwndbg", "gdbinit.py"),
    os.path.join(home, ".gdbinit-gef.py"),
    os.path.join(home, "gef.py"),
    os.path.join(home, ".gef.py"),
    os.path.join(home, ".local", "share", "gef", "gef.py"),
    os.path.join(home, "peda", "peda.py"),
]

for path in candidates:
    if not os.path.isfile(path):
        continue
    try:
        gdb.execute("source " + path, to_string=True)
        print("[dotfiles] loaded gdb plugin: " + path)
        break
    except Exception as exc:
        print("[dotfiles] failed to load %s: %s" % (path, exc))
end
