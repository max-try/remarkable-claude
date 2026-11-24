#!/usr/bin/env python3
"""Checks tools/paper-pro/check-hashtab.py against made-up name maps."""
import importlib.util
import os
import struct
import subprocess
import sys
import tempfile

here = os.path.dirname(os.path.abspath(__file__))
tool = os.path.join(here, "..", "tools", "paper-pro", "check-hashtab.py")
spec = importlib.util.spec_from_file_location("check_hashtab", tool)
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)

# The hashes inkDiary.qmd uses are qmldiff's hashes of these names.
assert c.qmldiff_hash("/qml/device/view/documentview/DocumentView.qml") == 1224665461898798997
assert c.qmldiff_hash("FocusScope") == 8397993708429497603
assert c.qmldiff_hash("root") == 6504254477
qmd = open(os.path.join(here, "..", "inkDiary.qmd")).read()
assert "AFFECT [[1224665461898798997]]" in qmd and "TRAVERSE [[8397993708429497603]]#[[6504254477]]" in qmd


def write(names, path):
    data = struct.pack(">QI", 0, 5) + b"magic" + struct.pack(">QI", c.VERSION_KEY, 8) + b"3.29.1.0"
    for name in names:
        raw = name.encode()
        data += struct.pack(">QI", c.qmldiff_hash(name), len(raw)) + raw
    with open(path, "wb") as f:
        f.write(data)


with tempfile.TemporaryDirectory() as tmp:
    full, partial = os.path.join(tmp, "full"), os.path.join(tmp, "partial")
    write(list(c.NEEDED), full)
    write([n for n in c.NEEDED if n != "toolbar"], partial)
    ok = subprocess.run([sys.executable, tool, full], capture_output=True, text=True)
    bad = subprocess.run([sys.executable, tool, partial], capture_output=True, text=True)
    assert ok.returncode == 0 and "All needed names found" in ok.stdout and "3.29.1.0" in ok.stdout, ok.stdout
    assert bad.returncode == 1 and "MISSING  toolbar" in bad.stdout, bad.stdout
print("PASS: qmd hashes match their names; name-map checker finds present and missing names")
