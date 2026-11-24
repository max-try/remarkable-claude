#!/usr/bin/env python3
"""Checks a Paper Pro name map ("hashtab") for every name the button patch relies on.

    python3 tools/paper-pro/check-hashtab.py hashtab-ferrari-3.29.1.0

The hashtab comes from `bash /home/root/xovi/rebuild_hashtable` on the tablet (Stage 1).
It lists the strings found in the notebook app's screens, so a name missing from it
means reMarkable renamed or removed that part in this software version. A name that is
present is a good sign, not proof that it is still in the same place. Reads the file
only and prints no other names from it (they come from reMarkable's own software).
"""
import struct
import sys


def qmldiff_hash(text: str) -> int:
    # qmldiff src/hash.rs: djb2-style, seed 5481, one byte per character, 64-bit wrap.
    value = 5481
    for char in text:
        value = ((value << 5) + value + (ord(char) & 0xFF)) & 0xFFFFFFFFFFFFFFFF
    return value


# qmldiff src/hashtab.rs INTERNAL_HASHTAB_VERSION_ALLOWED_KEY: the entry holding the version.
VERSION_KEY = 17607111715072197239

# Names the button patch needs: name -> why.
NEEDED = {
    "/qml/device/view/documentview/DocumentView.qml": "the file the button is added to (inkDiary.qmd AFFECT)",
    "FocusScope": "the item the button goes inside (TRAVERSE)",
    "root": "the item the button goes inside (TRAVERSE)",
    "toolbar": "hidden while the page is read",
    "zoomButton": "hidden while the page is read",
}
# Names the plugin uses from C++. The notebook may call them only from its own code,
# so a miss here is not an error; the Stage 1 test checks them directly instead.
ALSO_USED = {
    "shown": "toolbar state, recorded by the Stage 1 test",
    "expanded": "toolbar state, recorded by the Stage 1 test",
    "insertImageFileAsSceneItem": "puts the answer into the page",
    "viewToScene": "works out where on the page the answer goes",
    "boundingRect": "where existing writing ends, so answers go below it",
}


def read_hashtab(path: str) -> dict:
    table = {}
    with open(path, "rb") as f:
        data = f.read()
    pos = 0
    while pos + 12 <= len(data):
        key, length = struct.unpack(">QI", data[pos:pos + 12])
        pos += 12
        table[key] = data[pos:pos + length].decode("utf-8", "replace")
        pos += length
    return table


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    table = read_hashtab(sys.argv[1])
    version = table.get(VERSION_KEY, "not recorded")
    print(f"{len(table)} names; software version recorded in the file: {version}")
    missing = 0
    print("Needed by the button patch:")
    for name, why in NEEDED.items():
        found = table.get(qmldiff_hash(name)) == name
        missing += not found
        print(f"  {'ok     ' if found else 'MISSING'}  {name}  ({why})")
    print("Used from the plugin's code (a miss here is only informational):")
    for name, why in ALSO_USED.items():
        found = table.get(qmldiff_hash(name)) == name
        print(f"  {'seen   ' if found else 'not seen'}  {name}  ({why})")
    print("All needed names found." if not missing else f"{missing} needed name(s) missing: the patch must be updated for this version.")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
