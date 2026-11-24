#!/bin/sh
# Read-only: prints the facts the Paper Pro build depends on.
# Changes nothing, installs nothing, and doesn't touch notebooks or settings.
# The same commands are in docs/paper-pro/YOUR-STEPS.md as one line to paste.
echo "== model";      cat /sys/devices/soc0/machine 2>/dev/null; echo
echo "== processor";  uname -m
echo "== software";   grep -E '^(IMG_VERSION|VERSION_ID)=' /etc/os-release
echo "== Qt";         ls /usr/lib/libQt6Core.so.* 2>/dev/null
echo "== xovi";       ls /home/root/xovi /home/root/xovi/extensions.d 2>/dev/null || echo "not installed"
echo "== app";        sha256sum /usr/bin/xochitl
