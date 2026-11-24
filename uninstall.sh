#!/bin/sh
# Removes the plugin and its notebook patch. Keeps your settings and API key
# (/home/root/.config/ink-diary) and the Stage 1 test photos (/home/root/ink-diary-stage1).
set -eu
rm -f /home/root/xovi/extensions.d/ink-diary.so /home/root/xovi/exthome/qt-resource-rebuilder/inkDiary.qmd
printf 'Plugin removed. To get the normal notebook app back now: bash /home/root/xovi/stock\n'
printf '(or just restart the tablet). Settings kept in /home/root/.config/ink-diary.\n'
